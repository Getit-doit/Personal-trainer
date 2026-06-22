import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// The in-app AI coach, in three tiers (best available wins):
///   1. Claude API — if `Config.anthropicAPIKey` is set (smartest, needs network)
///   2. Apple on-device model — FoundationModels, if the device supports Apple
///      Intelligence (weaker, but free, offline, and private — no key needed)
///   3. Built-in rule-based trainer — always works, zero setup
enum CoachService {

    /// Which engine will currently answer (for UI labeling).
    enum Engine {
        case claude, onDevice, offline
        var label: String {
            switch self {
            case .claude: return "Claude"
            case .onDevice: return "On-device AI"
            case .offline: return "Built-in coach"
            }
        }
    }

    static var activeEngine: Engine {
        if !Config.anthropicAPIKey.isEmpty { return .claude }
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), OnDeviceCoach.isAvailable { return .onDevice }
        #endif
        return .offline
    }

    /// Answer the athlete. `memory` is a freshly-built markdown briefing about the
    /// account holder (current time, time since last workout, recent workout
    /// summaries, PRs, and fuel decisions) that every engine reads before replying.
    static func reply(to message: String, history: [CoachMessage], memory: String = "") async -> String {
        // Pull the most relevant entries from the internal library and add them
        // as grounding context — this sharpens the on-device model (no internet)
        // and Claude alike, and powers the offline coach below.
        let knowledge = CoachKnowledge.context(for: message)

        if !Config.anthropicAPIKey.isEmpty {
            // Claude is stateless per call, so memory + reference both go in system.
            let grounded = [memory, knowledge].filter { !$0.isEmpty }.joined(separator: "\n\n")
            if let remote = try? await callClaude(message: message, history: history, memory: grounded) {
                return remote
            }
        }
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if let onDevice = await OnDeviceCoach.shared.reply(to: message, memory: memory, reference: knowledge) {
                return onDevice
            }
        }
        #endif
        return offlineReply(to: message)
    }

    /// A stateless single-shot generation for utility copy (achievement
    /// recognition, check-in question phrasing). Unlike `reply`, it carries no
    /// chat history and never touches the persistent on-device session. Returns
    /// nil when no generative engine is available (callers supply a fallback).
    static func oneShot(_ prompt: String) async -> String? {
        if !Config.anthropicAPIKey.isEmpty {
            if let remote = try? await callClaude(message: prompt, history: [], memory: "") {
                return remote
            }
        }
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return await OnDeviceCoach.shared.oneShot(prompt)
        }
        #endif
        return nil
    }

    // MARK: - AI-recommended levers

    /// Ask the active generative engine for personalized lever *ideas* (just short
    /// titles), grounded in the athlete's context. The app synthesizes each lever's
    /// Yes/No question and polarity deterministically (small models are unreliable
    /// at both), so suggestions are always phrased so "Yes" = the good outcome.
    /// Returns nil when no generative engine is available or the model didn't
    /// return usable JSON (callers fall back to the built-in mapping).
    static func suggestLevers(memory: String, avoid: [String]) async -> [HabitEngine.Suggestion]? {
        guard activeEngine != .offline else { return nil }
        let avoidList = avoid.isEmpty ? "none" : avoid.joined(separator: ", ")
        let prompt = """
        Based on the athlete context below, suggest 4–6 specific daily nutrition "lever" \
        habits tailored to their goal, recent training, and their daily-habit answers. Each \
        is one short, concrete habit (a few words).
        Return ONLY a JSON array of short strings — the habit names — with no prose or code \
        fences, e.g. ["Protein at breakfast", "No soda", "Veggies at dinner"].
        Do not duplicate these existing levers: \(avoidList).

        Athlete context:
        \(memory)
        """
        guard let raw = await oneShot(prompt) else { return nil }
        return parseLeverTitles(raw)
    }

    /// Ask the coach for short conversational follow-up questions about the athlete's
    /// eating, given their intake answers. Returns nil offline or on parse failure.
    static func followUpQuestions(context: String) async -> [String]? {
        guard activeEngine != .offline else { return nil }
        let prompt = """
        You're a friendly, non-judgmental nutrition coach. Based on the athlete's daily-habit \
        answers below, ask 2–3 short, specific follow-up questions to understand their eating \
        better before recommending habits to work on.
        Return ONLY a JSON array of strings — the questions — with no prose or code fences.

        \(context)
        """
        guard let raw = await oneShot(prompt), let arr = parseStringArray(raw) else { return nil }
        let cleaned = arr.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        return cleaned.isEmpty ? nil : Array(cleaned.prefix(3))
    }

    /// Parse a JSON array of lever-name strings into fully-formed suggestions,
    /// de-duplicated by topic.
    private static func parseLeverTitles(_ raw: String) -> [HabitEngine.Suggestion]? {
        guard let titles = parseStringArray(raw) else { return nil }
        var seen = Set<String>()
        var out: [HabitEngine.Suggestion] = []
        for t in titles.prefix(8) {
            let lever = makeLever(fromTitle: t)
            guard !lever.title.isEmpty else { continue }
            let key = HabitEngine.topicKey(for: lever.title)
            if seen.contains(key) { continue }
            seen.insert(key); out.append(lever)
        }
        return out.isEmpty ? nil : out
    }

    /// Extract a `[String]` JSON array from a (possibly chatty) model reply.
    private static func parseStringArray(_ raw: String) -> [String]? {
        guard let start = raw.firstIndex(of: "["), let end = raw.lastIndex(of: "]"), start < end else {
            return nil
        }
        let json = String(raw[start...end])
        guard let data = json.data(using: .utf8),
              let arr = try? JSONDecoder().decode([String].self, from: data) else {
            return nil
        }
        return arr
    }

    // MARK: Lever synthesis (deterministic, so polarity/phrasing are always correct)

    private static let avoidCues = [
        "no ", "avoid", "skip", "quit", "cut ", "cut back", "limit", "less ",
        "without", "reduce", "stop ", "fewer", "drop "
    ]
    private static let actionVerbs = [
        "eat", "drink", "add", "track", "hit", "take", "get", "include", "have",
        "do", "walk", "cook", "prep", "swap", "log", "stretch", "sleep", "plan", "make"
    ]

    /// Build a lever from just a title: synthesize a Yes/No check-in question where
    /// "Yes" always means the good outcome, so `goodAnswerIsYes` is always true.
    static func makeLever(fromTitle rawTitle: String) -> HabitEngine.Suggestion {
        let title = rawTitle
            .trimmingCharacters(in: CharacterSet(charactersIn: " \t\"'.•-"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let question = isAvoidHabit(title) ? synthAvoidQuestion(title) : synthPositiveQuestion(title)
        return HabitEngine.Suggestion(title: title, question: question, goodAnswerIsYes: true)
    }

    private static func isAvoidHabit(_ title: String) -> Bool {
        let t = title.lowercased()
        return avoidCues.contains { t.hasPrefix($0) || t.contains(" \($0)") }
    }

    private static func synthAvoidQuestion(_ title: String) -> String {
        var t = title.lowercased()
        for cue in ["no ", "avoid ", "skip ", "quit ", "cut back on ", "cut ", "limit ", "less ", "reduce ", "stop ", "without ", "fewer ", "drop "] {
            if t.hasPrefix(cue) { t = String(t.dropFirst(cue.count)); break }
        }
        return "Did you stay off \(t) today?"
    }

    private static func synthPositiveQuestion(_ title: String) -> String {
        let t = title.lowercased()
        if actionVerbs.contains(where: { t.hasPrefix($0 + " ") }) {
            return "Did you \(t) today?"
        }
        return "Did you keep up with \(t) today?"
    }

    /// Warm the on-device model (if that's the active engine) for a faster first reply.
    static func prewarm() {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), activeEngine == .onDevice {
            Task { @MainActor in OnDeviceCoach.shared.prewarm() }
        }
        #endif
    }

    /// System prompt shared by the on-device model and Claude. Intentionally
    /// generic — the athlete's specifics (stats, goal, experience, equipment,
    /// constraints/injuries, recent training) are supplied per-message via the
    /// memory briefing built by `CoachMemory`. Always personalize from that.
    static let systemPrompt = """
    You are an expert, encouraging strength, conditioning, and longevity coach \
    inside a fitness app. Personalize every answer to the athlete using the \
    profile and memory provided with the conversation: their goal, experience \
    level, available equipment, schedule, and any stated constraints or injuries \
    — and never program around equipment they don't have or aggravate an injury \
    they've listed. Always have them warm up before lifting and introduce \
    impact (incline, stairs, sprints) gradually. Favor progressive overload, \
    autoregulation by RPE/reps-in-tank, compound-first training, and one \
    nutrition "lever" at a time over full macro counting. When asked for a plan, \
    build it around their experience, days per week, and equipment. Keep replies \
    under 120 words unless asked for detail.
    """

    // MARK: - Offline coach (internal knowledge library)

    /// Answers by searching the internal coaching library (`CoachKnowledge`) and
    /// returning the best-matching entry. Falls back to a guiding default when
    /// nothing matches well enough.
    private static func offlineReply(to message: String) -> String {
        if let answer = CoachKnowledge.bestAnswer(for: message) {
            return answer
        }
        return """
        I'm your strength & longevity coach. Ask me about fat loss, building muscle, \
        progression, your training plan, cardio, sleep & stress, injuries, or your one \
        nutrition lever. Start a session from the Train tab — and don't skip the warm-up.
        """
    }

    // MARK: - Claude API (optional)

    private static func callClaude(message: String, history: [CoachMessage], memory: String) async throws -> String {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw CoachError.badURL
        }

        var messages: [[String: String]] = history.map {
            ["role": $0.isUser ? "user" : "assistant", "content": $0.text]
        }
        messages.append(["role": "user", "content": message])

        // Prepend the live athlete memory to the system prompt so the model reads
        // it before answering — current time, recency, recent training and fuel.
        let system = memory.isEmpty ? systemPrompt
            : systemPrompt + "\n\nRead this current memory about the athlete before "
                + "answering, and reference it where relevant:\n\n" + memory

        let body: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": 500,
            "system": system,
            "messages": messages
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = json["content"] as? [[String: Any]],
            let first = content.first,
            let textValue = first["text"] as? String
        else {
            throw CoachError.badResponse
        }
        return textValue
    }

    enum CoachError: Error { case badURL, badResponse }
}

/// Drop your Anthropic API key here to enable live Claude coaching.
/// Leave empty to use the offline coach. Don't commit a real key to git.
enum Config {
    static let anthropicAPIKey = ""
}
