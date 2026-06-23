import SwiftUI
import SwiftData

/// App tabs, used to drive programmatic tab switches (e.g. back to Today after
/// finishing a workout).
enum AppTab: Hashable { case today, train, progress, fuel, coach }

/// Shared tab selection so deep views can switch tabs.
@MainActor final class AppRouter: ObservableObject {
    @Published var tab: AppTab = .today
}

/// Top-level tab navigation.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var health = HealthService()
    @StateObject private var router = AppRouter()
    @ObservedObject private var notif = NotificationCoach.shared
    @AppStorage("didOnboard") private var didOnboard = false
    @State private var showOnboarding = false
    @State private var isLaunching = true

    var body: some View {
        TabView(selection: $router.tab) {
            TodayView()
                .tag(AppTab.today)
                .tabItem { Label("Today", systemImage: "sun.max.fill") }

            TrainView()
                .tag(AppTab.train)
                .tabItem { Label("Train", systemImage: "dumbbell.fill") }

            ProgressDashboardView()
                .tag(AppTab.progress)
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }

            FuelView()
                .tag(AppTab.fuel)
                .tabItem { Label("Fuel", systemImage: "fork.knife") }

            CoachView()
                .tag(AppTab.coach)
                .tabItem { Label("Coach", systemImage: "bubble.left.and.text.bubble.right.fill") }
        }
        .tint(Theme.accent)
        .preferredColorScheme(.dark)
        .environmentObject(health)
        .environmentObject(router)
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
