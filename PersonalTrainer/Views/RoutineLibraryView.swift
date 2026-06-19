import SwiftUI
import SwiftData

/// Browsable routine library: your custom routines plus built-in programs (Full
/// Body, Push/Pull/Legs, Upper/Lower, 5×5, Conditioning) with day templates,
/// level, and equipment badges. The "start a workout" screen.
struct RoutineLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \CustomTemplate.order) private var custom: [CustomTemplate]

    var onStart: (RoutineDay) -> Void
    var onEmpty: () -> Void

    @State private var editorTemplate: CustomTemplate?
    @State private var showingNewEditor = false
    @State private var timeFilter: TimeFilter = .any

    /// Duration buckets for the "time available" filter.
    enum TimeFilter: String, CaseIterable, Identifiable {
        case any = "Any time"
        case short = "~30 min"
        case medium = "~45 min"
        case long = "60+ min"
        var id: String { rawValue }
        func matches(_ minutes: Int) -> Bool {
            switch self {
            case .any: return true
            case .short: return minutes <= 35
            case .medium: return (36...52).contains(minutes)
            case .long: return minutes >= 53
            }
        }
    }

    private var customPrograms: [String] {
        var seen: [String] = []
        for c in custom where !seen.contains(c.program) { seen.append(c.program) }
        return seen
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    timeFilterRow
                    emptyCard

                    // Custom routines
                    if !custom.isEmpty {
                        ForEach(customPrograms, id: \.self) { program in
                            programSection(program, days: custom.filter { $0.program == program }.map(RoutineDay.custom), custom: true)
                        }
                    }

                    // Built-in programs
                    ForEach(TrainingContent.programs, id: \.self) { program in
                        programSection(program, days: TrainingContent.templates(in: program).map(RoutineDay.builtin), custom: false)
                    }
                }
                .padding()
            }
            .scrollContentBackground(.hidden)
            .blueprintBackground()
            .navigationTitle("Start a Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNewEditor = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingNewEditor) {
                CustomTemplateEditorView(existing: nil, programSuggestions: ProgramScheduler.allProgramNames(custom: custom))
            }
            .sheet(item: $editorTemplate) { template in
                CustomTemplateEditorView(existing: template, programSuggestions: ProgramScheduler.allProgramNames(custom: custom))
            }
        }
    }

    private var timeFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TimeFilter.allCases) { option in
                    let selected = timeFilter == option
                    Button { timeFilter = option } label: {
                        Text(option.rawValue.uppercased())
                            .font(Theme.mono(10, weight: .semibold)).tracking(0.6)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(selected ? Theme.accent : Color.clear)
                            .overlay(Rectangle().stroke(selected ? Color.clear : Theme.accent.opacity(0.45), lineWidth: 1))
                            .foregroundStyle(selected ? Theme.blueprintDeep : Theme.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func programSection(_ program: String, days allDays: [RoutineDay], custom isCustom: Bool) -> some View {
        let days = allDays.filter { timeFilter.matches($0.estimatedMinutes) }
        if !days.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(program).font(Theme.hand(22, relativeTo: .title3))
                    if isCustom {
                        Image(systemName: "person.crop.circle").font(.caption).foregroundStyle(.secondary)
                    }
                    Rectangle().fill(Color.white.opacity(0.16)).frame(height: 1)
                }
                .padding(.leading, 4)
                ForEach(days) { day in
                    dayCard(day, isCustom: isCustom)
                }
            }
        }
    }

    private var emptyCard: some View {
        Button {
            onEmpty(); dismiss()
        } label: {
            Card {
                HStack {
                    Image(systemName: "square.dashed").foregroundStyle(Theme.accent)
                    Text("Empty session").bold()
                    Spacer()
                    Image(systemName: "plus.circle.fill").foregroundStyle(Theme.accent)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func dayCard(_ day: RoutineDay, isCustom: Bool) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(day.title).font(.headline)
                        Text(day.subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(day.level.uppercased())
                        .font(Theme.mono(9, weight: .semibold)).tracking(0.6)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .overlay(Rectangle().stroke(Theme.hairline, lineWidth: 1))
                        .foregroundStyle(.secondary)
                    if isCustom, case .custom(let template) = day {
                        Menu {
                            Button { editorTemplate = template } label: { Label("Edit", systemImage: "pencil") }
                            Button(role: .destructive) { context.delete(template); try? context.save() } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle").foregroundStyle(.secondary)
                        }
                    }
                }

                HStack(spacing: 10) {
                    ForEach(day.equipment, id: \.self) { eq in
                        eq.image.resizable().scaledToFit().frame(width: 20, height: 20)
                            .foregroundStyle(Theme.accent)
                    }
                    Spacer()
                    Text("\(day.exerciseCount) EX · ≈\(day.estimatedMinutes) MIN")
                        .font(Theme.mono(9)).tracking(0.5).foregroundStyle(.secondary)
                }

                Button {
                    onStart(day); dismiss()
                } label: {
                    Text("START \(day.title.uppercased())").blueprintPrimary()
                }
                .buttonStyle(.plain)
            }
        }
    }
}
