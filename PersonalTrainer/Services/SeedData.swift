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
        let existingByName = Dictionary(existing.map { ($0.name, $0) }, uniquingKeysWith: { a, _ in a })
        for seed in TrainingContent.exercises {
            let difficulty = TrainingContent.difficulty(for: seed.name)
            if let existing = existingByName[seed.name] {
                if existing.difficulty != difficulty { existing.difficulty = difficulty }   // backfill tag on prior installs
                if existing.isTimed != seed.timed { existing.isTimed = seed.timed }
                if existing.targetSeconds != seed.seconds { existing.targetSeconds = seed.seconds }
            } else {
                context.insert(
                    Exercise(
                        name: seed.name,
                        type: seed.type,
                        muscleGroup: seed.muscleGroup,
                        equipment: seed.equipment,
                        difficulty: difficulty,
                        isTimed: seed.timed,
                        targetSeconds: seed.seconds,
                        isPriorityProgression: seed.priority,
                        targetSets: seed.sets,
                        targetReps: seed.reps,
                        increment: seed.increment
                    )
                )
            }
        }
    }
}
