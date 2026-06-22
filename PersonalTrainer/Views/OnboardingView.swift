import SwiftUI
import SwiftData

/// First-launch onboarding: collects everything the app needs to build a
/// training plan for whoever sets it up — stats, experience, goal, schedule,
/// available equipment, and any injuries/limitations.
struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    var onDone: () -> Void

    @State private var name = ""
    @State private var sex = "Prefer not to say"
    @State private var age = 30
    @State private var feet = 5
    @State private var inches = 8
    @State private var weight = 175.0
    @State private var experience = "Beginner"
    @State private var days = 3
    @State private var goal = "General fitness"
    @State private var equipment: Set<String> = ["Dumbbells", "Bodyweight only"]
    @State private var constraints: [String] = []

    private let sexes = ["Male", "Female", "Prefer not to say"]
    private let levels = ["Beginner", "Intermediate", "Advanced"]
    private let goals = [
        "Lose fat", "Build muscle", "Functional strength",
        "Longevity & health", "General fitness", "Athletic performance"
    ]
    private let equipmentOptions = [
        "Full gym", "Barbell", "Dumbbells", "Kettlebell",
        "Machines / cables", "Resistance bands", "Pull-up bar", "Bodyweight only"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                introCard
                aboutCard
                trainingCard
                equipmentCard
                injuriesCard
                startButton
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .blueprintBackground()
        .onAppear(perform: loadProfile)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.accent)
            Text("Functional Trainer")
                .font(Theme.hand(34, relativeTo: .largeTitle))
            Text("Let's build your training blueprint")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 24)
    }

    private var introCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                SectionRule(title: "How it works")
                bullet("Compound-first training built around your goal & schedule")
                bullet("Log sets with RPE & reps-in-tank; lifts flag when ready to progress")
                bullet("Guided warm-up before every session")
                bullet("Track recovery, one nutrition lever, streaks, and your PRs")
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.accent).font(.caption)
            Text(text).font(.callout)
        }
    }

    // MARK: About you

    private var aboutCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                SectionRule(title: "About you")

                field("Name") {
                    TextField("Name", text: $name).multilineTextAlignment(.trailing)
                }
                field("Sex") {
                    Picker("Sex", selection: $sex) {
                        ForEach(sexes, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu).tint(Theme.accent)
                }
                field("Age") {
                    Stepper("\(age)", value: $age, in: 13...100).fixedSize()
                }
                field("Height") {
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
                field("Current weight") {
                    HStack(spacing: 4) {
                        TextField("Weight", value: $weight, format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 70)
                        Text("lb").foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: Training

    private var trainingCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                SectionRule(title: "Your training")

                VStack(alignment: .leading, spacing: 8) {
                    Text("Experience").font(.subheadline).foregroundStyle(.secondary)
                    Picker("Experience", selection: $experience) {
                        ForEach(levels, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                field("Days / week") {
                    Stepper("\(days)", value: $days, in: 2...6).fixedSize()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Primary goal").font(.subheadline).foregroundStyle(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(goals, id: \.self) { g in
                                chip(g, selected: goal == g) { goal = g }
                            }
                        }
                    }
                    TextField("Goal", text: $goal, axis: .vertical)
                        .lineLimit(1...3)
                        .blueprintField()
                }
            }
        }
    }

    // MARK: Equipment

    private var equipmentCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionRule(title: "Equipment you can use")
                Text("Tap all that apply — plans are built around what you have.")
                    .font(.caption).foregroundStyle(.secondary)
                FlowChips(options: equipmentOptions, selection: $equipment)
            }
        }
    }

    // MARK: Injuries

    private var injuriesCard: some View {
        ListEditorCard(
            title: "Injuries & limitations",
            systemImage: "exclamationmark.triangle.fill",
            tint: Theme.amber,
            placeholder: "e.g. Bad left knee, tight shoulder",
            items: $constraints
        )
    }

    // MARK: Bits

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(Theme.mono(10, weight: .semibold)).tracking(0.6)
                .padding(.horizontal, 11).padding(.vertical, 8)
                .background(selected ? Theme.accent : Color.clear)
                .overlay(Rectangle().stroke(Theme.accent.opacity(selected ? 1 : 0.5), lineWidth: 1))
                .foregroundStyle(selected ? Theme.blueprintDeep : Theme.accent)
        }
        .buttonStyle(.plain)
    }

    private func field<Control: View>(_ title: String, @ViewBuilder control: () -> Control) -> some View {
        HStack {
            Text(title)
            Spacer()
            control()
        }
    }

    private var startButton: some View {
        Button(action: save) {
            Label("Build My Plan", systemImage: "play.fill")
                .font(Theme.hand(20, relativeTo: .headline))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(Theme.blueprintDeep)
        }
        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    private func loadProfile() {
        guard let profile = profiles.first else { return }
        if !profile.name.isEmpty { name = profile.name }
        if !profile.sex.isEmpty { sex = profile.sex }
        if profile.age > 0 { age = profile.age }
        feet = Int(profile.heightInches) / 12
        inches = Int(profile.heightInches) % 12
        if profile.startWeight > 0 { weight = profile.startWeight }
        if !profile.experience.isEmpty { experience = profile.experience }
        days = profile.scheduleDaysPerWeek
        if !profile.goals.isEmpty { goal = profile.goals }
        if !profile.equipment.isEmpty { equipment = Set(profile.equipment) }
        constraints = profile.constraints
    }

    private func save() {
        let resolvedSex = sex == "Prefer not to say" ? "" : sex
        let profile = profiles.first ?? {
            let new = UserProfile(
                name: "", heightInches: 70, startWeight: 0,
                goals: goal, constraints: [], scheduleDaysPerWeek: days
            )
            context.insert(new)
            return new
        }()
        profile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.sex = resolvedSex
        profile.age = age
        profile.heightInches = Double(feet * 12 + inches)
        profile.startWeight = weight
        profile.experience = experience
        profile.scheduleDaysPerWeek = days
        profile.goals = goal.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.equipment = Array(equipment).sorted()
        profile.constraints = constraints
        try? context.save()
        onDone()
    }
}

/// A wrapping set of toggleable chips for multi-select (equipment, etc.).
struct FlowChips: View {
    let options: [String]
    @Binding var selection: Set<String>

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(options, id: \.self) { option in
                let on = selection.contains(option)
                Button {
                    if on { selection.remove(option) } else { selection.insert(option) }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: on ? "checkmark.square.fill" : "square")
                            .font(.caption)
                        Text(option).font(.footnote)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 8)
                    .overlay(Rectangle().stroke(Theme.accent.opacity(on ? 1 : 0.4), lineWidth: 1))
                    .foregroundStyle(on ? Theme.accent : .primary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
