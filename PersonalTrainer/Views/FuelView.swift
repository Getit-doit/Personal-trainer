import SwiftUI
import SwiftData

/// Nutrition tab — habit-based, one "lever" at a time rather than macro counting.
/// Log daily wins, flag weak links, and keep a single focus lever.
struct FuelView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \NutritionLog.date, order: .reverse) private var logs: [NutritionLog]
    @State private var today: NutritionLog?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let today {
                        leverCard(today)
                        winsCard(today)
                        weakLinksCard(today)
                    }
                    historyCard
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Fuel")
            .onAppear(perform: ensureToday)
        }
    }

    /// Fetch-or-create today's log exactly once.
    private func ensureToday() {
        guard today == nil else { return }
        if let existing = logs.first(where: { Calendar.current.isDateInToday($0.date) }) {
            today = existing
        } else {
            let log = NutritionLog(date: .now)
            log.currentLever = logs.first?.currentLever ?? ""   // carry lever forward
            context.insert(log)
            try? context.save()
            today = log
        }
    }

    private func leverCard(_ log: NutritionLog) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Label("Current Lever", systemImage: "target").font(.headline)
                Text("Focus on one habit at a time.")
                    .font(.caption).foregroundStyle(.secondary)
                TextField(
                    "e.g. 30g protein at breakfast",
                    text: Binding(
                        get: { log.currentLever },
                        set: { log.currentLever = $0; try? context.save() }
                    )
                )
                .textFieldStyle(.roundedBorder)
            }
        }
    }

    private func winsCard(_ log: NutritionLog) -> some View {
        ListEditorCard(
            title: "Today's Wins",
            systemImage: "checkmark.circle.fill",
            tint: Theme.accent,
            placeholder: "e.g. Morning protein, water swap",
            items: Binding(
                get: { log.wins },
                set: { log.wins = $0; try? context.save() }
            )
        )
    }

    private func weakLinksCard(_ log: NutritionLog) -> some View {
        ListEditorCard(
            title: "Weak Links",
            systemImage: "exclamationmark.triangle.fill",
            tint: .orange,
            placeholder: "e.g. Late-night snacking",
            items: Binding(
                get: { log.weakLinks },
                set: { log.weakLinks = $0; try? context.save() }
            )
        )
    }

    @ViewBuilder
    private var historyCard: some View {
        let past = logs.filter { !Calendar.current.isDateInToday($0.date) }
        if !past.isEmpty {
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    Label("History", systemImage: "clock.arrow.circlepath").font(.headline)
                    ForEach(past.prefix(7)) { log in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(log.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption).bold()
                            if !log.currentLever.isEmpty {
                                Text("Lever: \(log.currentLever)").font(.caption2).foregroundStyle(.secondary)
                            }
                            Text("\(log.wins.count) wins · \(log.weakLinks.count) weak links")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

/// A card that edits a string list — add via text field, remove via swipe.
struct ListEditorCard: View {
    let title: String
    let systemImage: String
    let tint: Color
    let placeholder: String
    @Binding var items: [String]
    @State private var draft = ""

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Label(title, systemImage: systemImage).font(.headline).foregroundStyle(tint)
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack {
                        Text("• \(item)")
                        Spacer()
                        Button {
                            items.remove(at: index)
                        } label: {
                            Image(systemName: "minus.circle.fill").foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.subheadline)
                }
                HStack {
                    TextField(placeholder, text: $draft)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(add)
                    Button(action: add) {
                        Image(systemName: "plus.circle.fill").foregroundStyle(tint)
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func add() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.append(trimmed)
        draft = ""
    }
}
