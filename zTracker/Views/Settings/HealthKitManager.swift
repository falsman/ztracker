//
//  HealthKitManager.swift
//  zTracker
//
//  Created by Jia Sahar on 12/21/25.
//

#if os(iOS)
import HealthKit
import SwiftUI
import SwiftData

actor HealthKitManager {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    private var healthKitEnabled = false
    
    private init() {}
    
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("Health Data Not Avaialable")
            return
        }
        
        let readTypes: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!
            ]
        
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
        
        healthKitEnabled = true
    }
}

extension HealthKitManager {
    func fetchSleepHours(for date: Date) async throws -> Duration {
        let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: yesterday)!,
            end: .now,
        )
        
        let asleepValues: Set<HKCategoryValueSleepAnalysis> = [
            .asleepCore, .asleepDeep, .asleepREM, .asleepUnspecified
        ]
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) {_, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let totalSeconds = (samples as? [HKCategorySample] ?? [])
                    .filter { asleepValues.contains(HKCategoryValueSleepAnalysis(rawValue: $0.value)!) }
                    .reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                
                continuation.resume(returning: .seconds(totalSeconds))
            }
            healthStore.execute(query)
        }
    }
    
    func fetchMindfulnessMinutes(for date: Date) async throws -> Duration {
        let type = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        
        let todayStart = Calendar.current.startOfDay(for: date)
        
        let predicate = HKQuery.predicateForSamples(
            withStart: todayStart,
            end: .now,
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let totalSeconds = (samples as? [HKCategorySample] ?? [])
                    .reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }

                continuation.resume(returning: .seconds(totalSeconds))
            }

            healthStore.execute(query)
        }
    }
}

public func syncHealthKitData(for date: Date, in context: ModelContext) async throws {
    let habits = try context.fetch(FetchDescriptor<Habit>(
                                   predicate: #Predicate {
        $0.title == "Sleep Hours" ||
        $0.title == "Mindful Minutes"
    }))
    print("FOund Habits")
    
    guard
        let sleepHabit = habits.first(where: { $0.title == "Sleep Hours" }),
        let mindfulHabit = habits.first(where: { $0.title == "Mindful Minutes" })
    else { return }
    print("Set habits")
    
    print("Loading HK")
    let healthKit = HealthKitManager.shared
    print("HK Loaded")
    let sleep = try await healthKit.fetchSleepHours(for: date)
    print("Sleep data loaded")
    let mindful = try await healthKit.fetchMindfulnessMinutes(for: date)
    print("Mindfulness data loaded")
    
    let day = Calendar.current.startOfDay(for: date)
    
    for (habit, duration) in [
        (sleepHabit, sleep),
        (mindfulHabit, mindful)
    ] {
        let habitID = habit.id
        let descriptor = FetchDescriptor<HabitEntry>(
            predicate: #Predicate {
                $0.habit?.id == habitID &&
                $0.date == day
            }
            )
        
        if let entry = try context.fetch(descriptor).first {
            print(entry.habit?.title ?? "default value")
            entry.time = duration
            entry.updatedAt = .now
            print("Entry Updated: \(entry.durationSeconds, default: "default value")")
        } else {
            let entry = HabitEntry(
                id: UUID(),
                date: day
            )
            entry.time = duration
            entry.updatedAt = .now
            entry.habit = habit
            print(entry.habit?.title ?? "default value")
            
            context.insert(entry)
            print("Entry Inserted: \(entry.durationSeconds, default: "default value")")
        }
    }
    try context.save()
    print("Context Saved")
}
#endif
