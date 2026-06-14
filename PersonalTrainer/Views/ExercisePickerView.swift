import SwiftUI
import SwiftData

/// A searchable picker over the exercise database, grouped by equipment with
/// the blueprint equipment logo on each section. A chip row filters by type.
struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var search = ""
    @State private var filter: Equipment?
    var onPick: (Exercise) -> Void

    private var filtered: [Exercise] {
        exercises.filter { ex in
            (filter == nil || ex.equipment == filter)
            && (search.isEmpty || ex.name.localizedCaseInsensitiveContains(search))
        }
    }

    private var grouped: [(equipment: Equipment, items: [Exercise])] {
        Dictionary(grouping: filtered, by: \.equipment)
            .map { ($0.key, $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.equipment.sortOrder < $1.equipment.sortOrder }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                equipmentFilterRow
                List {
                    ForEach(grouped, id: \.equipment) { section in
                        Section {
                            ForEach(section.items) { exercise in
                                row(exercise)
                            }
                        } header: {
                            HStack(spacing: 8) {
                                section.equipment.image
                                    .resizable().scaledToFit().frame(width: 22, height: 22)
                                    .foregroundStyle(Theme.accent)
                                Text(section.equipment.name)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
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

    private var equipmentFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(nil, label: "All", systemImage: "square.grid.2x2")
                ForEach(Equipment.allCases) { eq in
                    chip(eq, label: eq.name, image: eq.image)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private func chip(_ eq: Equipment?, label: String, systemImage: String? = nil, image: Image? = nil) -> some View {
        let selected = filter == eq
        Button {
            filter = selected ? nil : eq
        } label: {
            HStack(spacing: 5) {
                if let image {
                    image.resizable().scaledToFit().frame(width: 16, height: 16)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(label).font(.caption).bold()
            }
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(selected ? Theme.accent : Theme.card, in: Capsule())
            .foregroundStyle(selected ? Theme.blueprintDeep : .white)
        }
        .buttonStyle(.plain)
    }

    private func row(_ exercise: Exercise) -> some View {
        Button {
            onPick(exercise)
            dismiss()
        } label: {
            HStack {
                Circle().fill(Theme.color(for: exercise.muscleGroup)).frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 1) {
                    Text(exercise.name)
                    HStack(spacing: 6) {
                        Text(exercise.muscleGroup)
                        if exercise.isPriorityProgression {
                            Text("· Priority").foregroundStyle(Theme.accent)
                        }
                    }
                    .font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Text(exercise.type.rawValue).font(.caption2).foregroundStyle(.secondary)
                Image(systemName: "plus").foregroundStyle(Theme.accent)
            }
        }
        .tint(.primary)
    }
}
