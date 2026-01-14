//
//  EntryView.swift
//  zTracker
//
//  Created by Jia Sahar on 12/13/25.
//

import SwiftUI
import SwiftData

struct EntryView: View {
    let habit: Habit
    let entry: HabitEntry
    
    var body: some View {
        VStack(alignment: .trailing) {
            switch habit.type {
            case .boolean(_):
                HStack {
                    Image(systemName: entry.completed == true ? "checkmark.circle" : "circle.dotted")
                    Text(entry.completed == true ? "Completed" : "Incomplete")
                        .font(.subheadline)
                }
                
            case .duration(_):
                if let duration = entry.time {
                    HStack {
                        Image(systemName: "clock")
                        Text(duration.formatted(
                            .units(
                                allowed: [.hours, .minutes, .seconds, .milliseconds],
                                width: .abbreviated,
                                maximumUnitCount: 2
                                  )))
                            .font(.subheadline)
                    }
                }
                
            case .rating(_, let max, _):
                if let rating = entry.ratValue {
                    HStack {
                        ForEach(1...max, id: \.self) { index in
                            Image(systemName: index <= rating ? "star.fill" : "star")
                                .font(.subheadline)
                        }
                    }
                }

                
            case .numeric(_, _, let unit, _):
                if let value = entry.numValue {
                    HStack {
                        Image(systemName: "number")
                        Text(String(format: "%.1f %@", value, unit))
                            .font(.subheadline)
                    }
                }
            }
            
            if let note = entry.note, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}


#Preview("Habit Entries VStack") {
    let container = PreviewHelpers.previewContainer
    
    let habits = PreviewHelpers.makeHabits()
    habits.forEach { container.mainContext.insert($0) }
    
    try? container.mainContext.save()
    
    let firstFourHabits = Array(habits.prefix(4))
    
    return VStack {
        ForEach(firstFourHabits, id: \.id) { habit in
            if let entry = habit.entries.first {
                EntryView(habit: habit, entry: entry)
            }
            Divider()
        }
    }
    .modelContainer(container)
    
}

#Preview("Today View") {
        let container = PreviewHelpers.previewContainer
        
        let habits = PreviewHelpers.makeHabits()
        habits.forEach { container.mainContext.insert($0) }
        
        try? container.mainContext.save()
        
        return TodayView()
            .modelContainer(container)
            
}
