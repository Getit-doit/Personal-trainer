import SwiftUI

/// Inline "working…" indicator — the same branded barbell loader used at launch
/// and in the coach, with an optional caption. One animation, used everywhere.
struct BarLoadingView: View {
    var label: String? = nil

    var body: some View {
        VStack(spacing: 14) {
            BarbellLoaderView(scale: 0.6)
            if let label {
                Text(label)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

extension View {
    /// Dims the content and overlays the bar-loading animation when `active`.
    func barLoadingOverlay(_ active: Bool, label: String? = nil) -> some View {
        overlay {
            if active {
                ZStack {
                    Color.black.opacity(0.35).ignoresSafeArea()
                    BarLoadingView(label: label)
                        .padding(24)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                }
            }
        }
    }
}
