//
//  ContentView.swift
//  read-quran
//
//  Created by husam saleh on 25/03/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject var verseManager = QuranVerseManager()
    
    var body: some View {
        PopoverView()
            .environmentObject(verseManager)
    }
}

#Preview {
    ContentView()
}
