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
        do {
            let container = try ModelContainer(for: schema, configurations: config)
            return container
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
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
            
            let entryFillDice = Int.random(in: 0...6)
            var entryFill = true

            switch entryFillDice {
            case 1, 2, 3, 4, 5: entryFill = true
            default: entryFill = false
            }

            let entry = HabitEntry(
                id: UUID(),
                date: startOfDate,
                completed: {
                    let boolDice = Int.random(in: 0...4)
                    switch boolDice {
                    case 1, 2, 3, 4: return true
                    default: return false
                    }
                }(),
                durationSeconds:{
                    if case .duration(_) = habit.type { if entryFill { return Int64.random(in: 0...(8 * 60 * 60)) } else { return nil } }
                    return nil
                }(),
                ratValue: {
                    if case let .rating(min, max, _) = habit.type { if entryFill { return Int.random(in: min...max) } else { return nil } }
                    return nil
                }(),
                numValue: {
                    if case let .numeric(min, max, _, _) = habit.type { if entryFill { return Double.random(in: min...max) } else { return nil } }
                    return nil
                }(),
                note: {
                    var noteDice: Int
                    if entryFill { noteDice = Int.random(in: 0...5) } else { noteDice = 6 }
                    switch noteDice {
                    case 1: return "random note"
                    case 2: return "a longer random note to test"
                    case 3: return "testing multiline notes to check layout and how it looks"
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
            title: "Breakfast",
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
            type: .duration(goal: .init(target: (7 * 0.5 * 60 * 60), frequency: .weekly)),
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
            type: .numeric(min: 0, max: 20, unit: "cups", goal: .init(target: 8, frequency: .daily)),
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
            type: .duration(goal: .init(target: (8 * 60 * 60), frequency: .monthly)),
            color: "orange",
            icon: "figure.dance",
            isArchived: true,
            createdAt: date(stringDate: "2025-08-20"),
            reminder: nil,
            sortIndex: 8
        )
    ]
}

enum SampleDataSeeder {

    static func seedIfNeeded(context: ModelContext) {
        let alreadySeeded = UserDefaults.standard.bool(forKey: "didSeedSampleData")
        guard !alreadySeeded else { return }

        let habits = PreviewHelpers.makeHabits(days: 200)
        habits.forEach { context.insert($0) }

        do {
            try context.save()
            UserDefaults.standard.set(true, forKey: "didSeedSampleData")
        } catch {
            print("Sample data seeding failed:", error)
        }
    }
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
