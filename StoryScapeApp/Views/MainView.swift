//
//  MainView.swift
//  StoryScapeApp
//
//  Created by Dev Asheesh Chopra on 02/01/25.
//

import SwiftUI

/// The root View after sign-in (or from splash).
/// Shows `ContentView` with nav bar items for History & Settings.
struct MainView: View {
    
    @EnvironmentObject var sessionStore: SessionViewModel
    
    @State private var isShowingHistory = false
    @State private var isShowingSettings = false
    
    var body: some View {
        NavigationStack {
            ContentView()
                .navigationBarTitle("Story Generator", displayMode: .inline)
                .navigationBarItems(
                    leading: Button(action: { isShowingHistory.toggle() }) {
                        Image(systemName: "line.horizontal.3")
                    },
                    trailing: Button(action: { isShowingSettings.toggle() }) {
                        Image(systemName: "gearshape")
                    }
                )
                .sheet(isPresented: $isShowingHistory) {
                    HistoryView()
                }
                .sheet(isPresented: $isShowingSettings) {
                    SettingsView()
                }
        }
    }
}

#if DEBUG
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(SessionViewModel())
    }
}
#endif
