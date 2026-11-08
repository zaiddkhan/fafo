import SwiftUI
import WidgetKit

/// The FafoTimer widget extension: Live Activities only, no Home Screen
/// widgets.
@main
struct FafoTimerBundle: WidgetBundle {
  var body: some Widget {
    FafoTimerLiveActivity()
  }
}
