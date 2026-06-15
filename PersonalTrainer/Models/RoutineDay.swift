import Foundation

/// A single day a workout can be started from — either a built-in template or a
/// user-created custom template. Lets the library, scheduler, and session
/// factory treat both uniformly.
enum RoutineDay: Identifiable {
    case builtin(WorkoutTemplate)
    case custom(CustomTemplate)

    var id: String {
        switch self {
        case .builtin(let t): return "builtin-\(t.id)"
        case .custom(let c): return "custom-\(c.persistentModelID.hashValue)"
        }
    }

    var title: String {
        switch self {
        case .builtin(let t): return t.title
        case .custom(let c): return c.title
        }
    }

    var subtitle: String {
        switch self {
        case .builtin(let t): return t.subtitle
        case .custom(let c): return "\(c.items.count) exercises"
        }
    }

    var level: String {
        switch self {
        case .builtin(let t): return t.level
        case .custom(let c): return c.level
        }
    }

    var program: String {
        switch self {
        case .builtin(let t): return t.program
        case .custom(let c): return c.program
        }
    }

    var exerciseCount: Int {
        switch self {
        case .builtin(let t): return t.exercises.count
        case .custom(let c): return c.items.count
        }
    }

    /// Rough session duration in minutes (built-in: hand-set; custom: estimated
    /// from total sets at ~1.5 min/set plus warm-up).
    var estimatedMinutes: Int {
        switch self {
        case .builtin(let t):
            return t.minutes
        case .custom(let c):
            let totalSets = c.items.reduce(0) { $0 + max($1.sets, 1) }
            return max(15, Int((Double(totalSets) * 1.5).rounded()) + 5)
        }
    }

    var equipment: [Equipment] {
        switch self {
        case .builtin(let t):
            return TrainingContent.equipment(in: t)
        case .custom(let c):
            var seen: [Equipment] = []
            for item in c.sortedItems where !seen.contains(item.equipment) { seen.append(item.equipment) }
            return seen.sorted { $0.sortOrder < $1.sortOrder }
        }
    }
}

/// Picks the next day in a program based on history (which day was last done).
enum ProgramScheduler {
    /// All program names — built-in first, then any custom-only programs.
    static func allProgramNames(custom: [CustomTemplate]) -> [String] {
        var names = TrainingContent.programs
        for c in custom where !names.contains(c.program) { names.append(c.program) }
        return names
    }

    /// Ordered days for a program (built-in templates then custom days).
    static func days(for program: String, custom: [CustomTemplate]) -> [RoutineDay] {
        let builtin = TrainingContent.templates(in: program).map(RoutineDay.builtin)
        let customDays = custom
            .filter { $0.program == program }
            .sorted { $0.order < $1.order }
            .map(RoutineDay.custom)
        return builtin + customDays
    }

    /// The recommended next day: the one after the most recently completed day
    /// in this program, cycling back to the start.
    static func nextDay(program: String, custom: [CustomTemplate], sessions: [WorkoutSession]) -> RoutineDay? {
        let days = days(for: program, custom: custom)
        guard !days.isEmpty else { return nil }
        let titles = days.map(\.title)
        let lastDone = sessions
            .filter { $0.isFinished && titles.contains($0.notes) }
            .sorted { $0.date > $1.date }
            .first
        guard let lastDone, let index = titles.firstIndex(of: lastDone.notes) else {
            return days.first
        }
        return days[(index + 1) % days.count]
    }
}
