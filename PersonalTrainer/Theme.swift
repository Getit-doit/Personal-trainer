import SwiftUI

/// Centralized colors and small style helpers so the app has a consistent look.
enum Theme {
    static let accent = Color(red: 0.36, green: 0.74, blue: 0.55)   // energetic green
    static let accentDeep = Color(red: 0.20, green: 0.55, blue: 0.42)
    static let card = Color(.secondarySystemBackground)
    static let background = Color(.systemBackground)

    static let muscleColors: [String: Color] = [
        "Chest": .pink,
        "Back": .blue,
        "Legs": .orange,
        "Hinge": .indigo,
        "Shoulders": .purple,
        "Arms": .teal,
        "Core": .yellow,
        "Cardio": .red
    ]

    static func color(for muscle: String) -> Color {
        muscleColors[muscle] ?? accent
    }
}

/// A reusable rounded card container.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
