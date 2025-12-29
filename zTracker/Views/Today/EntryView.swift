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
        VStack(alignment: .leading) {
            switch habit.type {
            case .boolean:
                HStack {
                    Image(systemName: entry.completed == true ? "checkmark.circle.dotted" : "circle.dotted")
                        .foregroundStyle(entry.completed == true ? .green: .secondary)
                    Text(entry.completed == true ? "Completed" : "Not Completed")
                        .font(.subheadline)
                }
            case .duration:
                if let duration = entry.time {
                    HStack {
                        Image(systemName: "clock")
                        Text(duration.formatted(.time(pattern: .hourMinute)))
                            .font(.subheadline)
                    }
                }
                
            case .rating(_, let max):
                if let rating = entry.ratValue {
                    HStack {
                        ForEach(1...max, id: \.self) { index in
                            Image(systemName: index <= rating ? "star.fill" : "star")
                                .font(.caption)
                        }
                    }
                }
                
            case .numeric(_, _, let unit):
                if let value = entry.numValue {
                    HStack {
                        Image(systemName: "number")
                            .foregroundStyle(.purple)
                        Text(String(format: "%.2f %@", value, unit))
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
    }
}


#Preview("With Sample Data") {
    let container = PreviewHelpers.previewContainer
    
    let habits = PreviewHelpers.makeHabits()
    habits.forEach { container.mainContext.insert($0) }
    
    try? container.mainContext.save()
    
    let habitToShow = habits[1]
    let entryToShow = habitToShow.entries.first!
    
    return EntryView(habit: habitToShow, entry: entryToShow)
        .modelContainer(container)
        .environmentObject(AppState())
}
