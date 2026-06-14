import SwiftUI
import SwiftData

/// Lists all workout sessions and lets the user create/open one.
struct WorkoutsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @State private var newSession: WorkoutSession?

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "No Workouts",
                        systemImage: "dumbbell",
                        description: Text("Tap + to start logging your first workout.")
                    )
                } else {
                    List {
                        ForEach(sessions) { session in
                            NavigationLink {
                                ActiveWorkoutView(session: session)
                            } label: {
                                row(for: session)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { startBlankWorkout() } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(item: $newSession) { session in
                ActiveWorkoutView(session: session)
            }
        }
    }

    private func row(for session: WorkoutSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(session.name).font(.headline)
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
                Text("\(session.exercises.count) exercises")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func startBlankWorkout() {
        let session = WorkoutSession(name: "Workout \(sessions.count + 1)")
        context.insert(session)
        try? context.save()
        newSession = session
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(sessions[index])
        }
        try? context.save()
    }
}
