//
//  HabitEntry.swift
//  zTracker
//
//  Created by Jia Sahar on 12/12/25.
//

import SwiftData
import Foundation

@Model
final class HabitEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var completed: Bool?
    var time: Duration?
    var value: Double?
    var rating: Int?
    var note: String?
    var updatedAt: Date
    
    var habit: Habit?
    
    init(
        id: UUID = UUID(),
        habit: Habit? = nil,
        date: Date = Date(),
        completed: Bool? = nil,
        time: Duration? = nil,
        value: Double? = nil,
        rating: Int? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.habit = habit
        self.date = date
        self.completed = completed
        self.time = time
        self.value = value
        self.rating = rating
        self.note = note
        self.updatedAt = Date()
    }
    
    var displayValue: String {
        guard let habit = habit else { return "N/A" }
        
        switch habit.type {
        case .boolean: return completed == true ? "Completed" : "Not Completed"
        case .hours: return time?.formatted(.time(pattern: .hourMinute)) ?? "No Time"
        case .rating(let min, let max): if let rating = rating { return "\(rating)/\(max)" }
            return "No rating"
        case .numeric(let min, let max, let unit): if let value = value { return String(format: "%.2f %@", value, unit) }
            return "No value"
        }
    }
}
