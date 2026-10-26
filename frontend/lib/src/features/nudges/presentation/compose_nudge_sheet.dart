import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/services/app_sounds.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/features/friends/data/friends_providers.dart';
import 'package:fafu/src/features/friends/domain/friend.dart';
import 'package:fafu/src/features/groups/data/groups_providers.dart';
import 'package:fafu/src/features/groups/domain/group.dart';
import 'package:fafu/src/features/groups/presentation/group_sheet.dart';
import 'package:fafu/src/features/nudges/data/nudges_repository.dart';
import 'package:fafu/src/features/nudges/domain/nudge.dart';
import 'package:fafu/src/features/quests/domain/quest.dart';
import 'package:fafu/src/features/right_now/data/right_now_providers.dart';
import 'package:fafu/src/features/users/data/users_repository.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';

/// Opens the composer. Pass [quest] to share a side quest as a tagged nudge.
/// Resolves with the created nudge, or null if dismissed.
Future<NudgeResponse?> showComposeNudgeSheet(
  BuildContext context, {
  QuestResponse? quest,
}) {
  return showFafoSheet<NudgeResponse>(
    context,
    builder: (_) => ComposeNudgeSheet(quest: quest),
  );
}

/// "What's the plan?" One title, one friend or one group, a countdown after
/// yes (V3 brief 4.1). No location, no description; only quests carry one.
class ComposeNudgeSheet extends ConsumerStatefulWidget {
  const ComposeNudgeSheet({super.key, this.quest});

  final QuestResponse? quest;

  @override
  ConsumerState<ComposeNudgeSheet> createState() => _ComposeNudgeSheetState();
}

class _Target {
  const _Target.friend(this.id, this.name) : feedType = NudgeFeedType.friend;
  const _Target.group(this.id, this.name) : feedType = NudgeFeedType.group;

  final NudgeFeedType feedType;
  final String id;
  final String name;

  bool matches(NudgeFeedType type, String otherId) =>
      feedType == type && id == otherId;
}

class _ComposeNudgeSheetState extends ConsumerState<ComposeNudgeSheet> {
  final _title = TextEditingController();
  _Target? _target;
  int? _countdown;
  bool _sending = false;
  String? _error;

  QuestResponse? get _quest => widget.quest;

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

  String get _planTitle => _quest?.title ?? _title.text.trim();

  int _effectiveCountdown() =>
      _countdown ??
      ref.read(currentProfileProvider).value?.defaultCountdownMinutes ??
      10;

  Future<void> _newGroup() async {
    final group = await showGroupSheet(context);
    if (group != null && mounted) {
      setState(() => _target = _Target.group(group.id, group.name));
    }
  }

