//
//  BackgroundView.swift
//  StoryScapeApp
//
//  Created by Dev Asheesh Chopra on 02/01/25.
//

import SwiftUI

/// A simple view that renders a gradient background.
struct BackgroundView: View {
    var body: some View {
        LinearGradient(gradient: Gradient(colors: [.purple, .blue]),
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
            .edgesIgnoringSafeArea(.all)
    }
}
