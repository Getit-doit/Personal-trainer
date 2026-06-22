import Foundation

#if canImport(FoundationModels)
import FoundationModels

/// On-device coaching via Apple's Foundation Models (Apple Intelligence).
///
/// The "weaker built-in AI" tier: a local model that runs entirely on device —
/// no API key, no network, private. Available on Apple Intelligence-capable
/// devices running iOS 26+. A single session is kept alive so it retains
/// conversation context natively and can be prewarmed for a faster first reply.
@available(iOS 26.0, *)
@MainActor
final class OnDeviceCoach {
    static let shared = OnDeviceCoach()

    nonisolated static var isAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }

    private var session: LanguageModelSession?
    /// The last memory briefing we sent, so we only re-inject it when it changes.
    private var lastMemory = ""

    private func ensureSession() {
        if session == nil {
            session = LanguageModelSession(instructions: CoachService.systemPrompt)
            lastMemory = ""
        }
    }

    /// Warm the model so the first real reply isn't slow. Safe to call repeatedly.
    func prewarm() {
        guard Self.isAvailable else { return }
        ensureSession()
        session?.prewarm()
    }

    /// `memory` is the stable athlete briefing (injected only when it changes, so
    /// the persistent session isn't spammed). `reference` is per-question grounding
    /// (e.g. relevant internal-library entries) and is prepended every turn since
    /// it varies with the question.
    func reply(to message: String, memory: String = "", reference: String = "") async -> String? {
        guard Self.isAvailable else { return nil }
        ensureSession()
        guard let session else { return nil }

        var prompt = message
        if !reference.isEmpty {
            prompt = "Relevant reference for this question:\n\n\(reference)\n\nQuestion: \(message)"
        }
        if !memory.isEmpty && memory != lastMemory {
            prompt = "Current memory about the athlete — read before answering and "
                + "reference where relevant:\n\n\(memory)\n\n\(prompt)"
            lastMemory = memory
        }

        do {
            let response = try await session.respond(to: prompt)
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty || isRefusal(text) { return nil }   // fall back to built-in coach
            return text
        } catch {
            // Context window exceeded, guardrail, or model busy — reset and fall back.
            self.session = nil
            self.lastMemory = ""
            return nil
        }
    }

    /// A stateless one-off generation on a throwaway session, so utility prompts
    /// (achievement recognition, question phrasing) never pollute the chat context.
    func oneShot(_ prompt: String) async -> String? {
        guard Self.isAvailable else { return nil }
        let temp = LanguageModelSession(instructions: CoachService.systemPrompt)
        do {
            let response = try await temp.respond(to: prompt)
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return (text.isEmpty || isRefusal(text)) ? nil : text
        } catch {
            return nil
        }
    }

    /// The on-device model sometimes declines benign fitness questions. Treat an
    /// obvious refusal as "no answer" so the helpful rule-based coach takes over.
    private func isRefusal(_ text: String) -> Bool {
        let t = text.lowercased()
        return t.contains("cannot assist") || t.contains("can't assist")
            || t.contains("can't help with that") || t.contains("cannot help with that")
            || t.contains("unable to assist") || t.contains("i'm sorry, but i can")
    }
}
#endif
