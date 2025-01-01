//
//  SettingsView.swift
//  StoryScapeApp
//
//  Created by Dev Asheesh Chopra on 02/01/25.
//

import SwiftUI

/// Displays the main settings menu.
struct SettingsView: View {
    
    @EnvironmentObject var sessionStore: SessionViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var responseLanguage: String = UserDefaults.standard.string(forKey: "responseLanguage") ?? "Hindi"
    @State private var ageGroup: String = UserDefaults.standard.string(forKey: "ageGroup") ?? "3-5"
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    // Link to Recommendations
                    NavigationLink(destination: RecommendationsView()) {
                        Text("Recommendations")
                    }
                }
                
                Section {
                    // Link to Language
                    NavigationLink(destination: ResponseLanguageView(selectedLanguage: $responseLanguage)) {
                        HStack {
                            Text("Response Language")
                            Spacer()
                            Text(responseLanguage)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Link to Age Group
                    NavigationLink(destination: AgeGroupView(selectedAgeGroup: $ageGroup)) {
                        HStack {
                            Text("Age Group")
                            Spacer()
                            Text(ageGroup)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section {
                    // Sign Out
                    Button(action: {
                        sessionStore.signOut()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationBarTitle("Settings", displayMode: .inline)
        }
    }
}
