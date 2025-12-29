//
//  HabitPerformanceRow.swift
//  zTracker
//
//  Created by Jia Sahar on 12/15/25.
//

import SwiftUI
import SwiftData

struct HabitPerformanceRow: View {
    let habit: Habit
    let days: Int
    
    private var completionRate: Double { habit.completionRate(days: days) }
    private var streak: Int { habit.currentStreak() }
    
    var body: some View {
        HStack {
            if let icon = habit.icon {
                ZStack {
                    Circle()
                        .fill(Color(habit.color.color).opacity(0.3))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                }
            }
            
            VStack(alignment: .leading) {
                Text(habit.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                ProgressView(value: completionRate)
                    .frame(height: 4)
            }
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(Int(completionRate * 100)) %")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    Image(systemName: "flame")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text("\(streak)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .glassEffect(.regular.tint(Color(habit.color.color).opacity(0.3)), in: .rect(cornerRadius: 16))
    }
}

//#Preview("Empty State") {
//    HabitPerformanceRow(habit: Habit, days: 7)
//        .modelContainer(PreviewHelpers.previewContainer)
//        .environmentObject(AppState())
//}

#Preview("With Sample Data") {
    let container = PreviewHelpers.previewContainer
    
    let habits = PreviewHelpers.makeHabits()
    habits.forEach { container.mainContext.insert($0) }
    
    try? container.mainContext.save()
    
    let habitToShow = habits[0]
        
    return HabitPerformanceRow(habit: habitToShow, days: 7)
            .modelContainer(container)
            .environmentObject(AppState())
}
