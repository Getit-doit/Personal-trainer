import Foundation
import SwiftData

/// A completed or in-progress workout on a given day.
@Model
final class WorkoutSession {
    var name: String
    var date: Date
    var notes: String
    var isFinished: Bool

    @Relationship(deleteRule: .cascade, inverse: \LoggedExercise.session)
    var exercises: [LoggedExercise]

    init(name: String, date: Date = .now, notes: String = "", isFinished: Bool = false) {
        self.name = name
        self.date = date
        self.notes = notes
        self.isFinished = isFinished
        self.exercises = []
    }

    /// Total volume = sum of reps * weight across every completed set.
    var totalVolume: Double {
        exercises.flatMap(\.sets)
            .filter(\.isCompleted)
            .reduce(0) { $0 + Double($1.reps) * $1.weight }
    }

    var completedSetCount: Int {
        exercises.flatMap(\.sets).filter(\.isCompleted).count
    }
}

/// One exercise performed within a session (e.g. "Bench Press").
@Model
final class LoggedExercise {
    var name: String
    var muscleGroup: String
    var order: Int
    var session: WorkoutSession?

    @Relationship(deleteRule: .cascade, inverse: \SetEntry.exercise)
    var sets: [SetEntry]

    init(name: String, muscleGroup: String, order: Int = 0) {
        self.name = name
        self.muscleGroup = muscleGroup
        self.order = order
        self.sets = []
    }

    var sortedSets: [SetEntry] {
        sets.sorted { $0.order < $1.order }
    }
}

/// A single set: reps at a given weight.
@Model
final class SetEntry {
    var reps: Int
    var weight: Double
    var isCompleted: Bool
    var order: Int
    var exercise: LoggedExercise?

    init(reps: Int = 10, weight: Double = 0, isCompleted: Bool = false, order: Int = 0) {
        self.reps = reps
        self.weight = weight
        self.isCompleted = isCompleted
        self.order = order
    }
}

/// A body-weight measurement for the progress chart.
@Model
final class BodyMetric {
    var date: Date
    var weight: Double

    init(date: Date = .now, weight: Double) {
        self.date = date
        self.weight = weight
    }
}
