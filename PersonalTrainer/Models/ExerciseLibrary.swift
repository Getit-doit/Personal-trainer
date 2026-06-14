import Foundation

/// A catalog entry used to pick exercises when building a workout.
struct ExerciseInfo: Identifiable, Hashable {
    let name: String
    let muscleGroup: String
    var id: String { name }
}

/// A reusable, pre-built routine the user can start with one tap.
struct WorkoutPlan: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let level: String          // Beginner / Intermediate / Advanced
    let focus: String          // primary muscle focus
    let exercises: [PlanExercise]
}

struct PlanExercise: Hashable {
    let name: String
    let muscleGroup: String
    let sets: Int
    let reps: Int
}

/// Static content: the exercise catalog and the built-in plans.
enum ExerciseLibrary {
    static let all: [ExerciseInfo] = [
        // Chest
        .init(name: "Bench Press", muscleGroup: "Chest"),
        .init(name: "Incline Dumbbell Press", muscleGroup: "Chest"),
        .init(name: "Push-Up", muscleGroup: "Chest"),
        .init(name: "Cable Fly", muscleGroup: "Chest"),
        // Back
        .init(name: "Deadlift", muscleGroup: "Back"),
        .init(name: "Pull-Up", muscleGroup: "Back"),
        .init(name: "Bent-Over Row", muscleGroup: "Back"),
        .init(name: "Lat Pulldown", muscleGroup: "Back"),
        // Legs
        .init(name: "Back Squat", muscleGroup: "Legs"),
        .init(name: "Romanian Deadlift", muscleGroup: "Legs"),
        .init(name: "Leg Press", muscleGroup: "Legs"),
        .init(name: "Walking Lunge", muscleGroup: "Legs"),
        .init(name: "Calf Raise", muscleGroup: "Legs"),
        // Shoulders
        .init(name: "Overhead Press", muscleGroup: "Shoulders"),
        .init(name: "Lateral Raise", muscleGroup: "Shoulders"),
        .init(name: "Face Pull", muscleGroup: "Shoulders"),
        // Arms
        .init(name: "Barbell Curl", muscleGroup: "Arms"),
        .init(name: "Hammer Curl", muscleGroup: "Arms"),
        .init(name: "Triceps Pushdown", muscleGroup: "Arms"),
        .init(name: "Skull Crusher", muscleGroup: "Arms"),
        // Core
        .init(name: "Plank", muscleGroup: "Core"),
        .init(name: "Hanging Leg Raise", muscleGroup: "Core"),
        .init(name: "Cable Crunch", muscleGroup: "Core"),
        // Cardio
        .init(name: "Treadmill Run", muscleGroup: "Cardio"),
        .init(name: "Rowing Machine", muscleGroup: "Cardio"),
        .init(name: "Jump Rope", muscleGroup: "Cardio")
    ]

    static let muscleGroups: [String] = [
        "Chest", "Back", "Legs", "Shoulders", "Arms", "Core", "Cardio"
    ]

    static let plans: [WorkoutPlan] = [
        WorkoutPlan(
            title: "Full Body Starter",
            subtitle: "3 days/week · ~45 min",
            level: "Beginner",
            focus: "Full Body",
            exercises: [
                .init(name: "Back Squat", muscleGroup: "Legs", sets: 3, reps: 8),
                .init(name: "Bench Press", muscleGroup: "Chest", sets: 3, reps: 8),
                .init(name: "Bent-Over Row", muscleGroup: "Back", sets: 3, reps: 10),
                .init(name: "Overhead Press", muscleGroup: "Shoulders", sets: 3, reps: 10),
                .init(name: "Plank", muscleGroup: "Core", sets: 3, reps: 1)
            ]
        ),
        WorkoutPlan(
            title: "Push Day",
            subtitle: "Chest · Shoulders · Triceps",
            level: "Intermediate",
            focus: "Chest",
            exercises: [
                .init(name: "Bench Press", muscleGroup: "Chest", sets: 4, reps: 6),
                .init(name: "Incline Dumbbell Press", muscleGroup: "Chest", sets: 3, reps: 10),
                .init(name: "Overhead Press", muscleGroup: "Shoulders", sets: 3, reps: 8),
                .init(name: "Lateral Raise", muscleGroup: "Shoulders", sets: 3, reps: 15),
                .init(name: "Triceps Pushdown", muscleGroup: "Arms", sets: 3, reps: 12)
            ]
        ),
        WorkoutPlan(
            title: "Pull Day",
            subtitle: "Back · Biceps",
            level: "Intermediate",
            focus: "Back",
            exercises: [
                .init(name: "Deadlift", muscleGroup: "Back", sets: 4, reps: 5),
                .init(name: "Pull-Up", muscleGroup: "Back", sets: 3, reps: 8),
                .init(name: "Bent-Over Row", muscleGroup: "Back", sets: 3, reps: 10),
                .init(name: "Barbell Curl", muscleGroup: "Arms", sets: 3, reps: 12),
                .init(name: "Hammer Curl", muscleGroup: "Arms", sets: 3, reps: 12)
            ]
        ),
        WorkoutPlan(
            title: "Leg Day",
            subtitle: "Quads · Hamstrings · Calves",
            level: "Advanced",
            focus: "Legs",
            exercises: [
                .init(name: "Back Squat", muscleGroup: "Legs", sets: 5, reps: 5),
                .init(name: "Romanian Deadlift", muscleGroup: "Legs", sets: 3, reps: 8),
                .init(name: "Leg Press", muscleGroup: "Legs", sets: 3, reps: 12),
                .init(name: "Walking Lunge", muscleGroup: "Legs", sets: 3, reps: 20),
                .init(name: "Calf Raise", muscleGroup: "Legs", sets: 4, reps: 15)
            ]
        ),
        WorkoutPlan(
            title: "Quick HIIT",
            subtitle: "20 min · fat burn",
            level: "Beginner",
            focus: "Cardio",
            exercises: [
                .init(name: "Jump Rope", muscleGroup: "Cardio", sets: 4, reps: 1),
                .init(name: "Push-Up", muscleGroup: "Chest", sets: 4, reps: 15),
                .init(name: "Walking Lunge", muscleGroup: "Legs", sets: 4, reps: 20),
                .init(name: "Plank", muscleGroup: "Core", sets: 4, reps: 1)
            ]
        )
    ]
}
