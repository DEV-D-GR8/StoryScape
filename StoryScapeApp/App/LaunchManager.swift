//
//  LaunchManager.swift
//  StoryScapeApp
//
//  Created by Dev Asheesh Chopra on 02/01/25.
//

import Foundation

/// Tracks whether this is the first time the user has launched the app.
class LaunchManager: ObservableObject {
    
    @Published var isFirstLaunch: Bool
    
    init() {
        // Check if the app has been launched before
        let defaults = UserDefaults.standard
        let hasLaunchedBefore = defaults.bool(forKey: "hasLaunchedBefore")
        
        if !hasLaunchedBefore {
            isFirstLaunch = true
            defaults.set(true, forKey: "hasLaunchedBefore")
        } else {
            isFirstLaunch = false
        }
    }
}
