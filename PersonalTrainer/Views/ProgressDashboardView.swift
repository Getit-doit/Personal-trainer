import SwiftUI
import SwiftData
import Charts

/// Progress tab: personal bests (auto-detected + manual) and a per-lift
/// progression chart of estimated 1RM over time.
struct ProgressDashboardView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \PersonalBest.value, order: .reverse) private var prs: [PersonalBest]
    @Query(sort: \WorkoutSession.date) private var sessions: [WorkoutSession]
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var selectedLift = "Back Squat"
    @State private var showAddPR = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    TitleBlock(eyebrow: "Est. 1RM History", title: "Progress")
                    progressionCard
                    prCard
                }
                .padding()
            }
            .blueprintBackground()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddPR = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAddPR) {
                AddPRSheet(exercises: exercises)
            }
        }
    }

    // MARK: Progression chart

    private var liftNames: [String] {
        let logged = Set(sessions.filter(\.isFinished).flatMap(\.exercises).map(\.name))
        return logged.sorted()
    }

    /// Top-set estimated 1RM per session for the selected lift.
    private var liftHistory: [(date: Date, oneRM: Double)] {
        sessions
            .filter(\.isFinished)
            .compactMap { session -> (Date, Double)? in
                let best = session.exercises
                    .filter { $0.name == selectedLift }
                    .flatMap(\.sets)
                    .filter(\.isCompleted)
                    .map(\.estimatedOneRepMax)
                    .max()
                guard let best, best > 0 else { return nil }
                return (session.date, best)
            }
            .sorted { $0.0 < $1.0 }
    }

    private var progressionCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionRule(title: "Progression")
                if liftNames.isEmpty {
                    Text("Finish a workout to chart your estimated 1RM over time.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Picker("Lift", selection: $selectedLift) {
                        ForEach(liftNames, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.accentDeep)

                    let history = liftHistory
                    if history.count < 2 {
                        Text("Log this lift across at least two sessions to see a trend.")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Chart(history, id: \.date) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Est. 1RM", point.oneRM)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Theme.accent)
                            PointMark(
                                x: .value("Date", point.date),
                                y: .value("Est. 1RM", point.oneRM)
                            )
                            .foregroundStyle(Theme.accent)
                        }
                        .chartYScale(domain: .automatic(includesZero: false))
                        .frame(height: 200)
                    }
                }
            }
        }
        .onAppear {
            if let first = liftNames.first, !liftNames.contains(selectedLift) {
                selectedLift = first
            }
        }
    }

    // MARK: Personal bests

    private var bestPerExercise: [PersonalBest] {
        var seen = Set<String>()
        var result: [PersonalBest] = []
        for pr in prs where !seen.contains(pr.exerciseName) {
            seen.insert(pr.exerciseName)
            result.append(pr)
        }
        return result
    }

    private var prCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionRule(title: "Personal Bests")
                if bestPerExercise.isEmpty {
                    Text("PRs are detected automatically when you finish a workout. Tap + to add a historical PR.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(bestPerExercise) { pr in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(pr.exerciseName).font(.subheadline).bold()
                                Text("\(pr.weight.clean) LB × \(pr.reps) · \(pr.date.formatted(date: .abbreviated, time: .omitted).uppercased())")
                                    .font(Theme.mono(9)).tracking(0.5).foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 3) {
                                Text("\(pr.value.clean)").font(Theme.mono(18)).foregroundStyle(Theme.accent)
                                Text("EST · \(pr.source.rawValue.uppercased())")
                                    .font(Theme.mono(9)).tracking(0.8).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}

/// Manual historical PR entry.
struct AddPRSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let exercises: [Exercise]

    @State private var name = ""
    @State private var weight = 135.0
    @State private var reps = 1
    @State private var date = Date.now

    var body: some View {
        NavigationStack {
            Form {
                Picker("Exercise", selection: $name) {
                    Text("Select…").tag("")
                    ForEach(exercises) { Text($0.name).tag($0.name) }
                }
                HStack {
                    Text("Weight"); Spacer()
                    TextField("Weight", value: $weight, format: .number)
                        .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 80)
                    Text("lb").foregroundStyle(.secondary)
                }
                Stepper("Reps: \(reps)", value: $reps, in: 1...20)
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }
            .scrollContentBackground(.hidden)
            .listRowBackground(Color.clear)
            .blueprintBackground()
            .navigationTitle("Add PR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(name.isEmpty)
                }
            }
        }
    }

    private func save() {
        let oneRM = (weight * (1 + Double(reps) / 30) * 10).rounded() / 10
        let match = exercises.first { $0.name == name }
        context.insert(
            PersonalBest(
                exerciseName: name,
                value: oneRM,
                weight: weight,
                reps: reps,
                date: date,
                source: .manual,
                exercise: match
            )
        )
        try? context.save()
        dismiss()
    }
}
