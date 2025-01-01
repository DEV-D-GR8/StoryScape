//
//  UserDefaultsManager.swift
//  StoryScapeApp
//
//  Created by Dev Asheesh Chopra on 02/01/25.
//


import Foundation

class UserDefaultsManager {
    
    static let shared = UserDefaultsManager()
    private init() {}
    
    func set<T>(_ value: T, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    func string(forKey key: String) -> String? {
        UserDefaults.standard.string(forKey: key)
    }
    
}
