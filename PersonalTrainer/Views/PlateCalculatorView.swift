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

/// Visual barbell loader — REVISED to a dimensioned blueprint elevation.
///
/// Plates are now monochrome outlines (white ink), differentiated by SIZE and a
/// monospace denomination label rather than competition colors — matching the
/// app icon's drawing language. Tap a plate button to add it **per side**; tap a
/// loaded plate on the bar to remove it.
struct PlateCalculatorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var weight: Double
    var exerciseName: String? = nil
    var onApply: () -> Void

    @AppStorage("barTypeRaw") private var barTypeRaw = BarType.barbell.rawValue

    private var barType: BarType { BarType(rawValue: barTypeRaw) ?? .barbell }

    /// Real-world plate denominations only.
    private let denominations: [Double] = [45, 35, 25, 15, 10, 5, 2.5]

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

    // MARK: Barbell elevation drawing

    private var barbell: some View {
        VStack(spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .center, spacing: 2) {
                    // Bar shaft + collar (ink hairline, not solid gray)
                    Rectangle().fill(Theme.ink.opacity(0.22)).frame(width: 30, height: 6)
                        .overlay(Rectangle().stroke(Theme.hairline, lineWidth: 0.5))
                    Rectangle().fill(Theme.ink.opacity(0.3)).frame(width: 7, height: 22)

                    if loadedPlates.isEmpty {
                        Text("EMPTY BAR — TAP A PLATE BELOW")
                            .font(Theme.mono(11)).tracking(1)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 10)
                    } else {
                        ForEach(Array(loadedPlates.enumerated()), id: \.offset) { _, plate in
                            Button { removeOne(plate) } label: { plateView(plate) }
                                .buttonStyle(.plain)
                        }
                        // Sleeve end cap
                        Rectangle().fill(Theme.ink.opacity(0.3)).frame(width: 8, height: 24)
                    }
                    Spacer(minLength: 0)
                }
                .frame(height: 100)
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            }

            // Dimension line — echoes the icon's "45 LB" callout.
            if !loadedPlates.isEmpty {
                HStack(spacing: 8) {
                    Text("◄").font(Theme.mono(10)).foregroundStyle(Theme.accent)
                    Rectangle().fill(Theme.accent.opacity(0.5)).frame(height: 1)
                    Text("\(perSideTotal.clean) LB / SIDE").font(Theme.mono(10)).tracking(1.2).foregroundStyle(Theme.accent)
                    Rectangle().fill(Theme.accent.opacity(0.5)).frame(height: 1)
                    Text("►").font(Theme.mono(10)).foregroundStyle(Theme.accent)
                }
                .padding(.horizontal, 8)
            }
        }
        .padding(.vertical, 6)
        .background(Rectangle().fill(Theme.card))
        .overlay(Rectangle().stroke(Theme.hairline, lineWidth: 1))
        .overlay(CornerTicks().stroke(Theme.accent.opacity(0.9), lineWidth: 1.2))
    }

    /// A plate as a monochrome outlined rectangle, sized by weight, with a
    /// rotated monospace denomination. No competition colors.
    private func plateView(_ plate: Double) -> some View {
        let height = 40 + plate / 45 * 48        // 40…88 pt
        let width = 11 + plate / 45 * 9          // 11…20 pt
        return RoundedRectangle(cornerRadius: 2)
            .fill(Theme.accent.opacity(0.10))
            .frame(width: width, height: height)
            .overlay(
                Text(plate.clean)
                    .font(Theme.mono(9, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .rotationEffect(.degrees(-90))
            )
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(Theme.accent, lineWidth: 1.4))
    }

    // MARK: Totals

    private var totals: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(barType.mirrors ? "PER SIDE" : "PER DUMBBELL")
                    .font(Theme.label(9)).tracking(1.4).foregroundStyle(.secondary)
                Text("\(perSideTotal.clean) lb").font(Theme.mono(16))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("TOTAL · \(barType.weight.clean) BAR + \(barType.mirrors ? "2×" : "")\(perSideTotal.clean)")
                    .font(Theme.label(9)).tracking(1.2).foregroundStyle(.secondary)
                Text("\(total.clean) lb").font(Theme.mono(30, weight: .medium)).foregroundStyle(Theme.accent)
            }
        }
        .padding(.vertical, 12)
        .overlay(Rectangle().fill(Theme.hairline).frame(height: 1), alignment: .top)
        .overlay(Rectangle().fill(Theme.hairline).frame(height: 1), alignment: .bottom)
        .padding(.horizontal, 4)
    }

    // MARK: Plate buttons

    private var plateButtons: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TAP TO ADD — PER SIDE")
                .font(Theme.label(10)).tracking(1.6).foregroundStyle(Theme.accent)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 9)], spacing: 14) {
                ForEach(denominations, id: \.self) { plate in
                    let count = perSide[plate] ?? 0
                    Button { perSide[plate, default: 0] += 1 } label: {
                        VStack(spacing: 7) {
                            plateGlyph(plate, active: count > 0)
                            Text("×\(count)")
                                .font(Theme.mono(11))
                                .foregroundStyle(count > 0 ? Theme.accent : Color.white.opacity(0.4))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// A face-on plate drawing: weight stamped near the top and again
    /// upside-down near the bottom (symmetric about the center), with a
    /// punched center hole. All plates share one size; the 10 / 5 / 2.5
    /// render as hex bumper plates.
    private func plateGlyph(_ plate: Double, active: Bool) -> some View {
        let diameter: CGFloat = 56                  // uniform across denominations
        let hex = plate <= 10                       // gym hex bumpers
        let rim = active ? Theme.accent : Theme.ink.opacity(0.32)
        let lineWidth: CGFloat = active ? 4.4 : 3.6 // ~2× the previous weight
        let labelOffset = diameter * 0.30          // centers stamp between rim & hole

        return ZStack {
            // Plate body
            Group {
                if hex {
                    Hexagon().fill(active ? Theme.accent.opacity(0.13) : Theme.ink.opacity(0.03))
                    Hexagon().stroke(rim, style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))
                } else {
                    Circle().fill(active ? Theme.accent.opacity(0.13) : Theme.ink.opacity(0.03))
                    Circle().strokeBorder(rim, lineWidth: lineWidth)
                }
            }

            // Weight stamped near the top, like a real plate
            Text(plate.clean)
                .font(Theme.mono(11, weight: .semibold))
                .foregroundStyle(active ? Theme.ink : Theme.ink.opacity(0.55))
                .offset(y: -labelOffset)

            // Punched center hole
            Circle()
                .fill(Theme.blueprintDeep)
                .frame(width: 11, height: 11)
                .overlay(Circle().stroke(Theme.ink.opacity(active ? 0.4 : 0.22), lineWidth: 1))
        }
        .frame(width: diameter, height: diameter)
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

/// A flat-top hexagon — the silhouette of a gym hex/bumper plate.
struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let cx = rect.midX, cy = rect.midY
        let rx = w / 2, ry = h / 2
        var p = Path()
        // pointy-top hexagon, vertices every 60°
        for i in 0..<6 {
            let angle = CGFloat.pi / 180 * (60 * Double(i) - 90)
            let pt = CGPoint(x: cx + rx * cos(angle), y: cy + ry * sin(angle))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
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
