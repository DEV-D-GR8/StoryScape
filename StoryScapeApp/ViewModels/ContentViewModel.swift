//
//  ContentViewModel.swift
//  StoryScapeApp
//
//  Created by Dev Asheesh Chopra on 02/01/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import FirebaseAuth
import Combine


class ContentViewModel: ObservableObject {
    
    // MARK: - Published Properties (bind to View)
    
    /// The user's prompt for story generation.
    @Published var prompt: String = ""
    
    /// The generated story, if one exists.
    @Published var story: Story?
    
    /// Loading state for story generation.
    @Published var isLoading: Bool = false
    
    /// Error message if generation fails.
    @Published var errorMessage: String? = nil
    
    /// The selected generation mode (prompt only or image + prompt).
    @Published var selectedMode: GenerationMode = .promptOnly
    
    /// Image selected by the user.
    @Published var selectedImage: UIImage? = nil
    
    /// Whether the image picker is currently shown.
    @Published var isShowingImagePicker: Bool = false
    
    /// Whether to show the final story in the StoryView.
    @Published var showStoryView: Bool = false
    
    /// Whether to include AI-generated images in the generated story response.
    @Published var includeAIImages: Bool = UserDefaults.standard.bool(forKey: "includeAIImages")
    
    /// Suggestions from the recommendations system.
    @Published var suggestions: [String] = []
    
    /// Whether we are currently loading suggestions.
    @Published var isLoadingSuggestions: Bool = false
    
    /// Whether recommendations are enabled (toggled in Settings).
    @Published var recommendationsEnabled: Bool = UserDefaults.standard.bool(forKey: "recommendationsEnabled")
    
    /// Words or genres that the user selected or typed in from the Recommendations flow.
    @Published var selectedWords: [String] = UserDefaults.standard.stringArray(forKey: "selectedWords") ?? []
    
    /// Response language for story generation (e.g., "Hindi" or "English").
    @Published var responseLanguage: String = UserDefaults.standard.string(forKey: "responseLanguage") ?? "Hindi"
    
    /// Age group for story generation.
    @Published var ageGroup: String = UserDefaults.standard.string(forKey: "ageGroup") ?? "3-5"
    
    // For storing combined subscriptions (Combine usage).
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // Listen for external settings changes
        NotificationCenter.default.publisher(for: .settingsChanged)
            .sink { [weak self] _ in
                self?.fetchSettings()
                self?.resetSuggestions()
            }
            .store(in: &cancellables)
        
        // Listen for externally selected saved prompt
        NotificationCenter.default.publisher(for: .savedPromptSelected)
            .sink { [weak self] notification in
                if let prompt = notification.object as? String {
                    self?.prompt = prompt
                }
            }
            .store(in: &cancellables)
        
