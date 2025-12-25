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
            case .hours:
                if let time = entry.time {
                    HStack {
                        Image(systemName: "clock")
                        Text(time.formatted(.time(pattern: .hourMinute)))
                            .font(.subheadline)
                    }
                }
                
            case .rating(let min, let max):
                if let rating = entry.rating {
                    HStack {
                        ForEach(1...max, id: \.self) { index in
                            Image(systemName: index <= rating ? "star.fill" : "star")
                                .foregroundStyle(index <= rating ? .yellow : .secondary)
                                .font(.caption)
                        }
                        Text("\(rating)/\(max)")
                            .font(.caption)
                            .padding(.leading)
                    }
                }
                
            case .numeric(let min, let max, let unit):
                if let value = entry.value {
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
