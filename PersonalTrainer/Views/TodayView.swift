import SwiftUI
import SwiftData

/// Home screen: today's recovery check-in, progression flags for priority
/// lifts, current nutrition lever, and a quick way to start training.
struct TodayView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var health: HealthService
    @Query private var profiles: [UserProfile]
    @Query private var exercises: [Exercise]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \RecoveryLog.date, order: .reverse) private var recovery: [RecoveryLog]
    @Query(sort: \NutritionLog.date, order: .reverse) private var nutrition: [NutritionLog]

    @State private var startedSession: WorkoutSession?
    @State private var showTemplatePicker = false
    @State private var recoveryLog: RecoveryLog?
    @State private var showProfile = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    recoveryCard
                    healthCard
                    progressionCard
                    nutritionCard
                    startCard
                }
                .padding()
            }
            .blueprintBackground()
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showProfile = true } label: {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                if let profile { EditProfileView(profile: profile) }
            }
            .onAppear(perform: ensureRecoveryLog)
            .navigationDestination(item: $startedSession) { session in
                ActiveSessionView(session: session)
            }
            .confirmationDialog("Start a workout", isPresented: $showTemplatePicker, titleVisibility: .visible) {
                ForEach(TrainingContent.templates) { template in
                    Button("\(template.title) · \(template.subtitle)") {
                        startedSession = SessionFactory.fromTemplate(template, context: context)
                    }
                }
                Button("Empty session") {
                    startedSession = SessionFactory.blank(context: context)
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting).font(Theme.hand(28, relativeTo: .title))
            if let profile {
                Text(profile.goals)
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning 👋"
        case 12..<17: return "Good afternoon 👋"
        default: return "Good evening 👋"
        }
    }

    // MARK: Recovery

    /// Fetch-or-create today's recovery log exactly once.
    private func ensureRecoveryLog() {
        guard recoveryLog == nil else { return }
        if let existing = recovery.first(where: { Calendar.current.isDateInToday($0.date) }) {
            recoveryLog = existing
        } else {
            let log = RecoveryLog(date: .now)
            context.insert(log)
            try? context.save()
            recoveryLog = log
        }
    }

    @ViewBuilder
    private var recoveryCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Label("Recovery", systemImage: "bed.double.fill").font(Theme.hand(19, relativeTo: .headline))
                if let log = recoveryLog {
                    RecoveryEditor(log: log) { try? context.save() }
                    Text(advice(for: log))
                        .font(.caption)
                        .foregroundStyle(Theme.accentDeep)
                }
            }
        }
    }

    private func advice(for log: RecoveryLog) -> String {
        if log.sleepHours < 6.5 || log.stressLevel >= 4 {
            return "Under-recovered — keep top sets at RPE 7 and trim a set if needed."
        }
        return "Recovery looks solid — good day to push priority lifts."
    }

    // MARK: Apple Health

    @ViewBuilder
    private var healthCard: some View {
        if health.isAvailable {
            Card {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Apple Health", systemImage: "heart.fill").font(Theme.hand(19, relativeTo: .headline))
                    if health.authorized {
                        HStack(spacing: 12) {
                            healthMetric("Sleep", health.lastNightSleepHours.map { "\($0.clean)h" }, "bed.double.fill", .blue)
                            healthMetric("Steps", health.todaySteps.map { stepString($0) }, "figure.walk", .orange)
                            healthMetric("Weight", health.latestBodyWeight.map { "\($0.clean) lb" }, "scalemass.fill", Theme.accent)
                        }
                        if let sleep = health.lastNightSleepHours, let log = recoveryLog {
                            Button {
                                log.sleepHours = (sleep * 2).rounded() / 2
                                try? context.save()
                            } label: {
                                Label("Use \(sleep.clean)h from Health", systemImage: "arrow.down.circle")
                                    .font(.caption)
                            }
                            .tint(Theme.accent)
                        }
                    } else {
                        Text("Connect to read sleep, steps, and body weight, and save workouts.")
                            .font(.caption).foregroundStyle(.secondary)
                        Button {
                            Task { await health.requestAuthorization() }
                        } label: {
                            Label("Connect Apple Health", systemImage: "heart.text.square")
                                .foregroundStyle(Theme.blueprintDeep)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.accent)
                    }
                }
            }
            .task { if health.authorized { await health.refresh() } }
        }
    }

    private func healthMetric(_ title: String, _ value: String?, _ icon: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value ?? "—").font(Theme.hand(18, relativeTo: .subheadline))
            Text(title).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func stepString(_ steps: Double) -> String {
        steps >= 1000 ? String(format: "%.1fk", steps / 1000) : "\(Int(steps))"
    }

    // MARK: Progression

    private var suggestions: [ProgressionSuggestion] {
        ProgressionEngine.prioritySuggestions(exercises: exercises, sessions: sessions)
    }

    @ViewBuilder
    private var progressionCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Label("Progression Targets", systemImage: "arrow.up.right.circle.fill").font(Theme.hand(19, relativeTo: .headline))
                if suggestions.isEmpty {
                    Text("Log your priority lifts (RDL, goblet squat) to get progression flags.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(suggestions, id: \.exerciseName) { s in
                        HStack(alignment: .top) {
                            Image(systemName: s.readyToProgress ? "checkmark.circle.fill" : "pause.circle")
                                .foregroundStyle(s.readyToProgress ? Theme.accent : .secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(s.exerciseName).font(.subheadline).bold()
                                Text(s.reason).font(.caption2).foregroundStyle(.secondary)
                                if s.readyToProgress {
                                    Text("Try \(s.suggestedWeight.clean) lb (was \(s.lastTopWeight.clean))")
                                        .font(.caption2).bold().foregroundStyle(Theme.accentDeep)
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    // MARK: Nutrition lever

    @ViewBuilder
    private var nutritionCard: some View {
        let lever = nutrition.first?.currentLever ?? ""
        Card {
            VStack(alignment: .leading, spacing: 6) {
                Label("Today's Lever", systemImage: "target").font(Theme.hand(19, relativeTo: .headline))
                Text(lever.isEmpty ? "No lever set — pick one habit in the Fuel tab." : lever)
                    .font(.subheadline)
                    .foregroundStyle(lever.isEmpty ? .secondary : .primary)
            }
        }
    }

    // MARK: Start

    private var startCard: some View {
        Button { showTemplatePicker = true } label: {
            Label("Start Workout", systemImage: "play.fill")
                .font(Theme.hand(20, relativeTo: .headline))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(Theme.blueprintDeep)
        }
    }
}

/// Inline editor for sleep hours + stress level.
struct RecoveryEditor: View {
    @Bindable var log: RecoveryLog
    var onChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Sleep")
                Spacer()
                Stepper("\(log.sleepHours.clean) hrs", value: $log.sleepHours, in: 0...12, step: 0.5)
                    .fixedSize()
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Stress: \(stressLabel)")
                Slider(
                    value: Binding(
                        get: { Double(log.stressLevel) },
                        set: { log.stressLevel = Int($0.rounded()) }
                    ),
                    in: 1...5, step: 1
                )
                .tint(Theme.accent)
            }
        }
        .onChange(of: log.sleepHours) { onChange() }
        .onChange(of: log.stressLevel) { onChange() }
    }

    private var stressLabel: String {
        switch log.stressLevel {
        case 1: return "Calm"
        case 2: return "Low"
        case 3: return "Moderate"
        case 4: return "High"
        default: return "Very high"
        }
    }
}

extension Double {
    /// Trims trailing ".0" for clean display.
    var clean: String {
        self == rounded() ? String(format: "%.0f", self) : String(format: "%.1f", self)
    }
}
