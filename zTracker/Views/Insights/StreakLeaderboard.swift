//
//  StreakLeaderboard.swift
//  zTracker
//
//  Created by Jia Sahar on 12/14/25.
//

import SwiftUI
import SwiftData

struct StreakLeaderboard: View {
    var activeHabits: [Habit]
    
    var topHabits: [Habit] {
        activeHabits.sorted { $0.currentGoalStreak() > $1.currentGoalStreak() }.prefix(5).map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Top Streaks")
                .font(.headline)
                .padding()
            
            if topHabits.isEmpty {
                Text("No habits to display")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(topHabits) { habit in
                    HStack {
                        if let icon = habit.icon {
                            Image(systemName: icon)
                                .foregroundStyle(habit.swiftUIColor)
                        }
                        
                        Text(habit.title)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        HStack {
                            Image(systemName: "flame")
                                .foregroundStyle(.orange)
                            Text("\(habit.currentGoalStreak()) \(habit.type.goal.frequency.rawValue.lowercased())s")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding()
                }
            }
        }
        .glassEffect(in: .rect(cornerRadius: 16))
    }
}

//#Preview("Empty State") {
//    StreakLeaderboard()
//        .modelContainer(PreviewHelpers.previewContainer)
//        
//}
//
//#Preview("Streak Leaderboard") {
//    let container = PreviewHelpers.previewContainer
//    
//    let habits = PreviewHelpers.makeHabits()
//    habits.forEach { container.mainContext.insert($0) }
//    
//    try? container.mainContext.save()
//    
//    return StreakLeaderboard()
//        .modelContainer(container)
//        
//}
