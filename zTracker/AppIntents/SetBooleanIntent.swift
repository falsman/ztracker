//
//  SetBooleanIntent.swift
//  zTracker
//
//  Created by Jia Sahar on 12/14/25.
//

import AppIntents
import SwiftData

struct SetBooleanIntent: AppIntent, HabitIntentLogic {
    static var title: LocalizedStringResource = "Toggle Habit"
    static var description = IntentDescription("Mark a boolean habit as completed or not completed")
    
    @Parameter var habit: HabitEntity
    
    static var parameterSummary: some ParameterSummary {
        Summary("Toggle \(\.$habit)")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let habit = try await fetchHabit(habit)
        
        guard case .boolean = habit.type else {
            throw NSError(domain: "zTracker", code: 400, userInfo: [NSLocalizedDescriptionKey: "Habit is not a boolean type"])
        }
        
        let entry = habit.entry(for: Date())
        let newValue = !(entry?.completed ?? false)
        
        _ = await storage.createOrUpdateEntry(for: habit, completed: newValue)
        donateAfterSuccess(self)
        
        let status = newValue ? "completed" : "not completed"
        return .result(dialog: IntentDialog("Marked '\(habit.title)' as \(status)."))
    }
}
