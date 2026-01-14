//
//  HabitEntity.swift
//  zTracker
//
//  Created by Jia Sahar on 12/28/25.
//

import Foundation
import AppIntents
import SwiftData
import CoreSpotlight

struct HabitEntity: AppEntity, IndexedEntity {
    nonisolated(unsafe) static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Habit")
    nonisolated(unsafe) static var defaultQuery = HabitEntityQuery()
    
    var id: UUID
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(
        title: "\(title)",
        subtitle: "\(typeDescription)",
        image: icon.map { .init(systemName: $0) }
        )
    }
    
    var title: String
    var type: HabitType
    var icon: String?
    var typeDescription: String { type.displayName }
    
    init(id: UUID, title: String, type: HabitType, icon: String? = nil) {
        self.id = id
        self.title = title
        self.type = type
        self.icon = icon
    }
    
    init(from habit: Habit) {
        self.id = habit.id
        self.title = habit.title
        self.type = habit.type
        self.icon = habit.icon
    }
    
    func attributeSet() -> CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(contentType: .content)
        
        attributes.title = title
        attributes.contentDescription = "Track your \(title) habit"
        attributes.keywords = ["habit", "tracker", typeDescription.lowercased()]
        
        return attributes
    }
}

struct HabitEntityQuery: EntityQuery, EntityStringQuery {
    func entities(for identifiers: [UUID]) async throws -> [HabitEntity] {
        let container = try getModelContainer()
        let context = ModelContext(container)
        
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { habit in
                identifiers.contains(habit.id) && !habit.isArchived
            }
        )
        
        let habits = try context.fetch(descriptor)
        return habits.map { HabitEntity(from: $0) }
    }
    
    func entities(matching string: String) async throws -> [HabitEntity] {
        let container = try getModelContainer()
        let context = ModelContext(container)
        
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { habit in
                !habit.isArchived && habit.title.localizedStandardContains(string)
            },
            sortBy: [SortDescriptor(\.title)]
        )
        
        let habits = try context.fetch(descriptor)
        return habits.map { HabitEntity(from: $0) }
    }
    
    func suggestedEntities() async throws -> [HabitEntity] {
        let container = try getModelContainer()
        let context = ModelContext(container)
        
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.title)]
        )
        
        let habits = try context.fetch(descriptor)
        return habits.map { HabitEntity(from: $0) }
    }
}

func getModelContainer() throws -> ModelContainer {
    let storeURL = try DataStoreManager.shared.getStoreURL()
    let schema = Schema([Habit.self, HabitEntry.self])
    let config = ModelConfiguration(url: storeURL)
    
    return try ModelContainer(for: schema, configurations: [config])
}

extension HabitEntity {
    static func indexAllHabits() {
        do {
            let container = try getModelContainer()
            let context = ModelContext(container)

            let allHabits = try context.fetch(FetchDescriptor<Habit>())

            let activeHabits = allHabits.filter { !$0.isArchived }

            let items = activeHabits.map { habit -> CSSearchableItem in
                let entity = HabitEntity(from: habit)
                return CSSearchableItem(
                    uniqueIdentifier: habit.id.uuidString,
                    domainIdentifier: "com.ztracker.habit",
                    attributeSet: entity.attributeSet()
                )
            }

            let allIDs = Set(allHabits.map { $0.id.uuidString })
            let activeIDs = Set(activeHabits.map { $0.id.uuidString })
            let removedIDs = Array(allIDs.subtracting(activeIDs))

            let index = CSSearchableIndex.default()
            index.indexSearchableItems(items)
            index.deleteSearchableItems(withIdentifiers: removedIDs)

        } catch {
            print("Failed to sync habits with Spotlight: \(error)")
        }
    }
}


//struct OpenHabitIntent: AppIntent, OpenIntent {
//    static var title: LocalizedStringResource = "Open Habit"
//    
//    @Parameter(title: "Habit")
//    var target: HabitEntity
//    
//    @MainActor
//    func perform() async throws -> some IntentResult {
//        // code
//        return .result()
//    }
//}
