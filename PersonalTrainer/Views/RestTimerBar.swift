import SwiftUI

/// Floating control bar for the active rest timer, pinned to the bottom of the
/// session screen while resting.
struct RestTimerBar: View {
    @ObservedObject var rest: RestTimer

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().stroke(Theme.accent.opacity(0.2), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: rest.progress)
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.25), value: rest.progress)
                Text(rest.label)
                    .font(.caption).bold().monospacedDigit()
            }
            .frame(width: 46, height: 46)

            Button { rest.addTime(-15) } label: { pill("-15") }
            Button { rest.togglePause() } label: {
                Image(systemName: rest.isRunning ? "pause.fill" : "play.fill")
                    .frame(width: 36, height: 32)
                    .background(Theme.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
            }
            Button { rest.addTime(15) } label: { pill("+15") }

            Spacer()

            Button { rest.stop() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .tint(Theme.accentDeep)
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(Divider(), alignment: .top)
    }

    private func pill(_ text: String) -> some View {
        Text(text)
            .font(.caption).bold()
            .frame(width: 40, height: 32)
            .background(Theme.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(Theme.accentDeep)
    }
}
