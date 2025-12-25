//
//  HealthKitManager.swift
//  zTracker
//
//  Created by Jia Sahar on 12/21/25.
//

import HealthKit
import SwiftUI

actor HealthKitManager {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    private var isAuthorized = false
    
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
        
        isAuthorized = true
    }
}

extension HealthKitManager {
    func fetchSleepHours(for date: Date) async throws -> Duration {
        let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.date(byAdding: .day, value: -1, to: date)!,
            end: Calendar.current.startOfDay(for: date),
            options: .strictStartDate
        )
        
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
                    .reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                
                continuation.resume(returning: .seconds(totalSeconds))
            }
            healthStore.execute(query)
        }
    }
    
    func fetchMindfulnessMinutes(for date: Date) async throws -> Duration {
            let type = HKObjectType.categoryType(forIdentifier: .mindfulSession)!

            let predicate = HKQuery.predicateForSamples(
                withStart: Calendar.current.startOfDay(for: date),
                end: Calendar.current.startOfDay(for: date),
                options: .strictStartDate
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
