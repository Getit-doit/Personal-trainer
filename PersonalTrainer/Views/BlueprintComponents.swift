import SwiftUI

/// Blueprint "section rule": a small uppercase monospace label followed by a
/// hairline that runs to the edge — the title-block divider from the design comp.
/// Optional trailing text (e.g. a count or unit) sits at the right.
struct SectionRule: View {
    let title: String
    var trailing: String? = nil
    var tint: Color = Theme.accent

    var body: some View {
        HStack(spacing: 8) {
            Text(title.uppercased())
                .font(Theme.label(10))
                .tracking(1.6)
                .foregroundStyle(tint)
            Rectangle().fill(Color.white.opacity(0.16)).frame(height: 1)
            if let trailing {
                Text(trailing)
                    .font(Theme.mono(9))
                    .tracking(0.6)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// A blueprint title block: small mono eyebrow, big sans title, optional right
/// caption, and a bottom hairline — used at the top of each screen.
struct TitleBlock: View {
    let eyebrow: String
    let title: String
    var caption: String? = nil

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(eyebrow.uppercased())
                        .font(Theme.label(10)).tracking(2.2)
                        .foregroundStyle(Theme.accent)
                    Text(title)
                        .font(Theme.hand(32, relativeTo: .largeTitle))
                }
                Spacer()
                if let caption {
                    Text(caption.uppercased())
                        .font(Theme.mono(9)).tracking(1)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                }
            }
            Rectangle().fill(Color.white.opacity(0.3)).frame(height: 1)
        }
    }
}

extension View {
    /// Square, monospace, navy-on-cyan primary action — the blueprint CTA.
    func blueprintPrimary() -> some View {
        self
            .font(Theme.mono(14, weight: .semibold))
            .tracking(1.2)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Theme.accent)
            .foregroundStyle(Theme.blueprintDeep)
    }

    /// Square, monospace, outlined secondary action.
    func blueprintSecondary() -> some View {
        self
            .font(Theme.mono(13, weight: .semibold))
            .tracking(1.0)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Theme.accent.opacity(0.12))
            .overlay(Rectangle().stroke(Theme.accent.opacity(0.55), lineWidth: 1))
            .foregroundStyle(Theme.accent)
    }

    /// Blueprint text-field chrome: translucent fill + hairline border (replaces
    /// the solid-black system `.roundedBorder` style on the dark paper).
    func blueprintField() -> some View {
        self
            .padding(11)
            .background(Theme.card)
            .overlay(Rectangle().stroke(Theme.hairline, lineWidth: 1))
            .tint(Theme.accent)
    }
}
