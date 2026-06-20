import SwiftUI

/// Cold-start launch screen: the barbell loader over the blueprint paper, with
/// the wordmark above and the tagline below. Held while the app boots / the
/// on-device model warms, then cross-faded into the main tabs.
struct LaunchView: View {
    var body: some View {
        ZStack {
            BlueprintBackdrop().ignoresSafeArea()
            VStack(spacing: 26) {
                Text("Functional Trainer")
                    .font(Theme.hand(34, relativeTo: .largeTitle))
                    .foregroundStyle(.white)
                BarbellLoaderView(scale: 1.3)
                Text("FUNCTIONAL STRENGTH · LONGEVITY")
                    .font(Theme.mono(11)).tracking(2.5)
                    .foregroundStyle(Theme.accent)
            }
        }
    }
}
