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
        if !Config.anthropicAPIKey.isEmpty {
            if let remote = try? await callClaude(message: message, history: history, memory: memory) {
                return remote
            }
        }
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if let onDevice = await OnDeviceCoach.shared.reply(to: message, memory: memory) {
                return onDevice
            }
        }
        #endif
        return offlineReply(to: message)
    }

    /// Warm the on-device model (if that's the active engine) for a faster first reply.
    static func prewarm() {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), activeEngine == .onDevice {
            Task { @MainActor in OnDeviceCoach.shared.prewarm() }
        }
        #endif
    }

    /// System prompt shared by the on-device model and Claude.
    static let systemPrompt = """
    You are an expert, encouraging functional-strength and longevity coach inside \
    a fitness app. The athlete is a 33-year-old male, 5'10", started this block at \
    217 lb, training weekday mornings before a desk job. Goals: functional lean \
    strength and longevity. Constraints: sleeps only 6–7 hrs, high stress, and an \
    ankle that inflames easily (always respect the mandatory ankle warm-up and \
    introduce incline/impact/sprints/stairs gradually). Training is 3 days/week, \
    scaling toward 5 as recovery allows, compound-first full-body. Favor progressive \
    overload, autoregulation by RPE/reps-in-tank, and one nutrition "lever" at a \
    time over full macro counting. Keep replies under 120 words unless asked for detail.
    """

    // MARK: - Offline rule-based coach

    private static func offlineReply(to message: String) -> String {
        let text = message.lowercased()

        if text.contains("lose") && (text.contains("weight") || text.contains("fat")) {
            return """
            To lose fat sustainably, aim for a small calorie deficit (~300–500 kcal/day) \
            and keep protein high (~0.8 g per lb of bodyweight). Combine 3 strength \
            sessions a week with 2 short cardio/HIIT sessions. Strength training keeps \
            muscle while you cut. Want me to suggest a weekly split?
            """
        }
        if text.contains("muscle") || text.contains("bulk") || text.contains("gain") {
            return """
            For muscle gain, train each muscle group 2x/week, push close to failure, and \
            progressively add weight or reps. Eat in a slight surplus (~250 kcal over \
            maintenance) with 0.8–1 g protein per lb. Run the compound-first Full Body \
            A/B/C split from the Train tab.
            """
        }
        if text.contains("ankle") {
            return """
            Always run the full ankle warm-up before lifting — circles, knee-to-wall \
            dorsiflexion, banded eversion/inversion, slow calf raises, then 5 min easy \
            incline walk. Keep cardio low-impact (incline walking) and add incline, \
            stairs, or sprints in small steps weeks apart. If the ankle is warm or \
            swollen, skip impact that day and stick to seated/low-load work.
            """
        }
        if text.contains("sleep") || text.contains("stress") {
            return """
            On 6–7 hrs and high stress, autoregulate: if you're under-slept, keep top \
            sets at RPE 7 (2+ reps in tank) and cut a set rather than skipping the \
            session. A 5–10 min steam-room or easy incline walk down-regulates stress. \
            Protect a consistent wake time — that moves sleep quality more than anything.
            """
        }
        if text.contains("sore") || text.contains("recovery") || text.contains("rest") {
            return """
            Soreness is normal, especially after new exercises. Prioritize sleep (your \
            6–7 hrs is the limiter), stay hydrated, and do light incline walking on rest \
            days. If a joint — especially the ankle — hurts sharply, back off and \
            reassess. Scale toward 5 days only once recovery holds up.
            """
        }
        if text.contains("beginner") || text.contains("start") || text.contains("new") {
            return """
            Start with Full Body A 3 days a week from the Train tab. Do the ankle warm-up \
            first, lead with the compounds, and log every set with RPE and reps-in-tank. \
            Add a little weight when a lift clears all target reps with 2+ in the tank.
            """
        }
        if text.contains("protein") || text.contains("diet") || text.contains("eat") || text.contains("lever") {
            return """
            Skip full macro counting for now — pick one lever in the Fuel tab and nail it \
            daily (e.g. 30g protein at breakfast or a hydration swap). Once it's automatic, \
            move to the next weak link. One habit at a time beats tracking everything.
            """
        }
        if text.contains("plan") || text.contains("routine") || text.contains("workout") || text.contains("progress") {
            return """
            The Train tab has a compound-first Full Body A/B/C split — tap + to start one. \
            Lifts flag as "ready to progress" on the Today tab once you clear all target \
            reps with reps in the tank. Want a recommendation based on today's recovery?
            """
        }
        return """
        I'm your strength & longevity coach. Ask me about progression, the ankle/cardio \
        plan, sleep & stress, or your one nutrition lever. Start a session from the Train \
        tab — and don't skip the ankle warm-up.
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
