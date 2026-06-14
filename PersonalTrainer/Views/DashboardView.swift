import SwiftUI
import SwiftData

/// The home screen: a greeting, weekly stats, and recent activity.
struct DashboardView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \BodyMetric.date, order: .reverse) private var metrics: [BodyMetric]

    private var thisWeekSessions: [WorkoutSession] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return sessions.filter { $0.date >= weekAgo && $0.isFinished }
    }

    private var weeklyVolume: Double {
        thisWeekSessions.reduce(0) { $0 + $1.totalVolume }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    HStack(spacing: 12) {
                        StatTile(title: "Workouts",
                                 value: "\(thisWeekSessions.count)",
                                 caption: "this week",
                                 systemImage: "flame.fill",
                                 color: .orange)
                        StatTile(title: "Volume",
                                 value: weeklyVolume.compactKg,
                                 caption: "lifted",
                                 systemImage: "scalemass.fill",
                                 color: Theme.accent)
                    }

                    if let latest = metrics.first {
                        StatTile(title: "Body Weight",
                                 value: "\(latest.weight.clean) lb",
                                 caption: "latest",
                                 systemImage: "figure.stand",
                                 color: .blue)
                            .frame(maxWidth: .infinity)
                    }

                    recentSection
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Today")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(.title2).bold()
            Text("Let's get a session in.")
                .foregroundStyle(.secondary)
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning 👋"
        case 12..<17: return "Good afternoon 👋"
        default: return "Good evening 👋"
        }
    }

    @ViewBuilder
    private var recentSection: some View {
        HStack {
            Text("Recent Workouts").font(.headline)
            Spacer()
        }
        if sessions.filter(\.isFinished).isEmpty {
            Card {
                VStack(alignment: .leading, spacing: 6) {
                    Text("No workouts yet").font(.subheadline).bold()
                    Text("Start one from the Workouts or Plans tab.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        } else {
            ForEach(sessions.filter(\.isFinished).prefix(5)) { session in
                Card {
                    HStack {
                        Circle()
                            .fill(Theme.color(for: session.exercises.first?.muscleGroup ?? "Full Body"))
                            .frame(width: 10, height: 10)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.name).font(.subheadline).bold()
                            Text(session.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(session.completedSetCount) sets")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

/// A small stat card used on the dashboard.
struct StatTile: View {
    let title: String
    let value: String
    let caption: String
    let systemImage: String
    let color: Color

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: systemImage)
                    .foregroundStyle(color)
                Text(value).font(.title2).bold()
                Text(title).font(.caption).bold()
                Text(caption).font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}

extension Double {
    /// Trims trailing ".0" for clean display.
    var clean: String {
        self == rounded() ? String(format: "%.0f", self) : String(format: "%.1f", self)
    }

    /// Compact volume display, e.g. "12.4k" lb.
    var compactKg: String {
        if self >= 1000 {
            return String(format: "%.1fk", self / 1000)
        }
        return "\(clean)"
    }
}
