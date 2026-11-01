import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/theme/app_chrome.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/core/utils/server_clock.dart';
import 'package:fafu/src/features/friends/data/friends_providers.dart';
import 'package:fafu/src/features/groups/data/groups_providers.dart';
import 'package:fafu/src/features/nudges/domain/nudge.dart';
import 'package:fafu/src/features/nudges/domain/nudge_view.dart';
import 'package:fafu/src/features/users/data/users_repository.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';

/// A plan from a Recent or Plans row: the outcome, who answered what, and
/// "Send again" for plans you sent. Resolves with the nudge to send again.
Future<NudgeResponse?> showPlanDetailSheet(BuildContext context, NudgeView view) {
  return showFafoSheet<NudgeResponse>(
    context,
    title: 'Plan',
    builder: (_) => PlanDetailSheet(view: view),
  );
}

class PlanDetailSheet extends ConsumerWidget {
  const PlanDetailSheet({super.key, required this.view});

  final NudgeView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = view.nudge;
    final now = ServerClock.now();
    final answers = _answers(ref);
    return FafoSheetBody(
      footer: view.isSender
          ? FafoPill(
              label: 'Send again',
              block: true,
              onPressed: () => Navigator.of(context).pop(n),
            )
          : null,
      children: [
        Container(
          margin: const EdgeInsets.only(right: 6, bottom: 6),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppChrome.cardRadius),
            border: Border.all(color: AppColors.border, width: AppChrome.outlineWidth),
            boxShadow: AppChrome.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FafoEyebrow(_headline(now)),
              const SizedBox(height: 10),
              if (n.isQuest) ...[
                FafoQuestTags(difficulty: n.questDifficulty),
                const SizedBox(height: 10),
              ],
              FafoDisplay(n.title),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      view.isSender ? 'To ${view.targetName}' : 'From ${view.senderName}${n.isGroup ? ' · ${view.targetName}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.ui(13.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    planTimestamp(n.createdAt),
                    style: AppTypography.ui(13, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (answers.isNotEmpty) ...[
          const FafoSectionLabel('Answers', top: 22, bottom: 4),
          for (final a in answers)
            FafoListRow(
              title: a.name,
              leading: FafoAvatar(name: a.name, photoUrl: a.photo, size: FafoAvatarSize.md),
              trailing: Text(
                a.answer(view, now),
                style: AppTypography.ui(
                  13.5,
                  fontWeight: a.vote == null ? FontWeight.w400 : FontWeight.w600,
                  color: a.vote == 'yes' ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ],
    );
  }

  String _headline(DateTime now) {
    final n = view.nudge;
    final state = view.state(now);
    if (state == NudgeCardState.pending || state == NudgeCardState.accepted) return 'Active';
    if (n.isCancelled) return 'Cancelled';
    if (n.isGroup) return view.outcomeLabel(now);
    return switch (state) {
      NudgeCardState.goTime => view.isSender ? '${view.targetName}’s in' : 'You said yes',
      NudgeCardState.declined => view.isSender ? '${view.targetName} said no' : 'You said no',
      _ => 'Expired',
    };
  }

  /// Everyone the plan went to and how they answered.
  List<_Answer> _answers(WidgetRef ref) {
    final n = view.nudge;
    final me = ref.watch(currentProfileProvider).value;
    final friends = ref.watch(friendsListProvider).value ?? const [];
    final groups = ref.watch(groupsListProvider).value ?? const [];
    String nameOf(String uid, String fallback) {
      if (uid == me?.uid) return 'You';
      return friends.where((f) => f.user.uid == uid).firstOrNull?.user.displayName ?? fallback;
    }

    String? photoOf(String uid) {
      if (uid == me?.uid) return me?.photoUrl;
      return friends.where((f) => f.user.uid == uid).firstOrNull?.user.photoUrl;
    }

    if (n.isGroup) {
      final group = groups.where((g) => g.id == n.targetId).firstOrNull;
      final uids = <String>{
        if (group != null)
          for (final m in group.members)
            if (m.user.uid != n.senderUid) m.user.uid,
        ...n.votes.keys,
      };
      return [
        for (final uid in uids)
          _Answer(
            name: group?.members.where((m) => m.user.uid == uid).firstOrNull?.user.displayName ?? nameOf(uid, 'Member'),
            photo: group?.members.where((m) => m.user.uid == uid).firstOrNull?.user.photoUrl ?? photoOf(uid),
            vote: n.votes[uid],
          ),
      ];
    }
    final uid = view.isSender ? n.targetId : view.myUid;
    if (uid == null) return const [];
    return [
      _Answer(
        name: view.isSender ? nameOf(uid, view.targetName) : 'You',
        photo: photoOf(uid),
        vote: n.votes[uid],
      ),
    ];
  }
}

class _Answer {
  const _Answer({required this.name, required this.photo, required this.vote});

  final String name;
  final String? photo;
  final String? vote;

  String answer(NudgeView view, DateTime now) => switch (vote) {
    'yes' => 'In',
    'no' => 'Out',
    _ => view.answerWindowOpen(now) ? 'Waiting' : 'No answer',
  };
}

/// "Thu, 6:40 pm".
String planTimestamp(DateTime at) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final local = at.toLocal();
  final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final m = local.minute.toString().padLeft(2, '0');
  return '${days[local.weekday - 1]}, $h:$m ${local.hour < 12 ? 'am' : 'pm'}';
}

/// The Active / Expired row for a plan (Recent, a friend's or group's plans).
class PlanRow extends StatelessWidget {
  const PlanRow({super.key, required this.view, required this.now, required this.onTap});

  final NudgeView view;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = view.state(now);
    final active = s == NudgeCardState.pending || s == NudgeCardState.accepted;
    return FafoPlanRow(
      title: view.nudge.title,
      state: active ? 'Active' : 'Expired',
      active: active,
      isQuest: view.nudge.isQuest,
      onTap: onTap,
    );
  }
}
