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

    // Coach voice (spoken replies during a workout)
    @AppStorage("coachSpeakReplies") private var coachSpeakReplies = true
    @AppStorage("coachVoiceID") private var coachVoiceID = ""
    @AppStorage("coachVoiceRate") private var coachVoiceRate = 0.5
    @StateObject private var previewVoice = VoiceService()

    // Coach memory condensing
    @AppStorage("condenseMemory") private var condenseMemory = false
    @State private var summarizing = false
    @State private var memoryStatus = ""
    @Query private var sessions: [WorkoutSession]
    @Query private var nutrition: [NutritionLog]
    @Query private var prs: [PersonalBest]
    @Query private var exercises: [Exercise]

    private let equipmentOptions = [
        "Full gym", "Barbell", "Dumbbells", "Kettlebell",
        "Machines / cables", "Resistance bands", "Pull-up bar", "Bodyweight only"
    ]

    /// Bridge the stored `[String]` equipment to the `Set<String>` FlowChips uses.
    private var equipmentBinding: Binding<Set<String>> {
        Binding(
            get: { Set(profile.equipment) },
            set: { profile.equipment = Array($0).sorted() }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("You") {
                    LabeledContent("Name") {
                        TextField("Name", text: $profile.name).multilineTextAlignment(.trailing)
                    }
                    Picker("Sex", selection: $profile.sex) {
                        Text("Unspecified").tag("")
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                    }
                    Stepper("Age: \(profile.age)", value: $profile.age, in: 13...100)
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
                    LabeledContent("Weight") {
                        HStack(spacing: 4) {
                            TextField("Weight", value: $profile.startWeight, format: .number)
                                .font(Theme.mono(15))
                                .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 70)
                            Text("LB").font(Theme.mono(10)).foregroundStyle(.secondary)
                        }
                    }
                    Picker("Experience", selection: $profile.experience) {
                        Text("Beginner").tag("Beginner")
                        Text("Intermediate").tag("Intermediate")
                        Text("Advanced").tag("Advanced")
                    }
                    Stepper("Days / week: \(profile.scheduleDaysPerWeek)",
                            value: $profile.scheduleDaysPerWeek, in: 2...6)
                }
                .listRowBackground(Color.clear)

                Section("Goal") {
                    TextField("Primary goal", text: $profile.goals, axis: .vertical)
                        .lineLimit(1...3)
                }
                .listRowBackground(Color.clear)

                Section {
                    FlowChips(options: equipmentOptions, selection: equipmentBinding)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                } header: {
                    Text("Equipment")
                } footer: {
                    Text("Plan suggestions and the AI coach build around what you select.")
                }
                .listRowBackground(Color.clear)

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
                .listRowBackground(Color.clear)

                Section {
                    Toggle("Read replies aloud", isOn: $coachSpeakReplies)
                        .tint(Theme.accent)
                    Picker("Voice", selection: $coachVoiceID) {
                        Text("Default").tag("")
                        ForEach(VoiceService.voiceOptions(), id: \.id) { v in
                            Text(v.name).tag(v.id)
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Speed").font(.subheadline)
                        Slider(value: $coachVoiceRate, in: 0.35...0.6)
                            .tint(Theme.accent)
                    }
                    Button {
                        previewVoice.speakReplies = true
                        previewVoice.speak("Nice work. Two reps in the tank — add five pounds next set.")
                    } label: {
                        Label("Preview voice", systemImage: "speaker.wave.2.fill")
                    }
                    .tint(Theme.accent)
                } header: {
                    Text("Coach Voice")
                } footer: {
                    Text("Used when you talk to the coach during a workout. For more natural voices, download them in iOS Settings → Accessibility → Spoken Content → Voices, then pick one here.")
                }
                .listRowBackground(Color.clear)

                Section {
                    Toggle("Condense coach memory", isOn: $condenseMemory)
                        .tint(Theme.accent)
                    Button {
                        Task { await summarizeMemory() }
                    } label: {
                        HStack {
                            Label("Summarize memory now", systemImage: "arrow.down.right.and.arrow.up.left")
                            Spacer()
                            if summarizing { ProgressView() }
                            else if !memoryStatus.isEmpty {
                                Text(memoryStatus).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .tint(Theme.accent)
                    .disabled(summarizing)
                } header: {
                    Text("Coach Memory")
                } footer: {
                    Text("The coach reads a briefing about you before replying. If it gets large, condensing replaces the detailed history with a short AI summary to save space (and speed up the on-device model). Needs the AI coach to be available.")
                }
                .listRowBackground(Color.clear)

                Section {
                    ListEditorCard(
                        title: "Injuries & limitations",
                        systemImage: "exclamationmark.triangle.fill",
                        tint: .orange,
                        placeholder: "e.g. Bad left knee",
                        items: $profile.constraints
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } footer: {
                    Text("These inform the AI coach so it programs around your limitations.")
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

    private func summarizeMemory() async {
        guard CoachService.activeEngine != .offline else {
            memoryStatus = "AI coach unavailable"; return
        }
        summarizing = true
        defer { summarizing = false }
        let full = CoachMemory.build(
            profile: profile, sessions: sessions,
            nutrition: nutrition, prs: prs, exercises: exercises
        )
        if await CoachMemory.refreshSummary(full: full) {
            memoryStatus = "Condensed ✓"
            condenseMemory = true   // turn it on once a summary exists
        } else {
            memoryStatus = "Couldn't summarize"
        }
    }

    private func restLabel(_ seconds: Int) -> String {
        seconds < 60 ? "\(seconds)s"
            : (seconds % 60 == 0 ? "\(seconds / 60) min" : "\(seconds / 60):\(String(format: "%02d", seconds % 60))")
    }
}
