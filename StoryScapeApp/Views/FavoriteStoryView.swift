//
//  FavoriteStoryView.swift
//  StoryScapeApp
//
//  Created by Dev Asheesh Chopra on 02/01/25.
//

import SwiftUI

/// A read-only detail view for a single favorite story.
struct FavoriteStoryView: View {
    let story: Story
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(story.title)
                    .font(.title)
                    .bold()
                
                Text(story.introduction)
                
                if let intro = loadLocalImage("\(story.id)_intro.jpg") {
                    Image(uiImage: intro)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                
                Text(story.middle)
                
                if let middle = loadLocalImage("\(story.id)_middle.jpg") {
                    Image(uiImage: middle)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                
                Text(story.conclusion)
            }
            .padding()
        }
        .navigationTitle(story.title)
    }
    
    private func loadLocalImage(_ filename: String) -> UIImage? {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let fileURL = documentsURL.appendingPathComponent(filename)
        if let data = try? Data(contentsOf: fileURL) {
            return UIImage(data: data)
        }
        return nil
    }
}
