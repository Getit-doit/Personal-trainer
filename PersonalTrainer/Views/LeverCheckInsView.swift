import SwiftUI
import SwiftData

/// Manage diet-lever check-ins: the coach asks these as Yes/No notifications,
/// tracks streaks, and celebrates milestones. Also answerable in-app.
struct LeverCheckInsView: View {
    @Environment(\.modelContext) private var context
    @ObservedObject private var notif = NotificationCoach.shared
    @Query(sort: \DietHabit.startDate) private var habits: [DietHabit]
    @Query private var profiles: [UserProfile]
    @Query private var sessions: [WorkoutSession]
    @Query private var nutrition: [NutritionLog]
    @Query private var prs: [PersonalBest]
    @Query private var exercises: [Exercise]

    @State private var showAdd = false
    @State private var showIntake = false

    private var active: [DietHabit] { habits.filter(\.isActive) }
    private var hasGenerativeCoach: Bool { CoachService.activeEngine != .offline }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                TitleBlock(eyebrow: "Coach check-ins", title: "Levers",
                           caption: "Yes / No · streaks")

                if !notif.authorized {
                    permissionCard
                }

                if active.isEmpty {
                    emptyState
                } else {
                    ForEach(active) { habit in
                        habitCard(habit)
                    }
                }

                aiSuggestionsCard
                suggestionsCard
            }
            .padding()
        }
        .blueprintBackground()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddHabitView { habit in
                context.insert(habit)
                try? context.save()
                notif.rescheduleAll()
            }
        }
        .sheet(isPresented: $showIntake) {
            HabitIntakeView(
                memory: CoachMemory.build(
                    profile: profiles.first, sessions: sessions,
                    nutrition: nutrition, prs: prs, exercises: exercises
                ),
                existingTitles: habits.map(\.title)
            )
        }
    }

    // MARK: Build levers from daily habits

    private var aiSuggestionsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                SectionRule(title: "Build your levers")
                Text(hasGenerativeCoach
                     ? "Answer a few quick questions about your daily habits and your coach will suggest levers tailored to you."
                     : "Answer a few quick questions about your daily habits and we'll suggest levers that fit.")
                    .font(.caption).foregroundStyle(.secondary)
                Button { showIntake = true } label: {
                    Label("Answer a few questions", systemImage: "text.bubble")
                        .blueprintPrimary()
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// A selectable suggestion row that adds the lever when tapped.
    private func suggestionRow(_ s: HabitEngine.Suggestion) -> some View {
        Button { addSuggestion(s) } label: {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "plus.circle.fill").foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(s.title).font(.subheadline)
                    Text(s.question).font(.caption2).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Text(s.goodAnswerIsYes ? "YES = WIN" : "NO = WIN")
                    .font(Theme.mono(8)).tracking(1).foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private func addSuggestion(_ s: HabitEngine.Suggestion) {
        let habit = DietHabit(title: s.title, question: s.question, goodAnswerIsYes: s.goodAnswerIsYes)
        context.insert(habit)
        try? context.save()
        notif.rescheduleAll()
    }

    // MARK: Permission

    private var permissionCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                SectionRule(title: "Notifications off", tint: Theme.amber)
                Text("Turn on notifications so the coach can ask your check-ins with Yes/No buttons and celebrate your streaks.")
                    .font(.caption).foregroundStyle(.secondary)
                Button {
                    Task { await notif.requestAuthorization() }
                } label: {
                    Text("Enable check-ins").blueprintPrimary()
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emptyState: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                SectionRule(title: "No levers yet")
                Text("Add a nutrition lever below. The coach will check in every few days and keep a streak going.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Habit card

    private func habitCard(_ habit: DietHabit) -> some View {
        let days = HabitEngine.streakDays(habit)
        let next = HabitEngine.nextMilestone(habit)
        let last = habit.checkIns.max(by: { $0.date < $1.date })
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(habit.title).font(Theme.hand(20))
                        Text(habit.goodAnswerIsYes ? "Win = Yes" : "Win = No")
                            .font(Theme.mono(9)).tracking(1).foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("\(days)").font(Theme.mono(28, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                        Text("DAY STREAK").font(Theme.mono(8)).tracking(1.2).foregroundStyle(.secondary)
                    }
                }

                if let next {
                    let prev = HabitEngine.milestones.last { $0 <= days } ?? 0
                    let span = max(1, next - prev)
                    let progress = Double(days - prev) / Double(span)
                    VStack(alignment: .leading, spacing: 4) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Rectangle().fill(Theme.card)
                                Rectangle().fill(Theme.accent)
                                    .frame(width: geo.size.width * min(1, max(0, progress)))
                            }
                        }
                        .frame(height: 6)
                        .overlay(Rectangle().stroke(Theme.hairline, lineWidth: 1))
                        Text("\(next - days) days to \(next)-day mark")
                            .font(Theme.mono(9)).tracking(0.5).foregroundStyle(.secondary)
                    }
                } else if days >= HabitEngine.milestones.last! {
                    Text("Past every milestone — legendary.")
                        .font(Theme.mono(9)).tracking(0.5).foregroundStyle(Theme.accent)
                }

                Divider().overlay(Theme.hairline)

                Text(habit.question).font(.subheadline)

                HStack(spacing: 10) {
                    Button { notif.record(habit: habit, answeredYes: true) } label: {
                        Text("YES").blueprintSecondary()
                    }.buttonStyle(.plain)
                    Button { notif.record(habit: habit, answeredYes: false) } label: {
                        Text("NO").blueprintSecondary()
                    }.buttonStyle(.plain)
                }

                // Confirmation that the most recent answer registered. The streak
                // counts elapsed days held, so it ticks at day boundaries — this
                // makes each check-in visibly land.
                if let last {
                    HStack(spacing: 6) {
                        Image(systemName: last.wasGood ? "checkmark.circle.fill" : "arrow.counterclockwise.circle")
                            .foregroundStyle(last.wasGood ? Theme.accent : Theme.amber)
                        Text("Checked in \(checkInWhen(last.date)): \(last.answeredYes ? "Yes" : "No")"
                             + (last.wasGood ? "" : " — streak reset"))
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }

                if !habit.lastReflection.isEmpty {
                    Text("Last reflection: \(habit.lastReflection)")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                habit.isActive = false
                try? context.save()
                notif.rescheduleAll()
            } label: { Label("Stop tracking", systemImage: "pause.circle") }
            Button(role: .destructive) {
                context.delete(habit)
                try? context.save()
                notif.rescheduleAll()
            } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private func checkInWhen(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "today" }
        if cal.isDateInYesterday(date) { return "yesterday" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    // MARK: Suggestions

    private var suggestionsCard: some View {
        let existing = Set(habits.map(\.title))
        let starters = HabitEngine.suggestions.filter { !existing.contains($0.title) }
        return Group {
            if !starters.isEmpty {
                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionRule(title: "Starter levers")
                        ForEach(starters, id: \.title) { s in
                            suggestionRow(s)
                        }
                    }
                }
            }
        }
    }
}

/// Create a custom diet lever, with an AI button to phrase the question.
struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (DietHabit) -> Void

    @State private var title = ""
    @State private var question = ""
    @State private var goodAnswerIsYes = true
    @State private var frequencyDays = 3
    @State private var time = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: .now) ?? .now
    @State private var suggesting = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    field("Lever", "e.g. No soda", text: $title)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            SectionRule(title: "Check-in question")
                            Button {
                                Task { await suggestQuestion() }
                            } label: {
                                HStack(spacing: 4) {
                                    if suggesting { ProgressView().scaleEffect(0.7) }
                                    else { Image(systemName: "sparkles") }
                                    Text("AI").font(Theme.mono(9)).tracking(1)
                                }
                                .foregroundStyle(Theme.accent)
                            }
                            .buttonStyle(.plain)
                            .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || suggesting)
                        }
                        TextField("e.g. Have you had any soda the last few days?",
                                  text: $question, axis: .vertical)
                            .lineLimit(1...3)
                            .blueprintField()
                    }

                    Card {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionRule(title: "What counts as a win?")
                            Picker("", selection: $goodAnswerIsYes) {
                                Text("Answering Yes").tag(true)
                                Text("Answering No").tag(false)
                            }
                            .pickerStyle(.segmented)
                            Text(goodAnswerIsYes
                                 ? "Good when you can say Yes (e.g. \"drank protein\")."
                                 : "Good when you can say No (e.g. \"no soda\").")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }

                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionRule(title: "Cadence")
                            Stepper("Every \(frequencyDays) day\(frequencyDays == 1 ? "" : "s")",
                                    value: $frequencyDays, in: 1...14)
                            DatePicker("Time of day", selection: $time, displayedComponents: .hourAndMinute)
                        }
                    }
                }
                .padding()
            }
            .blueprintBackground()
            .navigationTitle("New Lever")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty
                                  || question.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func field(_ label: String, _ placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionRule(title: label)
            TextField(placeholder, text: text).blueprintField()
        }
    }

    private func suggestQuestion() async {
        suggesting = true
        defer { suggesting = false }

        // Offline rule-based coach can't phrase a question — use a clean template.
        guard CoachService.activeEngine != .offline else {
            question = goodAnswerIsYes
                ? "Have you stayed on track with \(title.lowercased()) the last few days?"
                : "Have you slipped on \(title.lowercased()) the last few days?"
            return
        }

        let win = goodAnswerIsYes ? "answering Yes is the good outcome" : "answering No is the good outcome"
        let prompt = "Write one short, friendly check-in question (max 18 words) a fitness "
            + "coach would send for the nutrition habit \"\(title)\", where \(win). "
            + "Return only the question."
        if let reply = await CoachService.oneShot(prompt) {
            let cleaned = reply.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleaned.isEmpty { question = cleaned }
        }
    }

    private func save() {
        let cal = Calendar.current
        let habit = DietHabit(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            question: question.trimmingCharacters(in: .whitespacesAndNewlines),
            goodAnswerIsYes: goodAnswerIsYes,
            frequencyDays: frequencyDays,
            hour: cal.component(.hour, from: time),
            minute: cal.component(.minute, from: time)
        )
        onSave(habit)
        dismiss()
    }
}

