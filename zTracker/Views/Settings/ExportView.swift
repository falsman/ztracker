//
//  ExportView.swift
//  zTracker
//
//  Created by Jia Sahar on 12/15/25.
//

import SwiftUI
import HealthKit

struct ExportView: View {
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
                    .disabled(exportData == nil)
            }
        }
        .navigationTitle("Export Data")
        .fileExporter(
            isPresented: $showingExporter,
            document: ExportDocument(data: exportData ?? Data()),
            contentType: exportFormat == "JSON" ? .json : .commaSeparatedText,
            defaultFilename: "zTracker_Export_\(Date().formatted(.iso8601))"
        ) { result in
            switch result {
            case .success: print("Export successful")
            case .failure(let error): print("Export failed: \(error)")
            }
        }
    }
    
    private func exportAllData() {
        Task {
            let habits = await StorageManager.shared.fetchAllHabits()
            let encoder = JSONEncoder()
            
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            do {
                exportData = try encoder.encode(habits)
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
