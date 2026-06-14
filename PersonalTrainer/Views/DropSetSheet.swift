import SwiftUI

/// Configures a drop set: lift the start weight to failure, strip to the next
/// weight (no rest), repeat until you reach the end weight.
struct DropSetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var startWeight: Double
    @State private var dropAmount: Double = 10
    @State private var endWeight: Double

    var onCreate: (_ start: Double, _ drop: Double, _ end: Double) -> Void

    init(startWeight: Double, onCreate: @escaping (Double, Double, Double) -> Void) {
        _startWeight = State(initialValue: max(startWeight, 5))
        _endWeight = State(initialValue: max(startWeight / 2, 5))
        self.onCreate = onCreate
    }

    /// The ladder of weights this configuration produces.
    private var ladder: [Double] {
        guard dropAmount > 0, startWeight >= endWeight else { return [startWeight] }
        var result: [Double] = []
        var weight = startWeight
        while weight >= endWeight - 0.001 && result.count < 20 {
            result.append(weight)
            weight -= dropAmount
        }
        return result
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    weightRow("Start weight", value: $startWeight)
                    weightRow("Drop each failure", value: $dropAmount)
                    weightRow("End weight", value: $endWeight)
                } header: {
                    Text("Drop Set")
                } footer: {
                    Text("Each stage is taken to failure with no rest before the next drop.")
                }

                Section("Preview · \(ladder.count) drops") {
                    HStack(spacing: 6) {
                        ForEach(Array(ladder.enumerated()), id: \.offset) { index, weight in
                            if index > 0 {
                                Image(systemName: "arrow.right")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            Text("\(weight.clean)")
                                .font(.caption).bold()
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Theme.accent.opacity(0.15), in: Capsule())
                                .foregroundStyle(Theme.accentDeep)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .blueprintBackground()
            .navigationTitle("Add Drop Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add \(ladder.count) Sets") {
                        onCreate(startWeight, dropAmount, endWeight)
                        dismiss()
                    }
                    .disabled(ladder.count < 2)
                }
            }
        }
    }

    private func weightRow(_ title: String, value: Binding<Double>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField(title, value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 70)
            Stepper(title, value: value, in: 0...1000, step: 5)
                .labelsHidden()
            Text("lb").foregroundStyle(.secondary)
        }
    }
}