/// The coach interviews the athlete about their daily habits, then recommends
/// levers targeting the weak spots. AI personalizes the list when available;
/// a deterministic mapping makes it work fully offline too.
struct HabitIntakeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var notif = NotificationCoach.shared

    let memory: String
    let existingTitles: [String]

    private enum Phase { case questions, loading, results }
    @State private var phase: Phase = .questions
    @State private var answers: [String: Int] = [:]
    @State private var results: [HabitEngine.Suggestion] = []
    @State private var added: Set<String> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    switch phase {
                    case .questions: questionsSection
                    case .loading: loadingSection
                    case .results: resultsSection
                    }
                }
                .padding()
            }
            .blueprintBackground()
            .navigationTitle("Your habits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(phase == .results ? "Done" : "Cancel") { dismiss() }
                }
            }
        }
    }

    private var questionsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("A few quick questions so your coach can suggest the right levers.")
                .font(.callout).foregroundStyle(.secondary)
            ForEach(HabitEngine.intake) { q in
                VStack(alignment: .leading, spacing: 8) {
                    SectionRule(title: q.prompt)
                    Picker(q.prompt, selection: Binding(
                        get: { answers[q.id] ?? -1 },
                        set: { answers[q.id] = $0 }
                    )) {
                        ForEach(q.options.indices, id: \.self) { i in
                            Text(q.options[i].label).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            Button { Task { await build() } } label: {
                Label("Build my levers", systemImage: "wand.and.stars").blueprintPrimary()
            }
            .buttonStyle(.plain)
            .disabled(answers.isEmpty)
            .padding(.top, 4)
        }
    }

    private var loadingSection: some View {
        VStack(spacing: 14) {
            ProgressView()
            Text("Building levers from your habits…")
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 50)
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if results.isEmpty {
                SectionRule(title: "Looking solid")
                Text("Your daily habits look strong — no obvious levers right now. You can still add one from the Starter list, or re-answer to explore.")
                    .font(.callout).foregroundStyle(.secondary)
            } else {
                SectionRule(title: "Recommended for you")
                Text("Tap any to start tracking it.").font(.caption).foregroundStyle(.secondary)
                ForEach(results, id: \.title) { resultRow($0) }
            }
            Button { phase = .questions } label: {
                Label("Re-answer", systemImage: "arrow.uturn.backward").blueprintSecondary()
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }

    private func resultRow(_ s: HabitEngine.Suggestion) -> some View {
        let isAdded = added.contains(s.title)
        return Button {
            guard !isAdded else { return }
            let habit = DietHabit(title: s.title, question: s.question, goodAnswerIsYes: s.goodAnswerIsYes)
            modelContext.insert(habit)
            try? modelContext.save()
            notif.rescheduleAll()
            added.insert(s.title)
        } label: {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                    .foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(s.title).font(.subheadline)
                    Text(s.question).font(.caption2).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Text(s.goodAnswerIsYes ? "YES = WIN" : "NO = WIN")
                    .font(Theme.mono(8)).tracking(1).foregroundStyle(.secondary)
            }
            .opacity(isAdded ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isAdded)
    }

    private func build() async {
        phase = .loading
        let deterministic = HabitEngine.deterministicLevers(from: answers)
        var merged = deterministic

        if CoachService.activeEngine != .offline {
            let summary = HabitEngine.intakeSummary(from: answers)
            let grounded = memory.isEmpty
                ? "## Daily habit answers\n\(summary)"
                : memory + "\n\n## Daily habit answers\n\(summary)"
            if let ai = await CoachService.suggestLevers(memory: grounded, avoid: existingTitles) {
                var seen = Set(ai.map { $0.title.lowercased() })
                merged = ai
                for d in deterministic where !seen.contains(d.title.lowercased()) {
                    merged.append(d); seen.insert(d.title.lowercased())
                }
            }
        }

        let existingLower = Set(existingTitles.map { $0.lowercased() })
        results = Array(merged.filter { !existingLower.contains($0.title.lowercased()) }.prefix(6))
        phase = .results
    }
}
