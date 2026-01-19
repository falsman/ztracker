//
//  Habit.swift
//  zTracker
//
//  Created by Jia Sahar on 12/12/25.
//

import SwiftUI
import SwiftData
import Foundation

@Model
final class Habit {
    @Attribute(.unique) var id: UUID
    var title: String
    var type: HabitType
    var color: String
    var icon: String?
    var isArchived: Bool
    var createdAt: Date
    var reminder: Date?
    var sortIndex: Int
    var metadata: Data?
    
    @Relationship(deleteRule: .cascade, inverse: \HabitEntry.habit)
    var entries: [HabitEntry] = []
    
    var swiftUIColor: Color {
        AppColor(rawValue: color)?.color ?? .theme
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        type: HabitType,
        color: String,
        icon: String? = nil,
        isArchived: Bool = false,
        createdAt: Date = today,
        reminder: Date? = nil,
        sortIndex: Int,
        metadata: Data? = nil
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.color = color
        self.icon = icon
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.reminder = reminder
        self.sortIndex = sortIndex
        self.metadata = metadata
    }
    
    func entry(for date: Date) -> HabitEntry? {
        let targetDay = Calendar.current.startOfDay(for: date)
        
        return entries.first { entry in Calendar.current.startOfDay(for: entry.date) == targetDay }
    }
    
    func createOrUpdateEntry(for date: Date = today, completed: Bool? = false, time: Duration? = nil, numValue: Double? = nil, ratValue: Int? = nil, note: String? = nil) -> HabitEntry {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        
        if let existingEntry = entries.first(where: {
            entry in calendar.startOfDay(for: entry.date) == targetDay
        }) {
            if let completed = completed { existingEntry.completed = completed }
            if let time = time { existingEntry.time = time }
            if let rating = ratValue { existingEntry.ratValue = rating }
            if let numeric = numValue { existingEntry.numValue = numeric }
            if let note = note { existingEntry.note = note }
            existingEntry.updatedAt = .now
            return existingEntry
        } else {
            let newEntry = HabitEntry(
                date: date,
                completed: completed,
                ratValue: ratValue,
                numValue: numValue,
                note: note,
                updatedAt: .now,
                
                habit: self
                )
            newEntry.time = time
            entries.append(newEntry)
            return newEntry
        }
    }
    
    func currentStreak() -> Int {
        var currentDate = Calendar.current.startOfDay(for: today)
        var streak = 0
        
        while true {
            guard let entry = entry(for: currentDate) else { break }
            
            let isCompleted: Bool
            switch type {
            case .boolean: isCompleted = entry.completed ?? false
            case .duration: isCompleted = (entry.time ?? .zero) > .zero
            case .rating: isCompleted = entry.ratValue != nil
            case .numeric: isCompleted = (entry.numValue ?? 0) > 0
            }
            
            if isCompleted { streak += 1 } else { break }
            
            guard let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) else { break }
            currentDate = previousDate
        }
        return streak
    }
    
    func completionRate(days: Int) -> Double {
        var completedDays: Int = 0
        
        for dayOffset in 0..<days {
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: today) ?? today
            
            if let entry = entry(for: date) {
                switch type {
                case .boolean: if entry.completed == true { completedDays += 1 }
                case .duration: if (entry.durationSeconds ?? 0) > 0 { completedDays += 1 }
                case .rating: if entry.ratValue != nil { completedDays += 1 }
                case .numeric: if (entry.numValue ?? 0) > 0 { completedDays += 1 }
                }
            }
        }
        return Double(completedDays) / Double(days)
    }
    
    func currentGoalStreak(reference: Date = today) -> Int {
        let frequency = type.goal.frequency
        let target = type.goal.target
        guard target > 0 else { return 0 }
        
        var streak = 0
        var index = 0
        
        while true {
            let interval = periodInterval(forIndex: index, frequency: frequency, reference: reference)
            let periodEntries = entries.filter { interval.contains($0.date) }
            let raw = rawValue(for: periodEntries, type: type)
            
            if raw >= target { streak += 1; index += 1 }
            else { break }
        }
        return streak
    }
    
    func goalProgress() -> (rawValue: Double, rate: Double) {
        let frequency = type.goal.frequency
        let target = type.goal.target
        guard target > 0 else { return (1.0, 0.0) }
        
        let interval = periodInterval(forIndex: 0, frequency: frequency, reference: today)
        
        let intervalEntries = entries.filter { entry in
            interval.contains(entry.date)
        }
        
        let raw: Double = rawValue(for: intervalEntries, type: type)
        return (raw, min(1.0, raw / target))
    }
    
    func habitAverage(days: Int) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: today)
        var values: [Double] = []
        
        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today),
                  let entry = entry(for: date) else { continue }
            
            switch type {
            case .boolean: return completionRate(days: days)
            case .duration: if let time = entry.time { values.append(Double(time.components.seconds)) }
            case .rating(min: _, max: _, goal: _): if let rating = entry.ratValue { values.append(Double(rating)) }
            case .numeric(min: _, max: _, unit: _, goal: _): if let numeric = entry.numValue { values.append(numeric) }
            }
        }
        
        return values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
    }
}

private extension Habit {
    func rawValue(for entries: [HabitEntry], type: HabitType) -> Double {
        switch type {
        case .boolean:
            let count = entries.reduce(0) { partial, entry in
                partial + (entry.completed == true ? 1 : 0)
            }
            return Double(count)
            
        case .duration:
            let totalSeconds = entries.reduce(0) { partial, entry in
                partial + Int(entry.durationSeconds ?? 0)
            }
            return Double(totalSeconds)
            
        case .rating:
            let count = entries.reduce(0) { partial, entry in
                partial + (entry.ratValue != nil ? 1 : 0)
            }
            return Double(count)
            
        case .numeric:
            let total = entries.reduce(0.0) { partial, entry in
                partial + (entry.numValue ?? 0)
            }
            return total
        }
    }
    
    func periodInterval(forIndex index: Int, frequency: HabitGoal.Frequency, reference: Date) -> DateInterval {
        let calendar = Calendar.current
        let refStart = startOfPeriod(for: reference, frequency: frequency, calendar: calendar)
        let start = calendar.date(byAdding: dateComponents(for: frequency, value: -index), to: refStart) ?? refStart
        let nextStart = nextPeriodStart(after: start, frequency: frequency, calendar: calendar)
        let end = calendar.date(byAdding: .nanosecond, value: -1, to: nextStart) ?? nextStart
        return DateInterval(start: start, end: end)
    }
    
    func startOfPeriod(for date: Date, frequency: HabitGoal.Frequency, calendar: Calendar) -> Date {
        switch frequency {
        case .daily:
            return calendar.startOfDay(for: date)
        case .weekly:
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            return calendar.date(from: components) ?? calendar.startOfDay(for: date)
        case .monthly:
            let components = calendar.dateComponents([.year, .month], from: date)
            return calendar.date(from: components) ?? calendar.startOfDay(for: date)
        }
    }
    
    func nextPeriodStart(after start: Date, frequency: HabitGoal.Frequency, calendar: Calendar) -> Date {
        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: start) ?? start
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: start) ?? start
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: start) ?? start
        }
    }
    
    func dateComponents(for frequency: HabitGoal.Frequency, value: Int) -> DateComponents {
        switch frequency {
        case .daily: return DateComponents(day: value)
        case .weekly: return DateComponents(weekOfYear: value)
        case .monthly: return DateComponents(month: value)
        }
    }
}
