import SwiftUI

/// Blueprint visual language: deep blue "paper", white ink lines, a faint grid,
/// outlined cards, and a marker-style display font.
enum Theme {
    // Blueprint paper
    static let blueprint = Color(red: 0.07, green: 0.24, blue: 0.49)
    static let blueprintDeep = Color(red: 0.03, green: 0.13, blue: 0.30)

    // Ink
    static let ink = Color.white
    static let accent = Color(red: 0.78, green: 0.91, blue: 1.0)   // chalk cyan
    static let accentDeep = Color.white

    /// Translucent white fill used for chips/cards on the blueprint.
    static let card = Color.white.opacity(0.08)
    static let background = blueprint

    /// Muscle-group accent dots, kept light so they read on blue.
    static let muscleColors: [String: Color] = [
        "Chest": Color(red: 1.0, green: 0.72, blue: 0.78),
        "Back": Color(red: 0.62, green: 0.82, blue: 1.0),
        "Legs": Color(red: 1.0, green: 0.84, blue: 0.62),
        "Hinge": Color(red: 0.80, green: 0.78, blue: 1.0),
        "Shoulders": Color(red: 0.86, green: 0.74, blue: 1.0),
        "Arms": Color(red: 0.70, green: 0.95, blue: 0.92),
        "Core": Color(red: 0.98, green: 0.95, blue: 0.70),
        "Cardio": Color(red: 1.0, green: 0.70, blue: 0.70)
    ]

    static func color(for muscle: String) -> Color {
        muscleColors[muscle] ?? accent
    }

    /// Hand-drawn / marker display font with Dynamic Type support.
    static func hand(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        Font.custom("MarkerFelt-Wide", size: size, relativeTo: style)
    }

    /// Style the UIKit-backed nav and tab bars to match the blueprint.
    static func applyBlueprintAppearance() {
        let paper = UIColor(red: 0.05, green: 0.16, blue: 0.36, alpha: 1)
        let ink = UIColor.white
        let marker = UIFont(name: "MarkerFelt-Wide", size: 20)
        let markerLarge = UIFont(name: "MarkerFelt-Wide", size: 32)

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = paper
        nav.shadowColor = .clear
        nav.titleTextAttributes = [.foregroundColor: ink, .font: marker as Any].compactMapValues { $0 }
        nav.largeTitleTextAttributes = [.foregroundColor: ink, .font: markerLarge as Any].compactMapValues { $0 }
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = ink

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = paper
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }
}

/// The blueprint paper: blue gradient + faint engineering grid.
struct BlueprintBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.blueprint, Theme.blueprintDeep],
                startPoint: .top, endPoint: .bottom
            )
            BlueprintGrid()
        }
    }
}

/// A minor/major line grid drawn with thin white strokes.
struct BlueprintGrid: View {
    var body: some View {
        Canvas { context, size in
            // Build paths first (no capture of the inout context), then stroke.
            func gridPath(step: CGFloat) -> Path {
                var path = Path()
                var x: CGFloat = 0
                while x <= size.width {
                    path.move(to: .init(x: x, y: 0)); path.addLine(to: .init(x: x, y: size.height)); x += step
                }
                var y: CGFloat = 0
                while y <= size.height {
                    path.move(to: .init(x: 0, y: y)); path.addLine(to: .init(x: size.width, y: y)); y += step
                }
                return path
            }
            let minor: CGFloat = 26
            context.stroke(gridPath(step: minor), with: .color(.white.opacity(0.06)), lineWidth: 0.5)
            context.stroke(gridPath(step: minor * 5), with: .color(.white.opacity(0.12)), lineWidth: 0.8)
        }
        .allowsHitTesting(false)
    }
}

extension View {
    /// Fills the area behind the content with the blueprint paper.
    func blueprintBackground() -> some View {
        background(BlueprintBackdrop().ignoresSafeArea())
    }
}

/// A reusable outlined "drawn" card on the blueprint, with a hand-sketched border.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoughRect(seed: 11)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                ZStack {
                    // Two slightly different strokes → felt-tip "drawn twice" look.
                    RoughRect(seed: 7).stroke(Color.white.opacity(0.75), lineWidth: 1.6)
                    RoughRect(seed: 29).stroke(Color.white.opacity(0.35), lineWidth: 1.0)
                }
            )
    }
}

/// Tiny deterministic RNG so the sketch lines are stable across redraws
/// (no shimmering) while still looking irregular.
private struct SeededRNG {
    var state: UInt64
    init(_ seed: UInt64) { state = seed &* 2862933555777941757 &+ 3037000493 }
    mutating func next() -> CGFloat {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat(Double(state >> 11) / Double(1 << 53))
    }
    mutating func jitter(_ amp: CGFloat) -> CGFloat { (next() * 2 - 1) * amp }
}

/// A rounded-ish rectangle whose edges wobble slightly, like a marker outline.
struct RoughRect: Shape {
    var seed: UInt64 = 1
    var amplitude: CGFloat = 1.6

    func path(in rect: CGRect) -> Path {
        var rng = SeededRNG(seed)
        let r = rect.insetBy(dx: 3, dy: 3)
        // Corners nudged a hair off-true.
        let tl = CGPoint(x: r.minX + rng.jitter(2), y: r.minY + rng.jitter(2))
        let tr = CGPoint(x: r.maxX + rng.jitter(2), y: r.minY + rng.jitter(2))
        let br = CGPoint(x: r.maxX + rng.jitter(2), y: r.maxY + rng.jitter(2))
        let bl = CGPoint(x: r.minX + rng.jitter(2), y: r.maxY + rng.jitter(2))

        var path = Path()
        addRoughLine(&path, from: tl, to: tr, rng: &rng)
        addRoughLine(&path, from: tr, to: br, rng: &rng)
        addRoughLine(&path, from: br, to: bl, rng: &rng)
        addRoughLine(&path, from: bl, to: tl, rng: &rng)
        path.closeSubpath()
        return path
    }

    private func addRoughLine(_ path: inout Path, from a: CGPoint, to b: CGPoint, rng: inout SeededRNG) {
        let segments = 6
        let len = max(hypot(b.x - a.x, b.y - a.y), 0.001)
        let nx = -(b.y - a.y) / len   // perpendicular unit vector
        let ny = (b.x - a.x) / len
        if path.isEmpty { path.move(to: a) } else { path.addLine(to: a) }
        for i in 1...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let wobble = i == segments ? 0 : rng.jitter(amplitude)
            let x = a.x + (b.x - a.x) * t + nx * wobble
            let y = a.y + (b.y - a.y) * t + ny * wobble
            path.addLine(to: CGPoint(x: x, y: y))
        }
    }
}
