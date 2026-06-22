import SwiftUI
import SwiftData

/// The recognition / reward wall: level + points, the achievements you've earned
/// (with the AI's personalized note), and the ones still locked.
struct AchievementsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Achievement.dateEarned, order: .reverse) private var earned: [Achievement]

    private var totalPoints: Int { earned.reduce(0) { $0 + $1.points } }
    private var earnedIDs: Set<String> { Set(earned.map(\.defID)) }
    private var locked: [RewardEngine.Def] {
        RewardEngine.catalog.filter { !earnedIDs.contains($0.id) }
    }

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                TitleBlock(eyebrow: "Recognition", title: "Rewards",
                           caption: "\(earned.count) of \(RewardEngine.catalog.count)")
                levelCard

                if !earned.isEmpty {
                    SectionRule(title: "Earned", trailing: "\(earned.count)")
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(earned) { a in
                            badge(icon: a.icon, title: a.title, tier: a.tier,
                                  subtitle: a.recognition.isEmpty ? a.detail : a.recognition,
                                  locked: false, points: a.points)
                        }
                    }
                }

                if !locked.isEmpty {
                    SectionRule(title: "Locked", trailing: "\(locked.count)")
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(locked) { def in
                            badge(icon: def.icon, title: def.title, tier: def.tier.rawValue,
                                  subtitle: def.detail, locked: true, points: def.points)
                        }
                    }
                }
            }
            .padding()
        }
        .blueprintBackground()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { NotificationCoach.shared.evaluateRewards() }
    }

    private var levelCard: some View {
        let level = RewardEngine.level(forPoints: totalPoints)
        let progress = RewardEngine.progressInLevel(totalPoints)
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("LEVEL").font(Theme.mono(9)).tracking(2).foregroundStyle(.secondary)
                        Text("\(level)").font(Theme.mono(40, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(totalPoints)").font(Theme.mono(22, weight: .semibold))
                        Text("POINTS").font(Theme.mono(8)).tracking(1.5).foregroundStyle(.secondary)
                    }
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Theme.card)
                        Rectangle().fill(Theme.accent).frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 8)
                .overlay(Rectangle().stroke(Theme.hairline, lineWidth: 1))
                Text("\(RewardEngine.pointsIntoLevel(totalPoints)) / 100 to level \(level + 1)")
                    .font(Theme.mono(9)).tracking(0.5).foregroundStyle(.secondary)
            }
        }
    }

    private func badge(icon: String, title: String, tier: String, subtitle: String,
                       locked: Bool, points: Int) -> some View {
        let tint = tierColor(tier)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: locked ? "lock.fill" : icon)
                    .font(.title2)
                    .foregroundStyle(locked ? Color.secondary : tint)
                Spacer()
                Text("+\(points)").font(Theme.mono(9)).tracking(0.5)
                    .foregroundStyle(locked ? .secondary : tint)
            }
            Text(title).font(Theme.hand(15)).foregroundStyle(locked ? .secondary : .primary)
            Text(subtitle).font(.caption2).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Text(tier.uppercased()).font(Theme.mono(8)).tracking(1.5)
                .foregroundStyle(locked ? .secondary : tint)
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .padding(12)
        .background(Rectangle().fill(Theme.card))
        .overlay(Rectangle().stroke(locked ? Theme.hairline : tint.opacity(0.7), lineWidth: 1))
        .opacity(locked ? 0.7 : 1)
    }

    private func tierColor(_ tier: String) -> Color {
        switch RewardEngine.tierColorName(tier) {
        case .gold: return Theme.amber
        case .silver: return Theme.accent
        case .bronze: return Theme.accent.opacity(0.75)
        }
    }
}
