//
//  CompletionRateChart.swift
//  zTracker
//
//  Created by Jia Sahar on 12/15/25.
//

import SwiftUI
import Charts
import SwiftData

struct CompletionRateChart: View {
    let habits: [Habit]
    let days: Int
    let color: Color
    
    private var dailyCompletion: [(date: Date, rate: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: today)
        
        return (0..<days).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            
            var completedHabits = 0
            var totalActiveHabits = 0
            
            for habit in habits where !habit.isArchived {
                totalActiveHabits += 1
                if let entry = habit.entry(for: date) {
                    switch habit.type {
                    case .boolean: if entry.completed == true { completedHabits += 1 }
                    case .duration: if entry.time != nil { completedHabits += 1 }
                    case .rating: if entry.ratValue != nil { completedHabits += 1 }
                    case .numeric: if entry.numValue != nil { completedHabits += 1 }
                    }
                }
            }
            
            let rate = totalActiveHabits > 0 ? Double(completedHabits) / Double(totalActiveHabits) : 0
            return (date: date, rate: rate)
        }.reversed()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Completion Rate")
                .font(.headline)
            
            Chart {
                ForEach(dailyCompletion.indices, id: \.self) { index in
                    let data = dailyCompletion[index]
                    
                    LineMark(
                        x: .value("Date", data.date, unit: .day),
                        y: .value("Rate", data.rate)
                        )
                    .foregroundStyle(color)
                    
                    AreaMark(
                        x: .value("Date", data.date, unit: .day),
                        y: .value("Rate", data.rate)
                        )
                    .foregroundStyle(color)
                    .opacity(0.3)
                }
            }
            .chartYScale(domain: [0, 1])
            .chartYAxis {
                AxisMarks(
                    format: Decimal.FormatStyle.Percent.percent,
                    values: [0, 25, 50, 75, 100]
                )
            }
            .chartXAxis {
                AxisMarks(
                    values: .stride(
                        by: days > 60 ? .month : .day,
                        count:
                            days > 60 ? 1 :
                            days > 30 ? 7 :
                            days >= 8 ? 7 :
                            1
                    )
                ) { value in
                    AxisGridLine()
                    AxisTick()

                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(
                                date,
                                format: days > 60
                                    ? .dateTime.month(.abbreviated)
                                    : .dateTime.day().month()
                            )
                            .font(.caption2)
                        }
                    }
                }
            }
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: 16))
    }
}

#Preview("Completion Rate Chart") {
    let container = PreviewHelpers.previewContainer
    let habits = PreviewHelpers.makeHabits()
    
    habits.forEach { container.mainContext.insert($0) }
    
    return CompletionRateChart(habits: habits, days: 80, color: .teal)
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
