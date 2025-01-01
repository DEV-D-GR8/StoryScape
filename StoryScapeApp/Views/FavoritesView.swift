//
//  FavoritesView.swift
//  StoryScapeApp
//
//  Created by Dev Asheesh Chopra on 02/01/25.
//

import SwiftUI

/// Displays a list of locally saved favorite stories.
struct FavoritesView: View {
    
    @EnvironmentObject var favoritesStore: FavoritesStore
    @State private var favoriteStories: [Story] = []
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredStories()) { story in
                    HStack {
                        NavigationLink(destination: FavoriteStoryView(story: story)) {
                            Text(story.title)
                        }
                    }
                    .contextMenu {
                        Button("Remove from Favorites") {
                            removeFavorite(story)
                        }
                    }
                }
            }
            .navigationBarTitle("Favorites", displayMode: .inline)
            .navigationBarItems(
                trailing:
                    Button(action: {
                        clearFavorites()
                    }) {
                        Text("Clear All")
                            .foregroundColor(.red)
                    }
            )
            .onAppear {
                loadFavoriteStories()
            }
            .onReceive(favoritesStore.objectWillChange) { _ in
                loadFavoriteStories()
            }
            .searchable(text: $searchText)
        }
    }
    
    private func loadFavoriteStories() {
        favoriteStories = []
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            for file in files {
                if file.pathExtension == "json" {
                    if let data = try? Data(contentsOf: file) {
                        let decoder = JSONDecoder()
                        if let story = try? decoder.decode(Story.self, from: data) {
                            favoriteStories.append(story)
                        }
                    }
                }
            }
        } catch {
            print("Error loading favorite stories: \(error)")
        }
    }
    
    private func removeFavorite(_ story: Story) {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let storyURL = documentsURL.appendingPathComponent("\(story.id).json")
        try? fileManager.removeItem(at: storyURL)
        
        let introImageURL = documentsURL.appendingPathComponent("\(story.id)_intro.jpg")
        try? fileManager.removeItem(at: introImageURL)
        
        let middleImageURL = documentsURL.appendingPathComponent("\(story.id)_middle.jpg")
        try? fileManager.removeItem(at: middleImageURL)
        
        favoritesStore.favoriteStoryIDs.remove(story.id)
    }
    
    private func clearFavorites() {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            for file in files {
                if file.pathExtension == "json" || file.pathExtension == "jpg" {
                    try fileManager.removeItem(at: file)
                }
            }
            favoritesStore.clearFavorites()
            favoriteStories = []
        } catch {
            print("Error clearing favorites: \(error)")
        }
    }
    
    private func filteredStories() -> [Story] {
        if searchText.isEmpty {
            return favoriteStories
        } else {
            return favoriteStories.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }
}
