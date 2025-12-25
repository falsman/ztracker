//
//  HabitEntity.swift
//  zTracker
//
//  Created by Jia Sahar on 12/14/25.
//

import AppIntents

struct HabitEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Habit"
    
    let id: UUID
    let title: String
    let habitType: HabitType
    let isNumeric: Bool
    let unit: String?
    let minValue: Double?
    let maxValue: Double?
    
    init(id: UUID, title: String, type: HabitType) {
        self.id = id
        self.title = title
        self.habitType = type
        
        switch type {
        case .numeric(let min, let max, let unit):
            self.isNumeric = true
            self.unit = unit
            self.minValue = min
            self.maxValue = max
        case .rating(let min, let max):
            self.isNumeric = true
            self.unit = nil
            self.minValue = Double(min)
            self.maxValue = Double(max)
        default:
            self.isNumeric = false
            self.unit = nil
            self.minValue = nil
            self.maxValue = nil
        }
    }
    static var defaultQuery = HabitQuery()
    
    var displayRepresentation: DisplayRepresentation {
        var subtitle: LocalizedStringResource?
        var icon: DisplayRepresentation.Image?
        
        switch habitType {
        case .boolean: subtitle = "Checkmark"; icon = .init(systemName: "checkmark")
        case .hours: subtitle = "Hours"; icon = .init(systemName: "clock")
        case .rating(let min, let max): subtitle = "Time"; icon = .init(systemName: "star")
        case .numeric(let min, let max, let unit): subtitle = "\(String(format: "%.0f", max)) \(unit)"; icon = .init(systemName: "number")
        }
        
        return DisplayRepresentation(
            title: LocalizedStringResource(stringLiteral: title),
            subtitle: subtitle,
            image: icon
        )
    }
}
