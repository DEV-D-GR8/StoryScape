//
//  FirebaseManager.swift
//  StoryScapeApp
//
//  Created by Dev Asheesh Chopra on 02/01/25.
//

import Foundation
import Firebase

class FirebaseManager {
    
    static let shared = FirebaseManager()
    
    private init() {
        // Private to ensure singleton usage
    }
    
    /// Example function that returns a reference to Firestore
    func firestore() -> Firestore {
        return Firestore.firestore()
    }
    
    /// Example function that returns a reference to Firebase Storage
    func storage() -> Storage {
        return Storage.storage()
    }
    
}
