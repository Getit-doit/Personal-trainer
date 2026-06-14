import Foundation
import SwiftData

// MARK: - User

/// The single owner of the app. Holds profile + training constraints that
/// influence coaching and the mandatory ankle warm-up gate.
@Model
final class UserProfile {
    var name: String
    var heightInches: Double
    var startWeight: Double
    var goals: String
    var constraints: [String]
    var scheduleDaysPerWeek: Int

    init(
        name: String,
        heightInches: Double,
        startWeight: Double,
        goals: String,
        constraints: [String],
        scheduleDaysPerWeek: Int
    ) {
        self.name = name
        self.heightInches = heightInches
        self.startWeight = startWeight
        self.goals = goals
        self.constraints = constraints
        self.scheduleDaysPerWeek = scheduleDaysPerWeek
    }
}

// MARK: - Exercise catalog

enum ExerciseType: String, Codable, CaseIterable {
    case compound = "Compound"
    case accessory = "Accessory"
}

/// A reusable exercise definition. `isPriorityProgression` marks lifts the user
/// wants to push first (e.g. RDL, goblet squat).
@Model
final class Exercise {
    var name: String
    var typeRaw: String
    var muscleGroup: String
    var isPriorityProgression: Bool
    var targetSets: Int
    var targetReps: Int
    /// Smallest sensible weight jump for this lift, in lb.
    var increment: Double

    var type: ExerciseType {
        get { ExerciseType(rawValue: typeRaw) ?? .accessory }
        set { typeRaw = newValue.rawValue }
    }

    init(
        name: String,
        type: ExerciseType,
        muscleGroup: String,
        isPriorityProgression: Bool = false,
        targetSets: Int = 3,
        targetReps: Int = 8,
        increment: Double = 5
    ) {
        self.name = name
        self.typeRaw = type.rawValue
        self.muscleGroup = muscleGroup
        self.isPriorityProgression = isPriorityProgression
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.increment = increment
    }
}

// MARK: - Workout session

@Model
final class WorkoutSession {
    var date: Date
    var notes: String
    var steamRoom: Bool
    /// Mandatory ankle warm-up gate — set logging is blocked until this is true.
    var ankleWarmupDone: Bool
    var isFinished: Bool

    @Relationship(deleteRule: .cascade, inverse: \LoggedExercise.session)
    var exercises: [LoggedExercise]

    @Relationship(deleteRule: .cascade, inverse: \CardioEntry.session)
    var cardio: CardioEntry?

    init(
        date: Date = .now,
        notes: String = "",
        steamRoom: Bool = false,
        ankleWarmupDone: Bool = false,
        isFinished: Bool = false
    ) {
        self.date = date
        self.notes = notes
        self.steamRoom = steamRoom
        self.ankleWarmupDone = ankleWarmupDone
        self.isFinished = isFinished
        self.exercises = []
    }

    var sortedExercises: [LoggedExercise] {
        exercises.sorted { $0.order < $1.order }
    }

    var totalVolume: Double {
        exercises.flatMap(\.sets)
            .filter(\.isCompleted)
            .reduce(0) { $0 + Double($1.reps) * $1.weight }
    }

    var completedSetCount: Int {
        exercises.flatMap(\.sets).filter(\.isCompleted).count
    }
}

/// One exercise performed within a session. Snapshots name/type/muscle so the
/// log stays readable even if the catalog entry changes later.
@Model
final class LoggedExercise {
    var name: String
    var typeRaw: String
    var muscleGroup: String
    var order: Int
    /// Exercises sharing a superset id are performed back-to-back with no rest
    /// between them; rest is taken only after the last exercise in the group.
    var supersetID: String?
    var session: WorkoutSession?
    var exercise: Exercise?

    @Relationship(deleteRule: .cascade, inverse: \SetLog.exercise)
    var sets: [SetLog]

    var type: ExerciseType { ExerciseType(rawValue: typeRaw) ?? .accessory }

    init(name: String, type: ExerciseType, muscleGroup: String, order: Int = 0) {
        self.name = name
        self.typeRaw = type.rawValue
        self.muscleGroup = muscleGroup
        self.order = order
        self.supersetID = nil
        self.sets = []
    }

