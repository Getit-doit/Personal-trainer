import SwiftUI
import AudioToolbox

/// A simple countdown rest timer with pause/resume, ±time, and a finish chime.
/// Auto-started when a set is completed; controllable from the rest bar.
@MainActor
final class RestTimer: ObservableObject {
    @Published private(set) var remaining = 0
    @Published private(set) var total = 0
    @Published private(set) var isRunning = false

    private var timer: Timer?

    /// True whenever there's time on the clock or it's counting.
    var isActive: Bool { remaining > 0 || isRunning }

    func start(seconds: Int) {
        guard seconds > 0 else { return }
        total = seconds
        remaining = seconds
        isRunning = true
        schedule()
    }

    /// Adjust the running clock (e.g. +15 / -15). Restarts ticking if needed.
    func addTime(_ delta: Int) {
        remaining = max(0, remaining + delta)
        total = max(total, remaining)
        if remaining > 0 && !isRunning {
            isRunning = true
            schedule()
        }
    }

    func togglePause() {
        if isRunning {
            timer?.invalidate()
            isRunning = false
        } else if remaining > 0 {
            isRunning = true
            schedule()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        remaining = 0
        total = 0
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
    }

    var label: String {
        String(format: "%d:%02d", remaining / 60, remaining % 60)
    }

    var progress: Double {
        total > 0 ? Double(total - remaining) / Double(total) : 0
    }
}
