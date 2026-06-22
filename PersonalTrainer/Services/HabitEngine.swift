import Foundation

/// Pure logic for diet-lever streaks: how long the athlete has held a habit,
/// which milestone they're on, and the copy used to ask and to celebrate.
enum HabitEngine {

    /// Day milestones we celebrate, smallest → largest.
    static let milestones = [3, 7, 14, 30, 60, 90, 180, 365]

    /// The day the current good streak began: the day after the most recent
    /// "bad" answer, or the habit's start date if it has never broken.
    static func streakStart(_ habit: DietHabit) -> Date {
        let lastBad = habit.checkIns
            .filter { !$0.wasGood }
            .map(\.date)
            .max()
        guard let lastBad else { return habit.startDate }
        let cal = Calendar.current
        return cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: lastBad)) ?? lastBad
    }

    /// Whole days the current good streak has lasted (0 if it just reset).
    static func streakDays(_ habit: DietHabit, asOf now: Date = .now) -> Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: streakStart(habit))
        let today = cal.startOfDay(for: now)
        return max(0, cal.dateComponents([.day], from: start, to: today).day ?? 0)
    }

    /// The highest milestone the current streak has reached, or nil.
    static func currentMilestone(_ habit: DietHabit, asOf now: Date = .now) -> Int? {
        let days = streakDays(habit, asOf: now)
        return milestones.filter { $0 <= days }.max()
    }

    /// The next milestone still ahead, for "X days to go" UI.
    static func nextMilestone(_ habit: DietHabit, asOf now: Date = .now) -> Int? {
        let days = streakDays(habit, asOf: now)
        return milestones.first { $0 > days }
    }

    /// A new milestone that has been crossed but not yet celebrated, if any.
    static func pendingCelebration(_ habit: DietHabit, asOf now: Date = .now) -> Int? {
        guard let reached = currentMilestone(habit, asOf: now),
              reached > habit.lastCelebratedMilestone else { return nil }
        return reached
    }

    /// Human phrase for a milestone, e.g. "over a month", "a week".
    static func milestonePhrase(_ days: Int) -> String {
        switch days {
        case 365...: return "a full year"
        case 180...: return "six months"
        case 90...: return "three months"
        case 60...: return "two months"
        case 30...: return "over a month"
        case 14...: return "two weeks"
        case 7...: return "a week"
        default: return "\(days) days"
        }
    }

    /// Default celebration body, e.g. for "No soda" reaching 30 days:
    /// "Congratulations — you've kept No soda going for over a month! How do you feel?"
    static func celebrationText(for habit: DietHabit, days: Int) -> String {
        "Congratulations — you've kept \"\(habit.title)\" going for "
            + "\(milestonePhrase(days))! How do you feel?"
    }

    // MARK: - Suggested levers

    /// Starter levers the athlete can add with one tap. `goodAnswerIsYes` encodes
    /// whether "Yes" is the win.
    struct Suggestion {
        let title: String
        let question: String
        let goodAnswerIsYes: Bool
    }

    static let suggestions: [Suggestion] = [
        Suggestion(title: "No soda",
                   question: "Have you had any soda the last few days?",
                   goodAnswerIsYes: false),
        Suggestion(title: "Morning protein",
                   question: "Did you drink your protein every morning this week?",
                   goodAnswerIsYes: true),
        Suggestion(title: "No late-night snacking",
                   question: "Did you avoid late-night snacking these past few nights?",
                   goodAnswerIsYes: true),
        Suggestion(title: "Hydration",
                   question: "Have you been hitting your water target lately?",
                   goodAnswerIsYes: true),
        Suggestion(title: "No fast food",
                   question: "Have you had any fast food the last few days?",
                   goodAnswerIsYes: false),
        Suggestion(title: "No alcohol",
                   question: "Have you had any alcohol the last few days?",
                   goodAnswerIsYes: false),
        Suggestion(title: "Veggies daily",
                   question: "Did you get vegetables in every day this week?",
                   goodAnswerIsYes: true)
    ]
}
