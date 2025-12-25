//
//  SetValueIntent.swift
//  zTracker
//
//  Created by Jia Sahar on 12/14/25.
//

import AppIntents
import SwiftData

struct SetValueIntent: AppIntent, HabitIntentLogic {
    static var title: LocalizedStringResource = "Set Value"
    static var description = IntentDescription("Set value or rating for habit")
    
    @Parameter var habit: HabitEntity
    @Parameter var value: Double
    
    static var parameterSummary: some ParameterSummary {
        Summary("Set \(\.$habit) to \(\.$value).")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let habit = try await fetchHabit(habit)
        
        switch habit.type {
        case .rating(let min, let max):
            let intValue = Int(value)
            guard intValue >= min && intValue <= max else {
                throw NSError(domain: "zTracker", code: 400, userInfo: [NSLocalizedDescriptionKey: "Rating must be between \(min) and \(max)"])
            }
            
            _ = await storage.createOrUpdateEntry(for: habit, rating: intValue)
            donateAfterSuccess(self)
            
            return .result(dialog: IntentDialog("Set '\(habit.title)' to \(intValue) out of \(max)"))
            
        case .numeric(let min, let max, let unit):
            guard value >= min && value <= max else {
                throw NSError(domain: "zTracker", code: 400, userInfo: [NSLocalizedDescriptionKey: "Value must be between \(min) and \(max)"])
            }
            
            _ = await storage.createOrUpdateEntry(for: habit, value: value)
            donateAfterSuccess(self)
            
            return .result(dialog: IntentDialog("Set '\(habit.title)' to \(formatted(value)) \(unit)"))
            
        default: throw NSError(domain: "zTracker", code: 500, userInfo: [NSLocalizedDescriptionKey: "Non-numeric habit type"])
        }
    }
}
