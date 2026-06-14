import SwiftUI
import SwiftData

/// The live workout screen: ankle warm-up gate → exercise/set logging with
/// RPE & reps-in-tank → low-impact cardio finisher → steam room / notes / finish.
struct ActiveSessionView: View {
    @Environment(\.modelContext) private var context
    @Bindable var session: WorkoutSession
    @Query private var existingPRs: [PersonalBest]

    @State private var showingPicker = false
    @State private var newPRBanner: [String] = []

    var body: some View {
        List {
            warmupSection

            if session.ankleWarmupDone {
                ForEach(session.sortedExercises) { exercise in
                    exerciseSection(exercise)
                }
                addExerciseSection
                cardioSection
                finishSection
            }
        }
        .navigationTitle(session.notes.isEmpty ? "Workout" : session.notes)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPicker) {
            ExercisePickerView { exercise in
                SessionFactory.add(exercise, to: session, context: context)
            }
        }
        .alert(
            "New PR! 🎉",
            isPresented: Binding(
                get: { !newPRBanner.isEmpty },
                set: { if !$0 { newPRBanner = [] } }
            )
        ) {
            Button("Nice") {}
        } message: {
            Text(newPRBanner.joined(separator: ", "))
        }
    }

    // MARK: Warm-up gate

    private var warmupSection: some View {
        Section {
            if session.ankleWarmupDone {
                Label("Ankle warm-up complete", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Theme.accent)
            } else {
                ForEach(TrainingContent.ankleWarmup, id: \.self) { item in
                    WarmupRow(text: item)
                }
                Button {
                    session.ankleWarmupDone = true
                    try? context.save()
                } label: {
                    Text("Mark warm-up done — unlock logging")
                        .frame(maxWidth: .infinity).bold()
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
            }
        } header: {
            Label("Required Ankle Warm-up", systemImage: "figure.walk")
        } footer: {
            if !session.ankleWarmupDone {
                Text("Logging is locked until the ankle warm-up is done. The ankle inflames easily — don't skip it.")
            }
        }
    }

    // MARK: Exercises

    @ViewBuilder
    private func exerciseSection(_ exercise: LoggedExercise) -> some View {
        Section {
            ForEach(exercise.sortedSets) { set in
                SetRow(set: set) { try? context.save() }
            }
            .onDelete { offsets in
                let sorted = exercise.sortedSets
                for index in offsets { context.delete(sorted[index]) }
                try? context.save()
            }
            Button { addSet(to: exercise) } label: {
                Label("Add Set", systemImage: "plus").font(.caption)
            }
            .tint(Theme.accent)
        } header: {
            HStack {
                Circle().fill(Theme.color(for: exercise.muscleGroup)).frame(width: 8, height: 8)
                Text(exercise.name)
                Spacer()
                Text(exercise.type.rawValue).font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    private var addExerciseSection: some View {
        Section {
            Button { showingPicker = true } label: {
                Label("Add Exercise", systemImage: "plus.circle.fill")
            }
            .tint(Theme.accent)
        }
    }

    // MARK: Cardio finisher

    private var cardioSection: some View {
        Section {
            if let cardio = session.cardio {
                CardioEditor(cardio: cardio) { try? context.save() }
                Button(role: .destructive) {
                    session.cardio = nil
                    context.delete(cardio)
                    try? context.save()
                } label: { Label("Remove Cardio", systemImage: "trash") }
            } else {
                Button {
                    let cardio = CardioEntry()
                    cardio.session = session
                    context.insert(cardio)
                    try? context.save()
                } label: {
                    Label("Add Low-Impact Finisher", systemImage: "figure.walk.motion")
                }
                .tint(Theme.accent)
            }
        } header: {
            Label("Cardio Finisher", systemImage: "heart.fill")
        } footer: {
            Text("Defaults to incline walking. Add incline, stairs, or sprints gradually and watch ankle load.")
        }
    }

    // MARK: Finish

    private var finishSection: some View {
        Section {
            Toggle("Steam room after", isOn: $session.steamRoom)
                .onChange(of: session.steamRoom) { try? context.save() }
            TextField("Session notes", text: $session.notes, axis: .vertical)
                .lineLimit(1...4)
                .onChange(of: session.notes) { try? context.save() }
            HStack {
                Text("Total Volume"); Spacer()
                Text("\(session.totalVolume.clean) lb").bold()
            }
            Button {
                finish()
            } label: {
                Text(session.isFinished ? "Finished ✓" : "Finish Workout")
                    .frame(maxWidth: .infinity).bold()
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
            .disabled(session.isFinished)
        }
    }

    private func addSet(to exercise: LoggedExercise) {
        let last = exercise.sortedSets.last
        let set = SetLog(
            weight: last?.weight ?? 0,
            reps: last?.reps ?? exercise.exercise?.targetReps ?? 8,
            rpe: last?.rpe ?? 7,
            repsInTank: last?.repsInTank ?? 2,
            order: exercise.sets.count
        )
        set.exercise = exercise
        context.insert(set)
        try? context.save()
    }

    private func finish() {
        session.isFinished = true
        let prs = PRService.detectPRs(in: session, existing: existingPRs) { context.insert($0) }
        try? context.save()
        if !prs.isEmpty { newPRBanner = prs }
    }
}

/// A tappable warm-up checklist item.
struct WarmupRow: View {
    let text: String
    @State private var done = false

    var body: some View {
        Button { done.toggle() } label: {
            HStack {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(done ? Theme.accent : .secondary)
                Text(text).foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

/// One editable set: completion, weight, reps, RPE, reps-in-tank.
struct SetRow: View {
    @Bindable var set: SetLog
    var onChange: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Button {
                    set.isCompleted.toggle(); onChange()
                } label: {
                    Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(set.isCompleted ? Theme.accent : .secondary)
                }
                .buttonStyle(.plain)

                field(value: $set.weight, unit: "lb", width: 56, decimal: true)
                Text("×").foregroundStyle(.secondary)
                intField(value: $set.reps, unit: "reps", width: 40)
                Spacer()
            }
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Text("RPE").font(.caption2).foregroundStyle(.secondary)
                    TextField("RPE", value: $set.rpe, format: .number)
                        .keyboardType(.decimalPad).frame(width: 36).multilineTextAlignment(.center)
                }
                HStack(spacing: 4) {
                    Text("Reps in tank").font(.caption2).foregroundStyle(.secondary)
                    Stepper("\(set.repsInTank)", value: $set.repsInTank, in: 0...6)
                        .fixedSize()
                }
                Spacer()
            }
            .font(.caption)
        }
        .onChange(of: set.weight) { onChange() }
        .onChange(of: set.reps) { onChange() }
        .onChange(of: set.rpe) { onChange() }
        .onChange(of: set.repsInTank) { onChange() }
    }

    private func field(value: Binding<Double>, unit: String, width: CGFloat, decimal: Bool) -> some View {
        HStack(spacing: 4) {
            TextField(unit, value: value, format: .number)
                .keyboardType(decimal ? .decimalPad : .numberPad)
                .frame(width: width).multilineTextAlignment(.center)
            Text(unit).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func intField(value: Binding<Int>, unit: String, width: CGFloat) -> some View {
        HStack(spacing: 4) {
            TextField(unit, value: value, format: .number)
                .keyboardType(.numberPad)
                .frame(width: width).multilineTextAlignment(.center)
            Text(unit).font(.caption2).foregroundStyle(.secondary)
        }
    }
}

/// Editor for the low-impact cardio finisher.
struct CardioEditor: View {
    @Bindable var cardio: CardioEntry
    var onChange: () -> Void

    var body: some View {
        Group {
            TextField("Modality", text: $cardio.modality)
            HStack {
                Text("Duration"); Spacer()
                Stepper("\(cardio.durationMinutes.clean) min", value: $cardio.durationMinutes, in: 0...90, step: 5).fixedSize()
            }
            HStack {
                Text("Speed"); Spacer()
                Stepper("\(cardio.speed.clean) mph", value: $cardio.speed, in: 0...10, step: 0.1).fixedSize()
            }
            HStack {
                Text("Incline"); Spacer()
                Stepper("\(cardio.incline.clean)%", value: $cardio.incline, in: 0...20, step: 0.5).fixedSize()
            }
            Picker("Ankle load", selection: $cardio.ankleLoadRaw) {
                ForEach(AnkleLoad.allCases, id: \.rawValue) { load in
                    Text(load.rawValue).tag(load.rawValue)
                }
            }
        }
        .onChange(of: cardio.modality) { onChange() }
        .onChange(of: cardio.durationMinutes) { onChange() }
        .onChange(of: cardio.speed) { onChange() }
        .onChange(of: cardio.incline) { onChange() }
        .onChange(of: cardio.ankleLoadRaw) { onChange() }
    }
}
