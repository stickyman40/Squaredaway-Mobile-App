import Foundation
import HealthKit
import SwiftUI

// ============================================================
//  HealthKitManager.swift
//  Singleton that owns the HKHealthStore and all read/write ops.
//  - Requests permissions on first use
//  - Graceful fallback to zero/manual when denied or unavailable
//  - All async — never blocks the main thread
//  - Requires NSHealthShareUsageDescription in Info.plist
// ============================================================

@MainActor
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    // MARK: - State
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published var isAvailable: Bool = HKHealthStore.isHealthDataAvailable()
    @Published var permissionGranted: Bool = false

    // MARK: - Today's Data
    @Published var stepsToday: Int = 0
    @Published var activeCaloriesToday: Double = 0
    @Published var activeMinutesToday: Int = 0
    @Published var heartRateAvg: Double? = nil
    @Published var latestWeightKg: Double? = nil

    // MARK: - Store
    private let store = HKHealthStore()

    // MARK: - Data Types we read
    private let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) { types.insert(steps) }
        if let activeCal = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) { types.insert(activeCal) }
        if let exerciseTime = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) { types.insert(exerciseTime) }
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) { types.insert(heartRate) }
        if let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass) { types.insert(bodyMass) }
        types.insert(HKObjectType.workoutType())
        return types
    }()

    private init() {}

    // MARK: - Request Authorization
    func requestAuthorization() async {
        guard isAvailable else {
            permissionGranted = false
            return
        }

        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            permissionGranted = true
            await fetchTodayData()
        } catch {
            // User denied or error — app continues with manual input
            permissionGranted = false
        }
    }

    // MARK: - Fetch All Today's Data
    func fetchTodayData() async {
        guard isAvailable, permissionGranted else { return }

        async let steps = fetchStepsToday()
        async let cals = fetchActiveCaloriesToday()
        async let mins = fetchActiveMinutesToday()
        async let hr = fetchAvgHeartRateToday()
        async let weight = fetchLatestWeight()

        stepsToday = await steps
        activeCaloriesToday = await cals
        activeMinutesToday = await mins
        heartRateAvg = await hr
        latestWeightKg = await weight
    }

    // MARK: - Steps Today
    private func fetchStepsToday() async -> Int {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }

        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: Date()),
            end: Date(),
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(value))
            }
            store.execute(query)
        }
    }

    // MARK: - Active Calories Today
    private func fetchActiveCaloriesToday() async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return 0 }

        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: Date()),
            end: Date(),
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    // MARK: - Active Minutes Today
    private func fetchActiveMinutesToday() async -> Int {
        guard let type = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else { return 0 }

        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: Date()),
            end: Date(),
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: .minute()) ?? 0
                continuation.resume(returning: Int(value))
            }
            store.execute(query)
        }
    }

    // MARK: - Average Heart Rate Today
    private func fetchAvgHeartRateToday() async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return nil }

        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: Date()),
            end: Date(),
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, result, _ in
                let beatsPerMin = HKUnit.count().unitDivided(by: .minute())
                let value = result?.averageQuantity()?.doubleValue(for: beatsPerMin)
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    // MARK: - Latest Body Weight
    private func fetchLatestWeight() async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return nil }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let kg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: kg)
            }
            store.execute(query)
        }
    }

    // MARK: - Steps (formatted)
    var stepsFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: stepsToday)) ?? "\(stepsToday)"
    }

    // MARK: - Fallback Activity Summary (when HealthKit not available)
    var fallbackSummary: String {
        "Connect Apple Health to sync steps and calories automatically, or log manually."
    }

    // MARK: - Open Settings for Health permission
    func openHealthSettings() {
        if let url = URL(string: "x-apple-health://") {
            UIApplication.shared.open(url)
        }
    }
}
