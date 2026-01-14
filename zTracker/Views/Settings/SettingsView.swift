//
//  SettingsView.swift
//  zTracker
//
//  Created by Jia Sahar on 12/14/25.
//

import SwiftUI
import HealthKit
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    ThemeColorSection()
                    
                    #if os(iOS)
                    HealthKitSection()
                    #endif
                    
                    RemindersSection()
                    
                    ImportExportSection()

                    InfoSection()
                    
                    #if DEBUG
                    DebugSection()
                    #else
                    NuclearSection()
                    #endif
                    
                }
                .navigationTitle("Settings")
                .padding()
                .frame(maxHeight: .infinity, alignment: .top)
            }
            #if os(iOS)
            .background(movingLinearGradient(selectedColor: .theme))
            #endif
            
        }
    }
    
}

struct ThemeColorSection: View {
    // TODO: attach settingsThemeColor to AppStorage
    @AppStorage("settingsThemeColorHex") private var settingsThemeColorHex = "#007AFF"
    @State private var settingsThemeColor: Color = .teal
    
    var body: some View {
        VStack {
            ColorPicker("Theme Color", selection: $settingsThemeColor, supportsOpacity: false)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(in: .rect(cornerRadius: 16))
    }
}


#if os(iOS)
struct HealthKitSection: View {
    @AppStorage("healthKitEnabled") var healthKitEnabled = false
    
    @AppStorage("sleepHabit") private var sleepHabitID: String = ""
    @AppStorage("mindfulHabit") private var mindfulHabitID: String = ""

    @Query(sort: \Habit.sortIndex) private var allHabits: [Habit]
     
    var durationHabits: [Habit] {
        allHabits.filter { habit in
            if case .duration = habit.type { return true }
            return false
        }
    }
    
    var sleepHabit: Habit? { allHabits.first { $0.id.uuidString == sleepHabitID } }
    var mindfulHabit: Habit? { allHabits.first { $0.id.uuidString == mindfulHabitID } }
    
    var body: some View {
        VStack {
            Toggle("Enable HealthKit", isOn: $healthKitEnabled)
                .disabled(sleepHabitID.isEmpty || mindfulHabitID.isEmpty)

                .onChange(of: sleepHabitID) {
                    if sleepHabitID.isEmpty { healthKitEnabled = false }
                }
                .onChange(of: mindfulHabitID) {
                    if mindfulHabitID.isEmpty { healthKitEnabled = false }
                }

                .onChange(of: healthKitEnabled) {
                    guard healthKitEnabled else { print("Health Kit Enabled: \(healthKitEnabled)"); return }
                    guard !mindfulHabitID.isEmpty, !sleepHabitID.isEmpty else { return }
                    print("Requesting HealthKit Authorization")
                    Task {
                        do { try await HealthKitManager.shared.requestAuthorization() }
                        catch { print("HealthKit Authorization Failed: \(error)") }
                    }
                }
            
            if (sleepHabitID.isEmpty || mindfulHabitID.isEmpty) {
                Text("Choose habits to sync with Health data.")
                    .font(.caption.italic())
            }
            
                Divider()

                VStack {
                    HStack {
                        Text("Sleep Duration Sync").foregroundStyle(.secondary).lineLimit(1)
                        
                        Spacer()
                        
                        Menu {
                            ForEach(durationHabits) { habit in
                                Button { sleepHabitID = habit.id.uuidString }
                                label: { Label(habit.title, systemImage: habit.icon ?? "questionmark.circle") }
                            }
                        } label: { Label(sleepHabit?.title ?? "Pick Sleep Habit", systemImage: sleepHabit?.icon ?? "questionmark.circle").lineLimit(1) }
                            .buttonStyle(.glass)
                    }
                    
                    
                    HStack {
                        Text("Mindfulness Mins. Sync").foregroundStyle(.secondary).lineLimit(1)
                        
                        Spacer()
                        
                        Menu {
                            ForEach(durationHabits) { habit in
                                Button { mindfulHabitID = habit.id.uuidString }
                                label: { Label(habit.title, systemImage: habit.icon ?? "questionmark.circle") }
                            }
                        } label: { Label(mindfulHabit?.title ?? "Pick Mindfulness Habit", systemImage: mindfulHabit?.icon ?? "questionmark.circle").lineLimit(1) }
                            .buttonStyle(.glass)
                    }
                }
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: 16))
    }
}
#endif


// TODO: interactive reminders!
struct RemindersSection: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false

    var body: some View {
        VStack {
            Toggle("Reminders", isOn: $notificationsEnabled)
                .onChange(of: notificationsEnabled) {
                    Task {
                        if notificationsEnabled {
                            let granted = try? await UNUserNotificationCenter.current()
                                .requestAuthorization(options: [.alert, .sound, .badge])
                            if granted != true { notificationsEnabled = false }
                        } else {
                            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                            notificationsEnabled = false
                        }
                    }
                }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(in: .rect(cornerRadius: 16))
        
        .onAppear {
            Task {
                let settings = await UNUserNotificationCenter.current().notificationSettings()
                notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
}

struct ImportExportSection: View {
    var body: some View {
        VStack {
            Text("Import/Export Data")
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack { ExportRowView() }
            Divider()
            HStack { ImportRowView() }
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: 16))
    }
}

struct InfoSection: View {
    private let privacyPolicyURLString = "https://zTracker.com/privacy"
    private let termsOfServiceURLString = "https://zTracker.com/terms"
    
    var body: some View {
        VStack {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }
            Link("Privacy Policy", destination: URL(string: privacyPolicyURLString)!)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Link("Terms of Service", destination: URL(string: termsOfServiceURLString)!)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            
            Button("Contact Support") { print("Not Setup Yet") }
                .frame(maxWidth: .infinity, alignment: .leading)
            
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: 16))
    }
}

struct NuclearSection: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingDeleteAlert = false

    var body: some View {
        VStack(alignment: .leading) {
            Text("Nuclear Option")
                .font(.headline)

            Button("Delete Everything", systemImage: "trash.fill", role: .destructive) { showingDeleteAlert = true }
                .buttonStyle(.glassProminent)

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(in: .rect(cornerRadius: 16))
        
        .alert("Are you sure you want to Delete Everything?", isPresented: $showingDeleteAlert) {
            Button("Delete Everything", systemImage: "trash.fill", role: .destructive) {
                context.container.deleteAllData() }
            Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
        } message: { Text("This action cannot be undone.")
        }
        
    }
}

#if DEBUG
struct DebugSection: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        VStack {
            Text("Debug Section")
                .font(.headline)
            
            Button("Reset Sample Data", systemImage: "trash.fill", role: .destructive) {
                resetSampleData()
                exit(0)
            }
            .buttonStyle(.glassProminent)
            Text("App/Session will end after this.").font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(in: .rect(cornerRadius: 16))
    }
    
    private func resetSampleData() {
        let habits = try? context.fetch(FetchDescriptor<Habit>())
        habits?.forEach { context.delete($0) }
        
        UserDefaults.standard.removeObject(forKey: "didSeedSampleData")
    }
}
#endif


#Preview("Empty State") {
    SettingsView()
        .modelContainer(PreviewHelpers.previewContainer)
        
}

#Preview("With Sample Data") {
        let container = PreviewHelpers.previewContainer
        
        let habits = PreviewHelpers.makeHabits()
        habits.forEach { container.mainContext.insert($0) }
        
        try? container.mainContext.save()
        
        return SettingsView()
            .modelContainer(container)
            
}

