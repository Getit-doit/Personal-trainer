import Foundation
import SwiftData

/// Seeds first-launch sample data so the app doesn't open empty.
enum SeedData {
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<BodyMetric>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        // Eight weeks of gently trending body-weight history.
        let calendar = Calendar.current
        let weights: [Double] = [185, 184.2, 184.5, 183.6, 182.9, 182.4, 181.8, 181.0]
        for (weeksAgo, weight) in weights.enumerated().reversed() {
            if let date = calendar.date(byAdding: .day, value: -weeksAgo * 7, to: .now) {
                context.insert(BodyMetric(date: date, weight: weight))
            }
        }
        try? context.save()
    }
}
