import 'package:flutter/material.dart';

import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/features/nudges/domain/nudge_view.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';

/// The card for one nudge, from this phone's side: white sender card or blue
/// receiver card (V3 brief 4.3, 4.4, 4.7). Re-renders every second so the
/// state flips at expiry and go time without waiting for a poll.
class NudgeCard extends StatelessWidget {
  const NudgeCard({
    super.key,
    required this.view,
    required this.myHandle,
    this.onYes,
    this.onNo,
    this.onCancel,
    this.answering = false,
    this.receiverHandle,
  });

  final NudgeView view;

  /// The viewer's username, for the receiver strip ("@maya / Receiver").
  final String myHandle;

  /// Overrides the receiver strip handle (the preview's demo friend).
  final String? receiverHandle;
  final VoidCallback? onYes;
  final VoidCallback? onNo;

  /// Sender only: calls the plan off while it's waiting or counting down.
  final VoidCallback? onCancel;
  final bool answering;

  @override
  Widget build(BuildContext context) {
    return FafoTicker(
      builder: (context, now) => view.isSender
          ? _SenderCard(view: view, now: now, onCancel: onCancel)
          : _ReceiverCard(
              view: view,
              now: now,
              handle: receiverHandle ?? myHandle,
              onYes: onYes,
              onNo: onNo,
              answering: answering,
            ),
    );
  }
}

class _SenderCard extends StatelessWidget {
  const _SenderCard({required this.view, required this.now, this.onCancel});

  final NudgeView view;
  final DateTime now;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final n = view.nudge;
    final isGroup = n.isGroup;
    final name = view.targetName;
    final state = view.state(now);
    String head;
    Widget? timerZone;
    String? foot;
    switch (state) {
      case NudgeCardState.pending:
        head = isGroup ? 'Waiting on $name' : 'Waiting for $name';
        if (isGroup && n.isAccepted) {
          // First yes set go time; answers stay open to the 10-minute mark.
          timerZone = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FafoCountdown(to: n.goTime, label: 'until go time'),
              const SizedBox(height: 10),
              Text(
                'Answers close in ${fafoMmss(n.answerDeadline.difference(now))}',
                style: AppTypography.ui(12.5, color: AppColors.textSecondary),
              ),
            ],
          );
        } else {
          timerZone = FafoCountdown(to: n.answerDeadline, label: 'left to answer');
        }
      case NudgeCardState.accepted:
        head = isGroup
            ? '${view.yesCount}/${view.groupSize} in'
            : '$name said yes';
        timerZone = FafoCountdown(to: n.goTime, label: 'until go time');
      case NudgeCardState.declined:
        head = isGroup ? 'No one’s in' : '$name said no';
        foot = 'A clear no. No follow-up needed.';
      case NudgeCardState.expired:
        head = isGroup ? 'No one’s in' : 'Expired';
        foot = isGroup
            ? 'Nobody said yes in 10 minutes.'
            : 'No answer in 10 minutes.';
      case NudgeCardState.goTime:
        head = 'Go time';
        timerZone = const FafoCountdown(to: null, label: 'go time');
      case NudgeCardState.cancelled:
        head = 'Cancelled';
        foot = 'You called it off.';
    }
    final canCancel = onCancel != null && (state == NudgeCardState.pending || state == NudgeCardState.accepted);
    return FafoCard(
      stripLeft: 'You',
      stripRight: 'Sender',
      zones: [
        FafoZone(
          children: [
            FafoEyebrow(head),
            if (n.isQuest) FafoQuestTags(difficulty: n.questDifficulty),
            FafoDisplay(n.title),
            if (n.description != null && n.description!.isNotEmpty)
              Text(
                n.description!,
                style: AppTypography.ui(14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
              ),
            if (isGroup) _Tally(view: view, color: AppColors.textPrimary, mutedNames: true),
          ],
        ),
        if (timerZone != null)
          FafoZone(
            big: true,
            children: [
              timerZone,
              if (canCancel) ...[
                const SizedBox(height: 6),
                FafoInlineLink(label: 'Cancel plan', onTap: onCancel),
              ],
            ],
          ),
        if (foot != null) FafoZone(children: [_Foot(foot)]),
      ],
    );
  }
}

