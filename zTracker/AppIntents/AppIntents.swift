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
    @Parameter(title: "Completion", default: true) var completion: Bool
    @Parameter(title: "Date", default: today) var date: Date
    
    /// Logs a boolean completion for the intent's habit on the specified date.
    /// 
    /// Finds the habit by its identifier, validates that it is a boolean habit, creates or updates the entry for the day, and saves the context.
    /// - Returns: An intent result containing a dialog with the formatted date and a `HabitCompletionSnippet` view.
    /// - Throws:
    ///   - `IntentError.habitNotFound` if the habit with the provided identifier does not exist.
    ///   - `IntentError.wrongHabitType` if the habit is not of boolean type.
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
        _ = actualHabit.createOrUpdateEntry(for: targetDate, completed: completion)
        
        try context.save()
        
        let formattedDate = date.formatted(date: .abbreviated, time: .omitted)
        return .result(
            dialog: "Entry Date: \(formattedDate)",
            view: HabitCompletionSnippet(habitTitle: habit.title, completed: completion)
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
    
    /// Logs a time-duration entry for the specified habit on the given date.
    /// - Parameters:
    ///   - habit: The habit to log the duration for.
    ///   - duration: The duration to record.
    ///   - date: The date for which to record the duration.
    /// - Throws: `IntentError.habitNotFound` if the habit cannot be located; `IntentError.wrongHabitType` if the habit is not a duration-type habit.
    /// - Returns: An intent result presenting a confirmation dialog with the entry date and a `HabitDurationSnippet` view showing the recorded duration.
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
        
        let formattedDate = date.formatted(date: .abbreviated, time: .omitted)
        
        return .result(
            dialog: "Entry Date: \(formattedDate)",
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
    
    /// Logs a rating for the specified habit on the given date and returns a result view showing the recorded rating.
    /// Creates or updates the habit entry for the date with the provided rating and saves the change.
    /// - Returns: An intent result containing a dialog with the formatted entry date and a `HabitRatingSnippet` that displays the recorded rating.
    /// - Throws:
    ///   - `IntentError.habitNotFound` if no habit exists with the provided identifier.
    ///   - `IntentError.wrongHabitType` if the resolved habit is not a rating-type habit.
    ///   - `IntentError.valueOutOfRange(min:max:)` if the provided rating is outside the habit's allowed range.
    func perform() throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let container = try getModelContainer()
        let context = ModelContext(container)
        
        let habitID = habit.id
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.id == habitID }
        )
        
        guard let actualHabit = try context.fetch(descriptor).first else { throw IntentError.habitNotFound }
        guard case .rating(let min, let max, _) = actualHabit.type else { throw IntentError.wrongHabitType }
        guard value >= min && value <= max else { throw IntentError.valueOutOfRange(min: min, max: max) }
        
        let targetDate = Calendar.current.startOfDay(for: date)
        _ = actualHabit.createOrUpdateEntry(for: targetDate, ratValue: value)
        
        try context.save()
        
        let formattedDate = date.formatted(date: .abbreviated, time: .omitted)
        return .result(
            dialog: "Entry Date: \(formattedDate)",
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
    
    /// Logs a numeric value for the intent's habit on the specified date.
    /// 
    /// Validates that the habit exists, that it is a numeric-type habit, and that the provided value falls within the habit's allowed range. Creates or updates the entry for the start of the given day and saves the change.
    /// - Returns: An `IntentResult` presenting a dialog with the entry's formatted date and a `HabitNumericSnippet` showing the habit title, numeric value, and unit.
    /// - Throws:
    ///   - `IntentError.habitNotFound` if no habit with the provided identifier exists.
    ///   - `IntentError.wrongHabitType` if the habit is not a numeric-type habit.
    ///   - `IntentError.valueOutOfRange(min:max:)` if the provided value is outside the habit's allowed minimum and maximum.
    func perform() throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let container = try getModelContainer()
        let context = ModelContext(container)
        
        let habitID = habit.id
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.id == habitID }
        )
        
        guard let actualHabit = try context.fetch(descriptor).first else { throw IntentError.habitNotFound }
        guard case .numeric(let min, let max, let unit, _) = actualHabit.type else { throw IntentError.wrongHabitType }
        guard value >= min && value <= max else { throw IntentError.valueOutOfRange(min: Int(min), max: Int(max)) }
        
        let targetDate = Calendar.current.startOfDay(for: date)
        _ = actualHabit.createOrUpdateEntry(for: targetDate, numValue: value)
        
        try context.save()
        
        let formattedDate = date.formatted(date: .abbreviated, time: .omitted)
        return .result(
            dialog: "Entry Date: \(formattedDate)",
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
        return .result(dialog: "Entry Date: \(formattedDate)")
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