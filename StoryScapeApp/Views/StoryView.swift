//
//  StoryView.swift
//  StoryScapeApp
//
//  Created by Dev Asheesh Chopra on 02/01/25.
//

import SwiftUI

/// Displays a generated story, with optional images, and an audio generation/playback button.
struct StoryView: View {
    let story: Story
    
    @StateObject private var audioPlayer = AudioPlayer()
    @State private var isGeneratingAudio = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(story.title)
                    .font(.title)
                    .bold()
                
                Text(story.introduction)
                
                if let urlString = story.introImageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                }
                
                Text(story.middle)
                
                if let urlString = story.middleImageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                }
                
                Text(story.conclusion)
                
                VStack {
                    if audioPlayer.currentTime == 0 && !audioPlayer.isPlaying {
                        Button(action: {
                            generateAndPlayAudio()
                        }) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.title)
                                Text(isGeneratingAudio ? "Generating Audio..." : "Play Audio")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isGeneratingAudio)
                        .overlay(
                            Group {
                                if isGeneratingAudio {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                            }
                        )
                    }
                    
                    if audioPlayer.currentTime > 0 || audioPlayer.isPlaying {
                        AudioPlayerControls(audioPlayer: audioPlayer)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(story.title)
        .alert("Error", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Audio Generation
    
    private func generateAndPlayAudio() {
        guard !isGeneratingAudio else { return }
        isGeneratingAudio = true
        
        guard let url = URL(string: "http://172.20.10.11:8000/generate_audio") else {
            showError = true
            errorMessage = "Invalid URL"
            isGeneratingAudio = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare story content for TTS
        let storyContent: [String: String] = [
            "title": story.title,
            "introduction": story.introduction,
            "middle": story.middle,
            "conclusion": story.conclusion
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: storyContent)
        } catch {
            showError = true
            errorMessage = "Failed to prepare request"
            isGeneratingAudio = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                self.isGeneratingAudio = false
                
                if let error = error {
                    self.showError = true
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let audioData = data else {
                    self.showError = true
                    self.errorMessage = "No audio data received"
                    return
                }
                
                self.audioPlayer.playFromData(audioData)
            }
        }.resume()
    }
}
