//
//  HabitQuery.swift
//  zTracker
//
//  Created by Jia Sahar on 12/14/25.
//

import AppIntents
import SwiftData

struct HabitQuery: EntityQuery {
    
    @Parameter(title: "Habit Type Filter")
    var typeFilter: HabitTypeFilter?
    
    enum HabitTypeFilter: String, AppEnum {
        case all
        case boolean
        case hours
        case rating
        case numeric
        
        static var typeDisplayRepresentation: TypeDisplayRepresentation = "Habit Type"
        
        static var caseDisplayRepresentations: [HabitTypeFilter: DisplayRepresentation] =  [
            .all: "All Habits",
            .boolean: "Checkmark Habits",
            .hours: "Time/Duration Habits",
            .rating: "Rating Habits",
            .numeric: "Numeric Habits"
        ]
    }
    
    init(typeFilter: HabitTypeFilter? = nil) { self.typeFilter = typeFilter }
    
    @MainActor
    func entities(for identifiers: [UUID]) async throws ->  [HabitEntity] {
        let storage = StorageManager.shared
        var entities: [HabitEntity] = []
        
        for id in identifiers {
            if let habit = await storage.fetchHabit(by: id) {
                let entity = HabitEntity(id: habit.id, title: habit.title, type: habit.type)
                if let filter = typeFilter, !matchesFilter(entity: entity, filter: filter) { continue }
                entities.append(entity)
            }
        }
        return entities
    }
    
    @MainActor
    func suggestedEntities() async throws -> [HabitEntity] {
        let storage = StorageManager.shared
        let habits = await storage.fetchAllHabits()
        
        return habits.compactMap { habit in
        let entity = HabitEntity(id: habit.id, title: habit.title, type: habit.type)
        if let filter = typeFilter, !matchesFilter(entity: entity, filter: filter) { return nil }
        
        return entity

        }
    }
    
    private func matchesFilter(entity: HabitEntity, filter: HabitTypeFilter) -> Bool {
        switch filter {
            case .all: return true
            case .boolean: if case .boolean = entity.habitType { return true }
            case .hours: if case .hours = entity.habitType { return true }
            case .rating: if case .rating = entity.habitType { return true }
            case .numeric: return entity.isNumeric
            }
            return false
    }
}
