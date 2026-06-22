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
}
