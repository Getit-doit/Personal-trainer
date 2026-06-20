import Foundation

/// Builds a markdown "memory" document about the account holder that the coach
/// reads before every reply: profile, the current time, how long since the last
/// workout, recent workout summaries, recent PRs, and the current fuel decisions.
enum CoachMemory {

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
            lines.append("- Height: \(Int(p.heightInches) / 12)'\(Int(p.heightInches) % 12)\"")
            lines.append("- Starting weight: \(p.startWeight.clean) lb")
            lines.append("- Goal: \(p.goals)")
            lines.append("- Schedule: \(p.scheduleDaysPerWeek) days/week")
            if !p.constraints.isEmpty {
                lines.append("- Constraints: \(p.constraints.joined(separator: "; "))")
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

        return lines.joined(separator: "\n")
    }

    // MARK: - Helpers

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
