import SwiftUI
import SwiftData

/// A persistent "AI COACH" bar at the top of the workout screen with live voice
/// waves. Tap to talk: it listens hands-free, auto-sends when you stop, speaks
/// the reply, then listens again so you can converse without tapping. It knows
/// the live session context (current lift, last set, what's next).
struct CoachVoiceBar: View {
    let session: WorkoutSession

    @Query private var profiles: [UserProfile]
    @Query private var sessions: [WorkoutSession]
    @Query private var nutrition: [NutritionLog]
    @Query private var prs: [PersonalBest]
    @Query private var exercises: [Exercise]
    @StateObject private var voice = VoiceService()

    private enum Phase { case idle, listening, thinking, speaking }
    @State private var phase: Phase = .idle
    @State private var conversing = false
    @State private var lastLine = ""

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("AI COACH")
                    .font(Theme.mono(9, weight: .semibold)).tracking(1.6)
                    .foregroundStyle(Theme.accent)
                Text(statusText)
                    .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 8)
            VoiceWaveform(
                level: CGFloat(voice.level),
                speaking: phase == .speaking,
                active: phase == .listening || phase == .speaking
            )
            .frame(width: 92, height: 24)

            Button(action: toggle) {
                Image(systemName: micIcon)
                    .font(.headline)
                    .frame(width: 40, height: 34)
                    .background(phase == .listening ? Theme.amber : Theme.accent,
                                in: RoundedRectangle(cornerRadius: 9))
                    .foregroundStyle(Theme.blueprintDeep)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal).padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .overlay(Divider(), alignment: .bottom)
        .onChange(of: voice.isListening) { _, listening in
            // Listening ended (silence or manual stop): send if we caught anything.
            guard phase == .listening, !listening else { return }
            let text = voice.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty { phase = .idle; conversing = false }
            else { send(text) }
        }
        .onChange(of: voice.isSpeaking) { _, speaking in
            guard phase == .speaking, !speaking else { return }
            if conversing { startListening() } else { phase = .idle }
        }
        .onDisappear { voice.reset(); conversing = false; phase = .idle }
    }

    // MARK: Display

    private var statusText: String {
        switch phase {
        case .idle: return "Tap to talk"
        case .listening: return voice.transcript.isEmpty ? "Listening…" : voice.transcript
        case .thinking: return "Thinking…"
        case .speaking: return lastLine.isEmpty ? "Speaking…" : lastLine
        }
    }

    private var micIcon: String {
        switch phase {
        case .listening: return "stop.fill"
        case .thinking, .speaking: return "waveform"
        case .idle: return "mic.fill"
        }
    }

    // MARK: Conversation

    private func toggle() {
        switch phase {
        case .idle:
            conversing = true
            startListening()
        case .listening:
            voice.stopListening()        // onChange handles send / idle
        case .thinking:
            break
        case .speaking:
            voice.stopSpeaking()
            conversing = false
            phase = .idle
        }
    }

    private func startListening() {
        Task {
            if !voice.dictationAvailable { await voice.requestAuthorization() }
            guard voice.dictationAvailable else {
                phase = .idle; conversing = false; return
            }
            phase = .listening
            voice.startListening()
        }
    }

    private func send(_ text: String) {
        phase = .thinking
        let full = CoachMemory.build(
            profile: profiles.first, sessions: sessions,
            nutrition: nutrition, prs: prs, exercises: exercises
        )
        let base = CoachMemory.condensed(
            full: full, profile: profiles.first, sessions: sessions, nutrition: nutrition
        )
        let memory = base + "\n\n## Right now (live workout)\n" + CoachMemory.liveSession(session)
        Task {
            let reply = await CoachService.reply(to: text, history: [], memory: memory)
            lastLine = reply
            guard !reply.isEmpty else { phase = .idle; conversing = false; return }
            phase = .speaking
            voice.speakReplies = true
            voice.speak(reply)   // isSpeaking → false later drives the next turn
        }
    }
}

/// Animated voice bars: reacts to mic level while listening, animates a wave
/// while speaking, settles flat when idle.
struct VoiceWaveform: View {
    var level: CGFloat
    var speaking: Bool
    var active: Bool
    private let bars = 13

    var body: some View {
        TimelineView(.animation(paused: !active)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 3) {
                ForEach(0..<bars, id: \.self) { i in
                    Capsule()
                        .fill(Theme.accent.opacity(active ? 0.9 : 0.3))
                        .frame(width: 3, height: height(i, t))
                }
            }
        }
    }

    private func height(_ i: Int, _ t: Double) -> CGFloat {
        let mid = Double(bars - 1) / 2
        let center = 1 - abs(Double(i) - mid) / mid   // taller toward the middle
        let maxH: CGFloat = 22
        if speaking {
            let wave = 0.5 + 0.5 * sin(t * 6 + Double(i) * 0.6)
            return 4 + CGFloat(wave * center) * maxH
        } else if active {
            let jitter = 0.55 + 0.45 * sin(t * 9 + Double(i))
            return 4 + level * CGFloat(center * jitter) * maxH
        }
        return 4
    }
}
