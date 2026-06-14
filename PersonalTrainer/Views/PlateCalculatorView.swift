import SwiftUI

/// The kind of bar/implement being loaded. `mirrors` doubles the per-side plate
/// total (a normal bar); dumbbell mode counts the entered plates once.
enum BarType: String, CaseIterable, Identifiable {
    case barbell, womens, ezCurl, trapBar, dumbbell

    var id: String { rawValue }

    var name: String {
        switch self {
        case .barbell: return "Barbell"
        case .womens: return "Women's Bar"
        case .ezCurl: return "EZ Curl Bar"
        case .trapBar: return "Trap Bar"
        case .dumbbell: return "Dumbbell"
        }
    }

    var weight: Double {
        switch self {
        case .barbell: return 45
        case .womens: return 35
        case .ezCurl: return 25
        case .trapBar: return 45
        case .dumbbell: return 0
        }
    }

    /// Whether plates are mirrored on both ends.
    var mirrors: Bool { self != .dumbbell }
}

/// Visual barbell loader. Tap a plate button to add it **per side**; tap a
/// loaded plate on the bar to remove it. Total = bar + (×2 unless dumbbell) ×
/// plates. Plates: 5–45 lb in 5 lb steps + optional 2.5 / 1.25 lb micro set.
/// If an `exerciseName` is supplied, the loadout can be saved as that lift's
/// default and is auto-restored next time.
struct PlateCalculatorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var weight: Double
    var exerciseName: String? = nil
    var onApply: () -> Void

    @AppStorage("barTypeRaw") private var barTypeRaw = BarType.barbell.rawValue
    @AppStorage("useMicroPlates") private var useMicroPlates = false

    private var barType: BarType { BarType(rawValue: barTypeRaw) ?? .barbell }

    private let standardPlates: [Double] = [45, 40, 35, 30, 25, 20, 15, 10, 5]
    private let microPlates: [Double] = [2.5, 1.25]

    private var denominations: [Double] {
        useMicroPlates ? standardPlates + microPlates : standardPlates
    }

    /// Count of each plate per side, keyed by plate weight.
    @State private var perSide: [Double: Int] = [:]

    /// Plates expanded heaviest → lightest for rendering (inner to outer).
    private var loadedPlates: [Double] {
        denominations.flatMap { plate in Array(repeating: plate, count: perSide[plate] ?? 0) }
    }

    private var perSideTotal: Double {
        denominations.reduce(0) { $0 + $1 * Double(perSide[$1] ?? 0) }
    }

    private var total: Double { barType.weight + (barType.mirrors ? 2 : 1) * perSideTotal }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    barbell
                    totals
                    plateButtons
                    options
                }
                .padding()
            }
            .scrollContentBackground(.hidden)
            .blueprintBackground()
            .navigationTitle("Load the Bar")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { restoreOnAppear() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Use \(total.clean) lb") {
                        weight = total
                        onApply()
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: Barbell graphic

    private var barbell: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: 1) {
                // Bar shaft + collar
                Rectangle().fill(Color.gray.opacity(0.5)).frame(width: 28, height: 6)
                Rectangle().fill(Color.gray).frame(width: 7, height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 2))

                if loadedPlates.isEmpty {
                    Text("Empty bar — tap a plate below")
                        .font(.caption).foregroundStyle(.secondary)
                        .padding(.leading, 10)
                } else {
                    ForEach(Array(loadedPlates.enumerated()), id: \.offset) { _, plate in
                        Button { removeOne(plate) } label: { plateView(plate) }
                            .buttonStyle(.plain)
                    }
                    // Sleeve end cap
                    Rectangle().fill(Color.gray.opacity(0.5)).frame(width: 12, height: 6)
                }
                Spacer(minLength: 0)
            }
            .frame(height: 96)
            .padding(.vertical, 8)
        }
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    private func plateView(_ plate: Double) -> some View {
        let height = 36 + plate / 45 * 48        // 36…84 pt
        let width = 9 + plate / 45 * 9           // 9…18 pt
        return RoundedRectangle(cornerRadius: 3)
            .fill(color(for: plate))
            .frame(width: width, height: height)
            .overlay(
                Text(plate.clean)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(-90))
            )
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(.black.opacity(0.15)))
    }

    // MARK: Totals

    private var totals: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(barType.mirrors ? "Per side" : "Per dumbbell").font(.caption).foregroundStyle(.secondary)
                Text("\(perSideTotal.clean) lb").font(.headline)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Total").font(.caption).foregroundStyle(.secondary)
                Text("\(total.clean) lb").font(Theme.hand(26, relativeTo: .title2)).foregroundStyle(Theme.accentDeep)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: Plate buttons

    private var plateButtons: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tap to add (per side)").font(.caption).foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 66), spacing: 10)], spacing: 10) {
                ForEach(denominations, id: \.self) { plate in
                    Button { perSide[plate, default: 0] += 1 } label: {
                        VStack(spacing: 4) {
                            Circle().fill(color(for: plate)).frame(width: 24, height: 24)
                            Text("\(plate.clean) lb").font(.caption2).bold()
                            Text("×\(perSide[plate] ?? 0)")
                                .font(.system(size: 10)).foregroundStyle(.secondary).monospacedDigit()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Options

    private var options: some View {
        VStack(spacing: 12) {
            Picker("Bar", selection: $barTypeRaw) {
                ForEach(BarType.allCases) { bar in
                    Text("\(bar.name) (\(bar.weight.clean) lb)").tag(bar.rawValue)
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.accent)

            Toggle("Micro plates (2.5 / 1.25 lb)", isOn: $useMicroPlates)
                .tint(Theme.accent)

            if let name = exerciseName, !name.isEmpty {
                Button {
                    LoadoutStore.save(exercise: name, barType: barTypeRaw, perSide: perSide)
                } label: {
                    Label("Save as default for \(name)", systemImage: "bookmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(Theme.accent)
            }

            Button(role: .destructive) {
                perSide = [:]
            } label: {
                Label("Clear plates", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: Helpers

    private func removeOne(_ plate: Double) {
        perSide[plate] = max(0, (perSide[plate] ?? 0) - 1)
    }

    /// Distinct color per plate, loosely echoing competition plate colors.
    private func color(for plate: Double) -> Color {
        switch plate {
        case 45: return .red
        case 40: return .blue
        case 35: return .yellow
        case 30: return .indigo
        case 25: return .green
        case 20: return .mint
        case 15: return .purple
        case 10: return .orange
        case 5: return .teal
        default: return .gray            // micro plates
        }
    }

    /// On open: restore the exercise's saved loadout if the set has no weight
    /// yet; otherwise reflect the current weight on the bar.
    private func restoreOnAppear() {
        guard perSide.isEmpty else { return }
        if weight <= 0, let name = exerciseName, let saved = LoadoutStore.load(exercise: name) {
            barTypeRaw = saved.barType
            perSide = saved.plates
        } else {
            decomposeCurrentWeight()
        }
    }

    /// Pre-fill plate counts by greedily decomposing the current weight.
    private func decomposeCurrentWeight() {
        let factor = barType.mirrors ? 2.0 : 1.0
        var remaining = (weight - barType.weight) / factor
        guard remaining > 0 else { return }
        var counts: [Double: Int] = [:]
        for plate in denominations {
            let count = Int((remaining + 0.001) / plate)
            if count > 0 {
                counts[plate] = count
                remaining -= Double(count) * plate
            }
        }
        if abs(remaining) < 0.01 { perSide = counts }
    }
}

/// Persists a per-exercise default bar + plate loadout in UserDefaults.
enum LoadoutStore {
    private struct Loadout: Codable { var barType: String; var plates: [String: Int] }

    private static func key(_ exercise: String) -> String { "loadout.\(exercise)" }

    static func save(exercise: String, barType: String, perSide: [Double: Int]) {
        let plates = Dictionary(uniqueKeysWithValues: perSide.map { (String($0.key), $0.value) })
        let loadout = Loadout(barType: barType, plates: plates)
        if let data = try? JSONEncoder().encode(loadout) {
            UserDefaults.standard.set(data, forKey: key(exercise))
        }
    }

    static func load(exercise: String) -> (barType: String, plates: [Double: Int])? {
        guard
            let data = UserDefaults.standard.data(forKey: key(exercise)),
            let loadout = try? JSONDecoder().decode(Loadout.self, from: data)
        else { return nil }
        let plates = Dictionary(uniqueKeysWithValues: loadout.plates.compactMap { key, value -> (Double, Int)? in
            Double(key).map { ($0, value) }
        })
        return (loadout.barType, plates)
    }
}
