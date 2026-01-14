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
import UniformTypeIdentifiers

@main
struct zTrackerApp: App {
    @AppStorage("sleepHabit") private var sleepHabitID: String = ""
    @AppStorage("mindfulHabit") private var mindfulHabitID: String = ""

    @State private var container: ModelContainer?
    @State private var needsPicker = DataStoreManager.shared.needsLocationPicker
    
    var sharedContainer: ModelContainer?
    private let notificationDelegate = NotificationDelegate()

    init() { UNUserNotificationCenter.current().delegate = notificationDelegate }
    
    var body: some Scene {
        WindowGroup {
            if let container = container {
                ContentView()
                    .modelContainer(container)
                    .task { HabitEntity.indexAllHabits() }
                                
            } else if !needsPicker {
                VStack { Text("Loading Data...").font(.headline).onAppear { setupContainer() } }
            } else {
                VStack {
                    Text("No data folder selected").font(.headline)
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
            
            #if DEBUG
            SampleDataSeeder.seedIfNeeded(context: tempContainer.mainContext)
            #endif
            
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
            id: UUID(),
            title: "Sleep Duration",
            type: .duration(goal: .init(target: (8 * 60 * 60), frequency: .daily)),
            color: "indigo",
            icon: "bed.double",
            sortIndex: 1
        )
        let mindfulMins = Habit(
            id: UUID(),
            title: "Mindful Minutes",
            type: .duration(goal: .init(target: 60, frequency: .daily)),
            color: "mint",
            icon: "apple.meditate",
            sortIndex: 2
        )
                
        context.insert(sleepHours)
        context.insert(mindfulMins)
        
        do {
            try context.save()
            
            print("sleep habit ID")
            sleepHabitID = sleepHours.id.uuidString
            print(sleepHabitID)
            print("mindful habit ID")
            mindfulHabitID = mindfulMins.id.uuidString
            print(mindfulHabitID)

        }
        catch { print("Failed to save default habits: \(error)") }
        
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
