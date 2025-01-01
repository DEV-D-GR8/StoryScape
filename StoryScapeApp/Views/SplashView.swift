//
//  SplashView.swift
//  StoryScapeApp
//
//  Created by Dev Asheesh Chopra on 02/01/25.
//

import SwiftUI

/// A simple splash screen animation that transitions to the main app.
struct SplashView: View {
    
    @State private var titleOffset = CGSize(width: -600, height: 0)
    @State private var subtitleOffset = CGSize(width: 600, height: 0)
    @State private var lottieScale = 0.0
    @State private var opacity = 0.0
    @State private var isActive = false
    
    @EnvironmentObject var sessionStore: SessionViewModel
    
    var body: some View {
        if isActive {
            MainView()
        } else {
            ZStack {
                BackgroundView()
                
                VStack(spacing: 25) {
                    Text("StoryScape")
                        .font(.system(size: 46, weight: .bold))
                        .foregroundColor(.white)
                        .offset(titleOffset)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Text("Every story, every genre,\nendless possibilities.")
                        .font(.system(size: 22, weight: .light))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .offset(subtitleOffset)
                    
                    ZStack {
                        LottieView(filename: "book", isPlaying: true)
                            .frame(width: 220, height: 220)
                            .scaleEffect(lottieScale)
                            .opacity(opacity)
                    }
                    .frame(height: 220)
                }
            }
            .onAppear {
                animateSequence()
            }
        }
    }
    
    private func animateSequence() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            titleOffset = .zero
        }
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3)) {
            subtitleOffset = .zero
        }
        
        withAnimation(.easeOut(duration: 0.7).delay(0.6)) {
            lottieScale = 1.0
            opacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.easeOut(duration: 0.3)) {
                isActive = true
            }
        }
    }
}

#if DEBUG
struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
            .environmentObject(SessionViewModel())
    }
}
#endif
