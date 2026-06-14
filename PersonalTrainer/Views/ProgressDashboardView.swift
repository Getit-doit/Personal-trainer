import SwiftUI
import SwiftData
import Charts

/// Charts for body weight over time and weekly training volume.
struct ProgressDashboardView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \BodyMetric.date) private var metrics: [BodyMetric]
    @Query(sort: \WorkoutSession.date) private var sessions: [WorkoutSession]
    @State private var showingAddWeight = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    bodyWeightCard
                    volumeCard
                    muscleSplitCard
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Progress")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAddWeight = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddWeight) {
                LogWeightSheet()
            }
        }
    }

    private var bodyWeightCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Label("Body Weight", systemImage: "figure.stand")
                    .font(.headline)
                if metrics.isEmpty {
                    Text("No data yet — tap + to log your weight.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Chart(metrics) { metric in
                        LineMark(
                            x: .value("Date", metric.date),
                            y: .value("Weight", metric.weight)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Theme.accent)

                        AreaMark(
                            x: .value("Date", metric.date),
                            y: .value("Weight", metric.weight)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.accent.opacity(0.3), .clear],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                    }
                    .chartYScale(domain: .automatic(includesZero: false))
                    .frame(height: 200)
                }
            }
        }
    }

    private var volumeCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Label("Weekly Volume", systemImage: "scalemass.fill")
                    .font(.headline)
                let data = weeklyVolume
                if data.isEmpty {
                    Text("Finish a workout to see your training volume.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Chart(data, id: \.weekStart) { item in
                        BarMark(
                            x: .value("Week", item.weekStart, unit: .weekOfYear),
                            y: .value("Volume", item.volume)
                        )
                        .foregroundStyle(Theme.accentDeep)
                        .cornerRadius(4)
                    }
                    .frame(height: 180)
                }
            }
        }
    }

    private var muscleSplitCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Label("Sets by Muscle Group", systemImage: "chart.pie.fill")
                    .font(.headline)
                let split = muscleSplit
                if split.isEmpty {
                    Text("Log some sets to see your training balance.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(split, id: \.muscle) { item in
                        HStack {
                            Circle()
                                .fill(Theme.color(for: item.muscle))
                                .frame(width: 8, height: 8)
                            Text(item.muscle).font(.subheadline)
                            Spacer()
                            Text("\(item.count) sets")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Derived data

    private var weeklyVolume: [(weekStart: Date, volume: Double)] {
        let finished = sessions.filter(\.isFinished)
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: finished) { session -> Date in
            calendar.dateInterval(of: .weekOfYear, for: session.date)?.start ?? session.date
        }
        return grouped.map { (week, items) in
            (week, items.reduce(0) { $0 + $1.totalVolume })
        }
        .sorted { $0.0 < $1.0 }
    }

    private var muscleSplit: [(muscle: String, count: Int)] {
        let exercises = sessions.filter(\.isFinished).flatMap(\.exercises)
        let grouped = Dictionary(grouping: exercises, by: \.muscleGroup)
        return grouped.map { (muscle, items) in
            (muscle, items.reduce(0) { $0 + $1.sets.filter(\.isCompleted).count })
        }
        .filter { $0.1 > 0 }
        .sorted { $0.1 > $1.1 }
    }
}

/// Sheet for logging a new body-weight entry.
struct LogWeightSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var weight = 180.0
    @State private var date = Date.now

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                HStack {
                    Text("Weight")
                    Spacer()
                    TextField("Weight", value: $weight, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("lb").foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        context.insert(BodyMetric(date: date, weight: weight))
                        try? context.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
