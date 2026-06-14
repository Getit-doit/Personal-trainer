import Foundation

/// Seed definition for a catalog exercise.
struct ExerciseSeed {
    let name: String
    let type: ExerciseType
    let muscleGroup: String
    let equipment: Equipment
    var priority: Bool = false
    var sets: Int = 3
    var reps: Int = 10
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

/// Static training content: the exercise database (by equipment), the 3-day
/// full-body split, and the mandatory ankle warm-up checklist.
enum TrainingContent {

    static let muscleGroups = ["Legs", "Hinge", "Chest", "Back", "Shoulders", "Arms", "Core"]

    /// The exercise database — compound-first, tagged by equipment & muscle.
    static let exercises: [ExerciseSeed] = [
        // MARK: Barbell
        .init(name: "Deadlift", type: .compound, muscleGroup: "Hinge", equipment: .barbell, sets: 3, reps: 5, increment: 10),
        .init(name: "Romanian Deadlift", type: .compound, muscleGroup: "Hinge", equipment: .barbell, priority: true, sets: 3, reps: 8, increment: 10),
        .init(name: "Trap Bar Deadlift", type: .compound, muscleGroup: "Hinge", equipment: .barbell, sets: 3, reps: 5, increment: 10),
        .init(name: "Bent-Over Row", type: .compound, muscleGroup: "Back", equipment: .barbell, sets: 3, reps: 8),
        .init(name: "Barbell Hip Thrust", type: .compound, muscleGroup: "Hinge", equipment: .barbell, sets: 3, reps: 10, increment: 10),
        .init(name: "Barbell Curl", type: .accessory, muscleGroup: "Arms", equipment: .barbell, sets: 3, reps: 12),
        .init(name: "Barbell Shrug", type: .accessory, muscleGroup: "Back", equipment: .barbell, sets: 3, reps: 12),

        // MARK: Squat Rack
        .init(name: "Back Squat", type: .compound, muscleGroup: "Legs", equipment: .squatRack, sets: 3, reps: 5, increment: 10),
        .init(name: "Front Squat", type: .compound, muscleGroup: "Legs", equipment: .squatRack, sets: 3, reps: 5),
        .init(name: "Overhead Press", type: .compound, muscleGroup: "Shoulders", equipment: .squatRack, sets: 3, reps: 6),
        .init(name: "Pin Press", type: .compound, muscleGroup: "Chest", equipment: .squatRack, sets: 3, reps: 5),
        .init(name: "Rack Pull", type: .compound, muscleGroup: "Hinge", equipment: .squatRack, sets: 3, reps: 6, increment: 10),

        // MARK: Bench
        .init(name: "Bench Press", type: .compound, muscleGroup: "Chest", equipment: .bench, sets: 3, reps: 5),
        .init(name: "Incline Bench Press", type: .compound, muscleGroup: "Chest", equipment: .bench, sets: 3, reps: 8),
        .init(name: "Close-Grip Bench Press", type: .compound, muscleGroup: "Arms", equipment: .bench, sets: 3, reps: 8),
        .init(name: "Dumbbell Bench Press", type: .accessory, muscleGroup: "Chest", equipment: .bench, sets: 3, reps: 10),

        // MARK: Dumbbell
        .init(name: "Goblet Squat", type: .compound, muscleGroup: "Legs", equipment: .dumbbell, priority: true, sets: 3, reps: 10),
        .init(name: "Incline Dumbbell Press", type: .accessory, muscleGroup: "Chest", equipment: .dumbbell, sets: 3, reps: 10),
        .init(name: "Dumbbell Row", type: .accessory, muscleGroup: "Back", equipment: .dumbbell, sets: 3, reps: 10),
        .init(name: "Dumbbell Shoulder Press", type: .accessory, muscleGroup: "Shoulders", equipment: .dumbbell, sets: 3, reps: 10),
        .init(name: "Lateral Raise", type: .accessory, muscleGroup: "Shoulders", equipment: .dumbbell, sets: 3, reps: 15),
        .init(name: "Hammer Curl", type: .accessory, muscleGroup: "Arms", equipment: .dumbbell, sets: 3, reps: 12),
        .init(name: "Walking Lunge", type: .compound, muscleGroup: "Legs", equipment: .dumbbell, sets: 3, reps: 12),
        .init(name: "Bulgarian Split Squat", type: .compound, muscleGroup: "Legs", equipment: .dumbbell, sets: 3, reps: 10),

        // MARK: Kettlebell
        .init(name: "Kettlebell Swing", type: .compound, muscleGroup: "Hinge", equipment: .kettlebell, sets: 4, reps: 15),
        .init(name: "Goblet Squat (KB)", type: .compound, muscleGroup: "Legs", equipment: .kettlebell, sets: 3, reps: 10),
        .init(name: "Kettlebell Carry", type: .accessory, muscleGroup: "Core", equipment: .kettlebell, sets: 3, reps: 1),
        .init(name: "Turkish Get-Up", type: .compound, muscleGroup: "Core", equipment: .kettlebell, sets: 3, reps: 3),

        // MARK: Cable
        .init(name: "Lat Pulldown", type: .accessory, muscleGroup: "Back", equipment: .cable, sets: 3, reps: 10),
        .init(name: "Seated Cable Row", type: .accessory, muscleGroup: "Back", equipment: .cable, sets: 3, reps: 10),
        .init(name: "Triceps Pushdown", type: .accessory, muscleGroup: "Arms", equipment: .cable, sets: 3, reps: 12),
        .init(name: "Cable Fly", type: .accessory, muscleGroup: "Chest", equipment: .cable, sets: 3, reps: 12),
        .init(name: "Face Pull", type: .accessory, muscleGroup: "Shoulders", equipment: .cable, sets: 3, reps: 15),
        .init(name: "Cable Crunch", type: .accessory, muscleGroup: "Core", equipment: .cable, sets: 3, reps: 15),

        // MARK: Machine
        .init(name: "Leg Press", type: .compound, muscleGroup: "Legs", equipment: .machine, sets: 3, reps: 12, increment: 10),
        .init(name: "Leg Curl", type: .accessory, muscleGroup: "Legs", equipment: .machine, sets: 3, reps: 12),
        .init(name: "Leg Extension", type: .accessory, muscleGroup: "Legs", equipment: .machine, sets: 3, reps: 15),
        .init(name: "Calf Raise", type: .accessory, muscleGroup: "Legs", equipment: .machine, sets: 4, reps: 15),
        .init(name: "Chest Press Machine", type: .accessory, muscleGroup: "Chest", equipment: .machine, sets: 3, reps: 12),
        .init(name: "Pec Deck", type: .accessory, muscleGroup: "Chest", equipment: .machine, sets: 3, reps: 15),

        // MARK: Bodyweight
        .init(name: "Pull-Up", type: .compound, muscleGroup: "Back", equipment: .bodyweight, sets: 3, reps: 8),
        .init(name: "Chin-Up", type: .compound, muscleGroup: "Back", equipment: .bodyweight, sets: 3, reps: 8),
        .init(name: "Push-Up", type: .accessory, muscleGroup: "Chest", equipment: .bodyweight, sets: 3, reps: 15),
        .init(name: "Dip", type: .compound, muscleGroup: "Chest", equipment: .bodyweight, sets: 3, reps: 10),
        .init(name: "Plank", type: .accessory, muscleGroup: "Core", equipment: .bodyweight, sets: 3, reps: 1),
        .init(name: "Hanging Leg Raise", type: .accessory, muscleGroup: "Core", equipment: .bodyweight, sets: 3, reps: 12),

        // MARK: Cardio
        .init(name: "Incline Walk", type: .accessory, muscleGroup: "Cardio", equipment: .treadmill, sets: 1, reps: 1),
        .init(name: "Treadmill Run", type: .accessory, muscleGroup: "Cardio", equipment: .treadmill, sets: 1, reps: 1),
        .init(name: "Rowing Machine", type: .accessory, muscleGroup: "Cardio", equipment: .treadmill, sets: 1, reps: 1),
        .init(name: "Stair Climber", type: .accessory, muscleGroup: "Cardio", equipment: .treadmill, sets: 1, reps: 1)
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
