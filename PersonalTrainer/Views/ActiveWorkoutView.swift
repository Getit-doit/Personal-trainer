import SwiftUI
import SwiftData

/// The screen for logging exercises and sets within a single session.
struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var context
    @Bindable var session: WorkoutSession
    @State private var showingPicker = false

    private var sortedExercises: [LoggedExercise] {
        session.exercises.sorted { $0.order < $1.order }
    }

    var body: some View {
        List {
            Section {
                TextField("Workout name", text: $session.name)
                    .font(.headline)
                DatePicker("Date", selection: $session.date)
            }

            ForEach(sortedExercises) { exercise in
                exerciseSection(exercise)
            }

            Section {
                Button {
                    showingPicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus.circle.fill")
                }
                .tint(Theme.accent)
            }

            if !session.exercises.isEmpty {
                Section {
                    HStack {
                        Text("Total Volume")
                        Spacer()
                        Text("\(session.totalVolume.clean) lb").bold()
                    }
                    Button {
                        session.isFinished = true
                        try? context.save()
                    } label: {
                        Text(session.isFinished ? "Finished ✓" : "Finish Workout")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                    .disabled(session.isFinished)
                }
            }
        }
        .navigationTitle(session.name.isEmpty ? "Workout" : session.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPicker) {
            ExercisePickerView { info in
                addExercise(info)
            }
        }
        .onChange(of: session.name) { try? context.save() }
        .onChange(of: session.date) { try? context.save() }
    }

    @ViewBuilder
    private func exerciseSection(_ exercise: LoggedExercise) -> some View {
        Section {
            ForEach(exercise.sortedSets) { set in
                SetRow(set: set, onChange: { try? context.save() })
            }
            .onDelete { offsets in
                let sorted = exercise.sortedSets
                for index in offsets { context.delete(sorted[index]) }
                try? context.save()
            }

            Button {
                addSet(to: exercise)
            } label: {
                Label("Add Set", systemImage: "plus")
                    .font(.caption)
            }
            .tint(Theme.accent)
        } header: {
            HStack {
                Circle()
                    .fill(Theme.color(for: exercise.muscleGroup))
                    .frame(width: 8, height: 8)
                Text(exercise.name)
                Spacer()
                Text(exercise.muscleGroup)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func addExercise(_ info: ExerciseInfo) {
        let exercise = LoggedExercise(
            name: info.name,
            muscleGroup: info.muscleGroup,
            order: session.exercises.count
        )
        exercise.session = session
        context.insert(exercise)
        // Seed with one empty set to start.
        let set = SetEntry(order: 0)
        set.exercise = exercise
        context.insert(set)
        try? context.save()
    }

    private func addSet(to exercise: LoggedExercise) {
        let last = exercise.sortedSets.last
        let set = SetEntry(
            reps: last?.reps ?? 10,
            weight: last?.weight ?? 0,
            order: exercise.sets.count
        )
        set.exercise = exercise
        context.insert(set)
        try? context.save()
    }
}

/// One editable set row: a completion toggle, reps, and weight.
struct SetRow: View {
    @Bindable var set: SetEntry
    var onChange: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                set.isCompleted.toggle()
                onChange()
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(set.isCompleted ? Theme.accent : .secondary)
            }
            .buttonStyle(.plain)

            HStack(spacing: 4) {
                TextField("Reps", value: $set.reps, format: .number)
                    .keyboardType(.numberPad)
                    .frame(width: 44)
                    .multilineTextAlignment(.center)
                Text("reps").font(.caption2).foregroundStyle(.secondary)
            }

            HStack(spacing: 4) {
                TextField("Weight", value: $set.weight, format: .number)
                    .keyboardType(.decimalPad)
                    .frame(width: 56)
                    .multilineTextAlignment(.center)
                Text("lb").font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .onChange(of: set.reps) { onChange() }
        .onChange(of: set.weight) { onChange() }
    }
}
