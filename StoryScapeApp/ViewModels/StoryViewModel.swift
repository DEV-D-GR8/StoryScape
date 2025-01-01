//
//  StoryViewModel.swift
//  StoryScapeApp
//
//  Created by Dev Asheesh Chopra on 02/01/25.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

/// Handles fetching, grouping, and deleting stories from Firestore.
/// Also manages favorites logic in tandem with `FavoritesStore`.
class StoryViewModel: ObservableObject {
    
    /// All stories from the current user.
    @Published var stories: [Story] = []
    
    /// Grouped sections of stories (e.g., Today, Yesterday, Last 7 Days, etc.)
    @Published var sections: [(title: String, stories: [Story], sortOrder: Int, date: Date?)] = []
    
    /// Text for searching stories.
    @Published var searchText: String = ""
    
    /// Reference to the user's favorites
    @ObservedObject var favoritesStore: FavoritesStore
    
    private var db = Firestore.firestore()
    
    init(favoritesStore: FavoritesStore) {
        self.favoritesStore = favoritesStore
    }
    
    /// Fetch all stories for the currently authenticated user.
    func fetchStories() {
        guard let user = Auth.auth().currentUser else {
            print("❌ StoryViewModel: No user authenticated.")
            return
        }
        
        db.collection("stories")
            .whereField("userId", isEqualTo: user.uid)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("❌ Error fetching stories: \(error)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("❌ No documents found.")
                    return
                }
                
                self.stories = documents.compactMap { doc -> Story? in
                    do {
                        var story = try doc.data(as: Story.self)
                        story.id = doc.documentID
                        return story
                    } catch {
                        print("❌ Error decoding story: \(error)")
                        return nil
                    }
                }
                self.groupStories()
            }
    }
    
    /// Group stories by time-bucket (today, yesterday, last7, last30, or monthly).
    func groupStories() {
        let calendar = Calendar.current
        var newSections: [(String, [Story], Int, Date?)] = []
        
        let today = stories.filter { calendar.isDateInToday($0.timestamp) }
        if !today.isEmpty {
            newSections.append(("Today", today, 0, nil))
        }
        
        let yesterday = stories.filter { calendar.isDateInYesterday($0.timestamp) }
        if !yesterday.isEmpty {
            newSections.append(("Yesterday", yesterday, 1, nil))
        }
        
        // Helper function
        func daysBetween(start: Date, end: Date) -> Int {
            let startOfStart = calendar.startOfDay(for: start)
            let startOfEnd = calendar.startOfDay(for: end)
            let components = calendar.dateComponents([.day], from: startOfStart, to: startOfEnd)
            return components.day ?? 0
        }
        
        let last7Days = stories.filter {
            let daysAgo = daysBetween(start: $0.timestamp, end: Date())
            return (daysAgo >= 2 && daysAgo <= 6)
        }
        if !last7Days.isEmpty {
            newSections.append(("Last 7 Days", last7Days, 2, nil))
        }
        
        let last30Days = stories.filter {
            let daysAgo = daysBetween(start: $0.timestamp, end: Date())
            return (daysAgo >= 7 && daysAgo <= 29)
        }
        if !last30Days.isEmpty {
            newSections.append(("Last 30 Days", last30Days, 3, nil))
        }
        
        let older = stories.filter {
            let daysAgo = daysBetween(start: $0.timestamp, end: Date())
            return daysAgo >= 30
        }
        
        // Group older by month
        let groupedByMonth = Dictionary(grouping: older) { story -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: story.timestamp)
        }
        
        for (monthYear, group) in groupedByMonth {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            let date = formatter.date(from: monthYear)
            newSections.append((monthYear, group, 4, date))
        }
        
        // Sort by sortOrder, then by reverse chronological if same sortOrder
        newSections.sort { (lhs, rhs) in
            if lhs.2 != rhs.2 {
                return lhs.2 < rhs.2
            } else if let lhsDate = lhs.3, let rhsDate = rhs.3 {
                // Descending by date
                return lhsDate > rhsDate
            }
            return false
        }
        
        sections = newSections
    }
    
    /// Check if a given story is in favorites.
    func isFavorite(_ story: Story) -> Bool {
        favoritesStore.favoriteStoryIDs.contains(story.id)
    }
    
    /// Toggle a story as favorite vs. not favorite.
    func toggleFavorite(_ story: Story) {
        if isFavorite(story) {
            favoritesStore.favoriteStoryIDs.remove(story.id)
            removeFavorite(story)
        } else {
            favoritesStore.favoriteStoryIDs.insert(story.id)
            saveFavorite(story)
        }
    }
    
    /// Deletes a story from Firestore and removes from favorites if needed.
    func deleteStory(_ story: Story) {
        db.collection("stories").document(story.id).delete { error in
            if let error = error {
                print("Error deleting story: \(error)")
                return
            }
            
            // Also remove from favorites (if it’s in there)
            if self.isFavorite(story) {
                self.toggleFavorite(story)
            }
            self.fetchStories()
        }
    }
    
    // MARK: - Local Favorites Management
    
    /// Save story to local JSON and image files in the device's documents directory.
    func saveFavorite(_ story: Story) {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let storyURL = documentsURL.appendingPathComponent("\(story.id).json")
        
        do {
            let data = try JSONEncoder().encode(story)
            try data.write(to: storyURL)
        } catch {
            print("Error saving story: \(error)")
        }
        
        // Download & save images
        if let introURLString = story.introImageURL, let introURL = URL(string: introURLString) {
            downloadAndSaveImage(url: introURL, filename: "\(story.id)_intro.jpg")
        }
        
        if let middleURLString = story.middleImageURL, let middleURL = URL(string: middleURLString) {
            downloadAndSaveImage(url: middleURL, filename: "\(story.id)_middle.jpg")
        }
    }
    
    /// Remove story + images from local JSON files.
    func removeFavorite(_ story: Story) {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let storyURL = documentsURL.appendingPathComponent("\(story.id).json")
        try? fileManager.removeItem(at: storyURL)
        
        let introImageURL = documentsURL.appendingPathComponent("\(story.id)_intro.jpg")
        try? fileManager.removeItem(at: introImageURL)
        
        let middleImageURL = documentsURL.appendingPathComponent("\(story.id)_middle.jpg")
        try? fileManager.removeItem(at: middleImageURL)
    }
    
    private func downloadAndSaveImage(url: URL, filename: String) {
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data {
                if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let fileURL = documentsURL.appendingPathComponent(filename)
                    do {
                        try data.write(to: fileURL)
                        print("Image saved to \(fileURL.lastPathComponent)")
                    } catch {
                        print("Error saving image: \(error)")
                    }
                }
            } else if let error = error {
                print("Error downloading image: \(error)")
            }
        }
        task.resume()
    }
    
    /// Returns filtered sections based on `searchText`.
    func filteredSections() -> [(title: String, stories: [Story])] {
        if searchText.isEmpty {
            return sections.map { ($0.title, $0.stories) }
        } else {
            return sections.compactMap { section in
                let filtered = section.stories.filter {
                    $0.title.localizedCaseInsensitiveContains(searchText)
                }
                return filtered.isEmpty ? nil : (section.title, filtered)
            }
        }
    }
}
