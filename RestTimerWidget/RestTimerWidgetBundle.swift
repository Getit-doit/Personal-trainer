import WidgetKit
import SwiftUI

/// Entry point for the widget extension. Hosts the rest-timer Live Activity.
@main
struct RestTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        RestTimerLiveActivity()
    }
}
