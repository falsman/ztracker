//
//  ImportView.swift
//  zTracker
//
//  Created by Jia Sahar on 12/15/25.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct ImportView: View {
    @State private var importFormat = "JSON"
    @State private var showingImporter = false
    
    var body: some View {
        Form {
            Section("Format") {
                Picker("Format", selection: $importFormat) {
                    Text("JSON").tag("JSON")
                    Text("CSV").tag("CSV")
                }
                .pickerStyle(.segmented)
            }
            
            Section {
                Button("Import Data") { showingImporter = true }
            }
        }
        .glassEffect(in: .rect(cornerRadius: 16))
        .navigationTitle("Import Data")
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: importFormat == "JSON" ? [.json] : [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls): importData(from: urls.first)
            case .failure(let error): print("Import failed: \(error)")
            }
        }
    }
    
    private func importData(from url: URL?) {
        guard let url = url else { return }
        
        do {
            _ = try Data(contentsOf: url)
            print("Importing data from: \(url.path)")
        } catch { print("Failed to import data: \(error)") }
    }
}
