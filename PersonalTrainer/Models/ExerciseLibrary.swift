import Foundation

/// Seed definition for a catalog exercise.
struct ExerciseSeed {
    let name: String
    let type: ExerciseType
    let muscleGroup: String
    var priority: Bool = false
    var sets: Int = 3
    var reps: Int = 8
    var increment: Double = 5
}

/// One exercise slot inside a starter template.
struct TemplateExercise {
    let name: String
    let sets: Int
    let reps: Int
}

/// A compound-first, full-body day template.
struct WorkoutTemplate: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let exercises: [TemplateExercise]
}

/// Static training content: the exercise catalog, the 3-day full-body split,
/// and the mandatory ankle warm-up checklist.
enum TrainingContent {

    static let muscleGroups = ["Legs", "Back", "Chest", "Shoulders", "Arms", "Core", "Hinge"]

    /// Compound-first catalog. Priority-progression lifts are flagged.
    static let exercises: [ExerciseSeed] = [
        // Compounds
        .init(name: "Back Squat", type: .compound, muscleGroup: "Legs", sets: 3, reps: 5, increment: 10),
        .init(name: "Front Squat", type: .compound, muscleGroup: "Legs", sets: 3, reps: 5, increment: 5),
        .init(name: "Goblet Squat", type: .compound, muscleGroup: "Legs", priority: true, sets: 3, reps: 10, increment: 5),
        .init(name: "Romanian Deadlift", type: .compound, muscleGroup: "Hinge", priority: true, sets: 3, reps: 8, increment: 10),
        .init(name: "Deadlift", type: .compound, muscleGroup: "Hinge", sets: 3, reps: 5, increment: 10),
        .init(name: "Trap Bar Deadlift", type: .compound, muscleGroup: "Hinge", sets: 3, reps: 5, increment: 10),
        .init(name: "Hip Thrust", type: .compound, muscleGroup: "Hinge", sets: 3, reps: 10, increment: 10),
        .init(name: "Bench Press", type: .compound, muscleGroup: "Chest", sets: 3, reps: 5, increment: 5),
        .init(name: "Overhead Press", type: .compound, muscleGroup: "Shoulders", sets: 3, reps: 6, increment: 5),
        .init(name: "Bent-Over Row", type: .compound, muscleGroup: "Back", sets: 3, reps: 8, increment: 5),
        .init(name: "Pull-Up", type: .compound, muscleGroup: "Back", sets: 3, reps: 8, increment: 5),
        .init(name: "Walking Lunge", type: .compound, muscleGroup: "Legs", sets: 3, reps: 12, increment: 5),
        // Accessories
        .init(name: "Incline Dumbbell Press", type: .accessory, muscleGroup: "Chest", sets: 3, reps: 10),
        .init(name: "Lat Pulldown", type: .accessory, muscleGroup: "Back", sets: 3, reps: 10),
        .init(name: "Dumbbell Row", type: .accessory, muscleGroup: "Back", sets: 3, reps: 10),
        .init(name: "Lateral Raise", type: .accessory, muscleGroup: "Shoulders", sets: 3, reps: 15),
        .init(name: "Face Pull", type: .accessory, muscleGroup: "Shoulders", sets: 3, reps: 15),
        .init(name: "Barbell Curl", type: .accessory, muscleGroup: "Arms", sets: 3, reps: 12),
        .init(name: "Hammer Curl", type: .accessory, muscleGroup: "Arms", sets: 3, reps: 12),
        .init(name: "Triceps Pushdown", type: .accessory, muscleGroup: "Arms", sets: 3, reps: 12),
        .init(name: "Leg Curl", type: .accessory, muscleGroup: "Legs", sets: 3, reps: 12),
        .init(name: "Calf Raise", type: .accessory, muscleGroup: "Legs", sets: 3, reps: 15),
        .init(name: "Plank", type: .accessory, muscleGroup: "Core", sets: 3, reps: 1),
        .init(name: "Hanging Leg Raise", type: .accessory, muscleGroup: "Core", sets: 3, reps: 12)
    ]

    /// 3-day full-body split, compound-first, with priority lifts woven in.
    static let templates: [WorkoutTemplate] = [
        WorkoutTemplate(
            title: "Full Body A",
            subtitle: "Squat focus",
            exercises: [
                .init(name: "Back Squat", sets: 3, reps: 5),
                .init(name: "Bench Press", sets: 3, reps: 5),
                .init(name: "Bent-Over Row", sets: 3, reps: 8),
                .init(name: "Romanian Deadlift", sets: 3, reps: 8),
                .init(name: "Plank", sets: 3, reps: 1)
            ]
        ),
        WorkoutTemplate(
            title: "Full Body B",
            subtitle: "Hinge focus",
            exercises: [
                .init(name: "Romanian Deadlift", sets: 3, reps: 8),
                .init(name: "Overhead Press", sets: 3, reps: 6),
                .init(name: "Pull-Up", sets: 3, reps: 8),
                .init(name: "Goblet Squat", sets: 3, reps: 10),
                .init(name: "Hanging Leg Raise", sets: 3, reps: 12)
            ]
        ),
        WorkoutTemplate(
            title: "Full Body C",
            subtitle: "Pull focus",
            exercises: [
                .init(name: "Deadlift", sets: 3, reps: 5),
                .init(name: "Incline Dumbbell Press", sets: 3, reps: 10),
                .init(name: "Lat Pulldown", sets: 3, reps: 10),
                .init(name: "Walking Lunge", sets: 3, reps: 12),
                .init(name: "Face Pull", sets: 3, reps: 15)
            ]
        )
    ]

    /// Mandatory ankle prep — every item must be checked before lifting.
    static let ankleWarmup: [String] = [
        "Ankle circles — 10 each direction",
        "Dorsiflexion knee-to-wall rocks — 2×10",
        "Banded eversion / inversion — 2×10",
        "Slow calf raises — 2×15",
        "5 min easy incline walk"
    ]
}
