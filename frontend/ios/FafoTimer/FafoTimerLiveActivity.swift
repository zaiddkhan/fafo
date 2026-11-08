import ActivityKit
import SwiftUI
import WidgetKit

/// FaFo brand colours (lib/src/core/theme/app_colors.dart).
private extension Color {
  static let fafoBlue = Color(red: 0x1A / 255, green: 0x6F / 255, blue: 0xD0 / 255)
  static let signalRed = Color(red: 0xEB / 255, green: 0x51 / 255, blue: 0x47 / 255)
}

/// Display face (Anton) for the plan title, mono (IBM Plex Mono) for small
/// caps labels; both bundled with the extension. Digits use the system face so
/// the countdown doesn't jitter as it ticks.
private extension Font {
  static func display(_ size: CGFloat) -> Font { .custom("Anton-Regular", size: size) }
  static func mono(_ size: CGFloat) -> Font { .custom("IBMPlexMono-SemiBold", size: size) }
  static func digits(_ size: CGFloat) -> Font {
    .system(size: size, weight: .heavy, design: .rounded).monospacedDigit()
  }
}

private extension ActivityViewContext where Attributes == FafoTimerAttributes {
  /// Hit zero: the app said so, or the stale date (the end) passed while the
  /// app was closed.
  var isDone: Bool { state.done || isStale }
  var tint: Color { state.red ? .signalRed : .fafoBlue }
  /// Guard against a bad window (end before start), which would trap.
  var window: ClosedRange<Date> { min(state.start, state.end)...state.end }
  var eyebrow: String {
    let head = state.head.uppercased()
    return attributes.isQuest ? "SIDE QUEST · \(head)" : head
  }
}

struct FafoTimerLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: FafoTimerAttributes.self) { context in
      LockScreenView(context: context)
        .activityBackgroundTint(context.tint)
        .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Mascot(height: 30).foregroundStyle(context.tint)
            .padding(.leading, 4)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Countdown(context: context, size: 30)
            .foregroundStyle(context.state.red ? Color.signalRed : .white)
            .padding(.trailing, 4)
        }
        DynamicIslandExpandedRegion(.center) {
          Text(context.attributes.title)
            .font(.display(20))
            .lineLimit(1)
            .foregroundStyle(.white)
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(alignment: .leading, spacing: 6) {
            Text(context.isDone ? context.eyebrow : "\(context.eyebrow) · \(context.state.label.uppercased())")
              .font(.mono(11))
              .tracking(1)
              .lineLimit(1)
              .foregroundStyle(.white.opacity(0.7))
            if !context.isDone {
              Bar(context: context).tint(context.tint)
            }
          }
          .padding(.horizontal, 4)
        }
      } compactLeading: {
        Mascot(height: 16).foregroundStyle(context.tint)
      } compactTrailing: {
        CompactCountdown(context: context)
          .foregroundStyle(context.state.red ? Color.signalRed : .white)
      } minimal: {
        Mascot(height: 14).foregroundStyle(context.tint)
      }
      .keylineTint(context.tint)
    }
  }
}

private struct LockScreenView: View {
  let context: ActivityViewContext<FafoTimerAttributes>

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 6) {
          Mascot(height: 14)
          Text(context.eyebrow)
            .font(.mono(11))
            .tracking(1.2)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        Text(context.attributes.title)
          .font(.display(24))
          .lineLimit(1)
          .minimumScaleFactor(0.75)
        if !context.isDone {
          Bar(context: context).tint(.white)
        }
      }
      Spacer(minLength: 8)
      VStack(alignment: .trailing, spacing: 2) {
        Countdown(context: context, size: 36)
        if !context.isDone {
          Text(context.state.label)
            .font(.mono(11))
            .opacity(0.85)
        }
      }
    }
    .foregroundStyle(.white)
    .padding(16)
  }
}

/// The big number. Ticks on its own; no app or push needed.
private struct Countdown: View {
  let context: ActivityViewContext<FafoTimerAttributes>
  let size: CGFloat

  var body: some View {
    if context.isDone {
      Text(context.state.doneLabel)
        .font(.display(size * 0.8))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    } else {
      Text(timerInterval: context.window, countsDown: true)
        .font(.digits(size))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .multilineTextAlignment(.trailing)
        // A timer Text otherwise claims the full width it could ever need;
        // this fits "14:59" with room to spare.
        .frame(maxWidth: size * 3.4, alignment: .trailing)
    }
  }
}

/// Dynamic Island compact slot: room for "14:42" and nothing more.
private struct CompactCountdown: View {
  let context: ActivityViewContext<FafoTimerAttributes>

  var body: some View {
    if context.isDone {
      Text(context.state.red ? "GO" : "0:00")
        .font(.digits(14))
    } else {
      Text(timerInterval: context.window, countsDown: true)
        .font(.digits(14))
        .multilineTextAlignment(.trailing)
        .frame(width: 44, alignment: .trailing)
    }
  }
}

/// Time left, shrinking as the timer runs.
private struct Bar: View {
  let context: ActivityViewContext<FafoTimerAttributes>

  var body: some View {
    ProgressView(timerInterval: context.window, countsDown: true) {
      EmptyView()
    } currentValueLabel: {
      EmptyView()
    }
    .labelsHidden()
  }
}

/// The FaFo dino, drawn as a template so it takes the surrounding colour.
private struct Mascot: View {
  let height: CGFloat

  var body: some View {
    Image("Mascot")
      .renderingMode(.template)
      .resizable()
      .scaledToFit()
      .frame(height: height)
  }
}
