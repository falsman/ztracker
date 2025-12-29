//
//  AppIntents.swift
//  zTracker
//
//  Created by Jia Sahar on 12/28/25.
//

import Foundation
import AppIntents
import SwiftData
import SwiftUI

struct LogBooleanHabitIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Log Boolean Habit"
    nonisolated(unsafe) static var description = IntentDescription("Mark a checkmark habit as completed")
    
    nonisolated(unsafe) static var isDiscoverable: Bool = true
    
    @Parameter(title: "Habit") var habit: HabitEntity
    @Parameter(title: "Date", default: today) var date: Date
    
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let container = try getModelContainer()
        let context = ModelContext(container)
        
        let habitID = habit.id
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.id == habitID }
        )
        guard let actualHabit = try context.fetch(descriptor).first else { throw IntentError.habitNotFound }
        guard case .boolean = actualHabit.type else { throw IntentError.wrongHabitType }
        
        let targetDate = Calendar.current.startOfDay(for: date)
        _ = actualHabit.createOrUpdateEntry(for: targetDate, completed: true)
        
        try context.save()
        
        let formattedDate = date.formatted(date: .abbreviated, time: .omitted)
        return .result(
            dialog: "Logged \(habit.title) for \(formattedDate) as completed.",
            view: HabitCompletionSnippet(habitTitle: habit.title, completed: true)
        )
    }
}

struct LogDurationHabitIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Log Duration Habit"
    nonisolated(unsafe) static var description = IntentDescription("Log time duration for a habit")
      
    nonisolated(unsafe) static var isDiscoverable: Bool = true
    
    @Parameter(title: "Habit") var habit: HabitEntity
    @Parameter(title: "Duration") var duration: Measurement<UnitDuration>
    @Parameter(title: "Date", default: today) var date: Date
    
    func perform() throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let container = try getModelContainer()
        let context = ModelContext(container)
        
        let habitID = habit.id
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.id == habitID }
        )
        
        guard let actualHabit = try context.fetch(descriptor).first else { throw IntentError.habitNotFound }
        guard case .duration = actualHabit.type else { throw IntentError.wrongHabitType }
        
        let seconds = Int(duration.converted(to: .seconds).value)
        let timeDuration = Duration.seconds(seconds)
        
        let targetDate = Calendar.current.startOfDay(for: date)
        _ = actualHabit.createOrUpdateEntry(for: targetDate, time: timeDuration)
        
        try context.save()
        
        let formattedDuration = duration.formatted()
        let formattedDate = date.formatted(date: .abbreviated, time: .omitted)
        
        return .result(
            dialog: "Logged \(habit.title) for \(formattedDate) as \(formattedDuration).",
            view: HabitDurationSnippet(habitTitle: habit.title, duration: timeDuration)
        )
    }
}


struct LogRatingHabitIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Log Rating Habit"
    nonisolated(unsafe) static var description = IntentDescription("Mark a rating habit as completed")
        
    nonisolated(unsafe) static var isDiscoverable: Bool = true

    @Parameter(title: "Habit") var habit: HabitEntity
    @Parameter(title: "Rating") var value: Int
    @Parameter(title: "Date", default: today) var date: Date
    
    func perform() throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let container = try getModelContainer()
        let context = ModelContext(container)
        
        let habitID = habit.id
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.id == habitID }
        )
        
        guard let actualHabit = try context.fetch(descriptor).first else { throw IntentError.habitNotFound }
        guard case .rating(let min, let max) = actualHabit.type else { throw IntentError.wrongHabitType }
        guard value >= min && value <= max else { throw IntentError.valueOutOfRange(min: min, max: max) }
        
        let targetDate = Calendar.current.startOfDay(for: date)
        _ = actualHabit.createOrUpdateEntry(for: targetDate, ratValue: value)
        
        try context.save()
        
        let formattedDate = date.formatted(date: .abbreviated, time: .omitted)
        return .result(
            dialog: "Logged \(habit.title) for \(formattedDate) as \(value)",
            view: HabitRatingSnippet(habitTitle: habit.title, rating: value, maxRating: max)
        )
    }
}

