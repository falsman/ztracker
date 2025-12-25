//
//  StatsOverviewView.swift
//  zTracker
//
//  Created by Jia Sahar on 12/13/25.
//

import SwiftUI
import SwiftData

struct StatsOverviewView: View {
    @Query private var activeHabits: [Habit]
    
    private var completionRate: Double {
        let today = Calendar.current.startOfDay(for: Date())
        var completed = 0
        
        for habit in activeHabits {
            if let entry = habit.entry(for: today) {
                switch habit.type {
                case .boolean: if entry.completed == true { completed += 1 }
                case .hours: if entry.time != nil { completed += 1 }
                case .rating: if entry.rating != nil { completed += 1 }
                case .numeric: if entry.value != nil { completed += 1 }
                }
            }
        }
        
        return activeHabits.isEmpty ? 0 : Double(completed) / Double(activeHabits.count)
    }
    
    var body: some View {
        HStack {
            StatCard(
                title: "Today",
                value: "\(Int(completionRate * 100))%"
                icon: "checkmark.circle",
                color: .green
            )
            
            StatCard(
                title: "Habits",
                value: "\(activeHabits.count)"
                icon: "square.grid.2x2",
                color: .blue
            )
            
            StatCard(
                title: "Streak",
                value: "\(activeHabits.map { $0.currentSteak() }.max() ?? 0)",
                icon: "flame",
                color: .orange
            )
        }
    }
}
