//
//  HabitType.swift
//  zTracker
//
//  Created by Jia Sahar on 12/12/25.
//


enum HabitType: Codable {
    case boolean
    case hours
    case rating(min: Int, max: Int)
    case numeric(min: Double, max: Double, unit: String)
    
    var displayName: String {
        switch self {
        case .boolean: return "Checkmark"
        case .hours: return "Time"
        case .rating: return "Rating"
        case .numeric: return "Number"
        }
    }
}

extension HabitType: @unchecked Sendable {}
