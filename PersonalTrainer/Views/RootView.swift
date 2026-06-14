import SwiftUI

/// Top-level tab navigation.
struct RootView: View {
    @StateObject private var health = HealthService()
    @AppStorage("didOnboard") private var didOnboard = false
    @State private var showOnboarding = false

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }

            TrainView()
                .tabItem { Label("Train", systemImage: "dumbbell.fill") }

            ProgressDashboardView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }

            FuelView()
                .tabItem { Label("Fuel", systemImage: "fork.knife") }

            CoachView()
                .tabItem { Label("Coach", systemImage: "bubble.left.and.text.bubble.right.fill") }
        }
        .tint(Theme.accent)
        .preferredColorScheme(.dark)
        .environmentObject(health)
        .onAppear { showOnboarding = !didOnboard }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                didOnboard = true
                showOnboarding = false
            }
        }
    }
}
