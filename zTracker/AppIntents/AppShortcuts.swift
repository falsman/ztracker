//
//  AppShortcuts.swift
//  zTracker
//
//  Created by Jia Sahar on 12/28/25.
//

import Foundation
import AppIntents

struct HabitTrackerAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogBooleanHabitIntent(),
            phrases: [
                "Log \(\.$habit) in \(.applicationName)",
                "Mark \(\.$habit) as complete in \(.applicationName)",
                "Complete \(\.$habit) in \(.applicationName)",
                "Check off \(\.$habit) in \(.applicationName)",
                "\(.applicationName): I completed \(\.$habit)"
            ],
            shortTitle: "Log Habit",
            systemImageName: "checkmark.circle"
        )
        
        AppShortcut(
            intent: LogRatingHabitIntent(),
            phrases: [
                "Rate \(\.$habit) in \(.applicationName)",
                "Give a rating for \(\.$habit) in \(.applicationName)",
                "Log rating for \(\.$habit) in \(.applicationName)",
                "Score \(\.$habit) in \(.applicationName)"
            ],
            shortTitle: "Rate Habit",
            systemImageName: "star.fill"
        )
        
        AppShortcut(
            intent: LogNumericHabitIntent(),
            phrases: [
                "Log value for \(\.$habit) in \(.applicationName)",
                "Set \(\.$habit) value in \(.applicationName)",
                "Record \(\.$habit) value in \(.applicationName)",
                "Track value for \(\.$habit) in \(.applicationName)"
            ],
            shortTitle: "Log Number",
            systemImageName: "number"
        )
        
        
        AppShortcut(
            intent: LogDurationHabitIntent(),
            phrases: [
                "Log duration of \(\.$habit) in \(.applicationName)",
                "\(.applicationName): Enter \(\.$habit) duration",
                "Track duration for \(\.$habit) in \(.applicationName)",
                "Record duration of \(\.$habit) in \(.applicationName)"
            ],
            shortTitle: "Log Duration",
            systemImageName: "clock.fill"
        )
        
        AppShortcut(
            intent: AddNoteToHabitIntent(),
            phrases: [
                "Add note to \(\.$habit) in \(.applicationName)",
                "Note for \(\.$habit) in \(.applicationName)",
                "Write note for \(\.$habit) in \(.applicationName)"
            ],
            shortTitle: "Add Note",
            systemImageName: "note.text"
        )
    }
    
    static let shortcutTileColor: ShortcutTileColor = .teal
}

