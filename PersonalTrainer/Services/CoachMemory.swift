import Foundation

/// Builds a markdown "memory" document about the account holder that the coach
/// reads before every reply: profile, the current time, how long since the last
/// workout, recent workout summaries, recent PRs, and the current fuel decisions.
enum CoachMemory {

    static let condenseKey = "condenseMemory"
    static let summaryKey = "coachMemorySummary"
    private static let summaryBaseLenKey = "coachMemorySummaryBaseLen"

    /// The memory to send the coach: the condensed version (dynamic header + a
    /// short AI summary) when condensing is on and a summary exists, otherwise the
    /// full briefing. Pass the already-built `full` to avoid rebuilding it.
    static func condensed(
        full: String,
        profile: UserProfile?,
        sessions: [WorkoutSession],
        nutrition: [NutritionLog]
    ) -> String {
        guard UserDefaults.standard.bool(forKey: condenseKey),
              let summary = UserDefaults.standard.string(forKey: summaryKey),
              !summary.isEmpty else { return full }
        return compact(profile: profile, sessions: sessions, nutrition: nutrition, summary: summary)
    }

    /// Generate and store a condensed AI summary of the full briefing. Returns
    /// whether it succeeded. No-op result when no generative engine is available.
    @discardableResult
    static func refreshSummary(full: String) async -> Bool {
        guard let summary = await CoachService.summarizeMemory(full) else { return false }
        UserDefaults.standard.set(summary, forKey: summaryKey)
        UserDefaults.standard.set(full.count, forKey: summaryBaseLenKey)
        return true
    }

    /// Fire-and-forget refresh when condensing is on and the summary is missing or
    /// the briefing has grown a lot since it was last summarized.
    static func refreshSummaryIfNeeded(full: String) async {
        guard UserDefaults.standard.bool(forKey: condenseKey) else { return }
        let existing = UserDefaults.standard.string(forKey: summaryKey) ?? ""
        let baseLen = UserDefaults.standard.integer(forKey: summaryBaseLenKey)
        let grewALot = baseLen > 0 && full.count > Int(Double(baseLen) * 1.5)
        guard existing.isEmpty || grewALot else { return }
        await refreshSummary(full: full)
    }

    /// A small briefing: live/time-sensitive bits kept fresh, with the bulky
    /// profile/history/exercise list replaced by the stored AI summary.
    static func compact(
        profile: UserProfile?,
        sessions: [WorkoutSession],
        nutrition: [NutritionLog],
        summary: String
    ) -> String {
        var lines: [String] = ["# Athlete memory (condensed)", "## Now"]
        let now = Date()
        lines.append("- \(now.formatted(date: .complete, time: .shortened)) (\(partOfDay(now)))")
        let finished = sessions.filter(\.isFinished).sorted { $0.date > $1.date }
        if let last = finished.first {
            lines.append("- Last workout: \(last.notes.isEmpty ? "Workout" : last.notes), \(sinceDescription(last.date)).")
        }
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        lines.append("- Completed this week: \(finished.filter { $0.date >= weekAgo }.count)")
        if let fuel = nutrition.sorted(by: { $0.date > $1.date }).first, !fuel.currentLever.isEmpty {
            lines.append("- Current fuel lever: \(fuel.currentLever)")
        }
        lines.append("## Profile & history (summary)")
        lines.append(summary)
        return lines.joined(separator: "\n")
    }

    static func build(
        profile: UserProfile?,
        sessions: [WorkoutSession],
        nutrition: [NutritionLog],
        prs: [PersonalBest],
        exercises: [Exercise]
    ) -> String {
        var lines: [String] = []

        // MARK: Now
        let now = Date()
        let nowStr = now.formatted(date: .complete, time: .shortened)
        lines.append("# Athlete memory")
        lines.append("## Now")
        lines.append("- Current date & time: \(nowStr)")
        lines.append("- Time of day: \(partOfDay(now))")

        // MARK: Profile
        if let p = profile {
            lines.append("## Profile")
            if !p.name.isEmpty { lines.append("- Name: \(p.name)") }
            if !p.sex.isEmpty { lines.append("- Sex: \(p.sex)") }
            if p.age > 0 { lines.append("- Age: \(p.age)") }
            lines.append("- Height: \(Int(p.heightInches) / 12)'\(Int(p.heightInches) % 12)\"")
            lines.append("- Weight: \(p.startWeight.clean) lb")
            if !p.experience.isEmpty { lines.append("- Experience: \(p.experience)") }
            lines.append("- Goal: \(p.goals)")
            lines.append("- Schedule: \(p.scheduleDaysPerWeek) days/week")
            if !p.equipment.isEmpty {
                lines.append("- Equipment available: \(p.equipment.joined(separator: ", "))")
            }
            if !p.constraints.isEmpty {
                lines.append("- Constraints / injuries: \(p.constraints.joined(separator: "; "))")
            }
        }

        // MARK: Training recency
        let finished = sessions.filter(\.isFinished).sorted { $0.date > $1.date }
        lines.append("## Training")
        if let last = finished.first {
            lines.append("- Last workout: \(last.notes.isEmpty ? "Workout" : last.notes), \(sinceDescription(last.date)).")
        } else {
            lines.append("- No completed workouts logged yet.")
        }
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let thisWeek = finished.filter { $0.date >= weekAgo }.count
        lines.append("- Completed this week: \(thisWeek)")

        // Recent workout summaries
        if !finished.isEmpty {
            lines.append("### Recent sessions")
            for s in finished.prefix(4) {
                lines.append("- \(summary(of: s))")
            }
        }

        // MARK: PRs
        let bestPerLift = uniqueBestPRs(prs)
        if !bestPerLift.isEmpty {
            lines.append("## Recent personal bests (est. 1RM)")
            for pr in bestPerLift.prefix(5) {
                lines.append("- \(pr.exerciseName): \(pr.value.clean) lb (\(pr.weight.clean)×\(pr.reps))")
            }
        }

        // MARK: Progression flags
        let ready = ProgressionEngine.prioritySuggestions(exercises: exercises, sessions: sessions)
            .filter(\.readyToProgress)
        if !ready.isEmpty {
            lines.append("## Ready to progress")
            for s in ready {
                lines.append("- \(s.exerciseName): try \(s.suggestedWeight.clean) lb (was \(s.lastTopWeight.clean))")
            }
        }

        // MARK: Fuel decisions
        if let fuel = nutrition.sorted(by: { $0.date > $1.date }).first {
            lines.append("## Fuel")
            if !fuel.currentLever.isEmpty { lines.append("- Current lever: \(fuel.currentLever)") }
            if !fuel.wins.isEmpty { lines.append("- Recent wins: \(fuel.wins.joined(separator: ", "))") }
            if !fuel.weakLinks.isEmpty { lines.append("- Weak links: \(fuel.weakLinks.joined(separator: ", "))") }
        }

        // MARK: Exercise options matched to experience
        let exerciseSection = exerciseOptions(exercises, experience: profile?.experience ?? "Beginner")
        if !exerciseSection.isEmpty {
            let level = profile?.experience ?? "Beginner"
            lines.append("## Exercise options (\(level) level and below — only program from these)")
            lines.append(contentsOf: exerciseSection)
        }

        return lines.joined(separator: "\n")
    }

