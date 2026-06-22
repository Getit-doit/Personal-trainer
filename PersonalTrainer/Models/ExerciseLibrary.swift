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

/// A compound-first day template that belongs to a named program.
struct WorkoutTemplate: Identifiable {
    let id = UUID()
    let program: String
    let level: String
    let title: String
    let subtitle: String
    var minutes: Int = 45
    let exercises: [TemplateExercise]
}

/// Static training content: the exercise database (by equipment), the
/// full-body split, and the guided warm-up checklist.
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
        // MARK: Full Body (Beginner)
        WorkoutTemplate(program: "Full Body", level: "Beginner",
            title: "Full Body A", subtitle: "Squat focus", minutes: 50,
            exercises: [
                .init(name: "Back Squat", sets: 3, reps: 5),
                .init(name: "Bench Press", sets: 3, reps: 5),
                .init(name: "Bent-Over Row", sets: 3, reps: 8),
                .init(name: "Romanian Deadlift", sets: 3, reps: 8),
                .init(name: "Plank", sets: 3, reps: 1)
            ]),
        WorkoutTemplate(program: "Full Body", level: "Beginner",
            title: "Full Body B", subtitle: "Hinge focus", minutes: 50,
            exercises: [
                .init(name: "Romanian Deadlift", sets: 3, reps: 8),
                .init(name: "Overhead Press", sets: 3, reps: 6),
                .init(name: "Pull-Up", sets: 3, reps: 8),
                .init(name: "Goblet Squat", sets: 3, reps: 10),
                .init(name: "Hanging Leg Raise", sets: 3, reps: 12)
            ]),
        WorkoutTemplate(program: "Full Body", level: "Beginner",
            title: "Full Body C", subtitle: "Pull focus", minutes: 50,
            exercises: [
                .init(name: "Deadlift", sets: 3, reps: 5),
                .init(name: "Incline Dumbbell Press", sets: 3, reps: 10),
                .init(name: "Lat Pulldown", sets: 3, reps: 10),
                .init(name: "Walking Lunge", sets: 3, reps: 12),
                .init(name: "Face Pull", sets: 3, reps: 15)
            ]),

        // MARK: Push / Pull / Legs (Intermediate)
        WorkoutTemplate(program: "Push / Pull / Legs", level: "Intermediate",
            title: "Push", subtitle: "Chest · Shoulders · Triceps", minutes: 60,
            exercises: [
                .init(name: "Bench Press", sets: 4, reps: 6),
                .init(name: "Overhead Press", sets: 3, reps: 8),
                .init(name: "Incline Dumbbell Press", sets: 3, reps: 10),
                .init(name: "Lateral Raise", sets: 3, reps: 15),
                .init(name: "Triceps Pushdown", sets: 3, reps: 12)
            ]),
        WorkoutTemplate(program: "Push / Pull / Legs", level: "Intermediate",
            title: "Pull", subtitle: "Back · Biceps", minutes: 60,
            exercises: [
                .init(name: "Deadlift", sets: 3, reps: 5),
                .init(name: "Pull-Up", sets: 3, reps: 8),
                .init(name: "Bent-Over Row", sets: 3, reps: 10),
                .init(name: "Hammer Curl", sets: 3, reps: 12),
                .init(name: "Face Pull", sets: 3, reps: 15)
            ]),
        WorkoutTemplate(program: "Push / Pull / Legs", level: "Intermediate",
            title: "Legs", subtitle: "Quads · Hamstrings · Calves", minutes: 60,
            exercises: [
                .init(name: "Back Squat", sets: 4, reps: 6),
                .init(name: "Romanian Deadlift", sets: 3, reps: 8),
                .init(name: "Leg Press", sets: 3, reps: 12),
                .init(name: "Walking Lunge", sets: 3, reps: 12),
                .init(name: "Calf Raise", sets: 4, reps: 15)
            ]),

        // MARK: Upper / Lower (Intermediate)
        WorkoutTemplate(program: "Upper / Lower", level: "Intermediate",
            title: "Upper", subtitle: "Push + pull", minutes: 60,
            exercises: [
                .init(name: "Bench Press", sets: 4, reps: 6),
                .init(name: "Bent-Over Row", sets: 4, reps: 8),
                .init(name: "Overhead Press", sets: 3, reps: 8),
                .init(name: "Lat Pulldown", sets: 3, reps: 10),
                .init(name: "Barbell Curl", sets: 3, reps: 12)
            ]),
        WorkoutTemplate(program: "Upper / Lower", level: "Intermediate",
            title: "Lower", subtitle: "Legs + core", minutes: 60,
            exercises: [
                .init(name: "Back Squat", sets: 4, reps: 6),
                .init(name: "Romanian Deadlift", sets: 3, reps: 8),
                .init(name: "Leg Curl", sets: 3, reps: 12),
                .init(name: "Walking Lunge", sets: 3, reps: 12),
                .init(name: "Hanging Leg Raise", sets: 3, reps: 12)
            ]),

        // MARK: 5×5 Strength (Beginner)
        WorkoutTemplate(program: "5×5 Strength", level: "Beginner",
            title: "Workout A", subtitle: "Squat · Bench · Row", minutes: 40,
            exercises: [
                .init(name: "Back Squat", sets: 5, reps: 5),
                .init(name: "Bench Press", sets: 5, reps: 5),
                .init(name: "Bent-Over Row", sets: 5, reps: 5)
            ]),
        WorkoutTemplate(program: "5×5 Strength", level: "Beginner",
            title: "Workout B", subtitle: "Squat · Press · Deadlift", minutes: 40,
            exercises: [
                .init(name: "Back Squat", sets: 5, reps: 5),
                .init(name: "Overhead Press", sets: 5, reps: 5),
                .init(name: "Deadlift", sets: 3, reps: 5)
            ]),

        // MARK: Conditioning (Beginner)
        WorkoutTemplate(program: "Conditioning", level: "Beginner",
            title: "Quick HIIT", subtitle: "Low-impact circuit", minutes: 20,
            exercises: [
                .init(name: "Kettlebell Swing", sets: 4, reps: 15),
                .init(name: "Push-Up", sets: 4, reps: 15),
                .init(name: "Goblet Squat", sets: 4, reps: 15),
                .init(name: "Plank", sets: 4, reps: 1)
            ]),
        WorkoutTemplate(program: "Conditioning", level: "Beginner",
            title: "Cardio Finisher", subtitle: "Low-impact incline walk", minutes: 15,
            exercises: [
                .init(name: "Incline Walk", sets: 1, reps: 1)
            ]),

        // MARK: Express (30 min) — short, compound-focused
        WorkoutTemplate(program: "Express (30 min)", level: "Beginner",
            title: "Express Full Body", subtitle: "3 lifts + core", minutes: 30,
            exercises: [
                .init(name: "Goblet Squat", sets: 3, reps: 10),
                .init(name: "Dumbbell Bench Press", sets: 3, reps: 10),
                .init(name: "Dumbbell Row", sets: 3, reps: 10),
                .init(name: "Plank", sets: 3, reps: 1)
            ]),
        WorkoutTemplate(program: "Express (30 min)", level: "Beginner",
            title: "Express Lower", subtitle: "Quick legs", minutes: 30,
            exercises: [
                .init(name: "Back Squat", sets: 3, reps: 5),
                .init(name: "Romanian Deadlift", sets: 3, reps: 8),
                .init(name: "Calf Raise", sets: 3, reps: 15)
            ]),
        WorkoutTemplate(program: "Express (30 min)", level: "Beginner",
            title: "Express Upper", subtitle: "Quick push/pull", minutes: 30,
            exercises: [
                .init(name: "Bench Press", sets: 3, reps: 6),
                .init(name: "Lat Pulldown", sets: 3, reps: 10),
                .init(name: "Lateral Raise", sets: 3, reps: 15)
            ])
    ]

    /// Program names in display order.
    static var programs: [String] {
        var seen: [String] = []
        for t in templates where !seen.contains(t.program) { seen.append(t.program) }
        return seen
    }

    static func templates(in program: String) -> [WorkoutTemplate] {
        templates.filter { $0.program == program }
    }

    /// Distinct equipment used by a template, for badge display.
    private static let equipmentByName: [String: Equipment] =
        Dictionary(exercises.map { ($0.name, $0.equipment) }, uniquingKeysWith: { a, _ in a })

    static func equipment(in template: WorkoutTemplate) -> [Equipment] {
        var seen: [Equipment] = []
        for ex in template.exercises {
            if let eq = equipmentByName[ex.name], !seen.contains(eq) { seen.append(eq) }
        }
        return seen.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Guided warm-up — every item is checked before lifting.
    static let generalWarmup: [String] = [
        "5 min easy cardio (walk, bike, or row)",
        "Leg swings — 10 each leg, front & side",
        "Hip circles & bodyweight squats — 2×10",
        "Arm circles & band pull-aparts — 2×15",
        "Ankle circles & calf raises — 2×15",
        "1–2 light warm-up sets of your first lift"
    ]
}
