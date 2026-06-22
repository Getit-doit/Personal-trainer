import SwiftUI
import SwiftData
import UIKit

@main
struct PersonalTrainerApp: App {
    /// Shared SwiftData container for all persisted models.
    let container: ModelContainer

    init() {
        Theme.applyBlueprintAppearance()
        do {
            container = try ModelContainer(
                for: UserProfile.self, Exercise.self, WorkoutSession.self,
                LoggedExercise.self, SetLog.self, CardioEntry.self,
                PersonalBest.self, NutritionLog.self, RecoveryLog.self,
                CustomTemplate.self, CustomTemplateItem.self,
                DietHabit.self, HabitCheckIn.self, Achievement.self
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
