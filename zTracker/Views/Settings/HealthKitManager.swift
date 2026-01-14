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

class HealthKitManager {
    @AppStorage("healthKitEnabled") private var healthKitEnabled = false
    
    nonisolated(unsafe) static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    
private init() {}
    
    func requestAuthorization() async throws {
        print("Checking HK Authorization")
        guard HKHealthStore.isHealthDataAvailable() else {
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
            end: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: date)!,
        )
        
        let asleepValues: Set<HKCategoryValueSleepAnalysis> = [
            .asleepCore, .asleepDeep, .asleepREM, .asleepUnspecified
        ]
        print(asleepValues)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) {_, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    print("HK Sleep Error: \(error)")
                    return
                }
                print(samples ?? "no samples found")
                
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

func syncHealthKitData(for date: Date, in context: ModelContext) async throws {
    let sleepID = UserDefaults.standard.string(forKey: "sleepHabit") ?? ""
    let mindfulID = UserDefaults.standard.string(forKey: "mindfulHabit") ?? ""
    
    guard let sleepUUID = UUID(uuidString: sleepID),
          let mindfulUUID = UUID(uuidString: mindfulID) else { return }
    
    let descriptor = FetchDescriptor<Habit>(
        predicate: #Predicate { $0.id == sleepUUID || $0.id == mindfulUUID }
    )
    let habits = try context.fetch(descriptor)
    
    guard let sleepHabit = habits.first(where: { $0.id == sleepUUID }),
          let mindfulHabit = habits.first(where: { $0.id == mindfulUUID }) else { return }
    print("Habits Found: \(habits[0].title), \(habits[1].title)")
    
    let sleepDuration = try await HealthKitManager.shared.fetchSleepHours(for: date)
    let mindfulDuration = try await HealthKitManager.shared.fetchMindfulnessMinutes(for: date)
    print("Sleep: \(sleepDuration), Mindful: \(mindfulDuration)")
    
    let startOfDate = Calendar.current.startOfDay(for: date)
    
    _ = sleepHabit.createOrUpdateEntry(for: startOfDate, time: sleepDuration)
    _ = mindfulHabit.createOrUpdateEntry(for: startOfDate, time: mindfulDuration)
    print("Entries Created")
    
    try context.save()
}

#endif