struct LogNumericHabitIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Log Numeric Habit"
    nonisolated(unsafe) static var description = IntentDescription("Log a numeric value for a habit")
       
    nonisolated(unsafe) static var isDiscoverable: Bool = true

    @Parameter(title: "Habit") var habit: HabitEntity
    @Parameter(title: "Value") var value: Double
    @Parameter(title: "Date", default: today) var date: Date
    
    func perform() throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let container = try getModelContainer()
        let context = ModelContext(container)
        
        let habitID = habit.id
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.id == habitID }
        )
        
        guard let actualHabit = try context.fetch(descriptor).first else { throw IntentError.habitNotFound }
        guard case .numeric(let min, let max, let unit) = actualHabit.type else { throw IntentError.wrongHabitType }
        guard value >= min && value <= max else { throw IntentError.valueOutOfRange(min: Int(min), max: Int(max)) }
        
        let targetDate = Calendar.current.startOfDay(for: date)
        _ = actualHabit.createOrUpdateEntry(for: targetDate, numValue: value)
        
        try context.save()
        
        let formattedDate = date.formatted(date: .abbreviated, time: .omitted)
        return .result(
            dialog: "Logged \(habit.title) for \(formattedDate) as \(value)",
            view: HabitNumericSnippet(habitTitle: habit.title, value: value, unit: unit)
            )
    }
}

struct AddNoteToHabitIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Add Note to Habit"
    nonisolated(unsafe) static var description = IntentDescription("Add or update a note for a habit entry")
        
    nonisolated(unsafe) static var isDiscoverable: Bool = true

    @Parameter(title: "Habit") var habit: HabitEntity
    @Parameter(title: "Note", inputOptions: .init(multiline: true)) var text: String
    @Parameter(title: "Date", default: today) var date: Date
    
    func perform() throws -> some IntentResult & ProvidesDialog {
        let container = try getModelContainer()
        let context = ModelContext(container)
        
        let habitID = habit.id
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.id == habitID }
        )
        
        guard let actualHabit = try context.fetch(descriptor).first else { throw IntentError.habitNotFound }
        
        let targetDate = Calendar.current.startOfDay(for: date)
        
        guard let existingEntry = actualHabit.entry(for: targetDate) else { throw IntentError.noEntryForDate }
        
        existingEntry.note = text
        existingEntry.updatedAt = Date.now
        
        try context.save()
        
        let formattedDate = date.formatted(date: .abbreviated, time: .omitted)
        return .result(dialog: "Added note to \(habit.title) for \(formattedDate): \n\(text)")
    }
}

#if os(iOS)
struct SyncHealthDataIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "Sync Health Data"
    nonisolated(unsafe) static var description = IntentDescription("Fetch Sleep Hours and Mindful Minutes from HealthKit and log them")

    nonisolated(unsafe) static var isDiscoverable: Bool = true
    
    @Parameter(title: "Date", default: today) var date: Date

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try getModelContainer()
        let context = ModelContext(container)
        
        try await syncHealthKitData(for: date, in: context)
        
        let formattedDate = date.formatted(date: .abbreviated, time: .omitted)
        return .result(dialog: "Health data synced for \(formattedDate).")
    }
}
#endif

enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case habitNotFound
    case wrongHabitType
    case valueOutOfRange(min: Int, max: Int)
    case noEntryForDate
    
    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .habitNotFound: return "Habit not found"
        case .wrongHabitType: return "This action doesn't match the habit type"
        case .valueOutOfRange(let min, let max): return "Value must be between \(min) and \(max)"
        case .noEntryForDate: return "No entry exists for this date. Please log the habit first before adding a note"
        }
    }
}
