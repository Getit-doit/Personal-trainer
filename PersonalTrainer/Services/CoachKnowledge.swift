import Foundation

/// An entry in the internal coaching library.
struct KnowledgeEntry: Identifiable, Decodable {
    let id: String
    let title: String
    /// Terms that should strongly surface this entry (weighted heavily in search).
    let keywords: [String]
    /// The answer, written in the coach's concise voice.
    let content: String
}

/// An internal, fully-offline coaching knowledge library the AI can search to
/// ground its answers — no network needed. The built-in (offline) coach answers
/// directly from it, and the on-device / Claude tiers get the most relevant
/// entries injected as reference context so their replies are better too.
///
/// Content is loaded from the bundled `CoachKnowledge.json` so the library can be
/// edited/expanded without recompiling.
enum CoachKnowledge {

    // MARK: - Library (loaded from bundled JSON)

    static let entries: [KnowledgeEntry] = load()

    private static func load() -> [KnowledgeEntry] {
        guard let url = Bundle.main.url(forResource: "CoachKnowledge", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([KnowledgeEntry].self, from: data) else {
            return []
        }
        return decoded
    }

    // MARK: - Search

    private static let stopwords: Set<String> = [
        "the", "and", "for", "are", "you", "your", "how", "what", "should", "can",
        "with", "that", "this", "get", "got", "have", "has", "any", "about", "best",
        "good", "way", "ways", "help", "need", "want", "should", "would", "could",
        "from", "when", "does", "doing", "into", "out", "but", "not", "more", "some",
        "they", "them", "their", "than", "then", "much", "many", "lot", "very", "really",
        "work", "works", "working", "use", "using", "make", "made"
    ]

    /// Lowercased content tokens (≥3 chars, no stopwords) for matching.
    static func tokens(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 3 && !stopwords.contains($0) }
    }

    /// Whether a query token and a candidate (keyword or title word) match.
    /// Exact match always counts; partial (substring) matches require the shorter
    /// side to be ≥4 chars, so plurals/compounds match ("squat"↔"squats",
    /// "reps"↔"reps in tank") without short keywords hitting interiors of unrelated
    /// words (e.g. "eat" inside "creatine").
    private static func termMatch(_ token: String, _ candidate: String) -> Bool {
        if candidate == token { return true }
        if candidate.count >= 4 && token.contains(candidate) { return true }
        if token.count >= 4 && candidate.contains(token) { return true }
        return false
    }

    /// Rank entries by relevance to a query. Keyword hits weigh most, then title,
    /// then body. Returns `(entry, score)` sorted high→low for nonzero scores.
    static func scored(_ query: String) -> [(entry: KnowledgeEntry, score: Double)] {
        let q = tokens(query)
        guard !q.isEmpty else { return [] }

        return entries.compactMap { entry -> (entry: KnowledgeEntry, score: Double)? in
            let titleTokens = tokens(entry.title)
            let kw = entry.keywords.map { $0.lowercased() }
            let body = entry.content.lowercased()
            var score = 0.0

            for t in q {
                if kw.contains(where: { termMatch(t, $0) }) {
                    score += 5
                } else if titleTokens.contains(where: { termMatch(t, $0) }) {
                    score += 3
                } else if body.contains(t) {
                    score += 1
                }
            }
            return score > 0 ? (entry: entry, score: score) : nil
        }
        .sorted { $0.score > $1.score }
    }

    static func search(_ query: String, limit: Int = 3) -> [KnowledgeEntry] {
        scored(query).prefix(limit).map { $0.entry }
    }

    /// The best offline answer for a query, composed from the top library
    /// entries — or nil if nothing matches well enough (caller supplies a default).
    static func bestAnswer(for query: String) -> String? {
        let ranked = scored(query)
        guard let top = ranked.first, top.score >= 5 else { return nil }
        var parts = [top.entry.content]
        // Add a second entry only when it's robustly on-topic too (multi-signal),
        // so a tangential match isn't tacked onto a clear single-topic question.
        if ranked.count > 1, ranked[1].score >= 8 {
            parts.append(ranked[1].entry.content)
        }
        return parts.joined(separator: "\n\n")
    }

    /// A compact reference block of the most relevant entries, for injecting into
    /// the generative engines (on-device / Claude) as grounding context.
    static func context(for query: String, limit: Int = 3) -> String {
        let ranked = scored(query).prefix(limit).filter { $0.score >= 3 }
        guard !ranked.isEmpty else { return "" }
        var lines = ["## Reference (internal coaching library)"]
        for item in ranked {
            lines.append("### \(item.entry.title)")
            lines.append(item.entry.content)
        }
        return lines.joined(separator: "\n")
    }
}