  Future<void> _send() async {
    final target = _target;
    if (target == null || _planTitle.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final nudge = await ref.read(nudgesRepositoryProvider).create(
        feedType: target.feedType,
        targetId: target.id,
        title: _planTitle,
        windowMinutes: _effectiveCountdown(),
        questId: _quest?.id,
      );
      AppSounds.play(FafoSound.nudgeSent);
      if (mounted) Navigator.of(context).pop(nudge);
    } catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = friendlyErrorMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final friends = ref.watch(friendsListProvider);
    final groups = ref.watch(groupsListProvider);
    final defaultCountdown = ref.watch(currentProfileProvider).value?.defaultCountdownMinutes ?? 10;
    final countdown = _countdown ?? defaultCountdown;
    final ok = _planTitle.isNotEmpty && _target != null;

    return FafoSheetBody(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 44),
          child: FafoEyebrow(_quest == null ? 'New nudge' : 'Side quest invite'),
        ),
        FafoCard(
          stripLeft: 'You',
          stripRight: 'Sender',
          zones: [
            FafoZone(
              gap: 12,
              children: [
                if (_quest != null)
                  FafoQuestTags(difficulty: _quest!.difficulty.name),
                const FafoDisplay('What’s the plan?'),
                if (_quest == null)
                  TextField(
                    controller: _title,
                    maxLength: 100,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppTypography.ui(17, fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(
                      hintText: 'Coffee downstairs?',
                      counterText: '',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  )
                else ...[
                  // Quests go out as the admin wrote them: read-only.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.rule, width: 2)),
                    ),
                    child: Text(_quest!.title, style: AppTypography.ui(17, fontWeight: FontWeight.w700)),
                  ),
                  if (_quest!.description != null)
                    Text(
                      _quest!.description!,
                      style: AppTypography.ui(14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
                    ),
                ],
                const SizedBox(height: 2),
                const FafoEyebrow('Invite', fontSize: 10.5),
                _InviteChips(
                  friends: friends.value ?? const [],
                  groups: groups.value ?? const [],
                  loading: friends.isLoading || groups.isLoading,
                  quest: _quest,
                  selected: _target,
                  onPick: (t) => setState(() => _target = t),
                  onNewGroup: _newGroup,
                ),
                const SizedBox(height: 2),
                const FafoEyebrow('Countdown after yes', fontSize: 10.5),
                FafoChipGrid(
                  children: [
                    for (final m in const [5, 10, 15])
                      FafoChip(
                        selected: countdown == m,
                        onTap: () => setState(() => _countdown = m),
                        child: Text('$m min'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                FafoPill(
                  label: _target == null ? 'Send' : 'Send to ${_target!.name}',
                  block: true,
                  busy: _sending,
                  onPressed: ok ? _send : null,
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: AppTypography.ui(13, color: AppColors.signalRed),
                  ),
              ],
            ),
          ],
        ),
        Text(
          'Your friend gets 10 minutes to answer. Your countdown starts when they say yes.',
          style: AppTypography.ui(13, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _InviteChips extends StatelessWidget {
  const _InviteChips({
    required this.friends,
    required this.groups,
    required this.loading,
    required this.quest,
    required this.selected,
    required this.onPick,
    required this.onNewGroup,
  });

  final List<FriendResponse> friends;
  final List<GroupResponse> groups;
  final bool loading;
  final QuestResponse? quest;
  final _Target? selected;
  final ValueChanged<_Target> onPick;
  final VoidCallback onNewGroup;

  @override
  Widget build(BuildContext context) {
    if (loading && friends.isEmpty && groups.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (friends.isEmpty && groups.isEmpty) {
      return Text(
        'No friends yet. Share your code from home to add some.',
        style: AppTypography.ui(13.5, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
      );
    }
    final chips = <Widget>[
      for (final f in friendsByRecentNudge(friends))
        _personChip(
          name: f.user.displayName,
          photoUrl: f.user.photoUrl,
          // Friends who turned off side quest invites can't be picked for one.
          enabled: quest == null || f.user.sideQuestInvites,
          offLabel: quest != null && !f.user.sideQuestInvites ? 'Quests off' : null,
          selected: selected?.matches(NudgeFeedType.friend, f.user.uid) ?? false,
          onTap: () => onPick(_Target.friend(f.user.uid, _firstName(f.user.displayName))),
        ),
      for (final g in groups)
        _personChip(
          name: g.name,
          square: true,
          enabled: true,
          selected: selected?.matches(NudgeFeedType.group, g.id) ?? false,
          onTap: () => onPick(_Target.group(g.id, g.name)),
        ),
      FafoChip(
        selected: false,
        minHeight: 68,
        semanticLabel: 'New group',
        onTap: onNewGroup,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('+', style: AppTypography.display(22, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(
              'New group',
              style: AppTypography.ui(12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    ];
    return FafoChipGrid(children: chips);
  }

  Widget _personChip({
    required String name,
    required bool enabled,
    required bool selected,
    required VoidCallback onTap,
    String? photoUrl,
    bool square = false,
    String? offLabel,
  }) {
    return FafoChip(
      selected: selected,
      enabled: enabled,
      minHeight: 68,
      semanticLabel: name,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FafoAvatar(name: name, square: square, photoUrl: photoUrl),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.ui(
              12.5,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.onAccent : AppColors.textPrimary,
            ),
          ),
          if (offLabel != null)
            Text(
              offLabel.toUpperCase(),
              style: AppTypography.label(fontSize: 9, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }
}

String _firstName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'friend';
  return trimmed.split(RegExp(r'\s+')).first;
}
