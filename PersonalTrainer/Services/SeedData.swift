import Foundation
import SwiftData

/// Seeds the exercise catalog on first launch so the app opens with a full
/// library to plan from. The user profile is created during onboarding, not
/// seeded, so the app starts blank and personalizes to whoever sets it up.
enum SeedData {
    static func seedIfNeeded(context: ModelContext) {
        seedExercises(context)
        try? context.save()
    }

    /// Insert any catalog exercises that aren't already stored (matched by name),
    /// so library updates reach users who have already onboarded — not just fresh
    /// installs. Existing exercises are left untouched.
    private static func seedExercises(_ context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        let existingNames = Set(existing.map(\.name))
        for seed in TrainingContent.exercises where !existingNames.contains(seed.name) {
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
}
