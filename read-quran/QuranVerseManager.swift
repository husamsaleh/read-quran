//
//  QuranVerseManager.swift
//  read-quran
//
//  Created by husam saleh on 25/03/2025.
//

import Foundation
import SwiftUI
import AVFoundation

struct QuranVerse: Identifiable {
    let id = UUID()
    let text: String
    let reference: String
    let audioURL: URL?
    let transliteration: String?
    let translation: String?
}

struct QuranChapter: Decodable {
    let name: String
    let englishName: String
    let number: Int
    let numberOfVerses: Int
    
    enum CodingKeys: String, CodingKey {
        case name = "name"
        case englishName = "englishName"
        case number = "number"
        case numberOfVerses = "numberOfAyahs"
    }
}

// Root response structure
struct QuranResponse: Decodable {
    let code: Int
    let status: String
    let data: [QuranChapter]
}

// Single chapter response structure
struct ChapterResponse: Decodable {
    let code: Int
    let status: String
    let data: ChapterData
}

struct ChapterData: Decodable {
    let number: Int
    let name: String
    let englishName: String
    let englishNameTranslation: String
    let ayahs: [Ayah]
}

struct Ayah: Decodable {
    let number: Int
    let text: String
    let numberInSurah: Int
    let audio: String?
    
    enum CodingKeys: String, CodingKey {
        case number
        case text
        case numberInSurah
        case audio
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        number = try container.decode(Int.self, forKey: .number)
        text = try container.decode(String.self, forKey: .text)
        numberInSurah = try container.decode(Int.self, forKey: .numberInSurah)
        
        // Handle the missing audio field gracefully
        audio = try container.decodeIfPresent(String.self, forKey: .audio) ?? 
                "https://cdn.islamic.network/quran/audio/128/ar.alafasy/\(number).mp3"
    }
}

class QuranVerseManager: ObservableObject {
    @Published var currentVerseIndex = 0
    @Published var verses: [QuranVerse] = []
    @Published var chapters: [QuranChapter] = []
    @Published var currentChapter: Int = 1
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var audioPlayer: AVPlayer?
    
    init() {
        fetchChapters()
    }
    
    var currentVerse: QuranVerse {
        guard !verses.isEmpty else {
            return QuranVerse(text: "Loading...", reference: "", audioURL: nil, transliteration: nil, translation: nil)
        }
        return verses[min(currentVerseIndex, verses.count - 1)]
    }
    
    func nextVerse() {
        if currentVerseIndex < verses.count - 1 {
            currentVerseIndex += 1
        } else {
            // If we're at the last verse of the current chapter, load the next chapter
            if currentChapter < 114 {
                currentChapter += 1
                fetchVersesForCurrentChapter()
                currentVerseIndex = 0
            } else {
                // We're at the end of the Quran, wrap around to the beginning
                currentChapter = 1
                fetchVersesForCurrentChapter()
                currentVerseIndex = 0
            }
        }
    }
    
    func previousVerse() {
        if currentVerseIndex > 0 {
            currentVerseIndex -= 1
        } else {
            // If we're at the first verse of the current chapter, load the previous chapter
            if currentChapter > 1 {
                currentChapter -= 1
                fetchVersesForCurrentChapter { [weak self] in
                    // Jump to the last verse of the previous chapter
                    self?.currentVerseIndex = (self?.verses.count ?? 1) - 1
                }
            }
        }
    }
    
    func fetchChapters() {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "https://api.alquran.cloud/v1/surah") else {
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            return
        }
        
        print("Fetching chapters from: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                // Print the raw JSON string for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Received JSON: \(jsonString.prefix(200))...")
                }
                
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(QuranResponse.self, from: data)
                    self?.chapters = response.data
                    
                    // Once we have chapters, fetch the first chapter's verses
                    self?.fetchVersesForCurrentChapter()
                } catch {
                    self?.errorMessage = "Failed to decode: \(error.localizedDescription)"
                    print("Decoding error: \(error)")
                }
            }
        }.resume()
    }
    
    func fetchVersesForCurrentChapter(completion: (() -> Void)? = nil) {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "https://api.alquran.cloud/v1/surah/\(currentChapter)") else {
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            return
        }
        
        print("Fetching chapter \(currentChapter) from: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                // Print a snippet of the raw JSON for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Received chapter data: \(jsonString.prefix(200))...")
                }
                
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(ChapterResponse.self, from: data)
                    
                    let chapterName = response.data.englishName
                    let arabicName = response.data.name
                    
                    self?.verses = response.data.ayahs.map { ayah in
                        let audioURLString = ayah.audio
                        let audioURL = URL(string: audioURLString ?? "")
                        
                        return QuranVerse(
                            text: ayah.text,
                            reference: "\(chapterName) (\(arabicName)) \(self?.currentChapter ?? 0):\(ayah.numberInSurah)",
                            audioURL: audioURL,
                            transliteration: nil,
                            translation: nil
                        )
                    }
                    
                    completion?()
                } catch {
                    self?.errorMessage = "Failed to decode: \(error.localizedDescription)"
                    print("Verse decoding error: \(error)")
                    
                    // Fallback to sample data for development/testing
                    if self?.verses.isEmpty ?? true {
                        self?.loadSampleData()
                    }
                }
            }
        }.resume()
    }
    
    private func loadSampleData() {
        // Sample data for fallback when API fails
        verses = [
            QuranVerse(text: "In the name of Allah, the Entirely Merciful, the Especially Merciful.", 
                      reference: "Al-Fatihah 1:1", 
                      audioURL: nil, 
                      transliteration: nil, 
                      translation: nil),
            QuranVerse(text: "All praise is due to Allah, Lord of the worlds.", 
                      reference: "Al-Fatihah 1:2", 
                      audioURL: nil, 
                      transliteration: nil, 
                      translation: nil),
            QuranVerse(text: "The Entirely Merciful, the Especially Merciful.", 
                      reference: "Al-Fatihah 1:3", 
                      audioURL: nil, 
                      transliteration: nil, 
                      translation: nil)
        ]
        
        if chapters.isEmpty {
            chapters = [
                QuranChapter(name: "الفاتحة", englishName: "Al-Fatihah", number: 1, numberOfVerses: 7),
                QuranChapter(name: "البقرة", englishName: "Al-Baqarah", number: 2, numberOfVerses: 286)
            ]
        }
    }
    
    func playCurrentVerseAudio() {
        guard let audioURL = currentVerse.audioURL else {
            errorMessage = "No audio available for this verse"
            return
        }
        
        print("Attempting to play audio from: \(audioURL.absoluteString)")
        
        // Stop any existing audio
        stopAudio()
        
        // Create a new player and play the audio
        let playerItem = AVPlayerItem(url: audioURL)
        audioPlayer = AVPlayer(playerItem: playerItem)
        
        // Add observer for when playback ends
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        audioPlayer?.play()
    }
    
    @objc func playerDidFinishPlaying(notification: Notification) {
        // Clean up when playback finishes
        NotificationCenter.default.removeObserver(
            self,
            name: .AVPlayerItemDidPlayToEndTime,
            object: notification.object
        )
    }
    
    func stopAudio() {
        audioPlayer?.pause()
        audioPlayer = nil
    }
    
    func selectChapter(_ chapterNumber: Int) {
        if chapterNumber >= 1 && chapterNumber <= 114 {
            currentChapter = chapterNumber
            fetchVersesForCurrentChapter()
            currentVerseIndex = 0
        }
    }
} 