//
//  HabitType.swift
//  zTracker
//
//  Created by Jia Sahar on 12/12/25.
//

struct HabitGoal: Codable, Hashable {
    enum Frequency: String, Codable, CaseIterable {
        case daily, weekly, monthly
    }
    
    var target: Double = 1
    var frequency: Frequency = .daily
    var state: Bool = false
}

enum HabitType: Codable, Hashable {
    case boolean(goal: HabitGoal)
    case duration(goal: HabitGoal)
    case rating(min: Int, max: Int, goal: HabitGoal)
    case numeric(min: Double, max: Double, unit: String, goal: HabitGoal)
    
    var displayName: String {
        switch self {
        case .boolean: return "Checkmark"
        case .duration: return "Time"
        case .rating: return "Rating"
        case .numeric: return "Number"
        }
    }
    
    var goal: HabitGoal {
        switch self {
        case .boolean(let goal), .duration(let goal), .rating(_, _, let goal), .numeric(_, _, _, let goal):
            return goal
        }
    }
}

extension HabitType: @unchecked Sendable {}
