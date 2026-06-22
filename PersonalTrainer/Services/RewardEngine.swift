import Foundation

/// The gamification core: a catalog of achievements, logic to detect newly
/// earned ones from the athlete's data, and the level/points curve. The AI layer
/// (CoachService) writes the personalized recognition copy on top of this.
enum RewardEngine {

    enum Tier: String { case bronze, silver, gold }

    /// A definition in the catalog. `met` is a pure predicate over a snapshot of
    /// the athlete's progress.
    struct Def: Identifiable {
        let id: String
        let title: String
        let detail: String
        let icon: String        // SF Symbol
        let tier: Tier
        let points: Int
        let met: (Snapshot) -> Bool
    }

    /// Everything the criteria look at, computed once per evaluation.
    struct Snapshot {
        let finishedWorkouts: Int
        let workoutsThisWeek: Int
        let weekStreak: Int          // consecutive weeks with ≥1 workout
        let prCount: Int
        let ankleWarmups: Int
        let longestDietStreak: Int   // best current streak across all habits, days
        let steamRoomSessions: Int

        init(sessions: [WorkoutSession], prs: [PersonalBest], habits: [DietHabit]) {
            let finished = sessions.filter(\.isFinished)
            finishedWorkouts = finished.count
            prCount = prs.count
            ankleWarmups = finished.filter(\.ankleWarmupDone).count
            steamRoomSessions = finished.filter(\.steamRoom).count

            let cal = Calendar.current
            let weekAgo = cal.date(byAdding: .day, value: -7, to: .now) ?? .now
            workoutsThisWeek = finished.filter { $0.date >= weekAgo }.count

            // Consecutive weeks (back from this one) containing at least one workout.
            let workoutWeeks = Set(finished.map { cal.component(.weekOfYear, from: $0.date) * 100 + cal.component(.yearForWeekOfYear, from: $0.date) })
            var streak = 0
            var cursor = Date.now
            while true {
                let key = cal.component(.weekOfYear, from: cursor) * 100 + cal.component(.yearForWeekOfYear, from: cursor)
                if workoutWeeks.contains(key) { streak += 1 } else { break }
                guard let prev = cal.date(byAdding: .day, value: -7, to: cursor) else { break }
                cursor = prev
            }
            weekStreak = streak

            longestDietStreak = habits.filter(\.isActive)
                .map { HabitEngine.streakDays($0) }
                .max() ?? 0
        }
    }

    static let catalog: [Def] = [
        Def(id: "first_workout", title: "First Rep", detail: "Logged your first workout.",
            icon: "figure.strengthtraining.traditional", tier: .bronze, points: 10) { $0.finishedWorkouts >= 1 },
        Def(id: "workouts_5", title: "Getting Consistent", detail: "5 workouts in the books.",
            icon: "5.circle.fill", tier: .bronze, points: 20) { $0.finishedWorkouts >= 5 },
        Def(id: "workouts_25", title: "Building the Base", detail: "25 workouts logged.",
            icon: "25.circle.fill", tier: .silver, points: 50) { $0.finishedWorkouts >= 25 },
        Def(id: "workouts_50", title: "Iron Habit", detail: "50 workouts — this is who you are now.",
            icon: "50.circle.fill", tier: .gold, points: 100) { $0.finishedWorkouts >= 50 },
        Def(id: "workouts_100", title: "Centurion", detail: "100 workouts. Elite consistency.",
            icon: "trophy.fill", tier: .gold, points: 200) { $0.finishedWorkouts >= 100 },

        Def(id: "week_3x", title: "Full Week", detail: "3 workouts in one week.",
            icon: "calendar.badge.checkmark", tier: .silver, points: 30) { $0.workoutsThisWeek >= 3 },
        Def(id: "weeks_4", title: "Month of Showing Up", detail: "4 weeks in a row with a workout.",
            icon: "flame.fill", tier: .silver, points: 60) { $0.weekStreak >= 4 },
        Def(id: "weeks_12", title: "Quarter Locked In", detail: "12-week training streak.",
            icon: "flame.circle.fill", tier: .gold, points: 150) { $0.weekStreak >= 12 },

        Def(id: "first_pr", title: "New Best", detail: "Set your first personal record.",
            icon: "star.fill", tier: .bronze, points: 15) { $0.prCount >= 1 },
        Def(id: "pr_10", title: "Record Breaker", detail: "10 personal records.",
            icon: "rosette", tier: .gold, points: 80) { $0.prCount >= 10 },

        Def(id: "ankle_10", title: "Joint Steward", detail: "Did the ankle warm-up 10 times.",
            icon: "shoeprints.fill", tier: .silver, points: 40) { $0.ankleWarmups >= 10 },
        Def(id: "steam_5", title: "Down-Regulator", detail: "5 steam-room recovery sessions.",
            icon: "humidity.fill", tier: .bronze, points: 20) { $0.steamRoomSessions >= 5 },

        Def(id: "diet_7", title: "One Week Strong", detail: "Held a nutrition lever for a week.",
            icon: "leaf.fill", tier: .bronze, points: 20) { $0.longestDietStreak >= 7 },
        Def(id: "diet_30", title: "Lever Locked", detail: "A nutrition lever held for a month.",
            icon: "leaf.circle.fill", tier: .silver, points: 60) { $0.longestDietStreak >= 30 },
        Def(id: "diet_90", title: "New Default", detail: "90 days on a nutrition lever — it's automatic now.",
            icon: "seal.fill", tier: .gold, points: 120) { $0.longestDietStreak >= 90 }
    ]

    static func def(for id: String) -> Def? { catalog.first { $0.id == id } }

    /// Catalog entries not yet earned whose criteria are now met.
    static func newlyEarned(snapshot: Snapshot, earnedIDs: Set<String>) -> [Def] {
        catalog.filter { !earnedIDs.contains($0.id) && $0.met(snapshot) }
    }

    // MARK: - Level curve

    /// Level from total points: every 100 points is a level (level 1 at 0).
    static func level(forPoints points: Int) -> Int { points / 100 + 1 }
    static func pointsIntoLevel(_ points: Int) -> Int { points % 100 }
    static func progressInLevel(_ points: Int) -> Double { Double(points % 100) / 100.0 }

    static func tierColorName(_ tier: String) -> Tier { Tier(rawValue: tier) ?? .bronze }
}
