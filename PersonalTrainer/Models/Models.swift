import Foundation
import SwiftData

// MARK: - User

/// The single owner of the app. Holds profile + training constraints that
/// influence coaching and the mandatory ankle warm-up gate.
@Model
final class UserProfile {
    var name: String
    var sex: String = ""               // "Male" / "Female" / "" (unspecified)
    var age: Int = 0
    var heightInches: Double
    var startWeight: Double
    var experience: String = "Beginner"   // Beginner / Intermediate / Advanced
    var goals: String
    /// Equipment the athlete can train with — drives plan suggestions.
    var equipment: [String] = []
    var constraints: [String]
    var scheduleDaysPerWeek: Int

    init(
        name: String,
        sex: String = "",
        age: Int = 0,
        heightInches: Double,
        startWeight: Double,
        experience: String = "Beginner",
        goals: String,
        equipment: [String] = [],
        constraints: [String],
        scheduleDaysPerWeek: Int
    ) {
        self.name = name
        self.sex = sex
        self.age = age
        self.heightInches = heightInches
        self.startWeight = startWeight
        self.experience = experience
        self.goals = goals
        self.equipment = equipment
        self.constraints = constraints
        self.scheduleDaysPerWeek = scheduleDaysPerWeek
    }
}

// MARK: - Exercise catalog

enum ExerciseType: String, Codable, CaseIterable {
    case compound = "Compound"
    case accessory = "Accessory"
}

/// Skill/experience tier for an exercise. Aligns with the athlete's profile
/// experience level so the coach can pull exercises that match (or are a step
/// below) their level. "Advanced" is the expert tier.
enum Difficulty: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    /// Higher = more demanding, for "at or below my level" comparisons.
    var rank: Int {
        switch self {
        case .beginner: return 0
        case .intermediate: return 1
        case .advanced: return 2
        }
    }
}

/// A reusable exercise definition. `isPriorityProgression` marks lifts the user
/// wants to push first (e.g. RDL, goblet squat).
@Model
final class Exercise {
    var name: String
    var typeRaw: String
    var muscleGroup: String
    var equipmentRaw: String = Equipment.barbell.rawValue
    var difficultyRaw: String = Difficulty.beginner.rawValue
    /// Time-based move (planks, carries, intervals) — sets track a duration
    /// instead of reps. `targetSeconds` is the default hold/interval length.
    var isTimed: Bool = false
    var targetSeconds: Int = 0
    var isPriorityProgression: Bool
    var targetSets: Int
    var targetReps: Int
    /// Smallest sensible weight jump for this lift, in lb.
    var increment: Double

    var type: ExerciseType {
        get { ExerciseType(rawValue: typeRaw) ?? .accessory }
        set { typeRaw = newValue.rawValue }
    }

    var equipment: Equipment {
        get { Equipment(rawValue: equipmentRaw) ?? .barbell }
        set { equipmentRaw = newValue.rawValue }
    }

