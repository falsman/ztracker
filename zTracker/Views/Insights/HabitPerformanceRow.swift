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
    
    private var habitGoalProgress: Double { habit.goalProgress().rate }
    
    var body: some View {
        HStack {
            if let icon = habit.icon {
                ZStack {
                    Circle()
                        .trim(from: 0, to: habitGoalProgress)
                        .fill(Color(habit.swiftUIColor).tertiary)
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                }
            }
            
            VStack(alignment: .leading) {
                Text(habit.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                ProgressView(value: habitGoalProgress)
                    .frame(height: 4)
            }
            Spacer()
            
            let averageInfo = HabitAverage(habit: habit, days: days)
            VStack(alignment: .trailing) {
                Text(averageInfo.value)
                Text(averageInfo.caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .containerRelativeFrame(.horizontal, count: 5, span: 1, spacing: 0, alignment: .trailing)

        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: 16)) // .regular.tint(Color(habit.swiftUIColor).opacity(0.3)),
    }
}



struct HabitAverage {
    let value: String
    let caption: String

    init(habit: Habit, days: Int) {
        
        let completedEntryCount = habit.completionRate(days: days) * Double(days)
        
        switch habit.type {
        case .boolean:
            value = completedEntryCount.formatted()
            caption = "days"
            
        case .rating(min: _, let max, _):
            value = habit.habitAverage(days: days).formatted(.number.precision(.fractionLength(2)))
            caption = "avg. / \(max)"
            
        case .duration:
            let duration = Duration.seconds(habit.habitAverage(days: days))
            value = duration.formatted(
                .units(
                    allowed: [.hours, .minutes, .seconds],
                    width: .narrow,
                    maximumUnitCount: 2
                )
            )
            caption = "avg."
            
        case .numeric(min: _, max: _, let unit, _):
            value = habit.habitAverage(days: days).formatted(.number.precision(.fractionLength(2)))
            caption = "avg. \(unit)"
        }
    }
}

#Preview("Habit Performance Row") {
    let container = PreviewHelpers.previewContainer
    
    let habits = PreviewHelpers.makeHabits()
    habits.forEach { container.mainContext.insert($0) }
    
    try? container.mainContext.save()
    
    return VStack {
        ForEach(habits, id: \.id) { habit in
            HabitPerformanceRow(habit: habit, days: 7)
            Divider()
        }
    }
    .modelContainer(container)
            
}

#Preview("Insights View") {
    NavigationStack {
        let container = PreviewHelpers.previewContainer
        
        let habits = PreviewHelpers.makeHabits()
        habits.forEach { container.mainContext.insert($0) }
        
        try? container.mainContext.save()
        
        return InsightsView()
            .modelContainer(container)
            
    }
}
