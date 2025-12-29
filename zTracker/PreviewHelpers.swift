//
//  PreviewHelpers.swift
//  zTracker
//
//  Created by Jia Sahar on 12/22/25.
//

import SwiftUI
import SwiftData

struct PreviewHelpers {
    static let previewContainer: ModelContainer = {
        let schema = Schema([Habit.self, HabitEntry.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: config)
    }()
    
    static func date(stringDate: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let newDate = dateFormatter.date(from: stringDate)!
        return newDate
    }

    static func makeHabits(withEntries: Bool = true) -> [Habit] {
        let habits = [
            Habit(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                title: "Meditated",
                type: .boolean,
                color: RGBValues(r: 0.93, g: 0.38, b: 0.65, a: 1),
                icon: "brain",
                isArchived: true,
                createdAt: date(stringDate: "2025-02-11"),
                reminder: nil
            ),
            Habit(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
                title: "Workout",
                type: .duration,
                color: RGBValues(r: 0, g: 0.70, b: 0, a:1),
                icon: "figure.run",
                isArchived: false,
                createdAt: date(stringDate: "2025-08-20"),
                reminder: nil
            ),
            Habit(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
                title: "Mood",
                type: .rating(min: 1, max: 5),
                color: RGBValues(r: 0.68, g: 0.35, b: 1, a:1),
                icon: "face.smiling",
                isArchived: false,
                createdAt: date(stringDate: "2024-11-06"),
                reminder: nil
            ),
            Habit(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
                title: "Water",
                type: .numeric(min: 0, max: 4, unit: "L"),
                color: RGBValues(r: 0.35, g: 0.66, b: 1, a:1),
                icon: "drop",
                isArchived: false,
                createdAt: date(stringDate: "2025-09-21"),
                reminder: nil
            )
        ]
        
        if withEntries {
            habits.forEach { makeRandomEntries(for: $0) }
        }
        
        return habits
    }
    
    static func makeRandomEntries(for habit: Habit, days: Int = 14) {
        (0..<days).forEach { offset in
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: .now)!


            let entry = HabitEntry(
                id: UUID(),
                date: date,
                completed: habit.type == .boolean ? Bool.random() : nil,
                ratValue: {
                    if case let .rating(min, max) = habit.type {
                        return Int.random(in: min...max) }
                    return nil
                }(),
                numValue: {
                    if case let .numeric(min, max, _) = habit.type {
                        return Double.random(in: min...max)
                    }
                    return nil
                }(),
                note: nil,
                updatedAt: .now
            )
            
            entry.time = .seconds(4500)
            entry.habit = habit
            habit.entries.append(entry)

        }
    }
}

#Preview("Empty State") {
    ContentView()
        .modelContainer(PreviewHelpers.previewContainer)
        .environmentObject(AppState())
}

#Preview("With Sample Data") {
    let container = PreviewHelpers.previewContainer
    
    let habits = PreviewHelpers.makeHabits()
    habits.forEach { container.mainContext.insert($0) }
    
    try? container.mainContext.save()
    
    return ContentView()
        .modelContainer(container)
        .environmentObject(AppState())
}
