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

    /// Start any routine day (built-in or custom).
    static func start(_ day: RoutineDay, context: ModelContext) -> WorkoutSession {
        switch day {
        case .builtin(let template): return fromTemplate(template, context: context)
        case .custom(let template): return fromCustom(template, context: context)
        }
    }

    static func fromCustom(_ template: CustomTemplate, context: ModelContext) -> WorkoutSession {
        let catalog = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        let byName = Dictionary(catalog.map { ($0.name, $0) }, uniquingKeysWith: { a, _ in a })

        let session = WorkoutSession()
        session.notes = template.title
        context.insert(session)

        for (index, item) in template.sortedItems.enumerated() {
            let catalogExercise = byName[item.name]
            let timed = catalogExercise?.isTimed ?? false
            let logged = LoggedExercise(
                name: item.name,
                type: catalogExercise?.type ?? .accessory,
                muscleGroup: item.muscleGroup,
                equipment: item.equipment,
                isTimed: timed,
                order: index
            )
            logged.session = session
            logged.exercise = catalogExercise
            context.insert(logged)
            let seconds = (catalogExercise?.targetSeconds ?? 0) > 0 ? (catalogExercise?.targetSeconds ?? 45) : 45
            for setIndex in 0..<max(item.sets, 1) {
                let set = SetLog(weight: 0, reps: item.reps, durationSeconds: timed ? seconds : 0, order: setIndex)
                set.exercise = logged
                context.insert(set)
            }
        }
        try? context.save()
        return session
    }

    static func fromTemplate(_ template: WorkoutTemplate, context: ModelContext) -> WorkoutSession {
        let catalog = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        let byName = Dictionary(catalog.map { ($0.name, $0) }, uniquingKeysWith: { a, _ in a })

        let session = WorkoutSession()
        session.notes = template.title
        context.insert(session)

        for (index, item) in template.exercises.enumerated() {
            let catalogExercise = byName[item.name]
            let timed = catalogExercise?.isTimed ?? false
            let logged = LoggedExercise(
                name: item.name,
                type: catalogExercise?.type ?? .compound,
                muscleGroup: catalogExercise?.muscleGroup ?? "",
                equipment: catalogExercise?.equipment ?? .barbell,
                isTimed: timed,
                order: index
            )
            logged.session = session
            logged.exercise = catalogExercise
            context.insert(logged)

            let seconds = (catalogExercise?.targetSeconds ?? 0) > 0 ? (catalogExercise?.targetSeconds ?? 45) : 45
            for setIndex in 0..<item.sets {
                let set = SetLog(weight: 0, reps: item.reps, durationSeconds: timed ? seconds : 0, order: setIndex)
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
            isTimed: exercise.isTimed,
            order: session.exercises.count
        )
        logged.session = session
        logged.exercise = exercise
        context.insert(logged)

        let seconds = exercise.targetSeconds > 0 ? exercise.targetSeconds : 45
        let set = SetLog(
            weight: 0, reps: exercise.targetReps,
            durationSeconds: exercise.isTimed ? seconds : 0, order: 0
        )
        set.exercise = logged
        context.insert(set)
        try? context.save()
    }
}
