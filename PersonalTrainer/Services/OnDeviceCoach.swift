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

    private func ensureSession() {
        if session == nil {
            session = LanguageModelSession(instructions: CoachService.systemPrompt)
        }
    }

    /// Warm the model so the first real reply isn't slow. Safe to call repeatedly.
    func prewarm() {
        guard Self.isAvailable else { return }
        ensureSession()
        session?.prewarm()
    }

    func reply(to message: String) async -> String? {
        guard Self.isAvailable else { return nil }
        ensureSession()
        guard let session else { return nil }
        do {
            let response = try await session.respond(to: message)
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty || isRefusal(text) { return nil }   // fall back to built-in coach
            return text
        } catch {
            // Context window exceeded, guardrail, or model busy — reset and fall back.
            self.session = nil
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
