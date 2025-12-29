//
//  StatsOverviewView.swift
//  zTracker
//
//  Created by Jia Sahar on 12/13/25.
//

import SwiftUI
import SwiftData

struct StatsOverviewView: View {
    @Query(filter: #Predicate<Habit> { !$0.isArchived })
    private var activeHabits: [Habit]
    
    // TODO: reuse function from before
    private var completionRate: Double {
        let today = Calendar.current.startOfDay(for: today)
        var completed = 0
        
        for habit in activeHabits {
            if let entry = habit.entry(for: today) {
                switch habit.type {
                case .boolean: if entry.completed == true { completed += 1 }
                case .duration: if entry.time != nil { completed += 1 }
                case .rating: if entry.ratValue != nil { completed += 1 }
                case .numeric: if entry.numValue != nil { completed += 1 }
                }
            }
        }
        
        return activeHabits.isEmpty ? 0 : Double(completed) / Double(activeHabits.count)
    }
    
    var body: some View {
        HStack {
            StatCard(
                title: "Today",
                value: "\(Int(completionRate * 100))%",
                icon: "checkmark.circle",
                color: .green
            )
            
            StatCard(
                title: "Habits",
                value: "\(activeHabits.count)",
                icon: "square.grid.2x2",
                color: .blue
            )
            
            StatCard(
                title: "Streak",
                value: "\(activeHabits.map { $0.currentStreak() }.max() ?? 0)",
                icon: "flame",
                color: .orange
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: icon)
                   // .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(maxWidth: .infinity)
        
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color, lineWidth: 0.5)
        )
        .glassEffect(.regular.tint(color.opacity(0.05)), in: .rect(cornerRadius: 16))
        
    }
}

#Preview {
    let container = PreviewHelpers.previewContainer
    let habits = PreviewHelpers.makeHabits()
    
    habits.forEach { container.mainContext.insert($0) }
    
    return StatsOverviewView()
        .modelContainer(container)
        .padding()
}

#Preview("Stat Card") {
    StatCard(
        title: "Today",
        value: "75%",
        icon: "checkmark.circle",
        color: .green
    )
    .padding()
}
