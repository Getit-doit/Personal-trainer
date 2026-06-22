import SwiftUI
import SwiftData

/// Top-level tab navigation.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var health = HealthService()
    @ObservedObject private var notif = NotificationCoach.shared
    @AppStorage("didOnboard") private var didOnboard = false
    @State private var showOnboarding = false
    @State private var isLaunching = true

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
        .overlay {
            if isLaunching {
                LaunchView().transition(.opacity)
            }
        }
        .task {
            // Warm the model / refresh health while we hold the launch screen,
            // then let the loader finish a full loop so it never cuts mid-sequence.
            CoachService.prewarm()
            notif.configure(container: context.container)
            notif.evaluateRewards()
            if health.authorized { await health.refresh() }
            try? await Task.sleep(for: .seconds(3.7))   // one barbell-loader loop
            withAnimation(.easeOut(duration: 0.5)) { isLaunching = false }
        }
        .onChange(of: scenePhase) { _, phase in
            // Re-check streaks, reschedule check-ins, and grant any new awards.
            if phase == .active {
                notif.rescheduleAll()
                notif.evaluateRewards()
            }
        }
    }
}
