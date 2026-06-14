import SwiftUI
import SwiftData

@main
struct PersonalTrainerApp: App {
    /// Shared SwiftData container for all persisted models.
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: WorkoutSession.self, LoggedExercise.self, SetEntry.self, BodyMetric.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        // Seed the body-weight history on first launch so charts aren't empty.
        SeedData.seedIfNeeded(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
