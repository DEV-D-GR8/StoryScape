//
//  RecommendationsViewModel.swift
//  StoryScapeApp
//
//  Created by Dev Asheesh Chopra on 02/01/25.
//

import SwiftUI
import Combine

/// Manages recommendation toggles (enable/disable) and user-selected words/genres.
class RecommendationsViewModel: ObservableObject {
    
    @Published var recommendationsEnabled: Bool = UserDefaults.standard.bool(forKey: "recommendationsEnabled")
    @Published var inputText: String = ""
    @Published var selectedWords: [String] = UserDefaults.standard.stringArray(forKey: "selectedWords") ?? []
    
    /// Sample list of available genres to pick from.
    let availableGenres: [String] = [
        "Adventure", "Mystery", "Fantasy", "Sci-Fi", "Romance", "Horror",
        "Thriller", "Comedy", "Drama", "Historical", "Poetry", "Biography",
        "Self-Help", "Philosophy", "Science", "Technology", "Education",
        "Children", "Young Adult", "Graphic Novel"
    ]
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $recommendationsEnabled
            .sink { newValue in
                UserDefaults.standard.set(newValue, forKey: "recommendationsEnabled")
                NotificationCenter.default.post(name: .settingsChanged, object: nil)
            }
            .store(in: &cancellables)
        
        $selectedWords
            .sink { newWords in
                UserDefaults.standard.set(newWords, forKey: "selectedWords")
                NotificationCenter.default.post(name: .settingsChanged, object: nil)
            }
            .store(in: &cancellables)
    }
    
    /// Add a word/genre to `selectedWords`.
    func addWord(_ word: String) {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !selectedWords.contains(trimmed) {
            selectedWords.append(trimmed)
        }
        inputText = ""
    }
    
    /// Remove a word/genre from `selectedWords`.
    func removeWord(_ word: String) {
        if let idx = selectedWords.firstIndex(of: word) {
            selectedWords.remove(at: idx)
        }
    }
}
