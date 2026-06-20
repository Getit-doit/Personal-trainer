import SwiftUI

/// A horizontal barbell that loads plates onto both sleeves in sequence
/// (45 → 25 → 10 → 5), holds fully loaded, then clears all at once and loops.
/// Driven by a single animation clock so staggered entries and the synchronized
/// exit stay in lockstep. `scale` renders it large on launch, small inline.
struct BarbellLoaderView: View {
    var scale: CGFloat = 1.0

    // Loop timing (seconds)
    private let cycle: Double = 3.7
    private let stagger: Double = 0.42
    private let entryDuration: Double = 0.5
    private let exitStart: Double = 3.0
    private let exitDuration: Double = 0.4

    // Plate specs, inner → outer: (denomination, width, height, center offset)
    private let plates: [(w: CGFloat, h: CGFloat, x: CGFloat)] = [
        (16, 84, 43),   // 45
        (14, 62, 62),   // 25
        (11, 46, 78.5), // 10
        (9, 34, 92.5)   // 5
    ]

    private let baseWidth: CGFloat = 264
    private let baseHeight: CGFloat = 104

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: cycle)
            ZStack {
                bar
                ForEach(plates.indices, id: \.self) { i in
                    let s = state(for: i, at: t)
                    plate(plates[i], state: s, side: 1)
                    plate(plates[i], state: s, side: -1)
                }
            }
            .frame(width: baseWidth, height: baseHeight)
            .scaleEffect(scale)
            .frame(width: baseWidth * scale, height: baseHeight * scale)
        }
    }

    private var bar: some View {
        ZStack {
            Capsule().fill(Theme.hairline)
                .frame(width: 208, height: 7)
            Capsule().fill(Color.white.opacity(0.4))
                .frame(width: 70, height: 12)
        }
    }

    private func plate(_ p: (w: CGFloat, h: CGFloat, x: CGFloat), state s: PlateState, side: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: p.w / 2, style: .continuous)
            .fill(Theme.accent.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: p.w / 2, style: .continuous)
                    .stroke(Theme.accent, lineWidth: 2)
            )
            .frame(width: p.w, height: p.h)
            .shadow(color: Theme.accent.opacity(0.5), radius: 5)
            .scaleEffect(s.scale)
            .opacity(s.opacity)
            .offset(x: side * (p.x + s.slide))
    }

    private struct PlateState { var opacity: Double; var scale: CGFloat; var slide: CGFloat }

    private func state(for index: Int, at t: Double) -> PlateState {
        let slideDist: CGFloat = 26
        let start = Double(index) * stagger

        if t < start {                          // not entered yet
            return PlateState(opacity: 0, scale: 0.85, slide: slideDist)
        }
        if t < start + entryDuration {          // sliding in with overshoot
            let p = (t - start) / entryDuration
            let e = 1 - (1 - p) * (1 - p)        // ease-out
            let bump = 0.12 * sin(Double.pi * p) // mid-entry scale overshoot
            return PlateState(
                opacity: min(1, e * 1.4),
                scale: 0.85 + 0.15 * CGFloat(e) + CGFloat(bump),
                slide: slideDist * (1 - CGFloat(e))
            )
        }
        if t < exitStart {                      // fully loaded, holding
            return PlateState(opacity: 1, scale: 1, slide: 0)
        }
        if t < exitStart + exitDuration {       // all fade out together
            let p = (t - exitStart) / exitDuration
            return PlateState(opacity: 1 - p, scale: 1, slide: 0)
        }
        return PlateState(opacity: 0, scale: 0.85, slide: slideDist) // gap before reset
    }
}
