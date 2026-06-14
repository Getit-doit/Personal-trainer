import SwiftUI

/// Branded loading animation: plates load onto a barbell in a loop, matching the
/// app logo. Use anywhere the app is working (AI thinking, fetching, etc.).
struct BarLoadingView: View {
    var label: String? = nil
    /// Plates per side at full load.
    private let maxPerSide = 3

    var body: some View {
        VStack(spacing: 14) {
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    var ctx = context
                    draw(in: &ctx, size: size, time: timeline.date.timeIntervalSinceReferenceDate)
                }
                .frame(width: 150, height: 84)
            }
            if let label {
                Text(label)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func draw(in context: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        let w = size.width, h = size.height
        let cy = h / 2, cx = w / 2
        let ink = Color.white

        // Loop phase 0 … (maxPerSide+1); integer part = plates fully loaded.
        let rate = 1.6
        let cycle = Double(maxPerSide + 1)
        let phase = (time * rate).truncatingRemainder(dividingBy: cycle)
        let step = Int(phase)
        let frac = phase - Double(step)

        // Bar (always present)
        context.fill(
            Path(roundedRect: CGRect(x: w * 0.18, y: cy - h * 0.06, width: w * 0.64, height: h * 0.12), cornerRadius: h * 0.06),
            with: .color(ink)
        )
        // End caps
        for ex in [w * 0.12, w * 0.84] {
            context.fill(
                Path(roundedRect: CGRect(x: ex, y: cy - h * 0.20, width: w * 0.04, height: h * 0.40), cornerRadius: 3),
                with: .color(ink)
            )
        }

        // Plates load inner → outer on both sides.
        let plateWidth = w * 0.055
        let spacing = w * 0.075
        let innerGap = w * 0.13
        for side in [-1.0, 1.0] {
            for i in 0..<maxPerSide {
                let opacity: Double = i < step ? 1.0 : (i == step ? frac : 0.0)
                guard opacity > 0.01 else { continue }
                let center = cx + side * (innerGap + Double(i) * spacing)
                let plateHeight = h * (0.62 - Double(i) * 0.07)
                var layer = context
                layer.opacity = opacity
                layer.fill(
                    Path(roundedRect: CGRect(
                        x: center - plateWidth / 2, y: cy - plateHeight / 2,
                        width: plateWidth, height: plateHeight
                    ), cornerRadius: plateWidth * 0.35),
                    with: .color(ink)
                )
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
