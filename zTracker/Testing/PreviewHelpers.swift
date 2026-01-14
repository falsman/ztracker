//
//  PreviewHelpers.swift
//  zTracker
//
//  Created by Jia Sahar on 12/22/25.
//

import SwiftUI
import SwiftData

#if DEBUG
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

    static func makeHabits(withEntries: Bool = true, days: Int = 7) -> [Habit] {
        if withEntries { sampleHabits.forEach { makeRandomEntries(for: $0, days: days) } }
        return sampleHabits
    }
    
    static func makeRandomEntries(for habit: Habit, days: Int = 7) {
        (0..<days).forEach { offset in
            let startOfDate = Calendar.current.date(byAdding: .day, value: -offset, to: today) ?? today

            let entry = HabitEntry(
                id: UUID(),
                date: startOfDate,
                completed: {
                    if case .boolean(_) = habit.type { return Bool.random() }
                    return nil
                }(),
                durationSeconds:{
                    if case .duration(_) = habit.type { return Int64.random(in: 0...(8 * 60 * 60)) }
                    return nil
                }(),
                ratValue: {
                    if case let .rating(min, max, _) = habit.type { return Int.random(in: min...max) }
                    return nil
                }(),
                numValue: {
                    if case let .numeric(min, max, _, _) = habit.type { return Double.random(in: min...max) }
                    return nil
                }(),
                note: {
                    let dice = Int.random(in: 0...5)
                    switch dice {
                    case 1: return "random note"
                    case 2: return "a longer random note to test"
                    case 3: return "testing multiline notes to check \n layout and how it looks"
                    case 4: return "melatonin"
                    case 5: return "talk to [felix]"
                    default: return nil
                    }
                }(),
                updatedAt: {
                    let randomTime: TimeInterval = .random(in: 0..<(24 * 60 * 60))
                    return Calendar.current.date(byAdding: .second, value: Int(randomTime), to: startOfDate) ?? .now
                }()
            )
            
            entry.habit = habit
            habit.entries.append(entry)

        }
    }
    
    nonisolated(unsafe) static var sampleHabits: [Habit] = [
        Habit(
            id: UUID(uuidString: "A7F4E6F1-0F5C-4A6B-9F1E-2B6E4E0A9C01")!,
            title: "Sleep Duration",
            type: .duration(goal: .init(target: (8 * 60 * 60), frequency: .daily)),
            color: "indigo",
            icon: "bed.double",
            sortIndex: 1
            ),
        Habit(
            id: UUID(uuidString: "D2C9E8A4-3C5E-4E77-9F2A-8F6D1C7A0B11")!,
            title: "Mindful Minutes",
            type: .duration(goal: .init(target: 60, frequency: .daily)),
            color: "mint",
            icon: "apple.meditate",
            sortIndex: 2
            ),
        Habit(
            id: UUID(),
            title: "Meals",
            type: .boolean(goal: .init(target: 1, frequency: .daily)),
            color: "green",
            icon: "fork.knife",
            isArchived: false,
            createdAt: date(stringDate: "2025-02-11"),
            reminder: nil,
            sortIndex: 3
        ),
        Habit(
            id: UUID(),
            title: "Workout",
            type: .duration(goal: .init(target: 1000, frequency: .weekly)),
            color: "orange",
            icon: "figure.run",
            isArchived: false,
            createdAt: date(stringDate: "2025-08-20"),
            reminder: nil,
            sortIndex: 5
        ),
        Habit(
            id: UUID(),
            title: "Mood",
            type: .rating(min: 1, max: 5, goal: .init(target: 4, frequency: .weekly)),
            color: "pink",
            icon: "face.smiling",
            isArchived: false,
            createdAt: date(stringDate: "2024-11-06"),
            reminder: nil,
            sortIndex: 9
        ),
        Habit(
            id: UUID(),
            title: "Water",
            type: .numeric(min: 0, max: 20, unit: "cups", goal: .init(target: 30, frequency: .monthly)),
            color: "blue",
            icon: "drop",
            isArchived: false,
            createdAt: date(stringDate: "2025-09-21"),
            reminder: nil,
            sortIndex: 6
        ),
        Habit(
            id: UUID(),
            title: "Cut Hair",
            type: .boolean(goal: .init(target: 4, frequency: .monthly)),
            color: "teal",
            icon: "scissors",
            isArchived: false,
            createdAt: date(stringDate: "2024-01-12"),
            reminder: nil,
            sortIndex: 10
        ),
        Habit(
            id: UUID(),
            title: "Sleep Quality",
            type: .rating(min: 1, max: 5, goal: .init(target: 1, frequency: .daily)),
            color: "orange",
            icon: "figure.dance",
            isArchived: true,
            createdAt: date(stringDate: "2025-08-20"),
            reminder: nil,
            sortIndex: 11
        ),
        Habit(
            id: UUID(),
            title: "Meditated",
            type: .boolean(goal: .init(target: 5, frequency: .weekly)),
            color: "mint",
            icon: "brain",
            isArchived: true,
            createdAt: date(stringDate: "2025-02-11"),
            reminder: nil,
            sortIndex: 7
        ),
        Habit(
            id: UUID(),
            title: "Dance",
            type: .duration(goal: .init(target: 100, frequency: .monthly)),
            color: "orange",
            icon: "figure.dance",
            isArchived: true,
            createdAt: date(stringDate: "2025-08-20"),
            reminder: nil,
            sortIndex: 8
        )
    ]
}

#Preview("Empty State") {
    ContentView()
        .modelContainer(PreviewHelpers.previewContainer)
        
}

#Preview("With Sample Data") {
    let container = PreviewHelpers.previewContainer
    
    let habits = PreviewHelpers.makeHabits()
    habits.forEach { container.mainContext.insert($0) }
    
    try? container.mainContext.save()
    
    return ContentView()
        .modelContainer(container)
        
}
#endif
