import SwiftUI
import UIKit

/// Blueprint visual language — REVISED.
///
/// The app icon is a precise engineering drawing (monospace lettering,
/// dimension lines, a title block). This theme makes the UI match it:
///   • Type   — MarkerFelt is gone. Clean system sans for copy/headlines,
///              a monospaced face for labels and every figure (reps, weights,
///              1RM) so data reads like a measurement.
///   • Lines  — the wobbly "drawn-twice" card border is gone. Crisp 1px
///              hairlines + corner tick marks, like a dimensioned sheet.
///   • Color  — one ink (white) + one accent (chalk cyan). Amber is reserved
///              for warnings only (the ankle gate, weak links).
enum Theme {
    // Blueprint paper
    static let blueprint = Color(red: 0.08, green: 0.25, blue: 0.49)
    static let blueprintDeep = Color(red: 0.04, green: 0.14, blue: 0.31)

    // Ink + accent
    static let ink = Color.white
    static let accent = Color(red: 0.68, green: 0.86, blue: 1.0)    // chalk cyan
    static let accentDeep = Color.white
    /// The ONLY warm color in the system — warnings only.
    static let amber = Color(red: 0.96, green: 0.78, blue: 0.48)

    /// Hairline fill used for chips/cards on the blueprint.
    static let card = Color.white.opacity(0.05)
    static let hairline = Color.white.opacity(0.28)
    static let background = blueprint

    /// De-rainbowed: muscle dots no longer carry meaning by hue. Everything
    /// reads in ink/accent; cardio borrows the warning amber. Kept as a map so
    /// existing call sites (`Theme.color(for:)`) keep compiling.
    static let muscleColors: [String: Color] = [
        "Chest": accent, "Back": accent, "Legs": accent, "Hinge": accent,
        "Shoulders": accent, "Arms": accent, "Core": accent, "Cardio": amber
    ]

    static func color(for muscle: String) -> Color {
        muscleColors[muscle] ?? accent
    }

    // MARK: Type

    /// Display / headline face. Clean system sans (replaces MarkerFelt).
    /// Signature kept identical to the old `hand(_:relativeTo:)` so every
    /// existing call site swaps over with no edits.
    static func hand(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        Font.system(size: size, weight: .semibold, design: .default)
    }

    /// Monospaced face for figures (weights, reps, RPE, 1RM, totals).
    static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        Font.system(size: size, weight: weight, design: .monospaced)
    }

    /// Small uppercase section label, blueprint title-block style.
    /// Use with `.tracking(1.6)` and `.textCase(.uppercase)` at the call site.
    static func label(_ size: CGFloat = 11) -> Font {
        Font.system(size: size, weight: .semibold, design: .monospaced)
    }

    /// Style the UIKit-backed nav and tab bars to match the blueprint.
    static func applyBlueprintAppearance() {
        let paper = UIColor(red: 0.05, green: 0.16, blue: 0.36, alpha: 1)
        let ink = UIColor.white
        let title = UIFont.systemFont(ofSize: 17, weight: .semibold)
        let large = UIFont.systemFont(ofSize: 32, weight: .bold)

        // Transparent so the blueprint paper + grid runs to the very top.
        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.backgroundColor = .clear
        nav.shadowColor = .clear
        nav.titleTextAttributes = [.foregroundColor: ink, .font: title]
        nav.largeTitleTextAttributes = [.foregroundColor: ink, .font: large]
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
            let minor: CGFloat = 24
            context.stroke(gridPath(step: minor), with: .color(.white.opacity(0.05)), lineWidth: 0.5)
            context.stroke(gridPath(step: minor * 5), with: .color(.white.opacity(0.11)), lineWidth: 0.8)
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

/// A precise outlined panel: 1px hairline border + corner tick marks.
/// Replaces the old hand-drawn `RoughRect` card — same `Card { … }` API.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Rectangle().fill(Theme.card)
            )
            .overlay(
                Rectangle().stroke(Theme.hairline, lineWidth: 1)
            )
            .overlay(CornerTicks().stroke(Theme.accent.opacity(0.9), lineWidth: 1.2))
    }
}

/// Four short L-shaped registration marks at the panel corners — the small
/// touch that makes a plain rectangle read as a drawing sheet.
struct CornerTicks: Shape {
    var len: CGFloat = 9
    var inset: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = rect.insetBy(dx: inset, dy: inset)
        // top-left
        p.move(to: .init(x: r.minX, y: r.minY + len)); p.addLine(to: .init(x: r.minX, y: r.minY)); p.addLine(to: .init(x: r.minX + len, y: r.minY))
        // top-right
        p.move(to: .init(x: r.maxX - len, y: r.minY)); p.addLine(to: .init(x: r.maxX, y: r.minY)); p.addLine(to: .init(x: r.maxX, y: r.minY + len))
        // bottom-right
        p.move(to: .init(x: r.maxX, y: r.maxY - len)); p.addLine(to: .init(x: r.maxX, y: r.maxY)); p.addLine(to: .init(x: r.maxX - len, y: r.maxY))
        // bottom-left
        p.move(to: .init(x: r.minX + len, y: r.maxY)); p.addLine(to: .init(x: r.minX, y: r.maxY)); p.addLine(to: .init(x: r.minX, y: r.maxY - len))
        return p
    }
}