    var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .beginner }
        set { difficultyRaw = newValue.rawValue }
    }

    init(
        name: String,
        type: ExerciseType,
        muscleGroup: String,
        equipment: Equipment = .barbell,
        difficulty: Difficulty = .beginner,
        isTimed: Bool = false,
        targetSeconds: Int = 0,
        isPriorityProgression: Bool = false,
        targetSets: Int = 3,
        targetReps: Int = 8,
        increment: Double = 5
    ) {
        self.name = name
        self.typeRaw = type.rawValue
        self.muscleGroup = muscleGroup
        self.equipmentRaw = equipment.rawValue
        self.difficultyRaw = difficulty.rawValue
        self.isTimed = isTimed
        self.targetSeconds = targetSeconds
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
    /// Warm-up gate — set logging is blocked until this is true.
    var warmupDone: Bool
    var isFinished: Bool

    @Relationship(deleteRule: .cascade, inverse: \LoggedExercise.session)
    var exercises: [LoggedExercise]

    @Relationship(deleteRule: .cascade, inverse: \CardioEntry.session)
    var cardio: CardioEntry?

    init(
        date: Date = .now,
        notes: String = "",
        steamRoom: Bool = false,
        warmupDone: Bool = false,
        isFinished: Bool = false
    ) {
        self.date = date
        self.notes = notes
        self.steamRoom = steamRoom
        self.warmupDone = warmupDone
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
    var equipmentRaw: String = Equipment.barbell.rawValue
    /// Snapshot of whether this is a time-based move (sets track a duration).
    var isTimed: Bool = false
    var order: Int
    /// Exercises sharing a superset id are performed back-to-back with no rest
    /// between them; rest is taken only after the last exercise in the group.
    var supersetID: String?
    var session: WorkoutSession?
    var exercise: Exercise?

    @Relationship(deleteRule: .cascade, inverse: \SetLog.exercise)
    var sets: [SetLog]

    var type: ExerciseType { ExerciseType(rawValue: typeRaw) ?? .accessory }
    var equipment: Equipment { Equipment(rawValue: equipmentRaw) ?? .barbell }

    init(name: String, type: ExerciseType, muscleGroup: String, equipment: Equipment = .barbell, isTimed: Bool = false, order: Int = 0) {
        self.name = name
        self.typeRaw = type.rawValue
        self.muscleGroup = muscleGroup
        self.equipmentRaw = equipment.rawValue
        self.isTimed = isTimed
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
    var isDropSet: Bool = false
    /// Duration in seconds for a timed set (plank, carry, interval); 0 = rep-based.
    var durationSeconds: Int = 0
    var order: Int
    var exercise: LoggedExercise?

    init(
        weight: Double = 0,
        reps: Int = 8,
        rpe: Double = 7,
        repsInTank: Int = 2,
        isCompleted: Bool = false,
        isDropSet: Bool = false,
        durationSeconds: Int = 0,
        order: Int = 0
    ) {
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.repsInTank = repsInTank
        self.isCompleted = isCompleted
        self.isDropSet = isDropSet
        self.durationSeconds = durationSeconds
        self.order = order
    }

    /// Epley estimated one-rep max for PR detection.
    var estimatedOneRepMax: Double {
        guard reps > 0, weight > 0 else { return 0 }
        return weight * (1 + Double(reps) / 30)
    }
}

// MARK: - Cardio finisher

enum ImpactLevel: String, Codable, CaseIterable {
    case none = "None"
    case light = "Light"
    case moderate = "Moderate"
    case high = "High"
}

/// Low-impact-by-default cardio finisher. Tracks impact level so impact can be
/// introduced gradually (useful for anyone managing joints).
@Model
final class CardioEntry {
    var modality: String          // e.g. "Incline Walk"
    var durationMinutes: Double
    var speed: Double             // mph
    var incline: Double          // %
    var impactLevelRaw: String
    var notes: String
    var session: WorkoutSession?

    var impactLevel: ImpactLevel {
        get { ImpactLevel(rawValue: impactLevelRaw) ?? .light }
        set { impactLevelRaw = newValue.rawValue }
    }

    init(
        modality: String = "Incline Walk",
        durationMinutes: Double = 15,
        speed: Double = 3.0,
        incline: Double = 5,
        impactLevel: ImpactLevel = .light,
        notes: String = ""
    ) {
        self.modality = modality
        self.durationMinutes = durationMinutes
        self.speed = speed
        self.incline = incline
        self.impactLevelRaw = impactLevel.rawValue
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

// MARK: - Custom routines

/// A user-created day template that belongs to a (possibly new) program.
@Model
final class CustomTemplate {
    var program: String
    var title: String
    var level: String
    var order: Int

    @Relationship(deleteRule: .cascade, inverse: \CustomTemplateItem.template)
    var items: [CustomTemplateItem]

    init(program: String, title: String, level: String = "Custom", order: Int = 0) {
        self.program = program
        self.title = title
        self.level = level
        self.order = order
        self.items = []
    }

    var sortedItems: [CustomTemplateItem] { items.sorted { $0.order < $1.order } }
}

/// One exercise slot inside a custom day template.
@Model
final class CustomTemplateItem {
    var name: String
    var muscleGroup: String
    var equipmentRaw: String = Equipment.barbell.rawValue
    var sets: Int
    var reps: Int
    var order: Int
    var template: CustomTemplate?

    var equipment: Equipment { Equipment(rawValue: equipmentRaw) ?? .barbell }

    init(name: String, muscleGroup: String, equipment: Equipment, sets: Int, reps: Int, order: Int) {
        self.name = name
        self.muscleGroup = muscleGroup
        self.equipmentRaw = equipment.rawValue
        self.sets = sets
        self.reps = reps
        self.order = order
    }
}

// MARK: - Diet lever check-ins

/// A single nutrition "lever" the coach checks in on via notifications with
/// Yes/No buttons — e.g. "Have you had any soda the last few days?" or "Did you
/// drink your protein every morning this week?". Streaks are computed from the
/// check-in history; milestones are celebrated.
@Model
final class DietHabit {
    /// Stable id carried in the notification payload so responses route back here.
    var id: UUID = UUID()
    var title: String                 // short tag, e.g. "No soda"
    var question: String              // the notification body / prompt
    /// True when answering "Yes" is the *good* outcome (e.g. "drank protein").
    /// False when "No" is good (e.g. "no soda").
    var goodAnswerIsYes: Bool
    var startDate: Date
    var isActive: Bool
    /// Ask roughly every N days.
    var frequencyDays: Int
    var hour: Int                     // preferred check-in time
    var minute: Int
    /// Largest streak milestone (in days) already celebrated, so we don't repeat.
    var lastCelebratedMilestone: Int
    /// Most recent "how do you feel?" reflection captured at a celebration.
    var lastReflection: String

    @Relationship(deleteRule: .cascade, inverse: \HabitCheckIn.habit)
    var checkIns: [HabitCheckIn]

    init(
        title: String,
        question: String,
        goodAnswerIsYes: Bool,
        startDate: Date = .now,
        isActive: Bool = true,
        frequencyDays: Int = 3,
        hour: Int = 18,
        minute: Int = 0
    ) {
        self.id = UUID()
        self.title = title
        self.question = question
        self.goodAnswerIsYes = goodAnswerIsYes
        self.startDate = startDate
        self.isActive = isActive
        self.frequencyDays = frequencyDays
        self.hour = hour
        self.minute = minute
        self.lastCelebratedMilestone = 0
        self.lastReflection = ""
        self.checkIns = []
    }
}

/// One answer to a diet-lever check-in.
@Model
final class HabitCheckIn {
    var date: Date
    var answeredYes: Bool
    /// Whether this answer counted as the good outcome for the habit.
    var wasGood: Bool
    var habit: DietHabit?

    init(date: Date = .now, answeredYes: Bool, wasGood: Bool) {
        self.date = date
        self.answeredYes = answeredYes
        self.wasGood = wasGood
    }
}

// MARK: - Recognition & rewards (gamification)

/// An earned achievement. Display fields are snapshotted from the catalog at
/// grant time so old awards still render even if the catalog changes.
@Model
final class Achievement {
    var id: UUID = UUID()
    var defID: String          // catalog key (also prevents duplicates)
    var title: String
    var detail: String
    var icon: String           // SF Symbol name
    var tier: String           // bronze / silver / gold
    var points: Int
    var dateEarned: Date
    /// AI-written personalized recognition line, filled in when available.
    var recognition: String

    init(
        defID: String,
        title: String,
        detail: String,
        icon: String,
        tier: String,
        points: Int,
        dateEarned: Date = .now,
        recognition: String = ""
    ) {
        self.id = UUID()
        self.defID = defID
        self.title = title
        self.detail = detail
        self.icon = icon
        self.tier = tier
        self.points = points
        self.dateEarned = dateEarned
        self.recognition = recognition
    }
}
