import SwiftUI
import SwiftData

/// A searchable picker over the exercise database, organized by **muscle group**
/// so you can plan a session around what you want to train. A chip row jumps to
/// a muscle; each row shows its equipment.
struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var search = ""
    @State private var filter: String?
    var onPick: (Exercise) -> Void

    /// Canonical training order; anything else falls to the end alphabetically.
    private let muscleOrder = ["Legs", "Hinge", "Chest", "Back", "Shoulders", "Arms", "Core", "Cardio"]

    private func order(_ muscle: String) -> Int {
        muscleOrder.firstIndex(of: muscle) ?? muscleOrder.count
    }

    private var filtered: [Exercise] {
        exercises.filter { ex in
            (filter == nil || ex.muscleGroup == filter)
            && (search.isEmpty || ex.name.localizedCaseInsensitiveContains(search))
        }
    }

    private var muscleGroups: [String] {
        var seen = Set<String>()
        for ex in exercises where !seen.contains(ex.muscleGroup) { seen.insert(ex.muscleGroup) }
        return seen.sorted { (order($0), $0) < (order($1), $1) }
    }

    private var grouped: [(muscle: String, items: [Exercise])] {
        Dictionary(grouping: filtered, by: \.muscleGroup)
            .map { ($0.key, $0.value.sorted { $0.name < $1.name }) }
            .sorted { (order($0.muscle), $0.muscle) < (order($1.muscle), $1.muscle) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                muscleFilterRow
                List {
                    ForEach(grouped, id: \.muscle) { section in
                        Section {
                            ForEach(section.items) { exercise in
                                row(exercise)
                                    .listRowBackground(Color.clear)
                            }
                        } header: {
                            HStack(spacing: 8) {
                                Text(section.muscle.uppercased())
                                    .font(Theme.label(11)).tracking(1.6)
                                    .foregroundStyle(Theme.accent)
                                Rectangle().fill(Color.white.opacity(0.16)).frame(height: 1)
                                Text("\(section.items.count)")
                                    .font(Theme.mono(9)).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .listRowBackground(Color.clear)
            }
            .blueprintBackground()
            .searchable(text: $search, prompt: "Search \(exercises.count) exercises")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }

    private var muscleFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(nil, label: "All")
                ForEach(muscleGroups, id: \.self) { muscle in
                    chip(muscle, label: muscle)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private func chip(_ muscle: String?, label: String) -> some View {
        let selected = filter == muscle
        Button {
            filter = selected ? nil : muscle
        } label: {
            Text(label.uppercased()).font(Theme.mono(10, weight: .semibold)).tracking(0.5)
                .padding(.horizontal, 11).padding(.vertical, 8)
                .background(selected ? Theme.accent : Color.clear)
                .overlay(Rectangle().stroke(selected ? Color.clear : Theme.hairline, lineWidth: 1))
                .foregroundStyle(selected ? Theme.blueprintDeep : Theme.accent)
        }
        .buttonStyle(.plain)
    }

    private func row(_ exercise: Exercise) -> some View {
        Button {
            onPick(exercise)
            dismiss()
        } label: {
            HStack(spacing: 10) {
                exercise.equipment.image
                    .resizable().scaledToFit().frame(width: 20, height: 20)
                    .foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 1) {
                    Text(exercise.name)
                    HStack(spacing: 6) {
                        Text(exercise.equipment.name.uppercased())
                        Text("· \(exercise.difficulty.rawValue.uppercased())")
                            .foregroundStyle(difficultyColor(exercise.difficulty))
                        if exercise.isPriorityProgression {
                            Text("· PRIORITY").foregroundStyle(Theme.accent)
                        }
                    }
                    .font(Theme.mono(9)).tracking(0.4).foregroundStyle(.secondary)
                }
                Spacer()
                Text(exercise.type.rawValue.uppercased())
                    .font(Theme.mono(9)).foregroundStyle(.secondary)
                Image(systemName: "plus").foregroundStyle(Theme.accent)
            }
        }
        .tint(.primary)
    }

    private func difficultyColor(_ d: Difficulty) -> Color {
        switch d {
        case .beginner: return .secondary
        case .intermediate: return Theme.accent
        case .advanced: return Theme.amber
        }
    }
}
