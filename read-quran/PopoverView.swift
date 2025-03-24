//
//  PopoverView.swift
//  read-quran
//
//  Created by husam saleh on 25/03/2025.
//

import SwiftUI

struct PopoverView: View {
    @EnvironmentObject var verseManager: QuranVerseManager
    @State private var showChapterPicker = false
    
    var body: some View {
        ZStack {
            // Background gradient - using a more distinct, darker gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.sRGB, red: 0.2, green: 0.25, blue: 0.3, opacity: 1),
                    Color(.sRGB, red: 0.1, green: 0.15, blue: 0.2, opacity: 1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if verseManager.isLoading {
                loadingView
            } else if let error = verseManager.errorMessage {
                errorView(message: error)
            } else {
                contentView
            }
        }
        .frame(width: 350, height: 300)
    }
    
    // MARK: - Content Views
    
    private var contentView: some View {
        VStack(spacing: 0) {
            headerView
            Divider().background(Color.white.opacity(0.2)).padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 16) {
                    // Verse text
                    Text(verseManager.currentVerse.text)
                        .font(.system(size: 20, weight: .medium))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .foregroundColor(.white)
                    
                    // Reference
                    Text(verseManager.currentVerse.reference)
                        .font(.system(size: 14))
                        .padding(8)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(8)
                        .foregroundColor(Color(.lightGray))
                }
                .padding(.vertical, 10)
            }
            
            Divider().background(Color.white.opacity(0.2)).padding(.horizontal)
            controlsView
        }
        .background(Color.clear)
    }
    
    private var headerView: some View {
        HStack {
            // Chapter selector with dropdown appearance
            Button(action: {
                showChapterPicker.toggle()
            }) {
                HStack {
                    Text(chapterTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(Color(.lightGray))
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: $showChapterPicker) {
                ChapterPickerView(isPresented: $showChapterPicker)
                    .frame(width: 320, height: 400)
                    .environmentObject(verseManager)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var controlsView: some View {
        HStack(spacing: 24) {
            // Previous verse button
            Button(action: {
                verseManager.previousVerse()
            }) {
                Image(systemName: "chevron.backward.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(Color(.systemTeal))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Play audio button (simplified)
            Button(action: {
                verseManager.playCurrentVerseAudio()
            }) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 42))
                    .foregroundColor(Color(.systemGreen))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Next verse button
            Button(action: {
                verseManager.nextVerse()
            }) {
                Image(systemName: "chevron.forward.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(Color(.systemTeal))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
        .padding(.bottom, 10)
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
                .colorScheme(.dark)
            Text("Loading...")
                .font(.headline)
                .foregroundColor(.white)
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(Color(.systemYellow))
            
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding()
            
            Button("Try Again") {
                verseManager.fetchChapters()
            }
            .buttonStyle(.bordered)
            .foregroundColor(.white)
            .background(Color(.systemBlue))
            .cornerRadius(8)
            .controlSize(.large)
        }
        .padding()
    }
    
    private var chapterTitle: String {
        guard !verseManager.chapters.isEmpty else { return "Loading Chapters..." }
        
        if let chapter = verseManager.chapters.first(where: { $0.number == verseManager.currentChapter }) {
            return "\(chapter.englishName) (\(chapter.name))"
        }
        
        return "Chapter \(verseManager.currentChapter)"
    }
}

struct ChapterPickerView: View {
    @EnvironmentObject var verseManager: QuranVerseManager
    @Binding var isPresented: Bool
    @State private var searchText = ""
    
    var filteredChapters: [QuranChapter] {
        if searchText.isEmpty {
            return verseManager.chapters
        } else {
            return verseManager.chapters.filter { 
                $0.englishName.lowercased().contains(searchText.lowercased()) ||
                $0.name.contains(searchText) ||
                String($0.number).contains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search header
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white)
                TextField("Search Chapters", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                    .colorScheme(.dark)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color(.darkGray))
            
            Divider().background(Color.white.opacity(0.2))
            
            if verseManager.chapters.isEmpty {
                Spacer()
                ProgressView()
                    .padding()
                    .colorScheme(.dark)
                Text("Loading chapters...")
                    .foregroundColor(.white)
                Spacer()
            } else {
                // Chapter list
                List {
                    ForEach(filteredChapters, id: \.number) { chapter in
                        ChapterRow(chapter: chapter)
                            .listRowBackground(Color(.darkGray))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                verseManager.selectChapter(chapter.number)
                                isPresented = false
                            }
                    }
                }
                .listStyle(PlainListStyle())
                .colorScheme(.dark)
            }
        }
        .background(Color(.darkGray))
        .cornerRadius(12)
    }
}

struct ChapterRow: View {
    let chapter: QuranChapter
    
    var body: some View {
        HStack(spacing: 12) {
            // Chapter number in a circle
            ZStack {
                Circle()
                    .fill(Color(.systemTeal).opacity(0.3))
                    .frame(width: 36, height: 36)
                
                Text("\(chapter.number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(.systemTeal))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(chapter.englishName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text("\(chapter.numberOfVerses) verses")
                    .font(.caption)
                    .foregroundColor(Color(.lightGray))
            }
            
            Spacer()
            
            Text(chapter.name)
                .font(.headline)
                .foregroundColor(Color(.systemTeal))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}

#Preview {
    PopoverView()
        .environmentObject(QuranVerseManager())
        .frame(width: 350, height: 300)
        .preferredColorScheme(.dark)
} 