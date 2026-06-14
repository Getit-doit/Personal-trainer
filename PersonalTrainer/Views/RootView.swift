import SwiftUI

/// Top-level tab navigation.
struct RootView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            WorkoutsView()
                .tabItem { Label("Workouts", systemImage: "dumbbell.fill") }

            PlansView()
                .tabItem { Label("Plans", systemImage: "list.bullet.rectangle.fill") }

            ProgressDashboardView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }

            CoachView()
                .tabItem { Label("Coach", systemImage: "bubble.left.and.text.bubble.right.fill") }
        }
        .tint(Theme.accent)
    }
}

#Preview {
    RootView()
        .modelContainer(for: [WorkoutSession.self, LoggedExercise.self, SetEntry.self, BodyMetric.self], inMemory: true)
}