class _ReceiverCard extends StatelessWidget {
  const _ReceiverCard({
    required this.view,
    required this.now,
    required this.handle,
    required this.onYes,
    required this.onNo,
    required this.answering,
  });

  final NudgeView view;
  final DateTime now;
  final String handle;
  final VoidCallback? onYes;
  final VoidCallback? onNo;
  final bool answering;

  @override
  Widget build(BuildContext context) {
    const white = AppColors.onAccent;
    final n = view.nudge;
    final state = view.state(now);
    String head;
    Widget? timerZone;
    String? foot;
    var showActions = false;
    switch (state) {
      case NudgeCardState.pending:
        head = 'You have 10 minutes';
        timerZone = FafoCountdown(to: n.answerDeadline, label: 'left to answer', color: white);
        showActions = true;
      case NudgeCardState.accepted:
        head = 'You said yes';
        timerZone = FafoCountdown(
          to: n.goTime,
          label: 'until your ${n.countdownMinutes}-minute plan starts',
          color: white,
        );
      case NudgeCardState.declined:
        head = 'You said no';
        foot = 'That’s it. No chat opens.';
      case NudgeCardState.expired:
        head = 'Expired';
        foot = 'The 10 minutes ran out.';
      case NudgeCardState.goTime:
        head = 'Go time';
        timerZone = const FafoCountdown(to: null, label: 'go time', color: white);
      case NudgeCardState.cancelled:
        head = 'Cancelled';
        foot = '${view.senderName} called it off.';
    }
    final from = 'From ${view.senderName}${n.isGroup ? ' in ${view.targetName}' : ''}';
    return FafoCard(
      blue: true,
      stripLeft: '@$handle',
      stripRight: 'Receiver',
      zones: [
        FafoZone(
          children: [
            FafoEyebrow(head, color: white),
            if (n.isQuest) FafoQuestTags(difficulty: n.questDifficulty, onBlue: true),
            Text(from, style: AppTypography.ui(13.5, fontWeight: FontWeight.w700, color: white)),
            FafoDisplay(n.title, color: white),
            if (n.description != null && n.description!.isNotEmpty)
              Text(
                n.description!,
                style: AppTypography.ui(
                  14,
                  fontWeight: FontWeight.w400,
                  color: white.withValues(alpha: 0.88),
                ),
              ),
            if (n.isGroup) _Tally(view: view, color: white),
          ],
        ),
        if (timerZone != null) FafoZone(big: true, children: [timerZone]),
        if (foot != null) FafoZone(children: [_Foot(foot, color: white)]),
        if (showActions)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Row(
              children: [
                Expanded(
                  child: FafoPill(
                    label: 'Yes, I’m in',
                    onBlue: true,
                    height: 54,
                    busy: answering,
                    onPressed: onYes,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 92,
                  child: FafoPill(
                    label: 'No',
                    primary: false,
                    onBlue: true,
                    height: 54,
                    onPressed: answering ? null : onNo,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Live group tally: "2/5 in" and who said yes.
class _Tally extends StatelessWidget {
  const _Tally({required this.view, required this.color, this.mutedNames = false});

  final NudgeView view;
  final Color color;
  final bool mutedNames;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '${view.yesCount}/${view.groupSize}',
          style: AppTypography.timer(20, color: color),
        ),
        Text('in', style: AppTypography.ui(14, fontWeight: FontWeight.w700, color: color)),
        if (view.nudge.yesNames.isNotEmpty)
          Text(
            view.nudge.yesNames.join(', '),
            style: AppTypography.ui(
              14,
              fontWeight: FontWeight.w700,
              color: mutedNames ? AppColors.textSecondary : color.withValues(alpha: 0.85),
            ),
          ),
      ],
    );
  }
}

class _Foot extends StatelessWidget {
  const _Foot(this.text, {this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTypography.ui(14, fontWeight: FontWeight.w700, color: color));
}
