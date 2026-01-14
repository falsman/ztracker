//
//  ImportExportManager.swift
//  zTracker
//
//  Created by Jia Sahar on 1/10/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Export Structures

struct HabitExportData: Codable, Identifiable {
    let id: UUID
    let title: String
    let type: HabitType
    let color: String
    let icon: String?
    let isArchived: Bool
    let createdAt: Date
    let reminder: Date?
    let sortIndex: Int
    let metadata: Data?
    
    init(from habit: Habit) {
        self.id = habit.id
        self.title = habit.title
        self.type = habit.type
        self.color = habit.color
        self.icon = habit.icon
        self.isArchived = habit.isArchived
        self.createdAt = habit.createdAt
        self.reminder = habit.reminder
        self.sortIndex = habit.sortIndex
        self.metadata = habit.metadata
    }
}

extension HabitType {
    var csvString: String {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self),
              let string = String(data: data, encoding: .utf8) else {
            return "{\"boolean\":{}}"
        }
        return string.replacingOccurrences(of: "\"", with: "'")
    }
    
    static func fromCSVString(_ string: String) -> HabitType? {
        let decoder = JSONDecoder()
        let jsonString = string.replacingOccurrences(of: "'", with: "\"")
        guard let data = jsonString.data(using: .utf8),
              let type = try? decoder.decode(HabitType.self, from: data) else {
            return nil
        }
        return type
    }
}

struct EntryExportData: Codable, Identifiable {
    let id: UUID
    let habitId: UUID
    let date: Date
    let completed: Bool?
    let durationSeconds: Int64?
    let ratValue: Int?
    let numValue: Double?
    let note: String?
    let updatedAt: Date
    
    init(from entry: HabitEntry) {
        self.id = entry.id
        self.habitId = entry.habit?.id ?? UUID()
        self.date = entry.date
        self.completed = entry.completed
        self.durationSeconds = entry.durationSeconds
        self.ratValue = entry.ratValue
        self.numValue = entry.numValue
        self.note = entry.note
        self.updatedAt = entry.updatedAt
    }
}

struct ExportData: Codable {
    let habits: [HabitExportData]
    let entries: [EntryExportData]
    let exportDate: Date
    let version: String
    
    init(habits: [HabitExportData], entries: [EntryExportData]) {
        self.habits = habits
        self.entries = entries
        self.exportDate = Date()
        self.version = "1.0"
    }
}

// MARK: - Import Result

struct ImportResult {
    let habitsImported: Int
    let entriesImported: Int
    let errors: [ImportError]
}

enum ImportError: Error, LocalizedError {
    case invalidFormat
    case decodingFailed(String)
    case habitNotFound(UUID)
    case duplicateEntry
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid file format"
        case .decodingFailed(let detail):
            return "Failed to decode data: \(detail)"
        case .habitNotFound(let id):
            return "Habit not found: \(id)"
        case .duplicateEntry:
            return "Duplicate entry detected"
        }
    }
}


// MARK: - Export Document

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .commaSeparatedText] }
    
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        data = Data()
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
