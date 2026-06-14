import SwiftUI
import SwiftData

/// First-launch onboarding: introduces the blueprint theme and captures the
/// athlete's starting stats into the `UserProfile`.
struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    var onDone: () -> Void

    @State private var name = ""
    @State private var feet = 5
    @State private var inches = 10
    @State private var startWeight = 217.0
    @State private var days = 3
    @State private var goals = "Functional lean strength + longevity"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                introCard
                statsCard
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
            Text("Your strength & longevity blueprint")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 24)
    }

    private var introCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Label("How it works", systemImage: "ruler")
                    .font(Theme.hand(19, relativeTo: .headline))
                bullet("Compound-first full-body training, 3 days/week")
                bullet("Log sets with RPE & reps-in-tank; lifts flag when ready to progress")
                bullet("Mandatory ankle warm-up before every session")
                bullet("Track recovery, one nutrition lever, and your PRs")
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.accent).font(.caption)
            Text(text).font(.callout)
        }
    }

    private var statsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                Label("Your starting blueprint", systemImage: "person.text.rectangle")
                    .font(Theme.hand(19, relativeTo: .headline))

                field("Name") {
                    TextField("Name", text: $name).multilineTextAlignment(.trailing)
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
                field("Start weight") {
                    HStack(spacing: 4) {
                        TextField("Weight", value: $startWeight, format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 70)
                        Text("lb").foregroundStyle(.secondary)
                    }
                }
                field("Days / week") {
                    Stepper("\(days)", value: $days, in: 2...6).fixedSize()
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Primary goal").font(.subheadline).foregroundStyle(.secondary)
                    TextField("Goal", text: $goals, axis: .vertical)
                        .lineLimit(1...3)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
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
            Label("Start Training", systemImage: "play.fill")
                .font(Theme.hand(20, relativeTo: .headline))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(Theme.blueprintDeep)
        }
    }

    private func loadProfile() {
        guard let profile = profiles.first else { return }
        if !profile.name.isEmpty && profile.name != "Athlete" { name = profile.name }
        feet = Int(profile.heightInches) / 12
        inches = Int(profile.heightInches) % 12
        startWeight = profile.startWeight
        days = profile.scheduleDaysPerWeek
        if !profile.goals.isEmpty { goals = profile.goals }
    }

    private func save() {
        let profile = profiles.first ?? {
            let new = UserProfile(
                name: "", heightInches: 70, startWeight: 217,
                goals: goals, constraints: [], scheduleDaysPerWeek: 3
            )
            context.insert(new)
            return new
        }()
        profile.name = name.isEmpty ? "Athlete" : name
        profile.heightInches = Double(feet * 12 + inches)
        profile.startWeight = startWeight
        profile.scheduleDaysPerWeek = days
        profile.goals = goals
        try? context.save()
        onDone()
    }
}
