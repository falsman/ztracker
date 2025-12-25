//
//  AdjustValueIntent.swift
//  zTracker
//
//  Created by Jia Sahar on 12/14/25.
//

import AppIntents

enum AdjustmentDirection: String, AppEnum {
    case increment, decrement
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Direction")
    static var caseDisplayRepresentations: [AdjustmentDirection: DisplayRepresentation] = [
        .increment: .init(title: "Increment"),
        .decrement: .init(title: "Decrement")
    ]
}

struct AdjustValueIntent: AppIntent, HabitIntentLogic {
    static var title: LocalizedStringResource = "Adjust Habit"
    static var description = IntentDescription("Increase or Decrease a numeric habit by a specified amount")
    
    @Parameter var habit: HabitEntity
    @Parameter(default: 1.00) var amount: Double
    @Parameter var direction: AdjustmentDirection
    
    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$direction) \(\.$habit) by \(\.$amount)")
    }
    
    func perform() async throws -> some IntentResult {
        let habit = try await fetchHabit(habit)
        guard case .numeric(let min, let max, let unit) = habit.type else {
            throw NSError(domain: "zTracker", code: 400, userInfo: [NSLocalizedDescriptionKey: "Habit is not a numeric type"])
        }
        
        let current = habit.entry(for: Date())?.value ?? 0.00
        let delta = direction == .increment ? amount : -amount
        let newValue = current + delta

        _ = await storage.createOrUpdateEntry(for: habit, value: newValue)
        donateAfterSuccess(self)
        
        return.result(dialog: IntentDialog("\(direction == .increment ? "Increased" : "Decreased") '\(habit.title)' by \(amount). New value: \(formatted(newValue)) \(unit)."))
        
        
    }
}
