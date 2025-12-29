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
    var durationSeconds: Int64? = nil
    var ratValue: Int?
    var numValue: Double?
    var note: String?
    var updatedAt: Date
    
    var habit: Habit?
    

    init(
        id: UUID = UUID(),
        date: Date = today,
        completed: Bool? = nil,
        durationSeconds: Int64? = nil,
        ratValue: Int? = nil,
        numValue: Double? = nil,
        note: String? = nil,
        updatedAt: Date = today,
        
        habit: Habit? = nil
    ) {
        self.id = id
        self.date = date
        self.completed = completed
        self .durationSeconds = durationSeconds
        self.ratValue = ratValue
        self.numValue = numValue
        self.note = note
        self.updatedAt = updatedAt
        
        self.habit = habit
    }
    
    
    var displayValue: String {
        guard let habit = habit else { return "N/A" }
        
        switch habit.type {
        case .boolean: return completed == true ? "Completed" : "Not Completed"
        case .duration: return time?.formatted(.time(pattern: .hourMinute)) ?? "No Time"
        case .rating(_, let max): if let ratValue = ratValue { return "\(ratValue)/\(max)" }
            return "No ratValue"
        case .numeric(_, _, let unit): if let numValue = numValue { return String(format: "%.2f %@", numValue, unit) }
            return "No numValue"
        }
    }
}

extension HabitEntry {
    var time: Duration? {
        get { durationSeconds.map { .seconds(Double($0)) } }
        set { durationSeconds = newValue.map { Int64($0.components.seconds) } }
    }
}


//struct DateDuration: Codable, Hashable {
//    var startTime: Date
//    var endTime: Date
//    
//}
//
//extension DateDuration {
//    var dateDuration: Duration {
//        .seconds(endTime.timeIntervalSince(startTime))
//    }
//}
