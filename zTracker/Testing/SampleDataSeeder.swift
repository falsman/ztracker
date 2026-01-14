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

    /// Seeds sample habit data into the provided model context if sample data has not been seeded yet.
    /// 
    /// Generates sample habits (spanning 500 days), inserts them into `context`, and attempts to save the context.
    /// On successful save, marks the "didSeedSampleData" flag in `UserDefaults` to prevent reseeding; on failure, logs the error to the console.
    /// - Parameter context: The `ModelContext` to insert sample habit objects into.
    static func seedIfNeeded(context: ModelContext) {
        let alreadySeeded = UserDefaults.standard.bool(forKey: "didSeedSampleData")
        guard !alreadySeeded else { return }

        let habits = PreviewHelpers.makeHabits(days: 500)
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