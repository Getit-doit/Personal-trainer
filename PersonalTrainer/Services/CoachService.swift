import Foundation

/// The in-app AI coach.
///
/// Works fully offline with a built-in rule-based trainer. If you add a Claude
/// API key in `Config.anthropicAPIKey`, it will instead call Claude for richer,
/// conversational coaching.
enum CoachService {
    static func reply(to message: String, history: [CoachMessage]) async -> String {
        if !Config.anthropicAPIKey.isEmpty {
            if let remote = try? await callClaude(message: message, history: history) {
                return remote
            }
        }
        return offlineReply(to: message)
    }

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
            maintenance) with 0.8–1 g protein per lb. Try the Push / Pull / Legs plans in \
            the Plans tab.
            """
        }
        if text.contains("sore") || text.contains("recovery") || text.contains("rest") {
            return """
            Soreness is normal, especially after new exercises. Prioritize 7–9 hours of \
            sleep, stay hydrated, and do light movement on rest days. If a joint (not a \
            muscle) hurts sharply, back off and reassess.
            """
        }
        if text.contains("beginner") || text.contains("start") || text.contains("new") {
            return """
            Welcome! Start with the "Full Body Starter" plan 3 days a week. Focus on form \
            over weight, log every set in the Workouts tab, and add a little weight each \
            week. Consistency beats intensity early on.
            """
        }
        if text.contains("protein") || text.contains("diet") || text.contains("eat") {
            return """
            A simple nutrition baseline: protein with every meal, plenty of vegetables, \
            whole-grain carbs around training, and healthy fats. Target ~0.8 g protein per \
            lb of bodyweight to support training.
            """
        }
        if text.contains("plan") || text.contains("routine") || text.contains("workout") {
            return """
            Check the Plans tab — I've built Push, Pull, Leg, Full-Body, and HIIT routines. \
            Tap "Start" on any plan and it becomes a logged session you can track. Want a \
            recommendation based on your goal?
            """
        }
        return """
        I'm your training coach 💪 Ask me about losing fat, building muscle, recovery, \
        nutrition, or which plan to follow. You can also start a workout from the Plans \
        tab and log it in Workouts.
        """
    }

    // MARK: - Claude API (optional)

    private static func callClaude(message: String, history: [CoachMessage]) async throws -> String {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw CoachError.badURL
        }

        var messages: [[String: String]] = history.map {
            ["role": $0.isUser ? "user" : "assistant", "content": $0.text]
        }
        messages.append(["role": "user", "content": message])

        let body: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": 500,
            "system": """
            You are an expert, encouraging personal trainer inside a fitness app. Give \
            concise, practical, safe advice on training, programming, and nutrition. Keep \
            replies under 120 words unless asked for detail.
            """,
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
