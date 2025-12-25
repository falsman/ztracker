//
//  zTrackerApp.swift
//  zTracker
//
//  Created by Jia Sahar on 12/12/25.
//

import SwiftUI
import SwiftData
import Combine

@main
struct zTrackerApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .modelContainer(StorageManager.shared.modelContainer!)
                .glassEffect()
        }
        .commands { SidebarCommands() }
        
        #if os(masOCS)
        Settings {
            SettingsView()
        }
        #endif
    }
}

@MainActor
class AppState: ObservableObject {
    @Published var selectedTab: Tab = .today
    @Published var showingNewHabit = false
    @Published var showingSettings = false
    @Published var selectedHabit: Habit? = nil
    
    enum Tab {
        case today, habits, insights, settings
    }
}
