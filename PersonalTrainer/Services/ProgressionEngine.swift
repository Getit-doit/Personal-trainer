import Foundation

/// A recommendation about whether a lift is ready to progress.
struct ProgressionSuggestion {
    let exerciseName: String
    let isPriority: Bool
    let readyToProgress: Bool
    let lastTopWeight: Double
    let suggestedWeight: Double
    let reason: String
}

/// Decides when a lift is ready for more load, using the most recent session.
///
/// Rule: a lift is ready to progress when, in its most recent completed session,
/// every working set met or beat the target reps **and** kept at least ~2 reps
/// in tank (RPE ≤ 8). When ready, we suggest the top-set weight plus the lift's
/// increment.
enum ProgressionEngine {

    static func suggestion(
        for exercise: Exercise,
        sessions: [WorkoutSession]
    ) -> ProgressionSuggestion? {
        // Most recent finished session that actually contains this lift.
        let logged: LoggedExercise? = sessions
            .filter(\.isFinished)
            .sorted { $0.date > $1.date }
            .lazy
            .compactMap { session in
                session.exercises.first { $0.name == exercise.name }
            }
            .first

        guard let logged else { return nil }

        let workingSets = logged.sortedSets.filter(\.isCompleted)
        guard !workingSets.isEmpty else { return nil }

        let topWeight = workingSets.map(\.weight).max() ?? 0
        let hitAllReps = workingSets.allSatisfy { $0.reps >= exercise.targetReps }
        let leftRepsInTank = workingSets.allSatisfy { $0.repsInTank >= 1 && $0.rpe <= 8 }
        let ready = hitAllReps && leftRepsInTank

        let reason: String
        if ready {
            reason = "Hit \(exercise.targetReps)+ reps on every set with reps to spare."
        } else if !hitAllReps {
            reason = "Hold weight — didn't clear \(exercise.targetReps) reps on all sets yet."
        } else {
            reason = "Hold weight — last sets were near failure (RPE high)."
        }

        return ProgressionSuggestion(
            exerciseName: exercise.name,
            isPriority: exercise.isPriorityProgression,
            readyToProgress: ready,
            lastTopWeight: topWeight,
            suggestedWeight: ready ? topWeight + exercise.increment : topWeight,
            reason: reason
        )
    }

    /// Suggestions for all priority lifts that have history, priority first.
    static func prioritySuggestions(
        exercises: [Exercise],
        sessions: [WorkoutSession]
    ) -> [ProgressionSuggestion] {
        exercises
            .filter(\.isPriorityProgression)
            .compactMap { suggestion(for: $0, sessions: sessions) }
            .sorted { $0.readyToProgress && !$1.readyToProgress }
    }
}

/// Detects and stores personal bests when a session is finished.
enum PRService {
    /// Scans a finished session and upserts a PR for any lift that beat its
    /// previous best estimated 1RM. Returns the names of new PRs.
    @discardableResult
    static func detectPRs(
        in session: WorkoutSession,
        existing: [PersonalBest],
        insert: (PersonalBest) -> Void
    ) -> [String] {
        var newPRs: [String] = []

        for logged in session.exercises {
            let bestSet = logged.sets
                .filter(\.isCompleted)
                .max { $0.estimatedOneRepMax < $1.estimatedOneRepMax }
            guard let bestSet, bestSet.estimatedOneRepMax > 0 else { continue }

            let priorBest = existing
                .filter { $0.exerciseName == logged.name }
                .map(\.value)
                .max() ?? 0

            if bestSet.estimatedOneRepMax > priorBest + 0.01 {
                let pr = PersonalBest(
                    exerciseName: logged.name,
                    value: (bestSet.estimatedOneRepMax * 10).rounded() / 10,
                    weight: bestSet.weight,
                    reps: bestSet.reps,
                    date: session.date,
                    source: .logged,
                    exercise: logged.exercise
                )
                insert(pr)
                newPRs.append(logged.name)
            }
        }
        return newPRs
    }
}
