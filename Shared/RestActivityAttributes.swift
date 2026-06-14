import Foundation
import ActivityKit

/// Shared between the app and the widget extension so the rest-timer Live
/// Activity (lock screen + Dynamic Island) renders the same data the app drives.
struct RestActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// When the current rest period will hit zero (drives the auto countdown).
        var endDate: Date
        var isRunning: Bool
        var exerciseName: String
    }

    /// Static label shown on the activity.
    var title: String
}
