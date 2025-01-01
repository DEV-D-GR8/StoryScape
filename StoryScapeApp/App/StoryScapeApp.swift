//
//  StoryScapeApp.swift
//  StoryScapeApp
//
//  Created by Dev Asheesh Chopra on 02/01/25.
//

import SwiftUI
import Firebase

@main
struct StoryScapeApp: App {
    
    // StateObjects for shared data across the app
    @StateObject var sessionStore = SessionViewModel()
    @StateObject var savedPromptsStore = SavedPromptsStore()
    @StateObject var favoritesStore = FavoritesStore()
    @StateObject var launchManager = LaunchManager()
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                // Simple loading indicator while we check auth state
                if sessionStore.isLoading {
                    LoadingView()
                } else {
                    // If user is authenticated:
                    if let _ = sessionStore.user {
                        // If it's the first launch, go directly to MainView
                        if launchManager.isFirstLaunch {
                            MainView()
                                .environmentObject(sessionStore)
                                .environmentObject(savedPromptsStore)
                                .environmentObject(favoritesStore)
                        } else {
                            // Otherwise, show the Splash screen first
                            SplashView()
                                .environmentObject(sessionStore)
                                .environmentObject(savedPromptsStore)
                                .environmentObject(favoritesStore)
                        }
                    } else {
                        // If user is not authenticated, show HomeView
                        HomeView()
                            .environmentObject(sessionStore)
                            .environmentObject(savedPromptsStore)
                            .environmentObject(favoritesStore)
                    }
                }
            }
        }
    }
}

/// A simple loading indicator used while checking authentication or other states.
struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView("Loading...")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
