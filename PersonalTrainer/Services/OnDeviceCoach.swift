import Foundation

#if canImport(FoundationModels)
import FoundationModels

/// On-device coaching via Apple's Foundation Models (Apple Intelligence).
///
/// This is the "weaker built-in AI" tier: a local ~3B model that runs entirely
/// on device — no API key, no network, private. Available on Apple
/// Intelligence-capable devices running iOS 26+. When unavailable, callers fall
/// back to the rule-based coach.
@available(iOS 26.0, *)
enum OnDeviceCoach {
    static var isAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }

    static func reply(to message: String, history: [CoachMessage]) async -> String? {
        guard isAvailable else { return nil }

        // Fold a little recent context into the prompt (fresh session per call).
        let recent = history.suffix(6).map { ($0.isUser ? "User: " : "Coach: ") + $0.text }
        let prompt = (recent + ["User: \(message)", "Coach:"]).joined(separator: "\n")

        do {
            let session = LanguageModelSession(instructions: CoachService.systemPrompt)
            let response = try await session.respond(to: prompt)
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : text
        } catch {
            return nil   // model busy, guardrail, or unsupported — fall back
        }
    }
}
#endif
