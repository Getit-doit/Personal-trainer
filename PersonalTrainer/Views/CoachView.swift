import SwiftUI

/// A chat message in the coach conversation.
struct CoachMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

/// The AI coach chat screen.
struct CoachView: View {
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
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                bubble(message).id(message.id)
                            }
                            if isThinking {
                                HStack {
                                    BarLoadingView(label: "Coach is loading up…")
                                    Spacer()
                                }
                                .padding(.horizontal)
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
                                    Text(suggestion)
                                        .font(.caption).bold()
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(Theme.accent.opacity(0.15), in: Capsule())
                                        .foregroundStyle(Theme.accentDeep)
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
            .navigationTitle("Coach")
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
            Text(message.text)
                .padding(12)
                .background(
                    message.isUser ? Theme.accent : Theme.card,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .foregroundStyle(message.isUser ? Theme.blueprintDeep : .primary)
            if !message.isUser { Spacer(minLength: 40) }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Ask your coach…", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .padding(10)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))

            Button {
                send(draft)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundStyle(Theme.accent)
            }
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty || isThinking)
        }
        .padding()
    }

    private func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let history = messages
        messages.append(CoachMessage(text: trimmed, isUser: true))
        draft = ""
        isThinking = true

        Task {
            let reply = await CoachService.reply(to: trimmed, history: history)
            await MainActor.run {
                isThinking = false
                messages.append(CoachMessage(text: reply, isUser: false))
            }
        }
    }
}
