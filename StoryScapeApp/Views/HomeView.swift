//
//  HomeView.swift
//  StoryScapeApp
//
//  Created by Dev Asheesh Chopra on 02/01/25.
//

import SwiftUI

/// A short intro/marketing page with animations (like a mini “Onboarding”).
/// Navigates to LoginView if user taps “Sign In”.
struct HomeView: View {
    
    @EnvironmentObject var sessionStore: SessionViewModel
    
    @State private var currentStep = 0
    @State private var showSignInButton = false
    
    let genres = ["From Action 🦸‍♂️", "To Horror 👻"]
    let lottieFiles = ["rocket", "horror4"]
    
    var body: some View {
        ZStack {
            BackgroundView()
            
            VStack(spacing: 20) {
                Spacer()
                
                if currentStep < genres.count {
                    VStack {
                        Text(genres[currentStep])
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundColor(.white)
                            .padding()
                        
                        LottieView(filename: lottieFiles[currentStep], isPlaying: true)
                            .frame(height: 300)
                    }
                    .id(currentStep)
                    .transition(.opacity)
                } else {
                    VStack {
                        Text("StoryScape")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                        
                        Text("Every story, every genre, endless possibilities.")
                            .font(.title2)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding([.leading, .trailing])
                        
                        LottieView(filename: "book", isPlaying: true)
                            .frame(height: 300)
                    }
                    .transition(.opacity)
                }
                
                Spacer()
                
                if showSignInButton {
                    NavigationLink(destination:
                        LoginView()
                            .environmentObject(sessionStore)
                            .navigationBarBackButtonHidden(true)
                    ) {
                        Text("Sign In")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.orange, Color.red]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(25)
                            .shadow(color: Color.red.opacity(0.5), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 50)
                    .padding(.bottom, 40)
                    .transition(.opacity)
                    .opacity(showSignInButton ? 1 : 0)
                    .animation(.easeInOut(duration: 1.8), value: showSignInButton)
                }
            }
            .padding(.bottom, 20)
        }
        .onAppear {
            startSequence()
        }
    }
    
    private func startSequence() {
        currentStep = 0
        
        for index in 0...genres.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 1.5 + (1.0 * Double(index))) {
                withAnimation(.easeInOut(duration: 0.7)) {
                    currentStep = index
                }
                
                if index == genres.count {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                        withAnimation(.easeInOut(duration: 1.0)) {
                            showSignInButton = true
                        }
                    }
                }
            }
        }
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(SessionViewModel())
    }
}
#endif
