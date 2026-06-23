import SwiftUI

/// A reusable list of the app's permissions with one-tap enable + live status.
/// Used during onboarding (so users grant up front) and in Settings (to manage
/// them later). Each request shows the system prompt; already-granted ones show ✓.
struct PermissionsView: View {
    @ObservedObject private var notif = NotificationCoach.shared
    @StateObject private var health = HealthService()
    @StateObject private var voice = VoiceService()
    @StateObject private var music = MusicService()
    @State private var working = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            row("Notifications", "bell.fill",
                detail: "Check-in reminders & rest-timer alarm",
                granted: notif.authorized) { await notif.requestAuthorization() }
            row("Apple Health", "heart.fill",
                detail: "Sleep, weight & steps; saves workouts",
                granted: health.authorized) { await health.requestAuthorization() }
            row("Microphone & Speech", "mic.fill",
                detail: "Talk to your coach hands-free",
                granted: voice.dictationAvailable) { await voice.requestAuthorization() }
            row("Apple Music", "music.note",
                detail: "Play your workout playlist",
                granted: music.authorized) { await music.requestAuthorization() }

            Button {
                Task {
                    working = true
                    await notif.requestAuthorization()
                    await health.requestAuthorization()
                    await voice.requestAuthorization()
                    await music.requestAuthorization()
                    working = false
                }
            } label: {
                HStack {
                    Text("ENABLE ALL").font(Theme.mono(12, weight: .semibold)).tracking(1)
                    if working { ProgressView().padding(.leading, 4) }
                }
                .frame(maxWidth: .infinity).padding(.vertical, 11)
                .background(Theme.accent).foregroundStyle(Theme.blueprintDeep)
            }
            .buttonStyle(.plain)
            .disabled(working)
            .padding(.top, 2)
        }
    }

    private func row(_ name: String, _ icon: String, detail: String,
                     granted: Bool, request: @escaping () async -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(granted ? Theme.accent : .secondary)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(name).font(.subheadline)
                Text(detail).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            if granted {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.accent)
            } else {
                Button("Enable") { Task { await request() } }
                    .font(.caption).tint(Theme.accent)
            }
        }
    }
}
