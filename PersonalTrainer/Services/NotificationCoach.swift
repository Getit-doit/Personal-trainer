import Foundation
import SwiftData
import UserNotifications

/// Drives the coach's notification check-ins and the recognition/reward system:
///   • schedules diet-lever questions as notifications with Yes / No buttons,
///   • records the answers, tracks streaks, and celebrates milestones,
///   • evaluates achievements from training + nutrition data and celebrates them.
///
/// Holds the `ModelContainer` so notification responses (which arrive outside any
/// SwiftUI view) can read and write the store on the main actor.
@MainActor
final class NotificationCoach: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationCoach()

    // Categories & actions registered with the system.
    static let leverCategory = "DIET_LEVER"
    static let celebrationCategory = "CELEBRATION"
    static let actionYes = "LEVER_YES"
    static let actionNo = "LEVER_NO"
    static let actionFeelGreat = "FEEL_GREAT"
    static let actionFeelTough = "FEEL_TOUGH"

    @Published var authorized = false

    private var container: ModelContainer?
    private var center: UNUserNotificationCenter { .current() }

    /// Wire up the delegate and categories, and learn the current auth state.
    /// Call once at launch with the app's shared container.
    func configure(container: ModelContainer) {
        self.container = container
        center.delegate = self
        registerCategories()
        center.getNotificationSettings { settings in
            let ok = settings.authorizationStatus == .authorized
            Task { @MainActor in self.authorized = ok; if ok { self.rescheduleAll() } }
        }
    }

    func requestAuthorization() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            authorized = granted
            if granted { rescheduleAll() }
        } catch {
            authorized = false
        }
    }

    private func registerCategories() {
        let yes = UNNotificationAction(identifier: Self.actionYes, title: "Yes", options: [])
        let no = UNNotificationAction(identifier: Self.actionNo, title: "No", options: [])
        let lever = UNNotificationCategory(
            identifier: Self.leverCategory, actions: [yes, no],
            intentIdentifiers: [], options: []
        )

        let great = UNNotificationAction(identifier: Self.actionFeelGreat, title: "Feeling great 💪", options: [])
        let tough = UNNotificationAction(identifier: Self.actionFeelTough, title: "Still tough", options: [])
        let celebration = UNNotificationCategory(
            identifier: Self.celebrationCategory, actions: [great, tough],
            intentIdentifiers: [], options: []
        )

        center.setNotificationCategories([lever, celebration])
    }

    // MARK: - Scheduling check-ins

    /// Re-schedule the next check-in for every active habit. Safe to call often
    /// (e.g. on foreground or after editing habits).
    func rescheduleAll() {
        guard authorized, let container else { return }
        let habits = (try? container.mainContext.fetch(FetchDescriptor<DietHabit>())) ?? []
        center.removePendingNotificationRequests(
            withIdentifiers: habits.map { checkInID($0) }
        )
        for habit in habits where habit.isActive {
            scheduleNext(for: habit)
        }
    }

    private func checkInID(_ habit: DietHabit) -> String { "checkin-\(habit.id.uuidString)" }

    /// Schedule the next single check-in for a habit at its preferred time,
    /// `frequencyDays` after its last activity (never in the past).
    private func scheduleNext(for habit: DietHabit) {
        guard authorized else { return }
        let cal = Calendar.current
        let last = habit.checkIns.map(\.date).max() ?? habit.startDate
        var fire = cal.date(byAdding: .day, value: habit.frequencyDays, to: last) ?? Date()
        fire = cal.date(bySettingHour: habit.hour, minute: habit.minute, second: 0, of: fire) ?? fire
        if fire < Date().addingTimeInterval(60) {
            let todayAt = cal.date(bySettingHour: habit.hour, minute: habit.minute, second: 0, of: Date()) ?? Date()
            fire = todayAt > Date() ? todayAt : (cal.date(byAdding: .day, value: 1, to: todayAt) ?? todayAt)
        }

        let content = UNMutableNotificationContent()
        content.title = habit.title
        content.body = habit.question
        content.categoryIdentifier = Self.leverCategory
        content.userInfo = ["kind": "checkin", "habitID": habit.id.uuidString]
        content.sound = .default

        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        center.add(UNNotificationRequest(identifier: checkInID(habit), content: content, trigger: trigger))
    }

    /// Record an answer directly (used by the in-app Yes/No buttons too).
    func record(habit: DietHabit, answeredYes: Bool) {
        guard let container else { return }
        let ctx = container.mainContext
        let wasGood = (answeredYes == habit.goodAnswerIsYes)
        let checkIn = HabitCheckIn(answeredYes: answeredYes, wasGood: wasGood)
        ctx.insert(checkIn)
        habit.checkIns.append(checkIn)   // sets the inverse relationship
        if !wasGood { habit.lastCelebratedMilestone = 0 }   // streak broke
        try? ctx.save()

        if let milestone = HabitEngine.pendingCelebration(habit) {
            habit.lastCelebratedMilestone = milestone
            try? ctx.save()
            scheduleCelebration(for: habit, days: milestone)
        }
        scheduleNext(for: habit)
        evaluateRewards()   // streak may have unlocked a diet achievement
    }

    private func scheduleCelebration(for habit: DietHabit, days: Int) {
        guard authorized else { return }
        let content = UNMutableNotificationContent()
        content.title = "🎉 \(habit.title)"
        content.body = HabitEngine.celebrationText(for: habit, days: days)
        content.categoryIdentifier = Self.celebrationCategory
        content.userInfo = ["kind": "celebration", "habitID": habit.id.uuidString]
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        center.add(UNNotificationRequest(
            identifier: "celebrate-\(habit.id.uuidString)-\(days)",
            content: content, trigger: trigger
        ))
    }

    // MARK: - Achievements / rewards

    /// Detect and persist any newly earned achievements, celebrate them, and
    /// kick off AI recognition copy. Returns the new awards (for in-app banners).
    @discardableResult
    func evaluateRewards() -> [Achievement] {
        guard let container else { return [] }
        let ctx = container.mainContext
        let sessions = (try? ctx.fetch(FetchDescriptor<WorkoutSession>())) ?? []
        let prs = (try? ctx.fetch(FetchDescriptor<PersonalBest>())) ?? []
        let habits = (try? ctx.fetch(FetchDescriptor<DietHabit>())) ?? []
        let earned = (try? ctx.fetch(FetchDescriptor<Achievement>())) ?? []

        let snapshot = RewardEngine.Snapshot(sessions: sessions, prs: prs, habits: habits)
        let newDefs = RewardEngine.newlyEarned(snapshot: snapshot, earnedIDs: Set(earned.map(\.defID)))
        guard !newDefs.isEmpty else { return [] }

        var created: [Achievement] = []
        for def in newDefs {
            let a = Achievement(
                defID: def.id, title: def.title, detail: def.detail,
                icon: def.icon, tier: def.tier.rawValue, points: def.points
            )
            ctx.insert(a)
            created.append(a)
            scheduleAchievementCelebration(a)
        }
        try? ctx.save()
        Task { await self.fillRecognition(for: created) }
        return created
    }

    private func scheduleAchievementCelebration(_ a: Achievement) {
        guard authorized else { return }
        let content = UNMutableNotificationContent()
        content.title = "🏆 Achievement unlocked"
        content.body = "\(a.title) — \(a.detail)"
        content.userInfo = ["kind": "achievement", "defID": a.defID]
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        center.add(UNNotificationRequest(identifier: "ach-\(a.defID)", content: content, trigger: trigger))
    }

    /// Ask the AI coach for a short, personalized recognition line per award.
    /// Best-effort: falls back silently to the catalog detail already shown.
    private func fillRecognition(for achievements: [Achievement]) async {
        // Only a real generative engine writes good recognition copy; the
        // rule-based offline coach would return generic advice, so skip it and
        // let the catalog detail stand.
        guard CoachService.activeEngine != .offline else { return }
        for a in achievements {
            let prompt = "The athlete just earned the achievement \"\(a.title)\": \(a.detail). "
                + "Write one short, specific, genuinely encouraging congratulations "
                + "(max 30 words, at most one emoji)."
            if let line = await CoachService.oneShot(prompt) {
                a.recognition = line
            }
        }
        try? container?.mainContext.save()
    }

    // MARK: - Delegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let info = response.notification.request.content.userInfo
        let kind = info["kind"] as? String ?? ""
        let habitID = info["habitID"] as? String
        let action = response.actionIdentifier
        await MainActor.run { self.handle(kind: kind, action: action, habitID: habitID) }
    }

    private func handle(kind: String, action: String, habitID: String?) {
        guard let container else { return }
        let ctx = container.mainContext
        guard let habitID, let uuid = UUID(uuidString: habitID),
              let habit = fetchHabit(uuid, ctx: ctx) else { return }

        switch (kind, action) {
        case ("checkin", Self.actionYes): record(habit: habit, answeredYes: true)
        case ("checkin", Self.actionNo):  record(habit: habit, answeredYes: false)
        case ("celebration", Self.actionFeelGreat):
            habit.lastReflection = "Feeling great"; try? ctx.save()
        case ("celebration", Self.actionFeelTough):
            habit.lastReflection = "Still tough"; try? ctx.save()
        default:
            break   // tapped/dismissed — handled in-app
        }
    }

    private func fetchHabit(_ id: UUID, ctx: ModelContext) -> DietHabit? {
        let descriptor = FetchDescriptor<DietHabit>(predicate: #Predicate { $0.id == id })
        return try? ctx.fetch(descriptor).first
    }
}
