//
//  zTrackerApp.swift
//  zTracker
//
//  Created by Jia Sahar on 12/12/25.
//

import SwiftUI
import SwiftData
import Combine
import AppIntents
import CoreSpotlight
import UserNotifications
internal import UniformTypeIdentifiers

@main
struct zTrackerApp: App {
    @StateObject private var appState = AppState()
    @State private var container: ModelContainer?
    @State private var needsPicker = DataStoreManager.shared.needsLocationPicker
    
    var sharedContainer: ModelContainer?
    private let notificationDelegate = NotificationDelegate()

    
    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }
    
    var body: some Scene {
        WindowGroup {
            if let container = container {
                ContentView()
                    .environmentObject(appState)
                    .modelContainer(container)
                    .task { HabitEntity.indexAllHabits() }
            } else if !needsPicker {
                VStack {
                    Text("Loading Data...")
                        .font(.headline)
                        .onAppear { setupContainer() }
                }
            } else {
                VStack {
                    Text("No data folder selected")
                        .font(.headline)
                    ChooseFolderButton { url in
                        do {
                            try DataStoreManager.shared.saveLocation(url)
                            setupContainer()
                        } catch { print("Could not save data folder: \(error)") }
                    }
                }
            }
        }
        .commands { SidebarCommands() }
    }
    private func setupContainer() {
        do {
            let storeURL = try DataStoreManager.shared.getStoreURL()
            
            let schema = Schema([Habit.self, HabitEntry.self])
            let modelConfigurations = ModelConfiguration(url: storeURL)
            let tempContainer = try ModelContainer(for: schema, configurations: [modelConfigurations])
            
            container = tempContainer
            
            Task { await createDefaultHabits(in: tempContainer.mainContext) }
        } catch {
            needsPicker = true
            print("Failed to create container: \(error)")
        }
    }
    
    private func createDefaultHabits(in context: ModelContext) async {
        let fetchDescriptor = FetchDescriptor<Habit>()
        
        guard let habits = try? context.fetch(fetchDescriptor), habits.isEmpty else { return }
        
        print("Creating default habits...")
        
        let sleepHours = Habit(
            id: UUID(uuidString: "A7F4E6F1-0F5C-4A6B-9F1E-2B6E4E0A9C01")!,
            title: "Sleep Hours",
            type: .duration,
            color: RGBValues(r: 109/255, g: 124/255, b: 255/255),
            icon: "moon.zzz"
            )
        let mindfulMins = Habit(
            id: UUID(uuidString: "D2C9E8A4-3C5E-4E77-9F2A-8F6D1C7A0B11")!,
            title: "Mindful Minutes",
            type: .duration,
            color: RGBValues(r: 0/255, g: 195/255, b: 208/255),
            icon: "apple.meditate"
            )
        
        context.insert(sleepHours)
        context.insert(mindfulMins)
            
            do {
                try context.save()
                print("Default habits created")
            } catch { print("Failed to save default habits: \(error)") }
        }
    }

class AppState: ObservableObject {
    @Published var selectedTab: Tab = .today
    @Published var showingHabitEditor = false
    @Published var showingSettings = false
    @Published var selectedHabit: Habit? = nil
    
    enum Tab {
        case today, habits, insights, settings
    }
}

struct ChooseFolderButton: View {
    let onPicked: (URL) -> Void
    @State private var showPicker = false
    
    var body: some View {
        Button("Choose Folder") {
            showPicker = true
        }
        .fileImporter(isPresented: $showPicker, allowedContentTypes: [.folder], allowsMultipleSelection: false) { result in
            guard let url = try? result.get().first else { return }
            onPicked(url)
        }
    }
}
