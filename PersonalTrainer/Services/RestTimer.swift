import SwiftUI
import AudioToolbox
import ActivityKit

/// A simple countdown rest timer with pause/resume, ±time, and a finish chime.
/// Auto-started when a set is completed; also drives a Live Activity on the lock
/// screen and Dynamic Island via ActivityKit.
@MainActor
final class RestTimer: ObservableObject {
    @Published private(set) var remaining = 0
    @Published private(set) var total = 0
    @Published private(set) var isRunning = false

    private var timer: Timer?
    private var exerciseName = ""
    private var activity: Activity<RestActivityAttributes>?

    /// True whenever there's time on the clock or it's counting.
    var isActive: Bool { remaining > 0 || isRunning }

    func start(seconds: Int, exerciseName: String = "") {
        guard seconds > 0 else { return }
        self.exerciseName = exerciseName
        total = seconds
        remaining = seconds
        isRunning = true
        schedule()
        startActivity()
    }

    /// Adjust the running clock (e.g. +15 / -15). Restarts ticking if needed.
    func addTime(_ delta: Int) {
        remaining = max(0, remaining + delta)
        total = max(total, remaining)
        if remaining > 0 && !isRunning {
            isRunning = true
            schedule()
        }
        updateActivity()
    }

    func togglePause() {
        if isRunning {
            timer?.invalidate()
            isRunning = false
        } else if remaining > 0 {
            isRunning = true
            schedule()
        }
        updateActivity()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        remaining = 0
        total = 0
        endActivity()
    }

    private func schedule() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
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
        AudioServicesPlaySystemSound(1057)                          // light alert tone
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        endActivity()
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
