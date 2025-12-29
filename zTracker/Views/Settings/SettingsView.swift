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
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("healthKitEnabled") private var healthKitEnabled = false
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system
    // TODO: attach themeColor to AppStorage
    @State private var themeColor = Color(.sRGB, red: 0.93, green: 0.38, blue: 0.65)
    
    @State private var notificationsEnabled = false
    @State private var showingHealthKitAlert = false
    @State private var healthKitStatus = HKHealthStore().authorizationStatus(for: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!)
    
    enum ThemeMode: String, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
    }
        
    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    VStack {
                        Picker("Theme Mode", selection: $themeMode) {
                            ForEach(ThemeMode.allCases, id: \.self) { theme in
                                Text(theme.rawValue).tag(theme)
                            }
                        }
                        
                        ColorPicker("Theme Color", selection: $themeColor, supportsOpacity: false)

                    }
                }
                
                #if os(iOS)
                Section("HealthKit Integration") {
                    Toggle("Enable HealthKit", isOn: $healthKitEnabled)
                        .onChange(of: healthKitEnabled) {
                            guard healthKitEnabled else { return }
                            Task { do {
                                try await HealthKitManager.shared.requestAuthorization()
                            } catch { print("HealthKit Authorization Failed: \(error)") }
                            }}
                }
                #endif
                
                // TODO: reminders!
                Section("Notifications") {
                    Toggle("Reminders", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) {
                            Task {
                                if notificationsEnabled {
                                    let granted = try? await UNUserNotificationCenter.current()
                                        .requestAuthorization(options: [.alert, .sound, .badge])
                                    if granted != true { notificationsEnabled = false }
                                } else {
                                    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                                }
                            }
                        }
                }
                
                Section("Data") {
                    NavigationLink("Export Data") { ExportView() }
                    NavigationLink("Import Data") { ImportView() }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    Link("Privacy Policy", destination: URL(string: "https://zTracker.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://zTracker.com/terms")!)
                    
                    Button("Contact Support") { print("Not Setup Yet") }
                }
                
                Section("Reset Data") {
                    Button("Delete Everything", role: .destructive) {
                        modelContext.container.deleteAllData()
                        print("All persistent data has been deleted.")
                    }
                        .buttonStyle(.glass)
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .onAppear {
            Task {
                let settings = await UNUserNotificationCenter.current().notificationSettings()
                notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
}

#Preview("Empty State") {
    SettingsView()
        .modelContainer(PreviewHelpers.previewContainer)
        .environmentObject(AppState())
}

#Preview("With Sample Data") {
        let container = PreviewHelpers.previewContainer
        
        let habits = PreviewHelpers.makeHabits()
        habits.forEach { container.mainContext.insert($0) }
        
        try? container.mainContext.save()
        
        return SettingsView()
            .modelContainer(container)
            .environmentObject(AppState())
}

