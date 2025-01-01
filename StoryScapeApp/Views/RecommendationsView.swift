//
//  RecommendationsView.swift
//  StoryScapeApp
//
//  Created by Dev Asheesh Chopra on 02/01/25.
//

import SwiftUI

/// Screen for enabling/disabling recommendations and adding custom words/genres.
struct RecommendationsView: View {
    
    @StateObject private var viewModel = RecommendationsViewModel()
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var savedPromptsStore: SavedPromptsStore
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle(isOn: $viewModel.recommendationsEnabled) {
                        Text("Enable Recommendations")
                    }
                }
                
                if viewModel.recommendationsEnabled {
                    Section(header: Text("Add Custom Words or Genres")) {
                        HStack {
                            TextField("Type a word", text: $viewModel.inputText, onCommit: {
                                viewModel.addWord(viewModel.inputText)
                            })
                            .onChange(of: viewModel.inputText) { newValue in
                                // If user typed a space, auto-add the word
                                if newValue.last == " " {
                                    viewModel.inputText.removeLast()
                                    viewModel.addWord(viewModel.inputText)
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button("Add") {
                                viewModel.addWord(viewModel.inputText)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            Button("Select") {
                                // Open the GenreSelectionView
                                isShowingGenreSelection = true
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        
                        if !viewModel.selectedWords.isEmpty {
                            ScrollView {
                                WrapView(data: viewModel.selectedWords, id: \.self) { word in
                                    HStack(spacing: 4) {
                                        Text(word)
                                            .foregroundColor(.white)
                                        Button(action: {
                                            viewModel.removeWord(word)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                    }
                                    .padding(8)
                                    .background(Color.blue)
                                    .cornerRadius(16)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
                
                // Always display saved prompts
                if !savedPromptsStore.savedPrompts.isEmpty {
                    Section(header: Text("Saved Prompts")) {
                        ForEach(savedPromptsStore.savedPrompts, id: \.self) { prompt in
                            HStack {
                                Text(prompt)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .onTapGesture {
                                        // Copy prompt to ContentView & navigate back
                                        NotificationCenter.default.post(name: .savedPromptSelected, object: prompt)
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                Spacer()
                                Button(action: {
                                    removeSavedPrompt(prompt)
                                }) {
                                    Image(systemName: "bookmark.fill")
                                        .foregroundColor(.yellow)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                        
                        Button(action: {
                            clearAllSavedPrompts()
                        }) {
                            Text("Clear All")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationBarTitle("Recommendations", displayMode: .inline)
            .sheet(isPresented: $isShowingGenreSelection) {
                GenreSelectionView(
                    selectedWords: $viewModel.selectedWords,
                    availableGenres: viewModel.availableGenres
                )
            }
        }
    }
    
    @State private var isShowingGenreSelection = false
    
    private func removeSavedPrompt(_ prompt: String) {
        if let idx = savedPromptsStore.savedPrompts.firstIndex(of: prompt) {
            savedPromptsStore.savedPrompts.remove(at: idx)
        }
    }
    
    private func clearAllSavedPrompts() {
        savedPromptsStore.savedPrompts.removeAll()
    }
}

#if DEBUG
struct RecommendationsView_Previews: PreviewProvider {
    static var previews: some View {
        RecommendationsView()
            .environmentObject(SavedPromptsStore())
    }
}
#endif
