//
//  SelectActionsIntent.swift
//  zTracker
//
//  Created by Jia Sahar on 12/15/25.
//


import AppIntents

struct SelectActionsIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Actions"

    @Parameter var actions: [ActionType]

    enum ActionType: String, AppEnum {
        case boolean = "Toggle"
        case hours = "Log Duration"
        case rating = "Log Rating"
        case numeric = "Log Value"
        case note = "Log Note"

        static var typeDisplayRepresentation: TypeDisplayRepresentation = "Action Type"

        static var caseDisplayRepresentations: [ActionType: DisplayRepresentation] = [
            .boolean: "Toggle Habit",
            .hours: "Log Duration",
            .rating: "Log Rating",
            .numeric: "Log Value",
            .note: "Log Note"
        ]
    }
}
