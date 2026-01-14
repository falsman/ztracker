//
//  ExportView.swift
//  zTracker
//
//  Created by Jia Sahar on 1/10/26.
//


struct ExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    
    @State private var exportFormat: ExportFormat = .json
    @State private var showingExporter = false
    @State private var exportData: Data?
    @State private var isExporting = false
    
    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case csv = "CSV"
    }
    
    var body: some View {
        Form {
            Section("Format") {
                Picker("Export Format", selection: $exportFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section {
                Button {
                    exportAllData()
                } label: {
                    HStack {
                        if isExporting {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Text("Export All Data")
                    }
                }
                .disabled(isExporting)
            } header: {
                Text("Export")
            } footer: {
                Text("Exports \(habits.count) habits and their entries")
            }
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: 16))
        .navigationTitle("Export Data")
        .fileExporter(
            isPresented: $showingExporter,
            document: ExportDocument(data: exportData ?? Data()),
            contentType: exportFormat == .json ? .json : .commaSeparatedText,
            defaultFilename: "zTracker_Export_\(Date().formatted(.iso8601))"
        ) { result in
            isExporting = false
            switch result {
            case .success(let url):
                print("Export successful to: \(url)")
            case .failure(let error):
                print("Export failed: \(error)")
            }
        }
    }
    
    private func exportAllData() {
        isExporting = true
        
        Task {
            do {
                let data: Data
                
                switch exportFormat {
                case .json:
                    data = try await exportToJSON()
                case .csv:
                    data = try await exportToCSV()
                }
                
                await MainActor.run {
                    exportData = data
                    showingExporter = true
                }
            } catch {
                print("Failed to export data: \(error)")
                await MainActor.run {
                    isExporting = false
                }
            }
        }
    }
    
    private func exportToJSON() async throws -> Data {
        let habitExports = habits.map { HabitExportData(from: $0) }
        let entryExports = habits.flatMap { habit in
            habit.entries.map { EntryExportData(from: $0) }
        }
        
        let exportData = ExportData(habits: habitExports, entries: entryExports)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        return try encoder.encode(exportData)
    }
    
    private func exportToCSV() async throws -> Data {
        var csvString = ""
        
        // Export habits
        csvString += "HABITS\n"
        csvString += "id,title,type,color,icon,isArchived,createdAt,reminder\n"
        
        for habit in habits {
            let reminder = habit.reminder?.ISO8601Format() ?? ""
            let typeString = habit.type.csvString
            csvString += "\(habit.id),\"\(habit.title)\",\"\(typeString)\",\(habit.color),\(habit.icon ?? ""),\(habit.isArchived),\(habit.createdAt.ISO8601Format()),\(reminder)\n"
        }
        
        // Export entries
        csvString += "\nENTRIES\n"
        csvString += "id,habitId,date,completed,durationSeconds,ratValue,numValue,note,updatedAt\n"
        
        for habit in habits {
            for entry in habit.entries {
                let completed = entry.completed?.description ?? ""
                let duration = entry.durationSeconds?.description ?? ""
                let rating = entry.ratValue?.description ?? ""
                let number = entry.numValue?.description ?? ""
                let note = entry.note?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""
                
                csvString += "\(entry.id),\(habit.id),\(entry.date.ISO8601Format()),\(completed),\(duration),\(rating),\(number),\"\(note)\",\(entry.updatedAt.ISO8601Format())\n"
            }
        }
        
        guard let data = csvString.data(using: .utf8) else {
            throw ImportError.invalidFormat
        }
        
        return data
    }
}