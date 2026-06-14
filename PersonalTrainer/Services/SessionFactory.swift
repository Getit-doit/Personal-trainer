import Foundation
import SwiftData

/// Builds new workout sessions (blank or from a template), wiring up exercises
/// and pre-filled sets from the catalog.
enum SessionFactory {

    static func blank(context: ModelContext) -> WorkoutSession {
        let session = WorkoutSession()
        context.insert(session)
        try? context.save()
        return session
    }

    static func fromTemplate(_ template: WorkoutTemplate, context: ModelContext) -> WorkoutSession {
        let catalog = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        let byName = Dictionary(uniqueKeysWithValues: catalog.map { ($0.name, $0) })

        let session = WorkoutSession()
        session.notes = template.title
        context.insert(session)

        for (index, item) in template.exercises.enumerated() {
            let catalogExercise = byName[item.name]
            let logged = LoggedExercise(
                name: item.name,
                type: catalogExercise?.type ?? .compound,
                muscleGroup: catalogExercise?.muscleGroup ?? "",
                equipment: catalogExercise?.equipment ?? .barbell,
                order: index
            )
            logged.session = session
            logged.exercise = catalogExercise
            context.insert(logged)

            for setIndex in 0..<item.sets {
                let set = SetLog(weight: 0, reps: item.reps, order: setIndex)
                set.exercise = logged
                context.insert(set)
            }
        }
        try? context.save()
        return session
    }

    /// Adds a catalog exercise to an existing session with one starter set.
    static func add(_ exercise: Exercise, to session: WorkoutSession, context: ModelContext) {
        let logged = LoggedExercise(
            name: exercise.name,
            type: exercise.type,
            muscleGroup: exercise.muscleGroup,
            equipment: exercise.equipment,
            order: session.exercises.count
        )
        logged.session = session
        logged.exercise = exercise
        context.insert(logged)

        let set = SetLog(weight: 0, reps: exercise.targetReps, order: 0)
        set.exercise = logged
        context.insert(set)
        try? context.save()
    }
}
