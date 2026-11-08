import ActivityKit
import Flutter
import Foundation

/// Method channel "fafo/live_activity" (lib/src/features/notifications/data/
/// live_timers.dart). Dart sends the full list of timers that should be on
/// screen; this makes the running Live Activities match it.
final class FafoLiveActivityPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "fafo/live_activity",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(FafoLiveActivityPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    // Before 16.2 there's no ActivityContent / stale date; skip quietly.
    guard #available(iOS 16.2, *) else {
      result(nil)
      return
    }
    switch call.method {
    case "sync":
      let raw = (call.arguments as? [[String: Any]]) ?? []
      Task { @MainActor in
        await LiveTimerStore.sync(raw.compactMap(LiveTimerStore.parse))
        result(nil)
      }
    case "endAll":
      Task { @MainActor in
        await LiveTimerStore.sync([])
        result(nil)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

@available(iOS 16.2, *)
private enum LiveTimerStore {
  typealias Item = (attributes: FafoTimerAttributes, state: FafoTimerAttributes.ContentState)

  static func parse(_ raw: [String: Any]) -> Item? {
    guard
      let id = raw["id"] as? String,
      let title = raw["title"] as? String,
      let head = raw["head"] as? String,
      let label = raw["label"] as? String,
      let doneLabel = raw["doneLabel"] as? String,
      let start = (raw["start"] as? NSNumber)?.doubleValue,
      let end = (raw["end"] as? NSNumber)?.doubleValue
    else { return nil }
    let attributes = FafoTimerAttributes(
      nudgeId: id,
      title: title,
      isQuest: raw["quest"] as? Bool ?? false
    )
    let state = FafoTimerAttributes.ContentState(
      head: head,
      label: label,
      doneLabel: doneLabel,
      start: Date(timeIntervalSince1970: start / 1000),
      end: Date(timeIntervalSince1970: end / 1000),
      red: raw["red"] as? Bool ?? false,
      done: raw["done"] as? Bool ?? false
    )
    return (attributes, state)
  }

  /// Update the ones that are still wanted, end the rest, start what's new.
  static func sync(_ items: [Item]) async {
    var wanted: [String: Item] = [:]
    for item in items where wanted[item.attributes.nudgeId] == nil {
      wanted[item.attributes.nudgeId] = item
    }

    for activity in Activity<FafoTimerAttributes>.activities {
      guard activity.activityState == .active || activity.activityState == .stale else {
        continue
      }
      let id = activity.attributes.nudgeId
      // Attributes are fixed for an activity's life, so a renamed plan is
      // ended here and started again below.
      if let item = wanted[id], item.attributes == activity.attributes {
        wanted[id] = nil
        if activity.content.state != item.state {
          await activity.update(content(item.state))
        }
      } else {
        await activity.end(nil, dismissalPolicy: .immediate)
      }
    }

    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
    for item in wanted.values {
      do {
        _ = try Activity<FafoTimerAttributes>.request(
          attributes: item.attributes,
          content: content(item.state),
          pushType: nil
        )
      } catch {
        NSLog("FaFo Live Activity request failed: \(error)")
      }
    }
  }

  /// Stale at zero, so a timer that runs out while the app is closed still
  /// flips to "Go time" / "Time's up" on the Lock Screen.
  private static func content(
    _ state: FafoTimerAttributes.ContentState
  ) -> ActivityContent<FafoTimerAttributes.ContentState> {
    ActivityContent(state: state, staleDate: state.done ? nil : state.end)
  }
}