        // Initial fetch of local user settings
        fetchSettings()
    }
    
    // MARK: - Public Methods Called by the View
    
    /// Main action to generate a story from either a prompt only or prompt + image.
    func generateStory() {
        // Validate input
        guard !prompt.isEmpty else {
            errorMessage = "Please enter a prompt."
            return
        }
        
        if selectedMode == .imageAndPrompt && selectedImage == nil {
            errorMessage = "Please select an image."
            return
        }
        
        // Reset old errors/story
        errorMessage = nil
        isLoading = true
        story = nil
        
        // Decide endpoint
        switch selectedMode {
        case .promptOnly:
            generateStoryFromPrompt()
        case .imageAndPrompt:
            generateStoryFromImage()
        }
    }
    
    /// Fetch new suggestions if needed.
    /// Usually called onAppear if recommendations are enabled.
    func checkAndFetchSuggestions() {
        // Check if we have cached suggestions and if they are still valid
        if let lastFetchDate = UserDefaults.standard.object(forKey: "lastSuggestionsFetchDate") as? Date,
           let cachedSuggestions = UserDefaults.standard.stringArray(forKey: "cachedSuggestions") {
            // If we already fetched suggestions today, use the cache
            if Calendar.current.isDateInToday(lastFetchDate) {
                self.suggestions = cachedSuggestions
                return
            }
        }
        // Otherwise fetch new suggestions
        fetchSuggestions()
    }
    
    /// Toggle whether a suggestion is bookmarked or not.
    func toggleBookmark(for suggestion: String, savedPromptsStore: SavedPromptsStore) {
        if let index = savedPromptsStore.savedPrompts.firstIndex(of: suggestion) {
            // If it's already saved, remove it
            savedPromptsStore.savedPrompts.remove(at: index)
        } else {
            // Otherwise add it
            savedPromptsStore.savedPrompts.append(suggestion)
        }
    }
    
    /// Refresh local settings (language, ageGroup, etc.) from UserDefaults.
    func fetchSettings() {
        recommendationsEnabled = UserDefaults.standard.bool(forKey: "recommendationsEnabled")
        selectedWords = UserDefaults.standard.stringArray(forKey: "selectedWords") ?? []
        responseLanguage = UserDefaults.standard.string(forKey: "responseLanguage") ?? "Hindi"
        ageGroup = UserDefaults.standard.string(forKey: "ageGroup") ?? "3-5"
        includeAIImages = UserDefaults.standard.bool(forKey: "includeAIImages")
    }
    
    /// Clear out old cached suggestions and re-fetch.
    func resetSuggestions() {
        UserDefaults.standard.removeObject(forKey: "cachedSuggestions")
        UserDefaults.standard.removeObject(forKey: "lastSuggestionsFetchDate")
        
        if recommendationsEnabled && selectedMode == .promptOnly {
            checkAndFetchSuggestions()
        }
    }
    
    // MARK: - Private Helpers
    
    private func generateStoryFromPrompt() {
        guard let url = URL(string: "http://172.20.10.11:8000/generate_story") else {
            self.errorMessage = "Invalid backend URL."
            self.isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "prompt": prompt,
            "response_language": responseLanguage,
            "age_group": ageGroup,
            "selected_words": selectedWords
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            errorMessage = "Failed to serialize request."
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received."
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let storyResponse = try decoder.decode(Story.self, from: data)
                    self.story = storyResponse
                    self.saveStoryToFirestore(storyResponse)
                    self.showStoryView = true
                } catch {
                    self.errorMessage = "Failed to parse response."
                }
            }
        }.resume()
    }
    
    private func generateStoryFromImage() {
        guard let url = URL(string: "http://172.20.10.11:8000/analyze_image") else {
            self.errorMessage = "Invalid backend URL."
            self.isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Build our multipart form data
        var formData = Data()
        
        // 1) prompt
        formData.append("--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
        formData.append("\(prompt)\r\n".data(using: .utf8)!)
        
        // 2) response_language
        formData.append("--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"response_language\"\r\n\r\n".data(using: .utf8)!)
        formData.append("\(responseLanguage)\r\n".data(using: .utf8)!)
        
        // 3) age_group
        formData.append("--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"age_group\"\r\n\r\n".data(using: .utf8)!)
        formData.append("\(ageGroup)\r\n".data(using: .utf8)!)
        
        // 4) selected_words (repeated)
        for word in selectedWords {
            formData.append("--\(boundary)\r\n".data(using: .utf8)!)
            formData.append("Content-Disposition: form-data; name=\"selected_words\"\r\n\r\n".data(using: .utf8)!)
            formData.append("\(word)\r\n".data(using: .utf8)!)
        }
        
        // 5) include_images
        formData.append("--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"include_images\"\r\n\r\n".data(using: .utf8)!)
        formData.append("\(includeAIImages)\r\n".data(using: .utf8)!)
        
        // 6) selected image
        if let selectedImage = selectedImage,
           let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
            
            formData.append("--\(boundary)\r\n".data(using: .utf8)!)
            formData.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
            formData.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            formData.append(imageData)
            formData.append("\r\n".data(using: .utf8)!)
        }
        
        formData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = formData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received."
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let storyResponse = try decoder.decode(Story.self, from: data)
                    self.story = storyResponse
                    self.saveStoryToFirestore(storyResponse)
                    self.showStoryView = true
                } catch {
                    self.errorMessage = "Failed to parse response."
                }
            }
        }.resume()
    }
    
    /// Save the generated story to Firestore under the current user's `stories` collection.
    private func saveStoryToFirestore(_ story: Story) {
        guard let user = Auth.auth().currentUser else {
            print("❌ Cannot save to Firestore: No authenticated user")
            return
        }
        
        let db = Firestore.firestore()
        
        let storyData: [String: Any] = [
            "id": story.id,
            "title": story.title,
            "introduction": story.introduction,
            "middle": story.middle,
            "conclusion": story.conclusion,
            "intro_image_url": story.introImageURL as Any,
            "middle_image_url": story.middleImageURL as Any,
            "timestamp": FieldValue.serverTimestamp(),
            "userId": user.uid
        ]
        
        db.collection("stories").document(story.id).setData(storyData) { error in
            if let error = error {
                print("❌ Firestore save error: \(error.localizedDescription)")
            } else {
                print("✅ Story saved with ID: \(story.id)")
            }
        }
    }
    
    /// Fetch suggestions from the server based on user-selected words and settings.
    private func fetchSuggestions() {
        isLoadingSuggestions = true
        errorMessage = nil
        
        guard let url = URL(string: "http://172.20.10.11:8000/get_suggestions") else {
            errorMessage = "Invalid backend URL."
            isLoadingSuggestions = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "selected_words": selectedWords,
            "response_language": responseLanguage,
            "age_group": ageGroup
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            errorMessage = "Failed to serialize request."
            isLoadingSuggestions = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoadingSuggestions = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received."
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let suggestionsResponse = try decoder.decode(SuggestionsResponse.self, from: data)
                    self.suggestions = suggestionsResponse.suggestions
                    
                    UserDefaults.standard.set(self.suggestions, forKey: "cachedSuggestions")
                    UserDefaults.standard.set(Date(), forKey: "lastSuggestionsFetchDate")
                } catch {
                    self.errorMessage = "Failed to parse suggestions."
                }
            }
        }.resume()
    }
}

/// A struct used for decoding suggestions from the server.
struct SuggestionsResponse: Codable {
    let suggestions: [String]
}

/// The generation modes for the story: either prompt-only or prompt + image.
enum GenerationMode: String, CaseIterable, Identifiable {
    case promptOnly = "Prompt Only"
    case imageAndPrompt = "Image and Prompt"
    
    var id: String { rawValue }
}
