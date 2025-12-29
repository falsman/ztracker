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
    var color: RGBValues
    var icon: String?
    var isArchived: Bool
    var createdAt: Date
    var reminder: Date?
    var metadata: Data?
    
    @Relationship(deleteRule: .cascade, inverse: \HabitEntry.habit)
    var entries: [HabitEntry] = []
    
    init(
        id: UUID = UUID(),
        title: String,
        type: HabitType,
        color: RGBValues,
        icon: String? = nil,
        isArchived: Bool = false,
        createdAt: Date = today,
        reminder: Date? = nil,
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
        self.metadata = metadata
    }
    
    func entry(for date: Date) -> HabitEntry? {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        
        return entries.first { entry in calendar.startOfDay(for: entry.date) == targetDay }
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
            existingEntry.updatedAt = today
            return existingEntry
        } else {
            let newEntry = HabitEntry(
                date: date,
                completed: completed,
                ratValue: ratValue,
                numValue: numValue,
                note: note,
                
                habit: self
                )
            newEntry.time = time
            entries.append(newEntry)
            return newEntry
        }
    }
    
    func currentStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: today)
        var currentDate = today
        var streak = 0
        
        while true {
            guard let entry = entry(for: currentDate) else { break }
            
            switch type {
            case .boolean: if entry.completed != true { return streak }
            case .duration: if entry.time == nil { return streak }
            case .rating(min:_, max:_): if entry.ratValue == nil { return streak }
            case .numeric(min:_, max:_, unit: _): if entry.numValue == nil { return streak }
            }
            
            streak += 1
            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else {break}
            currentDate = previousDate
        }
        return streak
    }
    
    func completionRate(days: Int = 30) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: today)
        var totalDays = 0
        var completedDays = 0
        
        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {continue}
            totalDays += 1
            
            if let entry = entry(for: date) {
                switch type {
                case .boolean: if entry.completed == true { completedDays += 1 }
                case .duration: if entry.time != nil { completedDays += 1 }
                case .rating(min:_, max:_): if entry.ratValue != nil { completedDays += 1 }
                case .numeric(min:_, max:_, unit: _): if entry.numValue != nil { completedDays += 1 }
                }
            }
        }
        return totalDays > 0 ? Double(completedDays) / Double(totalDays) : 0
    }
}
