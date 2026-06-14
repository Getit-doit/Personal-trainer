import SwiftUI

/// Calculates total barbell weight from plates loaded **per side**.
///
/// Total = bar weight + 2 × (sum of one side's plates). Plates range 5–45 lb in
/// 5 lb steps. The number field on each set still allows typing a weight
/// directly; this sheet is the plate-based alternative.
struct PlateCalculatorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var weight: Double
    var onApply: () -> Void

    /// Remembered between sets/sessions.
    @AppStorage("barWeight") private var barWeight = 45.0

    /// Plate denominations, heaviest first (5–45 lb in 5 lb increments).
    private let denominations = [45, 40, 35, 30, 25, 20, 15, 10, 5]

    /// Count of each plate per side.
    @State private var perSide: [Int: Int] = [:]

    private var perSideTotal: Double {
        denominations.reduce(0) { $0 + Double($1 * (perSide[$1] ?? 0)) }
    }

    private var total: Double {
        barWeight + 2 * perSideTotal
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Bar", selection: $barWeight) {
                        Text("None (0 lb)").tag(0.0)
                        Text("Women's (35 lb)").tag(35.0)
                        Text("Standard (45 lb)").tag(45.0)
                    }
                } header: {
                    Text("Bar Weight")
                }

                Section {
                    ForEach(denominations, id: \.self) { plate in
                        Stepper(
                            onIncrement: { perSide[plate, default: 0] += 1 },
                            onDecrement: { perSide[plate] = max(0, (perSide[plate] ?? 0) - 1) }
                        ) {
                            HStack {
                                plateChip(plate)
                                Text("\(plate) lb").bold()
                                Spacer()
                                Text("× \(perSide[plate] ?? 0)")
                                    .foregroundStyle(.secondary).monospacedDigit()
                            }
                        }
                    }
                } header: {
                    Text("Plates Per Side")
                } footer: {
                    Text("Add the plates you load on one side. Both sides are mirrored automatically.")
                }

                Section {
                    LabeledContent("Per side", value: "\(perSideTotal.clean) lb")
                    LabeledContent("Total") {
                        Text("\(total.clean) lb").font(.title3).bold().foregroundStyle(Theme.accentDeep)
                    }
                    if !perSide.values.contains(where: { $0 > 0 }) {
                        Text("Just the bar.").font(.caption).foregroundStyle(.secondary)
                    }
                    Button {
                        perSide = [:]
                    } label: {
                        Label("Clear plates", systemImage: "arrow.counterclockwise")
                    }
                    .tint(Theme.accent)
                }
            }
            .navigationTitle("Plate Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { decomposeCurrentWeight() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
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

    private func plateChip(_ plate: Int) -> some View {
        // Bigger plates render as a larger disc for quick scanning.
        let size = 16.0 + Double(plate) / 45.0 * 10.0
        return Circle()
            .fill(Theme.accent.opacity(0.25))
            .overlay(Circle().stroke(Theme.accent, lineWidth: 1.5))
            .frame(width: size, height: size)
    }

    /// Pre-fill the plate counts by greedily decomposing the current weight,
    /// so reopening the sheet reflects what's already entered.
    private func decomposeCurrentWeight() {
        guard perSide.isEmpty else { return }
        var remaining = (weight - barWeight) / 2
        guard remaining > 0 else { return }
        var counts: [Int: Int] = [:]
        for plate in denominations {
            let count = Int((remaining + 0.001) / Double(plate))
            if count > 0 {
                counts[plate] = count
                remaining -= Double(count * plate)
            }
        }
        // Only adopt the decomposition if it reconstructs the weight cleanly.
        if abs(remaining) < 0.01 {
            perSide = counts
        }
    }
}
