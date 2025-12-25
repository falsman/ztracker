//
//  HabitIntentLogic.swift
//  zTracker
//
//  Created by Jia Sahar on 12/14/25.
//

import SwiftData
import Foundation
import AppIntents

protocol HabitIntentLogic {
    var storage: StorageManager { get }
}

extension HabitIntentLogic {
    var storage: StorageManager { .shared }

    func fetchHabit(_ entity: HabitEntity) async throws -> Habit {
        guard let habit = await storage.fetchHabit(by: entity.id) else {
            throw NSError(domain: "zTracker", code: 404, userInfo: [NSLocalizedDescriptionKey: "Habit not found"])
        }
        
        return habit
    }

    func formatted(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.2f", value)
    }
    
    func donateAfterSuccess(_ intent: any AppIntent) {
        HabitDonation.donate(intent: intent)
    }
}