    var sortedSets: [SetLog] {
        sets.sorted { $0.order < $1.order }
    }
}

/// A single working set: weight × reps, with RPE and reps-in-tank for
/// autoregulated progression.
@Model
final class SetLog {
    var weight: Double
    var reps: Int
    var rpe: Double
    var repsInTank: Int
    var isCompleted: Bool
    /// Part of a drop-set sequence — no rest is taken before the next drop.
    var isDropSet: Bool
    var order: Int
    var exercise: LoggedExercise?

    init(
        weight: Double = 0,
        reps: Int = 8,
        rpe: Double = 7,
        repsInTank: Int = 2,
        isCompleted: Bool = false,
        isDropSet: Bool = false,
        order: Int = 0
    ) {
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.repsInTank = repsInTank
        self.isCompleted = isCompleted
        self.isDropSet = isDropSet
        self.order = order
    }

    /// Epley estimated one-rep max for PR detection.
    var estimatedOneRepMax: Double {
        guard reps > 0, weight > 0 else { return 0 }
        return weight * (1 + Double(reps) / 30)
    }
}

// MARK: - Cardio finisher

enum AnkleLoad: String, Codable, CaseIterable {
    case none = "None"
    case light = "Light"
    case moderate = "Moderate"
    case high = "High"
}

/// Low-impact-by-default cardio finisher. Tracks ankle load so impact can be
/// introduced gradually.
@Model
final class CardioEntry {
    var modality: String          // e.g. "Incline Walk"
    var durationMinutes: Double
    var speed: Double             // mph
    var incline: Double          // %
    var ankleLoadRaw: String
    var notes: String
    var session: WorkoutSession?

    var ankleLoad: AnkleLoad {
        get { AnkleLoad(rawValue: ankleLoadRaw) ?? .light }
        set { ankleLoadRaw = newValue.rawValue }
    }

    init(
        modality: String = "Incline Walk",
        durationMinutes: Double = 15,
        speed: Double = 3.0,
        incline: Double = 5,
        ankleLoad: AnkleLoad = .light,
        notes: String = ""
    ) {
        self.modality = modality
        self.durationMinutes = durationMinutes
        self.speed = speed
        self.incline = incline
        self.ankleLoadRaw = ankleLoad.rawValue
        self.notes = notes
    }
}

// MARK: - Personal bests

enum PRSource: String, Codable {
    case logged = "Logged"
    case manual = "Manual"
}

@Model
final class PersonalBest {
    var exerciseName: String
    var value: Double            // estimated 1RM in lb
    var weight: Double
    var reps: Int
    var date: Date
    var sourceRaw: String
    var exercise: Exercise?

    var source: PRSource {
        get { PRSource(rawValue: sourceRaw) ?? .logged }
        set { sourceRaw = newValue.rawValue }
    }

    init(
        exerciseName: String,
        value: Double,
        weight: Double = 0,
        reps: Int = 1,
        date: Date = .now,
        source: PRSource = .logged,
        exercise: Exercise? = nil
    ) {
        self.exerciseName = exerciseName
        self.value = value
        self.weight = weight
        self.reps = reps
        self.date = date
        self.sourceRaw = source.rawValue
        self.exercise = exercise
    }
}

// MARK: - Nutrition (one lever at a time)

@Model
final class NutritionLog {
    var date: Date
    var wins: [String]
    var weakLinks: [String]
    var currentLever: String

    init(date: Date = .now, wins: [String] = [], weakLinks: [String] = [], currentLever: String = "") {
        self.date = date
        self.wins = wins
        self.weakLinks = weakLinks
        self.currentLever = currentLever
    }
}

// MARK: - Recovery

@Model
final class RecoveryLog {
    var date: Date
    var sleepHours: Double
    /// 1 (calm) … 5 (very stressed)
    var stressLevel: Int

    init(date: Date = .now, sleepHours: Double = 7, stressLevel: Int = 3) {
        self.date = date
        self.sleepHours = sleepHours
        self.stressLevel = stressLevel
    }
}
