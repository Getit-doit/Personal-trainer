import SwiftUI
import SwiftData

/// Workout history + entry point for starting a new session.
struct TrainView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @State private var startedSession: WorkoutSession?
    @State private var showTemplatePicker = false

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "No Workouts Yet",
                        systemImage: "dumbbell",
                        description: Text("Tap + to start a full-body session.")
                    )
                } else {
                    List {
                        ForEach(sessions) { session in
                            NavigationLink {
                                ActiveSessionView(session: session)
                            } label: {
                                row(for: session)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .blueprintBackground()
            .navigationTitle("Train")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showTemplatePicker = true } label: { Image(systemName: "plus") }
                }
            }
            .navigationDestination(item: $startedSession) { session in
                ActiveSessionView(session: session)
            }
            .confirmationDialog("Start a workout", isPresented: $showTemplatePicker, titleVisibility: .visible) {
                ForEach(TrainingContent.templates) { template in
                    Button("\(template.title) · \(template.subtitle)") {
                        startedSession = SessionFactory.fromTemplate(template, context: context)
                    }
                }
                Button("Empty session") {
                    startedSession = SessionFactory.blank(context: context)
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func row(for session: WorkoutSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title(for: session)).font(.headline)
                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                if !session.isFinished {
                    Text("In progress")
                        .font(.caption2).bold()
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Theme.accent.opacity(0.2), in: Capsule())
                        .foregroundStyle(Theme.accentDeep)
                }
                Text("\(session.exercises.count) lifts · \(session.completedSetCount) sets")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func title(for session: WorkoutSession) -> String {
        session.notes.isEmpty ? "Workout" : session.notes
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { context.delete(sessions[index]) }
        try? context.save()
    }
}