    /// Catalog exercises at or below the athlete's level, grouped by muscle
    /// (compounds first), so the coach builds plans only from suitable lifts.
    private static func exerciseOptions(_ exercises: [Exercise], experience: String) -> [String] {
        let ceiling = (Difficulty(rawValue: experience) ?? .beginner).rank
        let eligible = exercises.filter { $0.difficulty.rank <= ceiling }
        guard !eligible.isEmpty else { return [] }
        let order = ["Legs", "Hinge", "Chest", "Back", "Shoulders", "Arms", "Core", "Cardio"]
        var lines: [String] = []
        for group in order {
            let inGroup = eligible.filter { $0.muscleGroup == group }
                .sorted { ($0.type == .compound ? 0 : 1, $0.name) < ($1.type == .compound ? 0 : 1, $1.name) }
            guard !inGroup.isEmpty else { continue }
            let names = inGroup.prefix(10).map(\.name).joined(separator: ", ")
            lines.append("- \(group): \(names)")
        }
        return lines
    }

    // MARK: - Helpers

    /// A snapshot of the workout in progress, so the coach can answer in context
    /// ("should I add weight?", "what's next?") during a live session.
    static func liveSession(_ session: WorkoutSession) -> String {
        var lines: [String] = []
        lines.append(session.warmupDone
            ? "- Warm-up: done"
            : "- Warm-up: not done yet (set logging is gated until it is)")
        let exs = session.sortedExercises
        if exs.isEmpty {
            lines.append("- No exercises added to this session yet.")
        } else {
            for ex in exs {
                let done = ex.sets.filter(\.isCompleted)
                var line = "- \(ex.name): \(done.count)/\(ex.sets.count) sets done"
                if let last = done.max(by: { $0.order < $1.order }), last.weight > 0 {
                    line += ", last \(last.weight.clean)×\(last.reps) @RPE\(last.rpe.clean)"
                }
                lines.append(line)
            }
            if let next = exs.first(where: { $0.sets.isEmpty || $0.sets.contains(where: { !$0.isCompleted }) }) {
                lines.append("- Up next: \(next.name)")
            }
        }
        if let cardio = session.cardio {
            lines.append("- Cardio finisher planned: \(cardio.modality)")
        }
        return lines.joined(separator: "\n")
    }

    private static func summary(of s: WorkoutSession) -> String {
        let date = s.date.formatted(date: .abbreviated, time: .omitted)
        let name = s.notes.isEmpty ? "Workout" : s.notes
        let lifts = s.exercises
            .sorted { $0.order < $1.order }
            .map { ex -> String in
                let topWeight = ex.sets.filter(\.isCompleted).map(\.weight).max() ?? 0
                let setCount = ex.sets.filter(\.isCompleted).count
                return topWeight > 0 ? "\(ex.name) \(topWeight.clean)×\(setCount)" : "\(ex.name) ×\(setCount)"
            }
            .prefix(5)
            .joined(separator: ", ")
        return "\(date) — \(name): \(lifts.isEmpty ? "no sets" : lifts) (\(s.totalVolume.clean) lb total)"
    }

    private static func uniqueBestPRs(_ prs: [PersonalBest]) -> [PersonalBest] {
        var seen = Set<String>()
        return prs.sorted { $0.value > $1.value }.filter { pr in
            guard !seen.contains(pr.exerciseName) else { return false }
            seen.insert(pr.exerciseName); return true
        }
    }

    private static func sinceDescription(_ date: Date) -> String {
        let cal = Calendar.current
        let minutes = Int(Date().timeIntervalSince(date) / 60)
        if minutes < 60 { return "\(max(minutes, 0)) min ago" }
        let hours = minutes / 60
        if hours < 24 && cal.isDateInToday(date) { return "earlier today (\(hours)h ago)" }
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: date), to: cal.startOfDay(for: Date())).day ?? 0
        switch days {
        case 0: return "earlier today"
        case 1: return "yesterday"
        default: return "\(days) days ago"
        }
    }

    private static func partOfDay(_ date: Date) -> String {
        switch Calendar.current.component(.hour, from: date) {
        case 5..<12: return "morning"
        case 12..<17: return "afternoon"
        case 17..<21: return "evening"
        default: return "night"
        }
    }
}
