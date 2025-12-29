//
//  ExportView.swift
//  zTracker
//
//  Created by Jia Sahar on 12/15/25.
//

import SwiftUI
internal import UniformTypeIdentifiers
import SwiftData

struct ExportView: View {
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    @State private var exportFormat = "JSON"
    @State private var showingExporter = false
    @State private var exportData: Data?
    
    var body: some View {
        Form {
            Section("Format") {
                Picker("Format", selection: $exportFormat) {
                    Text("JSON").tag("JSON")
                    Text("CSV").tag("CSV")
                }
                .pickerStyle(.segmented)
            }
            
            Section {
                Button("Export All Data") { exportAllData() }
            }
        }
        .glassEffect(in: .rect(cornerRadius: 16))
        .navigationTitle("Export Data")
        .fileExporter(
            isPresented: $showingExporter,
            document: ExportDocument(data: exportData ?? Data()),
            contentType: exportFormat == "JSON" ? .json : .commaSeparatedText,
            defaultFilename: "zTracker_Export_\(today.formatted(.iso8601))"
        ) { result in
            switch result {
            case .success: print("Export successful")
            case .failure(let error): print("Export failed: \(error)")
            }
        }
    }
    
        // TODO: doesn't export entries
    private func exportAllData() {
        Task {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = .prettyPrinted
                
                let exportStruct = habits.map { HabitExport(from: $0) }
                
                exportData = try encoder.encode(exportStruct)
                showingExporter = true
            } catch { print("Failed to encode data: \(error)") }
        }
    }
}

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .commaSeparatedText] }
    
    var data: Data
    
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = Data() }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct HabitExport: Codable {
    let id: UUID
    let title: String
    let type: HabitType
    let color: RGBValues
    let icon: String?
    let isArchived: Bool
    let createdAt: Date
    let reminder: Date?
    let metadata: Data?
    let entryIDs: [UUID]
    
    init(from habit: Habit) {
        self.id = habit.id
        self.title = habit.title
        self.type = habit.type
        self.color = habit.color
        self.icon = habit.icon
        self.isArchived = habit.isArchived
        self.createdAt = habit.createdAt
        self.reminder = habit.reminder
        self.metadata = habit.metadata
        self.entryIDs = habit.entries.map { $0.id }
    }
}


#Preview("Empty State") {
    ExportView()
        .modelContainer(PreviewHelpers.previewContainer)
        .environmentObject(AppState())
}

#Preview("With Sample Data") {
        let container = PreviewHelpers.previewContainer
        
        let habits = PreviewHelpers.makeHabits()
        habits.forEach { container.mainContext.insert($0) }
        
        try? container.mainContext.save()
        
        return ExportView()
            .modelContainer(container)
            .environmentObject(AppState())
}

