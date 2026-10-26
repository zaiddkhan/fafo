import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fafu/src/core/services/app_sounds.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/core/utils/server_clock.dart';
import 'package:fafu/src/features/nudges/domain/nudge.dart';
import 'package:fafu/src/features/nudges/domain/nudge_view.dart';
import 'package:fafu/src/features/nudges/presentation/nudge_cards.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';

Future<void> showPreviewSheet(BuildContext context) =>
    showFafoSheet<void>(context, builder: (_) => const PreviewSheet());

const _me = 'me';
const _demoFriends = [('maya', 'Maya'), ('leo', 'Leo'), ('nina', 'Nina')];

/// "Preview both sides" (V3 brief 3.9). Send as you, answer as a demo friend.
/// Entirely local: nothing is saved and no request is made. Kept self-contained
/// so it's easy to remove later.
class PreviewSheet extends StatefulWidget {
  const PreviewSheet({super.key});

  @override
  State<PreviewSheet> createState() => _PreviewSheetState();
}

class _PreviewSheetState extends State<PreviewSheet> {
  final _title = TextEditingController(text: 'Coffee downstairs?');
  int _friend = 0;
  int _countdown = 10;
  NudgeResponse? _nudge;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  (String, String) get _demo => _demoFriends[_friend];

  void _send() {
    final now = ServerClock.now();
    final answerBy = now.add(const Duration(minutes: 10));
    setState(() {
      AppSounds.play(FafoSound.nudgeSent);
      _nudge = NudgeResponse(
        id: 'preview',
        senderUid: _me,
        title: _title.text.trim(),
        responseWindowMinutes: _countdown,
        status: NudgeStatus.active,
        expiresAt: answerBy,
        answerBy: answerBy,
        reminderCount: 0,
        reminderLimit: 0,
        votes: const {},
        yesCount: 0,
        voterCount: 0,
        expectedVoterCount: 1,
        createdAt: now,
        senderName: 'you',
        targetName: _demo.$2,
      );
    });
  }

  void _answer(NudgeVote vote) {
    final n = _nudge;
    if (n == null) return;
    HapticFeedback.selectionClick();
    AppSounds.play(FafoSound.answer);
    final now = ServerClock.now();
    final yes = vote == NudgeVote.yes;
    final goAt = now.add(Duration(minutes: n.countdownMinutes));
    setState(() {
      _nudge = NudgeResponse(
        id: n.id,
        senderUid: n.senderUid,
        title: n.title,
        responseWindowMinutes: n.responseWindowMinutes,
        status: yes ? NudgeStatus.acceptedTimer : NudgeStatus.resolved,
        expiresAt: yes ? goAt : n.expiresAt,
        answerBy: n.answerBy,
        goAt: yes ? goAt : null,
        outcome: yes ? null : 'no',
        acceptedTimerStartedAt: yes ? now : null,
        resolvedAt: yes ? null : now,
        reminderCount: 0,
        reminderLimit: 0,
        votes: {_demo.$1: nudgeVoteToJson(vote)},
        yesCount: yes ? 1 : 0,
        voterCount: 1,
        expectedVoterCount: 1,
        createdAt: n.createdAt,
        senderName: n.senderName,
        targetName: n.targetName,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final n = _nudge;
    return FafoSheetBody(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: FafoSectionHeader(
                eyebrow: 'Live two-person preview',
                title: 'See both sides.',
              ),
            ),
            if (n != null)
              Padding(
                padding: const EdgeInsets.only(right: 44),
                child: FafoPill(
                  label: 'Start over',
                  small: true,
                  primary: false,
                  onPressed: () => setState(() => _nudge = null),
                ),
              )
            else
              const SizedBox(width: 44),
          ],
        ),
        Text(
          'Send as you. Answer as a demo friend. Nothing here is saved.',
          style: AppTypography.ui(15, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        ),
        const FafoRule(),
        if (n == null) _composer() else NudgeCard(view: NudgeView(n, myUid: _me), myHandle: 'you'),
        Center(child: Icon(Icons.arrow_downward, size: 18, color: AppColors.textPrimary)),
        if (n == null)
          _idleReceiver()
        else
          NudgeCard(
            view: NudgeView(n, myUid: _demo.$1),
            myHandle: _demo.$1,
            onYes: () => _answer(NudgeVote.yes),
            onNo: () => _answer(NudgeVote.no),
          ),
      ],
    );
  }

  Widget _composer() {
    return FafoCard(
      stripLeft: 'You',
      stripRight: 'Sender',
      zones: [
        FafoZone(
          gap: 12,
          children: [
            const FafoDisplay('What’s the plan?'),
            TextField(
              controller: _title,
              maxLength: 100,
              style: AppTypography.ui(17, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                hintText: 'Coffee downstairs?',
                counterText: '',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const FafoEyebrow('Invite', fontSize: 10.5),
            FafoChipGrid(
              children: [
                for (var i = 0; i < _demoFriends.length; i++)
                  FafoChip(
                    selected: _friend == i,
                    minHeight: 68,
                    onTap: () => setState(() => _friend = i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FafoAvatar(name: _demoFriends[i].$2),
                        const SizedBox(height: 6),
                        Text(
                          _demoFriends[i].$2,
                          style: AppTypography.ui(
                            12.5,
                            fontWeight: FontWeight.w700,
                            color: _friend == i ? AppColors.onAccent : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const FafoEyebrow('Countdown after yes', fontSize: 10.5),
            FafoChipGrid(
              children: [
                for (final m in const [5, 10, 15])
                  FafoChip(
                    selected: _countdown == m,
                    onTap: () => setState(() => _countdown = m),
                    child: Text('$m min'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            FafoPill(
              label: 'Send to ${_demo.$2}',
              block: true,
              onPressed: _title.text.trim().isEmpty ? null : _send,
            ),
          ],
        ),
      ],
    );
  }

  Widget _idleReceiver() {
    const white = AppColors.onAccent;
    return FafoCard(
      blue: true,
      stripLeft: '@${_demo.$1}',
      stripRight: 'Receiver',
      zones: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 52),
          child: Column(
            children: [
              FafoAvatar(name: _demo.$2, size: FafoAvatarSize.lg),
              const SizedBox(height: 14),
              Text(
                '${_demo.$2}’s side will light up when you send.',
                textAlign: TextAlign.center,
                style: AppTypography.ui(14, fontWeight: FontWeight.w700, color: white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
