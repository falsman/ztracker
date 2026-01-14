//
//  habitAveragePlayground.swift
//  zTracker
//
//  Created by Jia Sahar on 1/11/26.
//

//import Foundation
//import Playgrounds
//
//
//#Playground {
//    let type = HabitType.boolean
//
//    func daysAgo(_ days: Int) -> Date {
//        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -days, to: today) ?? today)
//        }
//    let entries = [
//            HabitEntry(date: daysAgo(0), completed: true),
//            HabitEntry(date: daysAgo(1), completed: true),
//            HabitEntry(date: daysAgo(2), completed: false),
//            HabitEntry(date: daysAgo(3), completed: true),
//            HabitEntry(date: daysAgo(4), completed: false),
//            HabitEntry(date: daysAgo(5), completed: true),
//            HabitEntry(date: daysAgo(6), completed: false),
//            HabitEntry(date: daysAgo(7), completed: false)
//    ]
//    
//    func entry(for date: Date) -> HabitEntry? {
//        let targetDay = Calendar.current.startOfDay(for: date)
//        
//        return entries.first { entry in Calendar.current.startOfDay(for: entry.date) == targetDay }
//    }
//    
//    let sameDayEntries = entries.filter {
//        Calendar.current.isDate($0.date, inSameDayAs: today)
//    }
//    print("count:", sameDayEntries.count)
//
//
//    func completionRate(days: Int) -> Double {
//        var completedDays: Int = 0
//        
//        for dayOffset in 0..<days {
//            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: today) ?? today
//            
//            if let entry = entry(for: date) {
//                switch type {
//                case .boolean: if entry.completed == true { completedDays += 1 }
//                case .duration: if (entry.durationSeconds ?? 0) > 0 { completedDays += 1 }
//                case .rating: if entry.ratValue != nil { completedDays += 1 }
//                case .numeric: if (entry.numValue ?? 0) > 0 { completedDays += 1 }
//                }
//            }
//        }
//        print(completedDays)
//        print(days)
//        return Double(completedDays) / Double(days)
//    }
//
//    let lastWeekRate = completionRate(days: 7)
////    let lastMonthRate = completionRate(days: 30)
//    
//    print("7 Day Rate: \(lastWeekRate)")
//}
