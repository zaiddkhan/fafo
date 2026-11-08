import ActivityKit
import Foundation

/// One running nudge / side-quest timer. Shared by the Runner app (which
/// starts, updates and ends activities) and the FafoTimer widget extension
/// (which draws them), so this file is a member of both targets.
@available(iOS 16.1, *)
struct FafoTimerAttributes: ActivityAttributes, Hashable {
  struct ContentState: Codable, Hashable {
    /// "Waiting for Sara", "From Sara", "You said yes", "Go time".
    var head: String
    /// Beside the countdown: "left to answer" / "to get there".
    var label: String
    /// Shown instead of the countdown once it hits zero: "Go time" / "Time's up".
    var doneLabel: String
    /// Timer window on the device clock (the app converts from server time).
    var start: Date
    var end: Date
    /// Go-time phase (signal red) rather than the answer window (FaFo blue).
    var red: Bool
    /// The app saw it hit zero; also implied once the activity goes stale.
    var done: Bool
  }

  var nudgeId: String
  var title: String
  var isQuest: Bool
}
