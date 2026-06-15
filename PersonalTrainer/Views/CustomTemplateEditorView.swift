import SwiftUI
import SwiftData

/// Create or edit a custom routine day (program, title, level, and exercises).
struct CustomTemplateEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// Existing template to edit, or nil to create a new one.
    var existing: CustomTemplate?
    /// Program names already in use, offered as quick suggestions.
    var programSuggestions: [String]

    @State private var program = ""
    @State private var title = ""
    @State private var level = "Custom"
    @State private var items: [DraftItem] = []
    @State private var showingPicker = false

    private let levels = ["Beginner", "Intermediate", "Advanced", "Custom"]

    struct DraftItem: Identifiable {
        let id = UUID()
        var name: String
        var muscleGroup: String
        var equipment: Equipment
        var sets: Int
        var reps: Int
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Routine") {
                    HStack {
                        TextField("Program (e.g. My Split)", text: $program)
                        if !programSuggestions.isEmpty {
                            Menu {
                                ForEach(programSuggestions, id: \.self) { name in
                                    Button(name) { program = name }
                                }
                            } label: { Image(systemName: "chevron.down.circle") }
                        }
                    }
                    TextField("Day name (e.g. Push)", text: $title)
                    Picker("Level", selection: $level) {
                        ForEach(levels, id: \.self) { Text($0) }
                    }
                }

                Section {
                    ForEach($items) { $item in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                item.equipment.image.resizable().scaledToFit()
                                    .frame(width: 18, height: 18).foregroundStyle(Theme.accent)
                                Text(item.name).font(.subheadline)
                            }
                            HStack {
                                Stepper("\(item.sets) sets", value: $item.sets, in: 1...10).fixedSize()
                                Spacer()
                                Stepper("\(item.reps) reps", value: $item.reps, in: 1...30).fixedSize()
                            }
                            .font(.caption)
                        }
                    }
                    .onDelete { items.remove(atOffsets: $0) }
                    .onMove { items.move(fromOffsets: $0, toOffset: $1) }

                    Button {
                        showingPicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle.fill")
                    }
                    .tint(Theme.accent)
                } header: {
                    HStack {
                        Text("Exercises")
                        Spacer()
                        if !items.isEmpty { EditButton().font(.caption) }
                    }
                } footer: {
                    Text("Tap Edit to reorder or delete. Order is how they'll appear in the session.")
                }
            }
            .scrollContentBackground(.hidden)
            .blueprintBackground()
            .navigationTitle(existing == nil ? "New Routine" : "Edit Routine")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingPicker) {
                ExercisePickerView { exercise in
                    items.append(DraftItem(
                        name: exercise.name,
                        muscleGroup: exercise.muscleGroup,
                        equipment: exercise.equipment,
                        sets: exercise.targetSets,
                        reps: exercise.targetReps
                    ))
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave)
                }
            }
            .onAppear(perform: load)
        }
    }

    private var canSave: Bool {
        !program.trimmingCharacters(in: .whitespaces).isEmpty
        && !title.trimmingCharacters(in: .whitespaces).isEmpty
        && !items.isEmpty
    }

    private func load() {
        guard let existing, items.isEmpty, program.isEmpty else { return }
        program = existing.program
        title = existing.title
        level = existing.level
        items = existing.sortedItems.map {
            DraftItem(name: $0.name, muscleGroup: $0.muscleGroup, equipment: $0.equipment, sets: $0.sets, reps: $0.reps)
        }
    }

    private func save() {
        let template: CustomTemplate
        if let existing {
            existing.items.forEach { context.delete($0) }
            existing.items = []
            existing.program = program
            existing.title = title
            existing.level = level
            template = existing
        } else {
            template = CustomTemplate(program: program, title: title, level: level, order: Int(Date().timeIntervalSince1970))
            context.insert(template)
        }
        for (index, draft) in items.enumerated() {
            let item = CustomTemplateItem(
                name: draft.name, muscleGroup: draft.muscleGroup,
                equipment: draft.equipment, sets: draft.sets, reps: draft.reps, order: index
            )
            item.template = template
            context.insert(item)
        }
        try? context.save()
        dismiss()
    }
}
