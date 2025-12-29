//
//  StreakCard.swift
//  zTracker
//
//  Created by Jia Sahar on 12/15/25.
//

import SwiftUI

struct StreakCard: View {
    let habit: Habit
    
    var body: some View {
        VStack {
            if let icon = habit.icon {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color(habit.color.color))
            }
            
            Text(habit.title)
                .font(.caption)
                .lineLimit(1)
                .multilineTextAlignment(.center)
            Text("\(habit.currentStreak())")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.orange)
            Text("days")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .glassEffect(.regular.tint(Color(habit.color.color)).interactive(), in: .rect(cornerRadius: 16))
    }
}
