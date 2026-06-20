import SwiftUI
import SwiftData

/// Workout history + entry point for starting a new session.
/// Uses a ScrollView (not List) so the blueprint paper shows through cleanly.
struct TrainView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @State private var startedSession: WorkoutSession?
    @State private var showTemplatePicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "No Workouts Yet",
                        systemImage: "dumbbell",
                        description: Text("Tap + to start a full-body session.")
                    )
                    .padding(.top, 80)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(sessions) { session in
                            NavigationLink {
                                ActiveSessionView(session: session)
                            } label: {
                                row(for: session)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    context.delete(session); try? context.save()
                                } label: { Label("Delete", systemImage: "trash") }
                            }
                            Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)
                        }
                    }
                    .padding(.horizontal)
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
            .sheet(isPresented: $showTemplatePicker) {
                RoutineLibraryView(
                    onStart: { startedSession = SessionFactory.start($0, context: context) },
                    onEmpty: { startedSession = SessionFactory.blank(context: context) }
                )
            }
        }
    }

    private func row(for session: WorkoutSession) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title(for: session)).font(.headline)
                Text(session.date.formatted(date: .abbreviated, time: .shortened).uppercased())
                    .font(Theme.mono(9)).tracking(0.6).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if !session.isFinished {
                    Text("IN PROGRESS")
                        .font(Theme.mono(8, weight: .semibold)).tracking(0.8)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .overlay(Rectangle().stroke(Theme.accent.opacity(0.6), lineWidth: 1))
                        .foregroundStyle(Theme.accent)
                }
                Text("\(session.exercises.count) LIFTS · \(session.completedSetCount) SETS")
                    .font(Theme.mono(9)).tracking(0.5).foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private func title(for session: WorkoutSession) -> String {
        session.notes.isEmpty ? "Workout" : session.notes
    }
}
