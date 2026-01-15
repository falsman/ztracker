//
//  Constants.swift
//  zTracker
//
//  Created by Jia Sahar on 12/27/25.
//

import Foundation

var today: Date { Calendar.current.startOfDay(for: Date()) }

var yesterday: Date {
    Calendar.current.date(byAdding: .day, value: -1, to: today)
        ?? Date().addingTimeInterval(-24 * 60 * 60)
}

var weekAgo: Date {
    Calendar.current.date(byAdding: .weekOfYear, value: -1, to: today)
        ?? Date().addingTimeInterval(-7 * 24 * 60 * 60)
}

var monthAgo: Date {
    Calendar.current.date(byAdding: .month, value: -1, to: today)
        ?? Date().addingTimeInterval(-30 * 24 * 60 * 60)
}
