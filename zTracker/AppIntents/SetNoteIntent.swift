//
//  SetNoteIntent.swift
//  zTracker
//
//  Created by Jia Sahar on 12/14/25.
//

import AppIntents

enum NoteMode: String, AppEnum {
    case replace, append
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Note Mode")
    static var caseDisplayRepresentations: [NoteMode: DisplayRepresentation] = [
        .replace: .init(title: "Replace"),
        .append: .init(title: "Append")
    ]
}

struct SetNoteIntent: AppIntent, HabitIntentLogic {
    static var title: LocalizedStringResource = "Set Habit Note"
    
    @Parameter var habit: HabitEntity
    @Parameter var note: String
    @Parameter(default: .replace) var mode: NoteMode
    
    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$mode) note for '\(\.$habit)'")
    }
    
    func perform() async throws -> some IntentResult {
        let habit = try await fetchHabit(habit)
        let existing = habit.entry(for: Date())?.note ?? ""
        
        let finalNote =
            mode == .append && !existing.isEmpty
            ? "\(existing)\n\(note)"
            : note
        
        _ = await storage.createOrUpdateEntry(for: habit, note: finalNote)
        donateAfterSuccess(self)
        
        let preview = finalNote.count > 20 ? String(finalNote.prefix(20)) + "…" : finalNote
        return .result(dialog: IntentDialog("Saved note: \(preview)"))
    }
}
