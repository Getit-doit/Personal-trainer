import SwiftUI

/// A searchable, grouped picker for adding an exercise to a workout.
struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    var onPick: (ExerciseInfo) -> Void

    private var filtered: [ExerciseInfo] {
        guard !search.isEmpty else { return ExerciseLibrary.all }
        return ExerciseLibrary.all.filter {
            $0.name.localizedCaseInsensitiveContains(search)
        }
    }

    private var grouped: [(group: String, items: [ExerciseInfo])] {
        Dictionary(grouping: filtered, by: \.muscleGroup)
            .map { ($0.key, $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.group < $1.group }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.group) { section in
                    Section(section.group) {
                        ForEach(section.items) { info in
                            Button {
                                onPick(info)
                                dismiss()
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(Theme.color(for: info.muscleGroup))
                                        .frame(width: 8, height: 8)
                                    Text(info.name)
                                    Spacer()
                                    Image(systemName: "plus")
                                        .foregroundStyle(Theme.accent)
                                }
                            }
                            .tint(.primary)
                        }
                    }
                }
            }
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
