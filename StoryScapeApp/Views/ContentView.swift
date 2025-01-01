//
//  ContentView.swift
//  StoryScapeApp
//
//  Created by Dev Asheesh Chopra on 02/01/25.
//

import SwiftUI

/// Primary story-generation screen, binding to `ContentViewModel`.
struct ContentView: View {
    
    @StateObject private var viewModel = ContentViewModel()
    @EnvironmentObject var savedPromptsStore: SavedPromptsStore  // For saved prompts/bookmarks
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            // Mode picker
            Picker("Generation Mode", selection: $viewModel.selectedMode) {
                ForEach(GenerationMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .disabled(viewModel.isLoading)
            
            // Input fields depending on the mode
            if viewModel.selectedMode == .promptOnly {
                promptOnlyView
            } else {
                imageAndPromptView
            }
            
            // Generate story button
            Button(action: {
                viewModel.generateStory()
            }) {
                Text("Generate Story")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.top, 5)
            .disabled(viewModel.isLoading || viewModel.prompt.isEmpty)
            
            // Loading and error states
            if viewModel.isLoading {
                ProgressView("Generating story and images...")
                    .padding()
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            // Suggestions (if in prompt-only mode and recommendations enabled)
            if viewModel.recommendationsEnabled && viewModel.selectedMode == .promptOnly {
                suggestionsSection
            }
            
            Spacer()
        }
        .navigationTitle("Story Generator")
        .sheet(isPresented: $viewModel.showStoryView, onDismiss: {
            // Reset if needed
            viewModel.story = nil
        }) {
            if let story = viewModel.story {
                StoryView(story: story)  // Show the newly generated story
            } else {
                Text("No story available.")
            }
        }
        .sheet(isPresented: $viewModel.isShowingImagePicker) {
            ImagePicker(image: $viewModel.selectedImage)
        }
        .onAppear {
            // On appear, fetch new suggestions if needed
            viewModel.fetchSettings()
            if viewModel.recommendationsEnabled && viewModel.selectedMode == .promptOnly {
                viewModel.checkAndFetchSuggestions()
            }
        }
        // Listen for custom events
        .onReceive(NotificationCenter.default.publisher(for: .settingsChanged)) { _ in
            viewModel.fetchSettings()
            viewModel.resetSuggestions()
        }
        .onReceive(NotificationCenter.default.publisher(for: .savedPromptSelected)) { notification in
            if let prompt = notification.object as? String {
                viewModel.prompt = prompt
                // Dismiss any presented sheets to go back to ContentView
                presentationMode.wrappedValue.dismiss()
            }
        }
        .onChange(of: viewModel.selectedMode) { _ in
            // If we switch to prompt-only and recommendations are enabled, fetch suggestions
            if viewModel.recommendationsEnabled && viewModel.selectedMode == .promptOnly {
                viewModel.checkAndFetchSuggestions()
            }
        }
    }
}

// MARK: - Subviews
extension ContentView {
    
    /// The text input portion for the "Prompt Only" mode.
    private var promptOnlyView: some View {
        ZStack(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                .frame(height: 100)
                .padding(.horizontal)
            
            HStack {
                ZStack(alignment: .topLeading) {
                    if viewModel.prompt.isEmpty {
                        Text("Enter a prompt for the story")
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    
                    TextEditor(text: $viewModel.prompt)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(height: 100)
                        .opacity(viewModel.prompt.isEmpty ? 0.85 : 1)
                }
                .padding(.leading)
                
                if !viewModel.prompt.isEmpty {
                    Button(action: {
                        viewModel.prompt = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title2)
                    }
                    .padding(.trailing, 33)
                }
            }
        }
        .scrollIndicators(.hidden)
    }
    
    /// The text + image selection input portion for the "Image and Prompt" mode.
    private var imageAndPromptView: some View {
        VStack {
            ZStack(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    .frame(height: 100)
                    .padding(.horizontal)
                
                HStack {
                    ZStack(alignment: .topLeading) {
                        if viewModel.prompt.isEmpty {
                            Text("Enter a prompt for the story")
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        }
                        
                        TextEditor(text: $viewModel.prompt)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(height: 100)
                            .opacity(viewModel.prompt.isEmpty ? 0.85 : 1)
                    }
                    .padding(.leading)
                    
                    if !viewModel.prompt.isEmpty {
                        Button(action: {
                            viewModel.prompt = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .font(.title2)
                        }
                        .padding(.trailing, 33)
                    }
                }
            }
            .scrollIndicators(.hidden)
            
            Button(action: {
                viewModel.isShowingImagePicker = true
            }) {
                Text("Select Image")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.top, 5)
            .disabled(viewModel.isLoading)
            
            if let selectedImage = viewModel.selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .padding()
                
                Toggle("Include AI Images in Response", isOn: $viewModel.includeAIImages)
                    .padding()
                    .onChange(of: viewModel.includeAIImages) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "includeAIImages")
                    }
            }
        }
    }
    
    /// The suggestions list (if recommendations are enabled).
    private var suggestionsSection: some View {
        Group {
            if viewModel.isLoadingSuggestions {
                ProgressView("Loading suggestions...")
                    .padding()
            } else if !viewModel.suggestions.isEmpty {
                VStack(alignment: .leading) {
                    Text("Suggestions")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.leading)
                        .padding(.top)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(viewModel.suggestions, id: \.self) { suggestion in
                                ZStack(alignment: .topTrailing) {
                                    // The suggestion prompt
                                    Button(action: {
                                        viewModel.prompt = suggestion
                                    }) {
                                        VStack(alignment: .leading, spacing: 10) {
                                            Text(suggestion)
                                                .foregroundColor(.primary)
                                                .font(.body)
                                                .lineLimit(nil)
                                                .multilineTextAlignment(.leading)
                                                .padding()
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [Color.white, Color.white.opacity(0.9)]),
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    )
                                                )
                                        )
                                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                    }
                                    .padding(.horizontal)
                                    
                                    // Bookmark button
                                    Button(action: {
                                        viewModel.toggleBookmark(for: suggestion, savedPromptsStore: savedPromptsStore)
                                    }) {
                                        let isBookmarked = savedPromptsStore.savedPrompts.contains(suggestion)
                                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                            .foregroundColor(isBookmarked ? .yellow : .gray)
                                            .padding()
                                    }
                                    .padding([.leading, .bottom])
                                    .padding(.trailing, 5)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(SavedPromptsStore())
    }
}
#endif
