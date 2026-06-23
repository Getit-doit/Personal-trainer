import SwiftUI
import SwiftData

/// A coach chat you can open mid-workout. It knows what you're doing right now
/// (current lift, last set, what's next) and supports hands-free voice — tap the
/// mic to talk, and replies can be read aloud.
struct InWorkoutCoachView: View {
    @Environment(\.dismiss) private var dismiss
    let session: WorkoutSession

    @Query private var profiles: [UserProfile]
    @Query private var sessions: [WorkoutSession]
    @Query private var nutrition: [NutritionLog]
    @Query private var prs: [PersonalBest]
    @Query private var exercises: [Exercise]

    @StateObject private var voice = VoiceService()
    @State private var messages: [CoachMessage] = [
        CoachMessage(text: "I'm right here mid-workout — ask me anything about this "
            + "session, your next set, form, or swaps. Tap the mic to talk.", isUser: false)
    ]
    @State private var draft = ""
    @State private var isThinking = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { bubble($0).id($0.id) }
                            if isThinking { CoachPendingView() }
                        }
                        .padding()
                    }
                    .onChange(of: messages) {
                        if let last = messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }
                inputBar
            }
            .blueprintBackground()
            .navigationTitle("Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        voice.speakReplies.toggle()
                        if !voice.speakReplies { voice.stopSpeaking() }
                    } label: {
                        Image(systemName: voice.speakReplies ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .foregroundStyle(voice.speakReplies ? Theme.accent : .secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await voice.requestAuthorization() }
            .onChange(of: voice.transcript) {
                if voice.isListening { draft = voice.transcript }
            }
            .onDisappear { voice.reset() }
        }
    }

    private func bubble(_ message: CoachMessage) -> some View {
        HStack {
            if message.isUser { Spacer(minLength: 40) }
            if message.isUser {
                Text(message.text)
                    .padding(12)
                    .background(Theme.accent)
                    .foregroundStyle(Theme.blueprintDeep)
            } else {
                VStack(alignment: .leading, spacing: 7) {
                    Text("COACH").font(Theme.mono(9, weight: .semibold)).tracking(1.6).foregroundStyle(Theme.accent)
                    Text(message.text).foregroundStyle(.primary)
                }
                .padding(12)
                .background(Theme.card)
                .overlay(Rectangle().stroke(Theme.hairline, lineWidth: 1))
            }
            if !message.isUser { Spacer(minLength: 40) }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            if voice.dictationAvailable {
                Button(action: toggleMic) {
                    Image(systemName: voice.isListening ? "stop.circle.fill" : "mic.fill")
                        .font(.headline)
                        .frame(width: 42, height: 42)
                        .background(voice.isListening ? Theme.amber : Theme.card)
                        .overlay(Rectangle().stroke(Theme.hairline, lineWidth: voice.isListening ? 0 : 1))
                        .foregroundStyle(voice.isListening ? Theme.blueprintDeep : Theme.accent)
                }
                .buttonStyle(.plain)
            }

            TextField(voice.isListening ? "Listening…" : "Ask your coach…", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .padding(11)
                .background(Theme.card)
                .overlay(Rectangle().stroke(Theme.hairline, lineWidth: 1))

            Button(action: { send(draft) }) {
                Image(systemName: "arrow.up")
                    .font(.headline)
                    .frame(width: 42, height: 42)
                    .background(Theme.accent)
                    .foregroundStyle(Theme.blueprintDeep)
            }
            .buttonStyle(.plain)
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty || isThinking)
        }
        .padding()
    }

    private func toggleMic() {
        if voice.isListening {
            voice.stopListening()
        } else {
            voice.stopSpeaking()
            draft = ""
            voice.startListening()
        }
    }

    private func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        voice.stopListening()

        draft = ""
        DispatchQueue.main.async { draft = "" }
        let history = messages
        messages.append(CoachMessage(text: trimmed, isUser: true))
        isThinking = true

        let full = CoachMemory.build(
            profile: profiles.first, sessions: sessions,
            nutrition: nutrition, prs: prs, exercises: exercises
        )
        let base = CoachMemory.condensed(
            full: full, profile: profiles.first, sessions: sessions, nutrition: nutrition
        )
        let memory = base + "\n\n## Right now (live workout)\n" + CoachMemory.liveSession(session)

        Task {
            let reply = await CoachService.reply(to: trimmed, history: history, memory: memory)
            await MainActor.run {
                isThinking = false
                messages.append(CoachMessage(text: reply, isUser: false))
                voice.speak(reply)
            }
        }
    }
}
