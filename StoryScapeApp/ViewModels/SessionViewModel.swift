//
//  SessionViewModel.swift
//  StoryScapeApp
//
//  Created by Dev Asheesh Chopra on 02/01/25.
//

import SwiftUI
import FirebaseAuth
import Combine

/// Handles user session state (e.g., sign in, sign out, track current user).
class SessionViewModel: ObservableObject {
    
    /// The current Firebase user (nil if signed out).
    @Published var user: User?
    
    /// Loading flag used while checking authentication state.
    @Published var isLoading = true
    
    private var handle: AuthStateDidChangeListenerHandle?
    
    init() {
        listenForAuthChanges()
    }
    
    /// Listen for changes in Firebase Auth state. 
    /// Updates `user` whenever sign-in/out occurs.
    private func listenForAuthChanges() {
        isLoading = true
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isLoading = false
            }
        }
    }
    
    /// Sign out the current user.
    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.user = nil
            }
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
