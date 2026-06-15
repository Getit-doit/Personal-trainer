import SwiftUI
import SwiftData

/// Edit the athlete profile after onboarding: stats, schedule, goal, and the
/// training constraints that drive coaching and the warm-up gate.
struct EditProfileView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var profile: UserProfile

    @State private var feet = 5
    @State private var inches = 10

    @AppStorage("restCompound") private var restCompound = 180
    @AppStorage("restAccessory") private var restAccessory = 90
    @AppStorage("autoStartRest") private var autoStartRest = true

    var body: some View {
        NavigationStack {
            Form {
                Section("You") {
                    LabeledContent("Name") {
                        TextField("Name", text: $profile.name).multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Height") {
                        HStack(spacing: 4) {
                            Picker("ft", selection: $feet) {
                                ForEach(4...7, id: \.self) { Text("\($0) ft").tag($0) }
                            }
                            Picker("in", selection: $inches) {
                                ForEach(0...11, id: \.self) { Text("\($0) in").tag($0) }
                            }
                        }
                        .pickerStyle(.menu).tint(Theme.accent)
                    }
                    LabeledContent("Start weight") {
                        HStack(spacing: 4) {
                            TextField("Weight", value: $profile.startWeight, format: .number)
                                .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 70)
                            Text("lb").foregroundStyle(.secondary)
                        }
                    }
                    Stepper("Days / week: \(profile.scheduleDaysPerWeek)",
                            value: $profile.scheduleDaysPerWeek, in: 2...6)
                }

                Section("Goal") {
                    TextField("Primary goal", text: $profile.goals, axis: .vertical)
                        .lineLimit(1...3)
                }

                Section {
                    Toggle("Auto-start after a set", isOn: $autoStartRest)
                        .tint(Theme.accent)
                    Stepper("Compound rest: \(restLabel(restCompound))",
                            value: $restCompound, in: 30...420, step: 15)
                    Stepper("Accessory rest: \(restLabel(restAccessory))",
                            value: $restAccessory, in: 30...420, step: 15)
                } header: {
                    Text("Rest Timer")
                } footer: {
                    Text("These set the auto-start rest and the preset chips during a workout.")
                }

                Section {
                    ListEditorCard(
                        title: "Constraints",
                        systemImage: "exclamationmark.triangle.fill",
                        tint: .orange,
                        placeholder: "e.g. Ankle inflames easily",
                        items: $profile.constraints
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } footer: {
                    Text("Constraints inform the AI coach and the mandatory ankle warm-up.")
                }
            }
            .scrollContentBackground(.hidden)
            .listRowBackground(Color.clear)
            .blueprintBackground()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                feet = Int(profile.heightInches) / 12
                inches = Int(profile.heightInches) % 12
            }
            .onChange(of: feet) { profile.heightInches = Double(feet * 12 + inches) }
            .onChange(of: inches) { profile.heightInches = Double(feet * 12 + inches) }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        try? context.save()
                        dismiss()
                    }
                }
            }
        }
    }

    private func restLabel(_ seconds: Int) -> String {
        seconds < 60 ? "\(seconds)s"
            : (seconds % 60 == 0 ? "\(seconds / 60) min" : "\(seconds / 60):\(String(format: "%02d", seconds % 60))")
    }
}
