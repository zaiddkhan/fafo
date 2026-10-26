import 'package:fafu/src/features/nudges/domain/nudge.dart';

/// What a card shows, from one phone's point of view (V3 brief, Nudge states).
enum NudgeCardState { pending, accepted, declined, expired, goTime }

/// How long a just-resolved nudge stays in the live area ("Go time", "said no")
/// before it moves to Recent.
const resolvedLinger = Duration(seconds: 30);

class NudgeView {
  NudgeView(this.nudge, {required this.myUid});

  final NudgeResponse nudge;
  final String myUid;

  bool get isSender => nudge.senderUid == myUid;
  String? get myVote => nudge.voteOf(myUid);

  /// Group size for the tally: members other than the sender.
  int get groupSize => nudge.expectedVoterCount;
  int get yesCount => nudge.yesCount;

  bool answerWindowOpen(DateTime now) =>
      nudge.isLive && now.isBefore(nudge.answerDeadline);

  NudgeCardState state(DateTime now) {
    final n = nudge;
    if (isSender) {
      if (n.isPending) {
        return now.isBefore(n.answerDeadline)
            ? NudgeCardState.pending
            : NudgeCardState.expired;
      }
      if (n.isAccepted) {
        if (!now.isBefore(n.goTime)) return NudgeCardState.goTime;
        // A group keeps collecting answers after the first yes.
        if (n.isGroup && answerWindowOpen(now)) return NudgeCardState.pending;
        return NudgeCardState.accepted;
      }
      return switch (n.outcome) {
        'yes' => NudgeCardState.goTime,
        'no' => NudgeCardState.declined,
        _ => NudgeCardState.expired,
      };
    }
    switch (myVote) {
      case 'yes':
        if (n.isAccepted && now.isBefore(n.goTime)) return NudgeCardState.accepted;
        return NudgeCardState.goTime;
      case 'no':
        return NudgeCardState.declined;
    }
    return answerWindowOpen(now) ? NudgeCardState.pending : NudgeCardState.expired;
  }

  /// Whether this nudge belongs in home's live area right now.
  bool isInLiveArea(DateTime now) {
    final s = state(now);
    // "Go time" shows briefly, then moves to Recent. A group can stay open to
    // answers past go time, so don't wait for the nudge itself to resolve.
    if (s == NudgeCardState.goTime && now.difference(nudge.goTime) >= resolvedLinger) {
      return false;
    }
    if (nudge.isLive) {
      // A receiver whose window closed unanswered goes straight to Recent.
      if (!isSender && s == NudgeCardState.expired) return false;
      return true;
    }
    final resolvedAt = nudge.resolvedAt ?? nudge.goAt;
    return resolvedAt != null && now.difference(resolvedAt) < resolvedLinger;
  }

  /// Outcome line in Recent: Yes, No or Expired; "{n}/{N} in" for groups.
  String outcomeLabel(DateTime now) {
    if (nudge.isGroup) {
      return yesCount > 0 ? '$yesCount/$groupSize in' : 'No one’s in';
    }
    return switch (state(now)) {
      NudgeCardState.goTime || NudgeCardState.accepted => 'Yes',
      NudgeCardState.declined => 'No',
      NudgeCardState.expired => 'Expired',
      NudgeCardState.pending => 'Pending',
    };
  }

  /// Friend's name, or the group's name.
  String get targetName => nudge.targetName ?? (nudge.isGroup ? 'your group' : 'your friend');
  String get senderName => isSender ? 'you' : (nudge.senderName ?? 'a friend');
}
