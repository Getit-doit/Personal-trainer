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
            let minor: CGFloat = 26
            let drawLines: (CGFloat, Double, Double) -> Void = { step, opacity, width in
                var path = Path()
                var x: CGFloat = 0
                while x <= size.width { path.move(to: .init(x: x, y: 0)); path.addLine(to: .init(x: x, y: size.height)); x += step }
                var y: CGFloat = 0
                while y <= size.height { path.move(to: .init(x: 0, y: y)); path.addLine(to: .init(x: size.width, y: y)); y += step }
                context.stroke(path, with: .color(.white.opacity(opacity)), lineWidth: width)
            }
            drawLines(minor, 0.06, 0.5)        // minor grid
            drawLines(minor * 5, 0.12, 0.8)    // major grid
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

/// A reusable outlined "drawn" card on the blueprint.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.65), lineWidth: 1.5)
            )
    }
}
