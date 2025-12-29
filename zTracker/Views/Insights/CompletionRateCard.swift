//
//  CompletionRateCard.swift
//  zTracker
//
//  Created by Jia Sahar on 12/14/25.
//

import SwiftUI
import SwiftData
import Foundation

struct CompletionRateCard: View {
    @Query private var habits: [Habit]
    
    private var weeklyCompletion: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: today)
        var totalCompletions = 0
        var totalPossible = 0
        
        for dayOffSet in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffSet, to: today) else { continue }
            
            for habit in habits where !habit.isArchived {
                totalPossible += 1
                if let entry = habit.entry(for: date) {
                    switch habit.type {
                    case .boolean: if entry.completed == true { totalCompletions += 1 }
                    case .duration: if entry.time != nil { totalCompletions += 1 }
                    case .rating: if entry.ratValue != nil { totalCompletions += 1 }
                    case .numeric: if entry.numValue != nil { totalCompletions += 1 }
                    }
                }
            }
        }
        
        return totalPossible > 0 ? Double(totalCompletions) / Double(totalPossible) : 0
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Weekly Completion")
                .font(.headline)
                .padding()
            
            HStack {
                VStack {
                    Text("\(Int(weeklyCompletion * 100))%")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    Text("of habits completed this week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                Spacer()
                
                CircularProgressView(progress: weeklyCompletion)
                    .frame(width: 80, height: 80)
            }
        }
        .glassEffect(in: .rect(cornerRadius: 16)) //.regular.tint(Color(habits.color)),
    }
}

#Preview {
    let container = PreviewHelpers.previewContainer
    let habits = PreviewHelpers.makeHabits()
    
    habits.forEach { container.mainContext.insert($0) }
    
    return CompletionRateCard()
        .modelContainer(container)
        .padding()
}
