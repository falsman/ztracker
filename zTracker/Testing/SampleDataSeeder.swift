//
//  SampleDataSeeder.swift
//  zTracker
//
//  Created by Jia Sahar on 1/12/26.
//

import SwiftData
import Foundation

#if DEBUG
enum SampleDataSeeder {

    static func seedIfNeeded(context: ModelContext) {
        let alreadySeeded = UserDefaults.standard.bool(forKey: "didSeedSampleData")
        guard !alreadySeeded else { return }

        let habits = PreviewHelpers.makeHabits(days: 100)
        habits.forEach { context.insert($0) }

        do {
            try context.save()
            UserDefaults.standard.set(true, forKey: "didSeedSampleData")
        } catch {
            print("Sample data seeding failed:", error)
        }
    }
}
#endif
