import SwiftUI
import SwiftData

/// A searchable, grouped picker over the catalog for adding an exercise.
struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var search = ""
    var onPick: (Exercise) -> Void

    private var filtered: [Exercise] {
        guard !search.isEmpty else { return exercises }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    private var grouped: [(group: String, items: [Exercise])] {
        Dictionary(grouping: filtered, by: \.muscleGroup)
            .map { ($0.key, $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.group < $1.group }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.group) { section in
                    Section(section.group) {
                        ForEach(section.items) { exercise in
                            Button {
                                onPick(exercise)
                                dismiss()
                            } label: {
                                HStack {
                                    Circle().fill(Theme.color(for: exercise.muscleGroup)).frame(width: 8, height: 8)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(exercise.name)
                                        if exercise.isPriorityProgression {
                                            Text("Priority progression")
                                                .font(.caption2).foregroundStyle(Theme.accentDeep)
                                        }
                                    }
                                    Spacer()
                                    Text(exercise.type.rawValue)
                                        .font(.caption2).foregroundStyle(.secondary)
                                    Image(systemName: "plus").foregroundStyle(Theme.accent)
                                }
                            }
                            .tint(.primary)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .blueprintBackground()
            .searchable(text: $search, prompt: "Search exercises")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
