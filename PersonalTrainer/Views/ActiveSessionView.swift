import SwiftUI
import SwiftData

/// The live workout screen: ankle warm-up gate → exercise/set logging with
/// RPE & reps-in-tank → low-impact cardio finisher → steam room / notes / finish.
struct ActiveSessionView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var health: HealthService
    @Bindable var session: WorkoutSession
    @Query private var existingPRs: [PersonalBest]

    @State private var showingPicker = false
    @State private var newPRBanner: [String] = []

    // Rest timer + Apple Music
    @StateObject private var rest = RestTimer()
    @StateObject private var music = MusicService()
    @State private var showingPlaylistPicker = false
    @AppStorage("workoutPlaylistID") private var playlistID = ""
    @AppStorage("workoutPlaylistName") private var playlistName = ""

    // Drop sets
    @State private var dropSetTarget: LoggedExercise?
    @State private var isSaving = false

    // Rest timer settings (editable in Profile)
    @AppStorage("restCompound") private var restCompound = 180
    @AppStorage("restAccessory") private var restAccessory = 90
    @AppStorage("autoStartRest") private var autoStartRest = true

    var body: some View {
        List {
            musicSection
            warmupSection

            if session.ankleWarmupDone {
                ForEach(session.sortedExercises) { exercise in
                    exerciseSection(exercise)
                }
                addExerciseSection
                restPresetSection
                cardioSection
                finishSection
            }
        }
        .scrollContentBackground(.hidden)
        .listRowBackground(Color.clear)
        .blueprintBackground()
        .barLoadingOverlay(isSaving, label: "Saving to Health…")
        .navigationTitle(session.notes.isEmpty ? "Workout" : session.notes)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if rest.isActive {
                RestTimerBar(rest: rest)
            }
        }
        .sheet(isPresented: $showingPicker) {
            ExercisePickerView { exercise in
                SessionFactory.add(exercise, to: session, context: context)
            }
        }
        .sheet(isPresented: $showingPlaylistPicker) {
            PlaylistPickerView(music: music) { selected in
                playlistID = selected.id
                playlistName = selected.name
                music.play(playlistID: selected.id)
            }
        }
        .sheet(item: $dropSetTarget) { exercise in
            DropSetSheet(startWeight: exercise.sortedSets.last?.weight ?? 45) { start, drop, end in
                addDropSet(to: exercise, start: start, drop: drop, end: end)
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

    // MARK: Music

    private var musicSection: some View {
        Section {
            if playlistID.isEmpty {
                Button {
                    showingPlaylistPicker = true
                } label: {
                    Label("Choose Workout Playlist", systemImage: "music.note.list")
                }
                .tint(Theme.accent)
            } else {
                HStack(spacing: 16) {
                    Button {
                        music.play(playlistID: playlistID)
                    } label: {
                        Image(systemName: "play.circle.fill").font(.title2)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(playlistName).font(.subheadline).bold()
                        Text(music.nowPlaying.isEmpty ? "Tap play to start" : music.nowPlaying)
                            .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                    Spacer()
                    Button { music.togglePlayPause() } label: {
                        Image(systemName: music.isPlaying ? "pause.fill" : "play.fill")
                    }
                    Button { music.skip() } label: {
                        Image(systemName: "forward.fill")
                    }
                }
                .buttonStyle(.plain)
                .tint(Theme.accentDeep)
            }
        } header: {
            HStack {
                Label("Music", systemImage: "music.note")
                Spacer()
                if !playlistID.isEmpty {
                    Button("Change") { showingPlaylistPicker = true }
                        .font(.caption)
                }
            }
        }
    }

    // MARK: Rest presets

    private var restPresetSection: some View {
        Section {
            HStack {
                ForEach(restPresets, id: \.self) { seconds in
                    Button {
                        rest.start(seconds: seconds)
                    } label: {
                        Text(restLabel(seconds))
                            .font(.caption).bold()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Theme.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(Theme.accentDeep)
                    }
                    .buttonStyle(.plain)
                }
            }
        } header: {
            Label("Rest Timer", systemImage: "timer")
        } footer: {
            Text(autoStartRest
                 ? "Auto-starts when you complete a set: \(restLabel(restCompound)) after compounds, \(restLabel(restAccessory)) after accessories. Change these in Profile."
                 : "Auto-start is off — tap a preset to start a rest. Change this in Profile.")
        }
    }

    private func restLabel(_ seconds: Int) -> String {
        seconds < 60 ? "\(seconds)s" : (seconds % 60 == 0 ? "\(seconds / 60)m" : "\(seconds / 60)m\(seconds % 60)")
    }

    private func defaultRest(for type: ExerciseType) -> Int {
        type == .compound ? restCompound : restAccessory
    }

    /// Preset chips reflect the user's configured rest times.
    private var restPresets: [Int] {
        Array(Set([60, 90, 120, restAccessory, restCompound])).sorted()
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
                        .foregroundStyle(Theme.blueprintDeep)
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
                SetRow(
                    set: set,
                    onChange: { try? context.save() },
                    onComplete: { handleSetCompleted(set, in: exercise) }
                )
            }
            .onDelete { offsets in
                let sorted = exercise.sortedSets
                for index in offsets { context.delete(sorted[index]) }
                try? context.save()
            }
            HStack {
                Button { addSet(to: exercise) } label: {
                    Label("Add Set", systemImage: "plus").font(.caption)
                }
                Spacer()
                Button { dropSetTarget = exercise } label: {
                    Label("Drop Set", systemImage: "arrow.down.right.circle").font(.caption)
                }
            }
            .tint(Theme.accent)
        } header: {
            HStack(spacing: 6) {
                exercise.equipment.image
                    .resizable().scaledToFit().frame(width: 18, height: 18)
                    .foregroundStyle(Theme.accent)
                Text(exercise.name)
                if exercise.supersetID != nil {
                    Text("SUPERSET")
                        .font(.system(size: 9)).bold()
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(Theme.accent.opacity(0.2), in: Capsule())
                        .foregroundStyle(Theme.accentDeep)
                }
                Spacer()
                supersetMenu(exercise)
            }
        }
    }

    /// Per-exercise actions: link/unlink supersets.
    private func supersetMenu(_ exercise: LoggedExercise) -> some View {
        Menu {
            if exercise.supersetID == nil {
                Button {
                    linkSupersetWithNext(exercise)
                } label: { Label("Superset with next", systemImage: "link") }
                    .disabled(isLastExercise(exercise))
            } else {
                Button {
                    unlinkSuperset(exercise)
                } label: { Label("Remove from superset", systemImage: "link.badge.minus") }
            }
        } label: {
            Image(systemName: "ellipsis.circle").foregroundStyle(.secondary)
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
                    .foregroundStyle(Theme.blueprintDeep)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
            .disabled(session.isFinished)
        }
    }

    // MARK: Superset + drop-set behavior

    /// Decides whether finishing a set should trigger rest. No rest is taken
    /// between consecutive drop-set stages, or mid-superset (rest comes after
    /// the last exercise in the group).
    private func handleSetCompleted(_ set: SetLog, in exercise: LoggedExercise) {
        guard autoStartRest else { return }
        let sets = exercise.sortedSets
        if set.isDropSet,
           let index = sets.firstIndex(where: { $0.persistentModelID == set.persistentModelID }),
           index + 1 < sets.count,
           sets[index + 1].isDropSet {
            return                                  // keep dropping, no rest
        }
        if let group = exercise.supersetID, !isLastInSuperset(exercise, group: group) {
            return                                  // next superset exercise, no rest
        }
        rest.start(seconds: defaultRest(for: exercise.type), exerciseName: exercise.name)
    }

    private func isLastInSuperset(_ exercise: LoggedExercise, group: String) -> Bool {
        let maxOrder = session.exercises.filter { $0.supersetID == group }.map(\.order).max() ?? exercise.order
        return exercise.order >= maxOrder
    }

    private func isLastExercise(_ exercise: LoggedExercise) -> Bool {
        (session.sortedExercises.last?.persistentModelID == exercise.persistentModelID)
    }

    private func linkSupersetWithNext(_ exercise: LoggedExercise) {
        let ordered = session.sortedExercises
        guard let index = ordered.firstIndex(where: { $0.persistentModelID == exercise.persistentModelID }),
              index + 1 < ordered.count else { return }
        let next = ordered[index + 1]
        let group = next.supersetID ?? UUID().uuidString
        exercise.supersetID = group
        next.supersetID = group
        try? context.save()
    }

    private func unlinkSuperset(_ exercise: LoggedExercise) {
        let group = exercise.supersetID
        exercise.supersetID = nil
        // If only one exercise is left in the group, dissolve it.
        if let group, session.exercises.filter({ $0.supersetID == group }).count <= 1 {
            session.exercises.filter { $0.supersetID == group }.forEach { $0.supersetID = nil }
        }
        try? context.save()
    }

    /// Generate a drop-set ladder from `start` down to `end` by `drop`, all
    /// marked as drop sets (no rest between them) and logged to failure.
    private func addDropSet(to exercise: LoggedExercise, start: Double, drop: Double, end: Double) {
        guard drop > 0, start >= end else { return }
        var weight = start
        var order = exercise.sets.count
        while weight >= end - 0.001 {
            let set = SetLog(weight: weight, reps: 0, rpe: 10, repsInTank: 0, isDropSet: true, order: order)
            set.exercise = exercise
            context.insert(set)
            order += 1
            weight -= drop
        }
        try? context.save()
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

        // Mirror the session to Apple Health as a strength workout.
        let end = Date()
        let start = min(session.date, end)
        if health.authorized {
            isSaving = true
            Task {
                await health.saveWorkout(start: start, end: end)
                isSaving = false
            }
        }
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
    var onComplete: () -> Void = {}
    @State private var showPlates = false

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Button {
                    set.isCompleted.toggle()
                    onChange()
                    if set.isCompleted { onComplete() }
                } label: {
                    Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(set.isCompleted ? Theme.accent : .secondary)
                }
                .buttonStyle(.plain)

                field(value: $set.weight, unit: "lb", width: 56, decimal: true)
                Button { showPlates = true } label: {
                    Image("eq_barbell").renderingMode(.template)
                        .resizable().scaledToFit().frame(width: 26, height: 20)
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Load plates")
                Text("×").foregroundStyle(.secondary)
                intField(value: $set.reps, unit: "reps", width: 40)
                if set.isDropSet {
                    Text("DROP")
                        .font(.system(size: 9)).bold()
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(.orange.opacity(0.2), in: Capsule())
                        .foregroundStyle(.orange)
                }
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
        .sheet(isPresented: $showPlates) {
            PlateCalculatorView(weight: $set.weight, exerciseName: set.exercise?.name, onApply: onChange)
        }
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
