import Foundation

/// An entry in the internal coaching library.
struct KnowledgeEntry: Identifiable {
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
enum CoachKnowledge {

    // MARK: - Library

    static let entries: [KnowledgeEntry] = [
        KnowledgeEntry(
            id: "fat_loss",
            title: "Losing fat",
            keywords: ["lose", "fat", "weight", "cut", "cutting", "lean", "deficit", "diet", "slim", "shred"],
            content: """
            Fat loss comes from a small, sustainable calorie deficit (~300–500 kcal/day) \
            held over weeks. Keep protein high (~0.7–1 g per lb of bodyweight) and keep \
            lifting heavy — that's what preserves muscle while you lose fat. Add a little \
            daily walking and 1–2 short conditioning sessions. Aim for ~0.5–1% of \
            bodyweight lost per week; faster usually means muscle loss. In the Fuel tab, \
            pick one nutrition lever (e.g. protein at breakfast) rather than counting every macro.
            """
        ),
        KnowledgeEntry(
            id: "muscle_gain",
            title: "Building muscle",
            keywords: ["muscle", "build", "bulk", "gain", "hypertrophy", "size", "grow", "mass"],
            content: """
            To build muscle, train each muscle group ~2x/week, keep most working sets 1–3 \
            reps shy of failure, and add weight or reps over time (progressive overload). \
            10–20 hard sets per muscle per week is a good range. Eat at maintenance or a \
            slight surplus (~200–300 kcal) with ~0.7–1 g protein per lb. Sleep is when the \
            growth happens. Start from a compound-first full-body template in the Train tab.
            """
        ),
        KnowledgeEntry(
            id: "progressive_overload",
            title: "Progressive overload",
            keywords: ["progress", "overload", "stronger", "strength", "add weight", "heavier", "increase", "progression"],
            content: """
            Progressive overload means gradually doing more over time — more weight, more \
            reps, or better control. The simplest rule: when you clear all your target \
            reps on every set with 2+ reps still in the tank, add the smallest jump next \
            session (often 5 lb, or 2.5 on small lifts). If you miss reps two sessions in \
            a row, hold the weight or back off 10%. The app flags lifts as "ready to \
            progress" on the Today tab once you've earned it.
            """
        ),
        KnowledgeEntry(
            id: "rpe_autoregulation",
            title: "RPE and reps-in-tank",
            keywords: ["rpe", "reps in tank", "reps-in-tank", "autoregulation", "autoregulate", "effort", "rir", "how hard"],
            content: """
            RPE rates how hard a set felt (10 = no reps left, 8 = ~2 reps in the tank). \
            Logging RPE and reps-in-tank lets you autoregulate: on good days you'll add \
            load, on tired days you'll keep effort at RPE 7–8 and still make progress \
            without grinding. Most productive lifting lives at RPE 7–9. Save true RPE 10 \
            for rare tests. Log it every set so the coach can tune your progression.
            """
        ),
        KnowledgeEntry(
            id: "warmup",
            title: "Warming up",
            keywords: ["warmup", "warm up", "warm-up", "prep", "before lifting", "before workout"],
            content: """
            A good warm-up takes 8–10 minutes: 5 min easy cardio, then dynamic mobility \
            (leg swings, hip circles, band pull-aparts, ankle circles), then 1–2 light \
            ramp-up sets of your first lift. It raises your core temperature, primes the \
            joints, and lets you move more weight with less injury risk. The app gates set \
            logging behind the warm-up for exactly this reason — don't skip it.
            """
        ),
        KnowledgeEntry(
            id: "mobility",
            title: "Mobility and flexibility",
            keywords: ["mobility", "flexibility", "stiff", "tight", "stretch", "stretching", "range of motion"],
            content: """
            Train mobility where you actually feel restricted rather than stretching \
            randomly. Use dynamic drills before lifting and longer holds after or on rest \
            days. Lifting through a full range of motion is itself great mobility work. \
            Hips, ankles, and thoracic spine (upper back) are the usual limiters for \
            squats and presses — spend your minutes there.
            """
        ),
        KnowledgeEntry(
            id: "knee_pain",
            title: "Knee discomfort",
            keywords: ["knee", "knees", "patella", "knee pain"],
            content: """
            For cranky knees, keep training but adjust: control the tempo, avoid sharp \
            pain (mild discomfort that warms up is usually okay), and favor variations you \
            tolerate — box squats, leg press in a shorter range, split squats, and plenty \
            of hamstring/glute work to balance the joint. Build quad strength gradually; \
            it's protective. Log the limitation in your profile so the coach programs \
            around it, and see a professional for sharp or swelling pain.
            """
        ),
        KnowledgeEntry(
            id: "shoulder_pain",
            title: "Shoulder discomfort",
            keywords: ["shoulder", "shoulders", "rotator", "cuff", "shoulder pain", "pressing"],
            content: """
            For touchy shoulders, swap straight-bar pressing for neutral-grip dumbbell or \
            landmine presses, keep elbows slightly tucked, and add face pulls and band \
            pull-aparts for the rear delts and rotator cuff. Don't push through pinching \
            pain at the top of presses. Build pressing volume back gradually once it's \
            calm, and flag the issue in your profile so the coach adapts.
            """
        ),
        KnowledgeEntry(
            id: "back_pain",
            title: "Lower-back discomfort",
            keywords: ["back", "lower back", "lumbar", "back pain", "spine"],
            content: """
            For a grumpy lower back, brace your core hard, keep a neutral spine, and pull \
            from a height (rack pulls or blocks) if floor deadlifts aggravate it. Hip \
            hinges, McGill-style core work (planks, bird-dogs, side planks), and walking \
            usually help. Avoid loaded rounding when it's flared up. If you have pain down \
            the leg, numbness, or it's sharp, get it checked before loading heavy.
            """
        ),
        KnowledgeEntry(
            id: "ankle",
            title: "Ankle care and impact",
            keywords: ["ankle", "ankles", "calf", "impact", "dorsiflexion"],
            content: """
            If your ankle flares easily, warm it thoroughly (circles, knee-to-wall \
            dorsiflexion, banded work, calf raises) and keep cardio low-impact — incline \
            walking over running. Introduce impact (incline, stairs, sprints) in small \
            steps weeks apart. On a warm or swollen day, skip impact and stick to seated \
            or low-load work. Set the cardio impact level in the finisher so you can track it.
            """
        ),
        KnowledgeEntry(
            id: "beginner",
            title: "Starting out",
            keywords: ["beginner", "start", "new", "novice", "first time", "getting started"],
            content: """
            As a beginner, consistency beats complexity. Run a full-body session 3x/week, \
            warm up, lead with the big compounds (squat, hinge, press, row), and log every \
            set with RPE and reps-in-tank. Add a small amount of weight whenever you clear \
            all target reps with 2+ in the tank — beginners can progress almost every \
            session. Focus on learning clean technique before chasing heavy loads.
            """
        ),
        KnowledgeEntry(
            id: "sleep",
            title: "Sleep for training",
            keywords: ["sleep", "tired", "rest", "insomnia", "recover", "fatigue"],
            content: """
            Sleep is the highest-leverage recovery tool. Aim for 7–9 hours; protect a \
            consistent wake time, get morning light, and cut caffeine 8–10 hours before \
            bed. When you're short on sleep, autoregulate: keep top sets at RPE 7, drop a \
            set rather than skipping the session, and don't test maxes. Under-sleeping \
            mostly costs you in strength output and appetite control.
            """
        ),
        KnowledgeEntry(
            id: "stress",
            title: "Training under stress",
            keywords: ["stress", "stressed", "busy", "overwhelmed", "cortisol", "anxious"],
            content: """
            High life stress eats into recovery, so train to leave a little in the tank on \
            hard weeks — RPE 7–8, fewer junk sets, and easy Zone 2 cardio or a short \
            sauna/walk to down-regulate. A lighter session you actually do beats a perfect \
            one you skip. Breathing drills and a wind-down routine before bed help more \
            than any supplement.
            """
        ),
        KnowledgeEntry(
            id: "soreness_recovery",
            title: "Soreness and recovery",
            keywords: ["sore", "soreness", "doms", "recovery", "ache", "recover faster"],
            content: """
            Soreness (DOMS) is normal after new or harder work and isn't required for \
            progress. Speed recovery with sleep, enough protein and calories, hydration, \
            and light movement (walking, easy cycling) on off days. Don't confuse soreness \
            with joint pain — soreness fades, sharp joint pain is a signal to back off. \
            Stay consistent rather than waiting to feel 100%.
            """
        ),
        KnowledgeEntry(
            id: "deload",
            title: "Deloads and fatigue",
            keywords: ["deload", "plateau", "stalled", "stuck", "burnout", "overtraining", "fatigued"],
            content: """
            If progress stalls, sleep tanks, or motivation and joints feel beat up, take a \
            deload: one easier week at ~60–70% of normal volume or load. You'll usually \
            come back stronger. Most lifters benefit from a deload every 4–8 weeks, or \
            whenever performance drifts down for a couple of sessions in a row.
            """
        ),
        KnowledgeEntry(
            id: "protein",
            title: "Protein",
            keywords: ["protein", "macros", "amino", "shake", "whey"],
            content: """
            Protein is the macro to prioritize: ~0.7–1 g per lb of bodyweight per day, \
            spread across 3–4 meals of 30–50 g. It preserves muscle in a cut, builds it in \
            a surplus, and keeps you full. Whole-food sources first (meat, eggs, dairy, \
            legumes); a shake is a convenient backup. If you change one thing about your \
            diet, make it hitting protein daily.
            """
        ),
        KnowledgeEntry(
            id: "nutrition_lever",
            title: "One nutrition lever at a time",
            keywords: ["nutrition", "eat", "eating", "lever", "habit", "diet", "food", "meal"],
            content: """
            Instead of overhauling everything, change one nutrition lever at a time and \
            make it automatic before adding the next — e.g. 30 g protein at breakfast, a \
            daily water target, or no liquid calories. Small habits you keep beat a strict \
            plan you abandon. Use the Fuel tab to set your current lever and the check-ins \
            to keep a streak going.
            """
        ),
        KnowledgeEntry(
            id: "hydration",
            title: "Hydration",
            keywords: ["water", "hydration", "hydrate", "drink", "thirsty", "electrolytes"],
            content: """
            Aim for pale-yellow urine as your simple hydration gauge — often ~0.5–1 oz of \
            water per lb of bodyweight across the day, more when it's hot or you sweat a \
            lot. Add electrolytes (sodium especially) on long or sweaty sessions. Even \
            mild dehydration drops strength and focus, so sip through your workout.
            """
        ),
        KnowledgeEntry(
            id: "cardio_zone2",
            title: "Cardio and conditioning",
            keywords: ["cardio", "conditioning", "zone 2", "zone2", "endurance", "running", "heart", "vo2", "hiit"],
            content: """
            For health and recovery, build a base of Zone 2 cardio — easy effort where you \
            can still hold a conversation — 2–3 times a week for 20–40 min. Add one short \
            harder interval session if you want to push conditioning. Low-impact options \
            (incline walk, bike, row) spare the joints. Cardio and lifting coexist fine; \
            just keep easy days truly easy.
            """
        ),
        KnowledgeEntry(
            id: "longevity",
            title: "Training for longevity",
            keywords: ["longevity", "healthspan", "age", "aging", "older", "long term", "health"],
            content: """
            For a long, capable life, train the things that decline with age: strength \
            (lift 2–4x/week), aerobic base (Zone 2), power/explosiveness, balance, and \
            muscle mass. Keep most lifting at moderate, joint-friendly intensities you can \
            sustain for years, and protect sleep and protein. Consistency over decades \
            beats any short, intense phase.
            """
        ),
        KnowledgeEntry(
            id: "consistency",
            title: "Staying consistent",
            keywords: ["consistent", "consistency", "motivation", "habit", "skip", "discipline", "routine", "lazy"],
            content: """
            Adherence is the real program. Make it easy to show up: schedule sessions, \
            keep a minimum version ("just the main lift") for busy days, and never miss \
            twice in a row. Track streaks and let small wins compound — the app's \
            check-ins and achievements exist to keep that momentum. A B-grade plan you do \
            for a year beats an A-plan you quit in a month.
            """
        ),
        KnowledgeEntry(
            id: "home_equipment",
            title: "Home / minimal-equipment training",
            keywords: ["home", "dumbbell", "dumbbells", "bands", "bodyweight", "no gym", "minimal", "kettlebell", "garage", "equipment"],
            content: """
            You can build real strength with little equipment. With dumbbells: goblet \
            squats, RDLs, lunges, presses, rows, and curls cover everything. Bodyweight: \
            push-ups, split squats, rows under a table/bar, and planks. To progress \
            without heavier weight, add reps, slow the tempo, shorten rest, or move to \
            single-limb variations. Set your available equipment in the profile so plans fit it.
            """
        ),
        KnowledgeEntry(
            id: "supersets",
            title: "Supersets",
            keywords: ["superset", "supersets", "save time", "efficient", "antagonist"],
            content: """
            A superset pairs two exercises back-to-back with little rest. Pair opposing or \
            unrelated muscles (e.g. a press with a row, or a lower-body lift with a core \
            move) to save time without hurting performance. Avoid supersetting two heavy \
            compounds that compete for the same muscles. Start a superset right in the \
            active session screen.
            """
        ),
        KnowledgeEntry(
            id: "drop_sets",
            title: "Drop sets",
            keywords: ["drop set", "drop-set", "dropset", "burnout set", "to failure"],
            content: """
            A drop set extends a set past failure by quickly reducing the weight and \
            continuing. It's a time-efficient way to add volume and a strong hypertrophy \
            stimulus — best used on machines or dumbbells for accessories, sparingly, near \
            the end of a session. Don't use them on heavy barbell compounds. The app can \
            log a drop sequence for you.
            """
        ),
        KnowledgeEntry(
            id: "rest_periods",
            title: "Rest between sets",
            keywords: ["rest", "rest period", "rest time", "how long rest", "between sets", "timer"],
            content: """
            Rest long enough to perform: ~2–3 min on heavy compounds, ~60–90 sec on \
            accessories. Cutting rest too short on big lifts costs you reps and load. If \
            you're short on time, superset unrelated moves instead of rushing your main \
            lifts. The rest timer auto-starts after each set — adjust the presets in your profile.
            """
        ),
        KnowledgeEntry(
            id: "frequency_split",
            title: "Frequency and splits",
            keywords: ["split", "frequency", "full body", "ppl", "upper lower", "how many days", "schedule"],
            content: """
            Match your split to your days. 3 days: full-body each session. 4 days: \
            upper/lower. 5–6 days: push/pull/legs or a body-part split. Hitting each muscle \
            ~2x/week drives growth better than once. Pick the layout you'll actually \
            attend; total weekly hard sets matter more than the specific template.
            """
        ),
        KnowledgeEntry(
            id: "compound_form",
            title: "The main compound lifts",
            keywords: ["squat", "deadlift", "bench", "press", "row", "form", "technique", "compound", "hinge"],
            content: """
            Build training around the big compounds: squat (knees and hips, full depth you \
            control), hinge/deadlift (push hips back, flat back, brace), press (overhead or \
            bench, ribs down, full lockout), and row (pull to the torso, no jerking). Lead \
            each session with one or two of these while you're fresh, then add accessories. \
            Film a set occasionally to check positions.
            """
        ),
        KnowledgeEntry(
            id: "core",
            title: "Core and abs",
            keywords: ["core", "abs", "ab", "six pack", "plank", "stomach", "midsection"],
            content: """
            Train the core to brace and resist motion: planks, side planks, dead bugs, \
            bird-dogs, hanging knee raises, and loaded carries. Heavy squats and \
            deadlifts already hammer the core. Visible abs are mostly a body-fat outcome — \
            built in the kitchen via a modest deficit, not endless crunches.
            """
        ),
        KnowledgeEntry(
            id: "creatine",
            title: "Creatine",
            keywords: ["creatine", "supplement", "supplements", "monohydrate"],
            content: """
            Creatine monohydrate is the most evidence-backed supplement for strength and \
            muscle: ~3–5 g per day, any time, every day (no need to load). It pulls a \
            little water into muscle, so expect a small scale bump early — that's normal, \
            not fat. Pair it with adequate protein and training. It's safe for long-term use.
            """
        ),
        KnowledgeEntry(
            id: "caffeine",
            title: "Caffeine and pre-workout",
            keywords: ["caffeine", "pre workout", "pre-workout", "energy", "coffee"],
            content: """
            Caffeine (~3–6 mg/kg, ~30–60 min pre-session) reliably boosts strength, focus, \
            and endurance. Don't take it within ~8–10 hours of bed or it'll wreck the \
            sleep you need to recover. You can train perfectly well without it — keep it a \
            tool, not a crutch, and cycle off occasionally to keep it effective.
            """
        ),
        KnowledgeEntry(
            id: "time_efficient",
            title: "Short on time",
            keywords: ["busy", "quick", "short", "travel", "no time", "20 minutes", "express"],
            content: """
            Short on time? Do the main lift plus one or two supersets and skip the fluff — \
            20–30 focused minutes maintains and even builds. On the road, a dumbbell or \
            bodyweight full-body circuit (squat, push, hinge, row, carry) covers the bases. \
            Something brief and consistent always beats an ideal session you skip.
            """
        )
    ]

    // MARK: - Search

    private static let stopwords: Set<String> = [
        "the", "and", "for", "are", "you", "your", "how", "what", "should", "can",
        "with", "that", "this", "get", "got", "have", "has", "any", "about", "best",
        "good", "way", "ways", "help", "need", "want", "should", "would", "could",
        "from", "when", "does", "doing", "into", "out", "but", "not", "more", "some",
        "they", "them", "their", "than", "then", "much", "many", "lot", "very", "really"
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
