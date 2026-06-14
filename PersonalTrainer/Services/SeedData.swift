import Foundation
import SwiftData

/// Seeds the user profile, exercise catalog, and a little recovery history on
/// first launch so the app opens with meaningful content.
enum SeedData {
    static func seedIfNeeded(context: ModelContext) {
        seedProfile(context)
        seedExercises(context)
        seedRecovery(context)
        try? context.save()
    }

    private static func seedProfile(_ context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
        guard existing.isEmpty else { return }
        let profile = UserProfile(
            name: "Athlete",
            heightInches: 70,            // 5'10"
            startWeight: 217,
            goals: "Functional lean strength + longevity",
            constraints: [
                "Sleeps 6–7 hrs",
                "High stress",
                "Ankle inflames easily — mandatory ankle warm-up",
                "Introduce incline / impact / sprints / stairs gradually"
            ],
            scheduleDaysPerWeek: 3
        )
        context.insert(profile)
    }

    private static func seedExercises(_ context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        guard existing.isEmpty else { return }
        for seed in TrainingContent.exercises {
            context.insert(
                Exercise(
                    name: seed.name,
                    type: seed.type,
                    muscleGroup: seed.muscleGroup,
                    equipment: seed.equipment,
                    isPriorityProgression: seed.priority,
                    targetSets: seed.sets,
                    targetReps: seed.reps,
                    increment: seed.increment
                )
            )
        }
    }

    private static func seedRecovery(_ context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<RecoveryLog>())) ?? []
        guard existing.isEmpty else { return }
        let calendar = Calendar.current
        let sample: [(sleep: Double, stress: Int)] = [
            (6.5, 3), (7.0, 2), (6.0, 4), (6.5, 3), (7.0, 3)
        ]
        for (daysAgo, entry) in sample.enumerated().reversed() {
            if let date = calendar.date(byAdding: .day, value: -daysAgo, to: .now) {
                context.insert(RecoveryLog(date: date, sleepHours: entry.sleep, stressLevel: entry.stress))
            }
        }
    }
}
