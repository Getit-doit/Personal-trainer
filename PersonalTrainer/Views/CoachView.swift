import SwiftUI
import SwiftData

/// A chat message in the coach conversation.
struct CoachMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

/// The AI coach chat screen.
struct CoachView: View {
    @Query private var profiles: [UserProfile]
    @Query private var sessions: [WorkoutSession]
    @Query private var nutrition: [NutritionLog]
    @Query private var prs: [PersonalBest]
    @Query private var exercises: [Exercise]

    @State private var messages: [CoachMessage] = [
        CoachMessage(
            text: "Hey! I'm your AI coach. Ask me anything about training, "
                + "nutrition, or recovery — or which plan to start.",
            isUser: false
        )
    ]
    @State private var draft = ""
    @State private var isThinking = false

    private let suggestions = [
        "How do I lose fat?",
        "Build muscle plan",
        "I'm a beginner",
        "Help with recovery"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TitleBlock(eyebrow: "Constraint-aware", title: "Coach")
                    .padding(.horizontal).padding(.top, 8).padding(.bottom, 4)
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                bubble(message).id(message.id)
                            }
                            if isThinking {
                                CoachPendingView()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages) {
                        if let last = messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                if messages.count <= 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestions, id: \.self) { suggestion in
                                Button {
                                    send(suggestion)
                                } label: {
                                    Text(suggestion.uppercased())
                                        .font(Theme.mono(10, weight: .semibold)).tracking(0.6)
                                        .padding(.horizontal, 11).padding(.vertical, 8)
                                        .overlay(Rectangle().stroke(Theme.accent.opacity(0.5), lineWidth: 1))
                                        .foregroundStyle(Theme.accent)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 8)
                }

                inputBar
            }
            .blueprintBackground()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .task { CoachService.prewarm() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles").font(.caption2)
                        Text(CoachService.activeEngine.label).font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
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
            TextField("Ask your coach…", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .padding(11)
                .background(Theme.card)
                .overlay(Rectangle().stroke(Theme.hairline, lineWidth: 1))

            Button {
                send(draft)
            } label: {
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

    private func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        draft = ""   // clear now…
        // …and again next tick: tapping send commits the field's pending edit
        // after this, which would otherwise re-populate the draft.
        DispatchQueue.main.async { draft = "" }
        let history = messages
        messages.append(CoachMessage(text: trimmed, isUser: true))
        isThinking = true

        // Build a fresh memory briefing so the coach knows the current time, how
        // long it's been since the last workout, recent session summaries, and
        // the latest fuel decisions before it answers. Uses a condensed version
        // when the user has enabled memory condensing.
        let full = CoachMemory.build(
            profile: profiles.first,
            sessions: sessions,
            nutrition: nutrition,
            prs: prs,
            exercises: exercises
        )
        let memory = CoachMemory.condensed(
            full: full, profile: profiles.first, sessions: sessions, nutrition: nutrition
        )

        Task {
            let reply = await CoachService.reply(to: trimmed, history: history, memory: memory)
            await MainActor.run {
                isThinking = false
                messages.append(CoachMessage(text: reply, isUser: false))
            }
            await CoachMemory.refreshSummaryIfNeeded(full: full)
        }
    }
}

/// Pending-response state: the barbell loader, three pulsing dots, and a faint
/// engine label — shown while the coach composes a reply.
struct CoachPendingView: View {
    private var label: String {
        CoachService.activeEngine == .onDevice
            ? "ON-DEVICE MODEL · WARMING"
            : "\(CoachService.activeEngine.label.uppercased()) · THINKING"
    }

    var body: some View {
        VStack(spacing: 14) {
            BarbellLoaderView(scale: 0.8)
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                HStack(spacing: 7) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 6, height: 6)
                            .opacity(0.3 + 0.7 * (0.5 + 0.5 * sin(t * 3 - Double(i) * 0.9)))
                    }
                }
            }
            HStack(spacing: 8) {
                Rectangle().fill(Theme.accent.opacity(0.4)).frame(width: 22, height: 1)
                Text(label)
                    .font(Theme.mono(9)).tracking(1.6)
                    .foregroundStyle(Theme.accent.opacity(0.7))
                Rectangle().fill(Theme.accent.opacity(0.4)).frame(width: 22, height: 1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
