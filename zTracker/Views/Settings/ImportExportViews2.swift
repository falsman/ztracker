//
//  ImportExportViews2.swift
//  zTracker
//
//  Created by Jia Sahar on 1/10/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ExportRowView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.sortIndex) private var habits: [Habit]
    
    @State private var exportFormat: ExportFormat = .json
    @State private var showingExporter = false
    @State private var exportData: Data?
    @State private var isExporting = false
    
    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case csv = "CSV"
    }
    
    var body: some View {
        HStack {
            Picker("Export Format", selection: $exportFormat) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            
            Spacer()
            
            Button {
                exportAllData()
            } label: {
                HStack {
                    if isExporting {
                        ProgressView()
                            .padding(.trailing, 8)
                    }
                    Text(isExporting ? "Exporting" : "Export Data")
                }
            }
            .buttonStyle(.glass)
            .disabled(isExporting)
        }
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

struct ImportRowView: View {
    @Environment(\.modelContext) private var context
    
    @State private var importFormat: ImportFormat = .json
    @State private var showingImporter = false
    @State private var isImporting = false
    @State private var importResult: ImportResult?
    @State private var showingResult = false
        
    enum ImportFormat: String, CaseIterable {
        case json = "JSON"
        case csv = "CSV"
    }
    
    var body: some View {
        
        HStack {
            Picker("Import Format", selection: $importFormat) {
                ForEach(ImportFormat.allCases, id: \.self) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            
            Button {
                showingImporter = true
            } label: {
                HStack {
                    if isImporting {
                        ProgressView()
                            .padding(.trailing, 8)
                    }
                    Text(isImporting ? "Importing" : "Import Data")
                }
            }
            .buttonStyle(.glass)
            .disabled(isImporting)
            
            if let result = importResult {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Import Complete")
                        .font(.headline)
                    Text("Habits imported: \(result.habitsImported)")
                    Text("Entries imported: \(result.entriesImported)")
                    
                    if !result.errors.isEmpty {
                        Text("Errors: \(result.errors.count)")
                            .foregroundStyle(.red)
                    }
                }
                .padding()
            }
            
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: importFormat == .json ? [.json] : [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    importData(from: url)
                }
            case .failure(let error):
                print("Import failed: \(error)")
            }
        }
    }
    
    private func importData(from url: URL) {
        isImporting = true
        
        Task {
            do {
                let data = try Data(contentsOf: url)
                let result: ImportResult
                
                switch importFormat {
                case .json:
                    result = try await importFromJSON(data: data)
                case .csv:
                    result = try await importFromCSV(data: data)
                }
                
                await MainActor.run {
                    importResult = result
                    isImporting = false
                }
            } catch {
                print("Failed to import data: \(error)")
                await MainActor.run {
                    isImporting = false
                }
            }
        }
    }
    
    private func importFromJSON(data: Data) async throws -> ImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let exportData = try decoder.decode(ExportData.self, from: data)
        
        var habitsImported = 0
        var entriesImported = 0
        var errors: [ImportError] = []
        
        // Create a mapping of habit IDs to new habits
        var habitMap: [UUID: Habit] = [:]
        
        // Import habits
        for habitData in exportData.habits {
            let habit = Habit(
                id: habitData.id,
                title: habitData.title,
                type: habitData.type,
                color: habitData.color,
                icon: habitData.icon,
                isArchived: habitData.isArchived,
                createdAt: habitData.createdAt,
                reminder: habitData.reminder,
                sortIndex: habitData.sortIndex,
                metadata: habitData.metadata
            )
            
            context.insert(habit)
            habitMap[habitData.id] = habit
            habitsImported += 1
        }
        
        // Import entries
        for entryData in exportData.entries {
            guard let habit = habitMap[entryData.habitId] else {
                errors.append(.habitNotFound(entryData.habitId))
                continue
            }
            
            let entry = HabitEntry(
                id: entryData.id,
                date: entryData.date,
                completed: entryData.completed,
                durationSeconds: entryData.durationSeconds,
                ratValue: entryData.ratValue,
                numValue: entryData.numValue,
                note: entryData.note,
                updatedAt: entryData.updatedAt,
                habit: habit
            )
            
            context.insert(entry)
            entriesImported += 1
        }
        
        try context.save()
        
        return ImportResult(
            habitsImported: habitsImported,
            entriesImported: entriesImported,
            errors: errors
        )
    }
    
    private func importFromCSV(data: Data) async throws -> ImportResult {
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw ImportError.invalidFormat
        }
        
        var habitsImported = 0
        var entriesImported = 0
        var errors: [ImportError] = []
        var habitMap: [UUID: Habit] = [:]
        
        let sections = csvString.components(separatedBy: "\n\n")
        
        for section in sections {
            let lines = section.components(separatedBy: "\n").filter { !$0.isEmpty }
            guard let header = lines.first else { continue }
            
            if header == "HABITS" {
                // Parse habits
                for line in lines.dropFirst(2) {
                    do {
                        let habit = try parseHabitCSV(line: line)
                        context.insert(habit)
                        habitMap[habit.id] = habit
                        habitsImported += 1
                    } catch {
                        errors.append(.decodingFailed(error.localizedDescription))
                    }
                }
            } else if header == "ENTRIES" {
                // Parse entries
                for line in lines.dropFirst(2) {
                    do {
                        let entry = try parseEntryCSV(line: line, habitMap: habitMap)
                        context.insert(entry)
                        entriesImported += 1
                    } catch {
                        errors.append(.decodingFailed(error.localizedDescription))
                    }
                }
            }
        }
        
        try context.save()
        
        return ImportResult(
            habitsImported: habitsImported,
            entriesImported: entriesImported,
            errors: errors
        )
    }
    
    private func parseHabitCSV(line: String) throws -> Habit {
        let components = line.components(separatedBy: ",")
        guard components.count >= 7 else {
            throw ImportError.invalidFormat
        }
        
        let id = UUID(uuidString: components[0]) ?? UUID()
        let title = components[1].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        let typeString = components[2].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        let type = HabitType.fromCSVString(typeString) ?? .boolean(goal: .init(target: 0, frequency: .daily))
        let color = components[3]
        let icon = components[4].isEmpty ? nil : components[4]
        let isArchived = Bool(components[5]) ?? false
        let createdAt = ISO8601DateFormatter().date(from: components[6]) ?? Date()
        let reminder = components.count > 7 && !components[7].isEmpty
            ? ISO8601DateFormatter().date(from: components[7])
            : nil
        let sortIndex = Int(components[8]) ?? 0
        
        return Habit(
            id: id,
            title: title,
            type: type,
            color: color,
            icon: icon,
            isArchived: isArchived,
            createdAt: createdAt,
            reminder: reminder,
            sortIndex: sortIndex
        )
    }
    
    private func parseEntryCSV(line: String, habitMap: [UUID: Habit]) throws -> HabitEntry {
        let components = line.components(separatedBy: ",")
        guard components.count >= 9 else {
            throw ImportError.invalidFormat
        }
        
        let id = UUID(uuidString: components[0]) ?? UUID()
        let habitId = UUID(uuidString: components[1]) ?? UUID()
        
        guard let habit = habitMap[habitId] else {
            throw ImportError.habitNotFound(habitId)
        }
        
        let date = ISO8601DateFormatter().date(from: components[2]) ?? Date()
        let completed = components[3].isEmpty ? nil : Bool(components[3])
        let durationSeconds = components[4].isEmpty ? nil : Int64(components[4])
        let ratValue = components[5].isEmpty ? nil : Int(components[5])
        let numValue = components[6].isEmpty ? nil : Double(components[6])
        let note = components[7].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        let updatedAt = ISO8601DateFormatter().date(from: components[8]) ?? Date()
        
        return HabitEntry(
            id: id,
            date: date,
            completed: completed,
            durationSeconds: durationSeconds,
            ratValue: ratValue,
            numValue: numValue,
            note: note.isEmpty ? nil : note,
            updatedAt: updatedAt,
            habit: habit
        )
    }
}

#Preview("Import/Export Section View"){
    ImportExportSection()
}


