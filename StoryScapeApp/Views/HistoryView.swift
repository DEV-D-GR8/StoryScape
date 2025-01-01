//
//  HistoryView.swift
//  StoryScapeApp
//
//  Created by Dev Asheesh Chopra on 02/01/25.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct HistoryView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @EnvironmentObject var favoritesStore: FavoritesStore
    @State private var stories: [StoryResponse] = []
    @State private var groupedStories: [String: [StoryResponse]] = [:]
    @State private var sortedKeys: [String] = []
    @State private var sections: [(title: String, stories: [StoryResponse], sortOrder: Int, date: Date?)] = []
    @State private var searchText: String = ""
    @State private var showFavorites = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredSections, id: \.title) { section in
                    StorySectionView(
                        section: (section.title, section.stories),
                        isFavorite: isFavorite,
                        toggleFavorite: toggleFavorite,
                        deleteStory: deleteStory
                    )
                }
            }
            .navigationBarTitle("History", displayMode: .inline)
            .navigationBarItems(
                leading: Button(action: {
                    showFavorites = true
                }) {
                    Image(systemName: "star.fill")
                },
                trailing: EditButton()
            )
            .sheet(isPresented: $showFavorites) {
                FavoritesView()
            }
            .onAppear {
                fetchStories()
            }
            .searchable(text: $searchText)
        }
    }
    
    var filteredSections: [(title: String, stories: [StoryResponse])] {
        if searchText.isEmpty {
            return sections.map { ($0.title, $0.stories) }
        } else {
            return sections.compactMap { section in
                let filteredStories = section.stories.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
                return !filteredStories.isEmpty ? (title: section.title, stories: filteredStories) : nil
            }
        }
    }
    
    func isFavorite(_ story: StoryResponse) -> Bool {
        favoritesStore.favoriteStoryIDs.contains(story.id)
    }
    
    func toggleFavorite(for story: StoryResponse) {
        if isFavorite(story) {
            favoritesStore.favoriteStoryIDs.remove(story.id)
            removeFavorite(story)
        } else {
            favoritesStore.favoriteStoryIDs.insert(story.id)
            saveFavorite(story)
        }
    }
    
    func groupStories() {
        let calendar = Calendar.current
        var newSections: [(title: String, stories: [StoryResponse], sortOrder: Int, date: Date?)] = []
        
        func daysBetween(start: Date, end: Date) -> Int {
            let startOfStart = calendar.startOfDay(for: start)
            let startOfEnd = calendar.startOfDay(for: end)
            let components = calendar.dateComponents([.day], from: startOfStart, to: startOfEnd)
            return components.day ?? 0
        }
        
        let todayStories = stories.filter { calendar.isDateInToday($0.timestamp) }
        if !todayStories.isEmpty {
            newSections.append((title: "Today", stories: todayStories, sortOrder: 0, date: nil))
        }
        
        let yesterdayStories = stories.filter { calendar.isDateInYesterday($0.timestamp) }
        if !yesterdayStories.isEmpty {
            newSections.append((title: "Yesterday", stories: yesterdayStories, sortOrder: 1, date: nil))
        }
        
        let last7DaysStories = stories.filter {
            let daysAgo = daysBetween(start: $0.timestamp, end: Date())
            return daysAgo >= 2 && daysAgo <= 6
        }
        if !last7DaysStories.isEmpty {
            newSections.append((title: "Last 7 Days", stories: last7DaysStories, sortOrder: 2, date: nil))
        }
        
        let last30DaysStories = stories.filter {
            let daysAgo = daysBetween(start: $0.timestamp, end: Date())
            return daysAgo >= 7 && daysAgo <= 29
        }
        if !last30DaysStories.isEmpty {
            newSections.append((title: "Last 30 Days", stories: last30DaysStories, sortOrder: 3, date: nil))
        }
        
        let otherStories = stories.filter {
            let daysAgo = daysBetween(start: $0.timestamp, end: Date())
            return daysAgo >= 30
        }
        let groupedByMonth = Dictionary(grouping: otherStories) { (story) -> String in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM yyyy"
            return dateFormatter.string(from: story.timestamp)
        }
        for (monthYear, stories) in groupedByMonth {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM yyyy"
            let date = dateFormatter.date(from: monthYear)
            newSections.append((title: monthYear, stories: stories, sortOrder: 4, date: date))
        }
        
        newSections.sort { (s1, s2) -> Bool in
            if s1.sortOrder != s2.sortOrder {
                return s1.sortOrder < s2.sortOrder
            } else if let date1 = s1.date, let date2 = s2.date {
                return date1 > date2
            } else {
                return false
            }
        }
        
        sections = newSections
    }
    
    func saveFavorite(_ story: StoryResponse) {
        let fileManager = FileManager.default
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let storyURL = documentsURL.appendingPathComponent("\(story.id).json")
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(story)
                try data.write(to: storyURL)
            } catch {
                print("Error saving story: \(error)")
            }
            if let introImageUrlString = story.intro_image_url,
               let introImageUrl = URL(string: introImageUrlString) {
                downloadAndSaveImage(url: introImageUrl, filename: "\(story.id)_intro.jpg")
            }
            if let middleImageUrlString = story.middle_image_url,
               let middleImageUrl = URL(string: middleImageUrlString) {
                downloadAndSaveImage(url: middleImageUrl, filename: "\(story.id)_middle.jpg")
            }
        }
    }
    
    func removeFavorite(_ story: StoryResponse) {
        let fileManager = FileManager.default
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let storyURL = documentsURL.appendingPathComponent("\(story.id).json")
            try? fileManager.removeItem(at: storyURL)
            let introImageURL = documentsURL.appendingPathComponent("\(story.id)_intro.jpg")
            try? fileManager.removeItem(at: introImageURL)
            let middleImageURL = documentsURL.appendingPathComponent("\(story.id)_middle.jpg")
            try? fileManager.removeItem(at: middleImageURL)
        }
    }
    
    func downloadAndSaveImage(url: URL, filename: String) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data {
                let fileManager = FileManager.default
                if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let fileURL = documentsURL.appendingPathComponent(filename)
                    do {
                        try data.write(to: fileURL)
                    } catch {
                        print("Error saving image: \(error)")
                    }
                }
            } else if let error = error {
                print("Error downloading image: \(error)")
            }
        }.resume()
    }
    
    func fetchStories() {
        guard let user = Auth.auth().currentUser else {
            print("HistoryView: No authenticated user found")
            return
        }
        let db = Firestore.firestore()
        db.collection("stories")
            .whereField("userId", isEqualTo: user.uid)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("HistoryView: Error fetching stories: \(error)")
                    return
                }
                guard let documents = querySnapshot?.documents else {
                    print("HistoryView: No documents found")
                    return
                }
                stories = documents.compactMap { document -> StoryResponse? in
                    do {
                        var story = try document.data(as: StoryResponse.self)
                        story.id = document.documentID
                        return story
                    } catch {
                        print("HistoryView: Error decoding story \(document.documentID): \(error)")
                        return nil
                    }
                }
                groupStories()
            }
    }
    
    func deleteStory(_ story: StoryResponse) {
        let db = Firestore.firestore()
        db.collection("stories").document(story.id).delete { error in
            if let error = error {
                print("Error deleting story: \(error)")
                return
            }
            fetchStories()
        }
    }
}