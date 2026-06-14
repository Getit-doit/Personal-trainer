import WidgetKit
import SwiftUI
import ActivityKit

private let accent = Color(red: 0.36, green: 0.74, blue: 0.55)

/// The rest-timer Live Activity: lock-screen banner + Dynamic Island.
struct RestTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestActivityAttributes.self) { context in
            LockScreenRestView(context: context)
                .padding()
                .activityBackgroundTint(Color.black.opacity(0.55))
                .activitySystemActionForegroundColor(accent)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Rest", systemImage: "timer").foregroundStyle(accent)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    countdown(context)
                        .font(.title2).bold().monospacedDigit()
                        .frame(maxWidth: 70)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if !context.state.exerciseName.isEmpty {
                        Text("After \(context.state.exerciseName)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: "timer").foregroundStyle(accent)
            } compactTrailing: {
                countdown(context).monospacedDigit().frame(maxWidth: 44)
            } minimal: {
                Image(systemName: "timer").foregroundStyle(accent)
            }
        }
    }

    /// Auto-counting timer text when running; static "Paused" otherwise.
    @ViewBuilder
    private func countdown(_ context: ActivityViewContext<RestActivityAttributes>) -> some View {
        if context.state.isRunning {
            Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                .multilineTextAlignment(.trailing)
        } else {
            Text("Paused")
        }
    }
}

/// Lock-screen / banner presentation.
struct LockScreenRestView: View {
    let context: ActivityViewContext<RestActivityAttributes>

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Label("Resting", systemImage: "timer")
                    .font(.headline).foregroundStyle(accent)
                if !context.state.exerciseName.isEmpty {
                    Text("After \(context.state.exerciseName)")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if context.state.isRunning {
                Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .frame(maxWidth: 110)
            } else {
                Text("Paused").font(.title2).bold().foregroundStyle(.white)
            }
        }
    }
}
