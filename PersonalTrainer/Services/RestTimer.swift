import SwiftUI
import AudioToolbox
import ActivityKit
import UserNotifications

/// A simple countdown rest timer with pause/resume, ±time, and a finish alarm.
/// Auto-started when a set is completed; also drives a Live Activity on the lock
/// screen and Dynamic Island via ActivityKit, and schedules a local notification
/// so the alarm fires even when the app is backgrounded or the screen is locked.
@MainActor
final class RestTimer: ObservableObject {
    @Published private(set) var remaining = 0
    @Published private(set) var total = 0
    @Published private(set) var isRunning = false
    /// True briefly after the timer hits 0, so the bar can offer "+15s" if the
    /// rest felt too short.
    @Published private(set) var didFinish = false

    private var timer: Timer?
    private var exerciseName = ""
    private var activity: Activity<RestActivityAttributes>?
    private let restNotifID = "rest-timer-done"
    /// Wall-clock end time while running, so the countdown stays correct across
    /// backgrounding (the in-process timer is suspended in the background).
    private var endDate: Date?

    /// True whenever there's time on the clock, it's counting, or it just finished.
    var isActive: Bool { remaining > 0 || isRunning || didFinish }

    func start(seconds: Int, exerciseName: String = "") {
        guard seconds > 0 else { return }
        self.exerciseName = exerciseName
        total = seconds
        remaining = seconds
        isRunning = true
        didFinish = false
        endDate = Date().addingTimeInterval(Double(seconds))
        schedule()
        startActivity()
        ensureNotificationAuth()
        scheduleRestNotification(after: seconds)
    }

    /// Adjust the running clock (e.g. +15 / -15), or extend a just-finished rest.
    func addTime(_ delta: Int) {
        remaining = max(0, remaining + delta)
        total = max(total, remaining)
        if remaining > 0 {
            didFinish = false
            if !isRunning { isRunning = true; schedule() }
            endDate = Date().addingTimeInterval(Double(remaining))
            if activity == nil { startActivity() } else { updateActivity() }
            scheduleRestNotification(after: remaining)
        }
    }

    /// Reconcile the displayed countdown with the real clock — call when the app
    /// returns to the foreground, since the in-process timer pauses in background.
    func syncToWallClock() {
        guard isRunning, let endDate else { return }
        let secs = Int(endDate.timeIntervalSinceNow.rounded(.up))
        remaining = max(0, secs)
        if remaining == 0 { finish() }
    }

    func togglePause() {
        if isRunning {
            timer?.invalidate()
            isRunning = false
            endDate = nil
            cancelRestNotification()
        } else if remaining > 0 {
            isRunning = true
            endDate = Date().addingTimeInterval(Double(remaining))
            schedule()
            scheduleRestNotification(after: remaining)
        }
        updateActivity()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        didFinish = false
        remaining = 0
        total = 0
        endDate = nil
        cancelRestNotification()
        endActivity()
    }

    private func schedule() {
        timer?.invalidate()
        // .common so the countdown keeps ticking while the user scrolls the
        // workout list (default-mode timers pause during scroll tracking).
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        guard remaining > 0 else { finish(); return }
        remaining -= 1
        if remaining == 0 { finish() }
    }

    private func finish() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        didFinish = true
        endDate = nil
        cancelRestNotification()   // foreground: our own alarm handles it
        RestAlert.fire()           // sound + haptic per user settings
        endActivity()
    }

    // MARK: - Background alarm (local notification)

    private func ensureNotificationAuth() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
            }
        }
    }

    private func scheduleRestNotification(after seconds: Int) {
        guard seconds > 0 else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [restNotifID])
        let content = UNMutableNotificationContent()
        content.title = "Rest's up"
        content.body = exerciseName.isEmpty ? "Time for your next set." : "Back to \(exerciseName)."
        content.userInfo = ["kind": "rest"]
        if (UserDefaults.standard.object(forKey: "restSoundOn") as? Bool) ?? true {
            content.sound = .default
        }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(seconds), repeats: false)
        center.add(UNNotificationRequest(identifier: restNotifID, content: content, trigger: trigger))
    }

    private func cancelRestNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [restNotifID])
    }

    var label: String {
        String(format: "%d:%02d", remaining / 60, remaining % 60)
    }

    var progress: Double {
        total > 0 ? Double(total - remaining) / Double(total) : 0
    }

    // MARK: - Live Activity

    private var contentState: RestActivityAttributes.ContentState {
        RestActivityAttributes.ContentState(
            endDate: Date().addingTimeInterval(Double(remaining)),
            isRunning: isRunning,
            exerciseName: exerciseName
        )
    }

    private func startActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled, activity == nil else { return }
        do {
            activity = try Activity.request(
                attributes: RestActivityAttributes(title: "Rest"),
                content: ActivityContent(state: contentState, staleDate: nil),
                pushType: nil
            )
        } catch {
            activity = nil
        }
    }

    private func updateActivity() {
        guard let activity else { return }
        let state = contentState
        Task { await activity.update(ActivityContent(state: state, staleDate: nil)) }
    }

    private func endActivity() {
        guard let activity else { return }
        let finalState = RestActivityAttributes.ContentState(
            endDate: Date(), isRunning: false, exerciseName: exerciseName
        )
        Task {
            await activity.end(ActivityContent(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
        }
        self.activity = nil
    }
}

/// The in-app rest-finish alarm: plays the chosen chime + haptic per the user's
/// settings, optionally repeating (insistent) for a noisy gym. Used by the timer
/// and by the settings preview.
enum RestAlert {
    /// Selectable chime sounds (system sound IDs). Preview lets users pick by ear.
    static let sounds: [(id: Int, name: String)] = [
        (1057, "Chime"),
        (1005, "Alert"),
        (1013, "Tock"),
        (1322, "Bloom")
    ]

    static func fire() {
        let d = UserDefaults.standard
        if (d.object(forKey: "restSoundOn") as? Bool) ?? true {
            let id = SystemSoundID(UInt32((d.object(forKey: "restSoundID") as? Int) ?? 1057))
            let repeats = d.bool(forKey: "restInsistent") ? 3 : 1
            for i in 0..<repeats {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.55) {
                    AudioServicesPlaySystemSound(id)
                }
            }
        }
        if (d.object(forKey: "restHapticOn") as? Bool) ?? true {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    /// Play a single sound for the settings preview.
    static func preview(soundID: Int) {
        AudioServicesPlaySystemSound(SystemSoundID(UInt32(soundID)))
    }
}
