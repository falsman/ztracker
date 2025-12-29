//
//  HabitType.swift
//  zTracker
//
//  Created by Jia Sahar on 12/12/25.
//


enum HabitType: Codable, Hashable {
    case boolean
    case duration
    case rating(min: Int, max: Int)
    case numeric(min: Double, max: Double, unit: String)
    
    var displayName: String {
        switch self {
        case .boolean: return "Checkmark"
        case .duration: return "Time"
        case .rating: return "Rating"
        case .numeric: return "Number"
        }
    }
}

extension HabitType: @unchecked Sendable {}
