import SwiftUI
import UIKit

/// Blueprint visual language (per the design review): a precise engineering
/// drawing — deep-blue paper + faint grid, crisp 1px hairline cards with corner
/// tick marks, one cyan accent (amber reserved for warnings), and a monospace
/// "measurements" type system. No marker font, no sketch wobble.
enum Theme {
    // Blueprint paper
    static let blueprint = Color(red: 0.078, green: 0.247, blue: 0.490)   // #143f7d
    static let blueprintDeep = Color(red: 0.039, green: 0.137, blue: 0.314) // #0a2350

    // Ink
    static let ink = Color.white
    static let accent = Color(red: 0.682, green: 0.863, blue: 1.0)   // #aedcff chalk cyan
    static let accentDeep = Color(red: 0.039, green: 0.137, blue: 0.314) // navy, for text on cyan
    /// Reserved strictly for warnings (ankle, weak links, low impact).
    static let warning = Color(red: 0.957, green: 0.784, blue: 0.478) // #f4c87a amber

    /// Translucent white fill used for chips/cards on the blueprint.
    static let card = Color.white.opacity(0.06)
    static let background = blueprint

    /// Muscle dots are retired in the blueprint look — one neutral ink.
    static func color(for muscle: String) -> Color { Color.white.opacity(0.5) }

    // MARK: Type system

    /// Display/title face — Plex-Sans-like (system sans, bold). Scales with Dynamic Type.
    static func title(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }

    /// Monospace face for labels, figures, and measurements (Plex-Mono-like).
    static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    /// Back-compat shim: previous code called `Theme.hand(...)` for headings.
    /// Now routes to the crisp title face (marker font retired).
    static func hand(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }

    /// Style the UIKit-backed nav and tab bars to match the blueprint.
    static func applyBlueprintAppearance() {
        let paper = UIColor(red: 0.031, green: 0.102, blue: 0.235, alpha: 1) // #081a3c
        let ink = UIColor.white

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = paper
        nav.shadowColor = .clear
        nav.titleTextAttributes = [.foregroundColor: ink, .font: UIFont.systemFont(ofSize: 17, weight: .bold)]
        nav.largeTitleTextAttributes = [.foregroundColor: ink, .font: UIFont.systemFont(ofSize: 32, weight: .bold)]
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

/// A minor (24pt) / major (120pt) line grid drawn with thin white strokes.
struct BlueprintGrid: View {
    var body: some View {
        Canvas { context, size in
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
            context.stroke(gridPath(step: 24), with: .color(.white.opacity(0.05)), lineWidth: 1)
            context.stroke(gridPath(step: 120), with: .color(.white.opacity(0.11)), lineWidth: 1)
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

/// Short L-shaped tick marks at each corner — the blueprint "drawing" detail.
struct CornerTicks: Shape {
    var length: CGFloat = 11
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let l = length
        // Top-left
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + l)); p.addLine(to: CGPoint(x: rect.minX, y: rect.minY)); p.addLine(to: CGPoint(x: rect.minX + l, y: rect.minY))
        // Top-right
        p.move(to: CGPoint(x: rect.maxX - l, y: rect.minY)); p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY)); p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + l))
        // Bottom-right
        p.move(to: CGPoint(x: rect.maxX, y: rect.maxY - l)); p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY)); p.addLine(to: CGPoint(x: rect.maxX - l, y: rect.maxY))
        // Bottom-left
        p.move(to: CGPoint(x: rect.minX + l, y: rect.maxY)); p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY)); p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - l))
        return p
    }
}

/// A crisp hairline card with corner ticks — the blueprint panel.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.05))
            .overlay(Rectangle().stroke(Color.white.opacity(0.28), lineWidth: 1))
            .overlay(CornerTicks().stroke(Color.white.opacity(0.55), lineWidth: 1))
    }
}
