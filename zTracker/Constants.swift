//
//  Constants.swift
//  zTracker
//
//  Created by Jia Sahar on 12/27/25.
//

import Foundation

// MARK: - dates
var today: Date { Calendar.current.startOfDay(for: .now) }

var yesterday: Date {
    Calendar.current.date(byAdding: .day, value: -1, to: today)
        ?? .now.addingTimeInterval(-24 * 60 * 60)
}

var weekAgo: Date {
    Calendar.current.date(byAdding: .weekOfYear, value: -1, to: today)
        ?? .now.addingTimeInterval(-7 * 24 * 60 * 60)
}

var monthAgo: Date {
    Calendar.current.date(byAdding: .month, value: -1, to: today)
        ?? .now.addingTimeInterval(-30 * 24 * 60 * 60)
}

// MARK: - unix epoch

var unixEpoch: Date {
    Date(timeIntervalSince1970: 0)
}
