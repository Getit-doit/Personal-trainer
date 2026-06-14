import SwiftUI
import SwiftData

/// Browse the built-in workout plans and start one as a logged session.
struct PlansView: View {
    @Environment(\.modelContext) private var context
    @State private var startedSession: WorkoutSession?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(ExerciseLibrary.plans) { plan in
                        PlanCard(plan: plan) {
                            start(plan)
                        }
                    }
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Plans")
            .navigationDestination(item: $startedSession) { session in
                ActiveWorkoutView(session: session)
            }
        }
    }

    /// Turns a plan into a fresh, ready-to-log session and opens it.
    private func start(_ plan: WorkoutPlan) {
        let session = WorkoutSession(name: plan.title)
        context.insert(session)

        for (exerciseIndex, planExercise) in plan.exercises.enumerated() {
            let exercise = LoggedExercise(
                name: planExercise.name,
                muscleGroup: planExercise.muscleGroup,
                order: exerciseIndex
            )
            exercise.session = session
            context.insert(exercise)
            for setIndex in 0..<planExercise.sets {
                let set = SetEntry(reps: planExercise.reps, weight: 0, order: setIndex)
                set.exercise = exercise
                context.insert(set)
            }
        }
        try? context.save()
        startedSession = session
    }
}

struct PlanCard: View {
    let plan: WorkoutPlan
    var onStart: () -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.title).font(.title3).bold()
                        Text(plan.subtitle)
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(plan.level)
                        .font(.caption2).bold()
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Theme.color(for: plan.focus).opacity(0.2), in: Capsule())
                        .foregroundStyle(Theme.color(for: plan.focus))
                }

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(plan.exercises, id: \.name) { ex in
                        HStack {
                            Circle()
                                .fill(Theme.color(for: ex.muscleGroup))
                                .frame(width: 6, height: 6)
                            Text(ex.name).font(.subheadline)
                            Spacer()
                            Text("\(ex.sets) × \(ex.reps)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                Button(action: onStart) {
                    Text("Start Workout")
                        .frame(maxWidth: .infinity)
                        .bold()
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
            }
        }
    }
}
