//
//  zTrackerAppShortcuts.swift
//  zTracker
//
//  Created by Jia Sahar on 12/14/25.
//

import AppIntents
import SwiftUI

struct zTrackerAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SetDurationIntent(),
            phrases: [
                "Log \(.applicationName) hours",
                "Add hours in \(.applicationName)",
                "Record habit duration in \(.applicationName)",
                "What was the duration of the habit in \(.applicationName)"
            ],
            shortTitle: "Log Habit Duration",
            systemImageName: "clock"
        )
        
        AppShortcut(
            intent: SetValueIntent(),
            phrases: [
                "Rate my habit in \(.applicationName)",
                "Set habit quality in \(.applicationName)",
                "What was my habit rating in \(.applicationName)",
                "Rate today's habit in \(.applicationName)"
            ],
            shortTitle: "Set Habit Rating",
            systemImageName: "star"
        )
        
        AppShortcut(
            intent: SetBooleanIntent(),
            phrases: [
                "Toggle a habit in \(.applicationName)",
                "Check off a habit in \(.applicationName)",
                "Complete a habit in \(.applicationName)",
                "Mark habit as done in \(.applicationName)"
            ],
            shortTitle: "Toggle Habit",
            systemImageName: "checkmark.square"
        )
        
        AppShortcut(
            intent: SetValueIntent(),
            phrases: [
                "Set habit value in \(.applicationName)",
                "Log value for habit in \(.applicationName)",
                "Record number for habit in \(.applicationName)"
            ],
            shortTitle: "Set Habit Value",
            systemImageName: "number"
        )
        
        AppShortcut(
            intent: SetValueIntent(),
            phrases: [
                "Log numeric habit in \(.applicationName)",
                "Record number for \(.applicationName) habit",
                "Quick number entry in \(.applicationName)"
            ],
            shortTitle: "Log Numeric Habit",
            systemImageName: "numbers.rectangle"
        )
        
        AppShortcut(
            intent: AdjustValueIntent(),
            phrases: [
                "Increase habit in \(.applicationName)",
                "Add to habit in \(.applicationName)",
                "Increase habit value in \(.applicationName)"
            ],
            shortTitle: "Increment Habit",
            systemImageName: "plus"
        )
        
        AppShortcut(
            intent: AdjustValueIntent(),
            phrases: [
                "Decrease habit in \(.applicationName)",
                "Subtract from habit in \(.applicationName)",
                "Decrease habit value in \(.applicationName)"
            ],
            shortTitle: "Decrement Habit",
            systemImageName: "minus"
        )
        
        AppShortcut(
            intent: SetNoteIntent(),
            phrases: [
                "Add note to habit in \(.applicationName)",
                "Write note for habit in \(.applicationName)",
                "Record note in \(.applicationName)"
            ],
            shortTitle: "Add Habit Note",
            systemImageName: "square.and.pencil"
        )
        
//        AppShortcut(
//            intent: SetMultipleIntent(),
//            phrases: [
//                "Quick log in \(.applicationName)",
//                "Log duration and rating in \(.applicationName)",
//                "Daily log in \(.applicationName)"
//            ],
//            shortTitle: "Quick Log",
//            systemImageName: "bolt"
//        )
    }
    static var shortcutTileColor = Color(.teal)
}
