//
//  SettingsView.swift
//  zTracker
//
//  Created by Jia Sahar on 12/14/25.
//

import SwiftUI
import HealthKit
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("healthKitEnabled") private var healthKitEnabled = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("syncFrequency") private var syncFrequency = 300
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system
    // TODO: attach themeColor to AppStorage
    @State private var themeColor = Color(.teal)
    
    @State private var showingHealthKitAlert = false
    @State private var healthKitStatus = HKHealthStore().authorizationStatus(for: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!)
    
    enum ThemeMode: String, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
    }
    
    enum SyncFrequencies: Int, CaseIterable {
        case fiveMinutes = 300
        case fifteenMinutes = 900
        case thirtyMinutes = 1800
        case oneHour = 3600
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
                
                Section("HealthKit Integration") {
                    Toggle("Enable HealthKit", isOn: $healthKitEnabled)
                        .onChange(of: healthKitEnabled) { oldValue, newValue in
                            if newValue { requestHealthKitAccess() }
                        }
                    if healthKitEnabled {
                        VStack(alignment: .leading) {
                            Label("Sleep Analysis", systemImage: "bed.double")
                                .foregroundStyle(.blue)
                            Text("Automatically import sleep data from Health")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(alignment: .leading) {
                            Label("Mindfulness", systemImage: "brain.head.profile")
                                .foregroundStyle(.purple)
                            Text("Import mindfulness minutes from Health")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section("Notifications") {
                    Toggle("Daily Reminders", isOn: $notificationsEnabled)
                    
                    if notificationsEnabled {
                        DatePicker("Reminder Time", selection: .constant(Date()), displayedComponents: .hourAndMinute)
                    }
                }
                
                
//                Section("Sync") {
//                    Picker("Sync Frequency", selection: $syncFrequency) {
//                        ForEach(SyncFrequencies.allCases, id: \.self) { seconds in
//                            Text(seconds.rawValue).tag(seconds)
//                        }
//                    }
//                    Button("Force Sync Now") {
//                        Task { await StorageManager.shared.forceSync() }
//                    }
//                    .buttonStyle(.glass)
//                }
                
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
            .glassEffect(in: .rect(cornerRadius: 16))
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .buttonStyle(.glass)
                }
            }
        }
    }
}
