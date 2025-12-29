//
//  StreakLeaderboard.swift
//  zTracker
//
//  Created by Jia Sahar on 12/14/25.
//

import SwiftUI
import SwiftData

struct StreakLeaderboard: View {
    @Query(filter: #Predicate<Habit> { !$0.isArchived }) private var habits: [Habit]
    
    var topHabits: [Habit] {
        habits.sorted { $0.currentStreak() > $1.currentStreak() }.prefix(5).map { $0 }
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
                                .foregroundStyle(Color(habit.color.color))
                        }
                        
                        Text(habit.title)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        HStack {
                            Image(systemName: "flame")
                                .foregroundStyle(.orange)
                            Text("\(habit.currentStreak()) days")
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

#Preview("Empty State") {
    StreakLeaderboard()
        .modelContainer(PreviewHelpers.previewContainer)
        .environmentObject(AppState())
}

#Preview("With Sample Data") {
    NavigationStack {
        let container = PreviewHelpers.previewContainer
        
        let habits = PreviewHelpers.makeHabits()
        habits.forEach { container.mainContext.insert($0) }
        
        try? container.mainContext.save()
        
        return StreakLeaderboard()
            .modelContainer(container)
            .environmentObject(AppState())
    }
}
