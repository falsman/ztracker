//
//  SetDurationIntent.swift
//  zTracker
//
//  Created by Jia Sahar on 12/14/25.
//

import SwiftData
import AppIntents

struct SetDurationIntent: AppIntent, HabitIntentLogic {
    static var title: LocalizedStringResource = "Log Habit Duration"
    static var description: IntentDescription = "Log time for a duration habit."
    
    @Parameter var habit: HabitEntity
    
    @Parameter(default: 8) var hours: Int
    @Parameter(default: 0) var minutes: Int
    
    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$hours)h \(\.$minutes)m for \(\.$habit)")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let habit = try await fetchHabit(habit)
        
        guard case .hours = habit.type else {
            throw NSError(domain: "zTracker", code: 400, userInfo: [NSLocalizedDescriptionKey: "Habit is not a duration type"])
        }
        
        let duration = Duration.seconds(hours * 3600 + minutes * 60)
        
        _ = await storage.createOrUpdateEntry(for: habit, time: duration)
        donateAfterSuccess(self)
        
        return .result(dialog: IntentDialog("Logged \(hours) hours \(minutes > 0 ? "\(minutes) minutes" : "") of '\(habit.title)'."))
    }
}
