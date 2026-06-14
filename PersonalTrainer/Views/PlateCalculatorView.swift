import SwiftUI

/// Visual barbell loader. Tap a plate button to add it **per side**; tap a
/// loaded plate on the bar to remove it. Total = bar + 2 × (one side's plates).
/// Plates range 5–45 lb in 5 lb steps, with an optional 2.5 / 1.25 lb micro set.
struct PlateCalculatorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var weight: Double
    var onApply: () -> Void

    @AppStorage("barWeight") private var barWeight = 45.0
    @AppStorage("useMicroPlates") private var useMicroPlates = false

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

    private var total: Double { barWeight + 2 * perSideTotal }

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
            .background(Theme.background)
            .navigationTitle("Load the Bar")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { decomposeCurrentWeight() }
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
                Text("Per side").font(.caption).foregroundStyle(.secondary)
                Text("\(perSideTotal.clean) lb").font(.headline)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Total").font(.caption).foregroundStyle(.secondary)
                Text("\(total.clean) lb").font(.title2).bold().foregroundStyle(Theme.accentDeep)
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
            Picker("Bar", selection: $barWeight) {
                Text("No bar (0)").tag(0.0)
                Text("35 lb").tag(35.0)
                Text("45 lb").tag(45.0)
            }
            .pickerStyle(.segmented)

            Toggle("Micro plates (2.5 / 1.25 lb)", isOn: $useMicroPlates)
                .tint(Theme.accent)

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

    /// Pre-fill plate counts by greedily decomposing the current weight.
    private func decomposeCurrentWeight() {
        guard perSide.isEmpty else { return }
        var remaining = (weight - barWeight) / 2
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
