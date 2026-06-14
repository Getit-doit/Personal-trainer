import Foundation
import HealthKit

/// Reads sleep, body weight, and steps from Apple Health and writes completed
/// workouts and body-weight entries back. Fits the longevity goal by surfacing
/// recovery + activity data alongside training.
@MainActor
final class HealthService: ObservableObject {
    private let store = HKHealthStore()

    @Published var isAvailable = HKHealthStore.isHealthDataAvailable()
    @Published var authorized = false
    @Published var lastNightSleepHours: Double?
    @Published var latestBodyWeight: Double?       // lb
    @Published var todaySteps: Double?

    private var sleepType: HKCategoryType { HKCategoryType(.sleepAnalysis) }
    private var bodyMassType: HKQuantityType { HKQuantityType(.bodyMass) }
    private var stepType: HKQuantityType { HKQuantityType(.stepCount) }
    private var workoutType: HKWorkoutType { HKObjectType.workoutType() }

    private var readTypes: Set<HKObjectType> { [sleepType, bodyMassType, stepType, workoutType] }
    private var shareTypes: Set<HKSampleType> { [workoutType, bodyMassType] }

    func requestAuthorization() async {
        guard isAvailable else { return }
        do {
            try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
            authorized = true
            await refresh()
        } catch {
            authorized = false
        }
    }

    /// Refresh all the surfaced metrics.
    func refresh() async {
        async let sleep = readLastNightSleep()
        async let weight = readLatestBodyWeight()
        async let steps = readTodaySteps()
        lastNightSleepHours = await sleep
        latestBodyWeight = await weight
        todaySteps = await steps
    }

    // MARK: - Reads

    private func readLastNightSleep() async -> Double? {
        let calendar = Calendar.current
        // Window: 6pm yesterday → noon today, to catch a typical night's sleep.
        guard
            let start = calendar.date(byAdding: .hour, value: -18, to: calendar.startOfDay(for: .now)),
            let end = calendar.date(byAdding: .hour, value: 12, to: calendar.startOfDay(for: .now))
        else { return nil }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil
            ) { _, samples, _ in
                let asleep = (samples as? [HKCategorySample])?.filter { isAsleep($0.value) } ?? []
                let seconds = asleep.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                continuation.resume(returning: seconds > 0 ? seconds / 3600 : nil)
            }
            store.execute(query)
        }
    }

    private func readLatestBodyWeight() async -> Double? {
        let sort = [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: bodyMassType, predicate: nil, limit: 1, sortDescriptors: sort
            ) { _, samples, _ in
                let pounds = (samples?.first as? HKQuantitySample)?
                    .quantity.doubleValue(for: .pound())
                continuation.resume(returning: pounds)
            }
            store.execute(query)
        }
    }

    private func readTodaySteps() async -> Double? {
        let start = Calendar.current.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum
            ) { _, stats, _ in
                let steps = stats?.sumQuantity()?.doubleValue(for: .count())
                continuation.resume(returning: steps)
            }
            store.execute(query)
        }
    }

    // MARK: - Writes

    /// Save a finished session as a strength-training workout in Health.
    func saveWorkout(start: Date, end: Date) async {
        guard authorized else { return }
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        do {
            try await builder.beginCollection(at: start)
            try await builder.endCollection(at: end)
            _ = try await builder.finishWorkout()
        } catch {
            // Non-fatal — workout stays logged locally regardless.
        }
    }

    func saveBodyWeight(pounds: Double, date: Date = .now) async {
        guard authorized else { return }
        let quantity = HKQuantity(unit: .pound(), doubleValue: pounds)
        let sample = HKQuantitySample(type: bodyMassType, quantity: quantity, start: date, end: date)
        try? await store.save(sample)
        await refresh()
    }
}

/// Treats any "asleep" category value as sleep (handles the iOS 16+ stages).
private func isAsleep(_ value: Int) -> Bool {
    if #available(iOS 16.0, *) {
        switch HKCategoryValueSleepAnalysis(rawValue: value) {
        case .asleepCore, .asleepDeep, .asleepREM, .asleepUnspecified:
            return true
        default:
            return false
        }
    } else {
        return value == HKCategoryValueSleepAnalysis.asleep.rawValue
    }
}
