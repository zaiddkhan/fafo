import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/services/app_sounds.dart';
import 'package:fafu/src/core/theme/app_chrome.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/features/friends/data/friends_providers.dart';
import 'package:fafu/src/features/friends/domain/friend.dart';
import 'package:fafu/src/features/groups/data/groups_providers.dart';
import 'package:fafu/src/features/groups/domain/group.dart';
import 'package:fafu/src/features/nudges/data/nudges_repository.dart';
import 'package:fafu/src/features/nudges/domain/nudge.dart';
import 'package:fafu/src/features/quests/data/quests_providers.dart';
import 'package:fafu/src/features/quests/domain/quest.dart';
import 'package:fafu/src/features/right_now/data/right_now_providers.dart';
import 'package:fafu/src/features/users/data/users_repository.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_toast.dart';

/// Opens the composer. Pass [quest] to share a side quest as a tagged nudge.
/// Resolves with the created nudge, or null if dismissed. [friend] or [group]
/// preselects who it's for; [again] prefills a plan to send again.
Future<NudgeResponse?> showComposeNudgeSheet(
  BuildContext context, {
  QuestResponse? quest,
  PublicUserResponse? friend,
  GroupResponse? group,
  NudgeResponse? again,
  VoidCallback? onAddFriends,
}) {
  return showFafoSheet<NudgeResponse>(
    context,
    title: quest != null || again?.isQuest == true ? 'Side quest invite' : 'New nudge',
    builder: (_) => ComposeNudgeSheet(quest: quest, friend: friend, group: group, again: again, onAddFriends: onAddFriends),
  );
}

/// "What's the plan?" One title, one friend or one group, a countdown after
/// yes. No location, no description; only quests carry one.
class ComposeNudgeSheet extends ConsumerStatefulWidget {
  const ComposeNudgeSheet({super.key, this.quest, this.friend, this.group, this.again, this.onAddFriends});

  final QuestResponse? quest;
  final PublicUserResponse? friend;
  final GroupResponse? group;
  final NudgeResponse? again;

  /// "Add friends" from the no-friends state. The sheet closes first.
  final VoidCallback? onAddFriends;

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

/// Plan titles: up to 100 characters, counter from 80.
const _titleMax = 100;
const _counterFrom = 80;

class _ComposeNudgeSheetState extends ConsumerState<ComposeNudgeSheet> {
  final _title = TextEditingController();
  _Target? _target;
  int? _countdown;
  bool _sending = false;

  /// The side quest being sent: the one passed in, or (for Send again) the
  /// one the old plan carried. Built from the old plan when the quest list
  /// hasn't loaded or the quest is gone, so the title stays locked.
  _QuestInfo? get _quest {
    final q = widget.quest;
    if (q != null) return _QuestInfo(q.id, q.title, q.description, q.difficulty.name);
    final again = widget.again;
    final questId = again?.questId;
    if (again == null || questId == null) return null;
    final quests = ref.read(questsListProvider).value ?? const <QuestResponse>[];
    final found = quests.where((q) => q.id == questId).firstOrNull;
    if (found != null) return _QuestInfo(found.id, found.title, found.description, found.difficulty.name);
    return _QuestInfo(questId, again.title, again.description, again.questDifficulty);
  }

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
    final friend = widget.friend;
    final group = widget.group;
    final again = widget.again;
    if (friend != null) {
      _target = _Target.friend(friend.uid, _firstName(friend.displayName));
    } else if (group != null) {
      _target = _Target.group(group.id, group.name);
    } else if (again != null && again.targetId != null) {
      final name = again.targetName ?? (again.isGroup ? 'group' : 'friend');
      _target = again.isGroup
          ? _Target.group(again.targetId!, name)
          : _Target.friend(again.targetId!, _firstName(name));
    }
    if (again != null) {
      if (!again.isQuest) _title.text = again.title;
      _countdown = again.countdownMinutes;
    }
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

  Future<void> _send() async {
    final target = _target;
    if (target == null || _planTitle.isEmpty || _sending) return;
    setState(() {
      _sending = true;
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
        });
        FafoToasts.show(friendlyErrorMessage(e), kind: FafoToastKind.error);
      }
    }
  }

  Future<void> _showAll(List<_Pick> picks) async {
    final picked = await showFafoSheet<_Target>(
      context,
      title: 'Invite',
      tall: true,
      builder: (_) => _ShowAllSheet(picks: picks, selected: _target),
    );
    if (picked != null && mounted) setState(() => _target = picked);
  }

  void _addFriends() {
    Navigator.of(context).pop();
    widget.onAddFriends?.call();
  }

  @override
  Widget build(BuildContext context) {
    final friends = ref.watch(friendsListProvider);
    final groups = ref.watch(groupsListProvider);
    final defaultCountdown = ref.watch(currentProfileProvider).value?.defaultCountdownMinutes ?? 10;
    final countdown = _countdown ?? defaultCountdown;
    if (widget.again?.questId != null) ref.watch(questsListProvider);
    final quest = _quest;
    final targetFriend = _target?.feedType == NudgeFeedType.friend
        ? (friends.value ?? const <FriendResponse>[]).where((f) => f.user.uid == _target!.id).firstOrNull
        : null;
    // Send again can't reach a friend who has since turned quest invites off.
    final targetOk = _target != null && (quest == null || targetFriend == null || targetFriend.user.sideQuestInvites);
    final ok = _planTitle.isNotEmpty && targetOk;
    final length = _title.text.characters.length;
    final picks = _picks(friends.value ?? const [], groups.value ?? const [], quest, ref.watch(currentProfileProvider).value?.uid);

    return FafoSheetBody(
      footer: FafoPill(
        label: _target == null ? 'Send' : 'Send to ${_target!.name}',
        block: true,
        busy: _sending,
        onPressed: ok ? _send : null,
      ),
      children: [
        Container(
          margin: const EdgeInsets.only(right: 6, bottom: 6),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppChrome.cardRadius),
            border: Border.all(color: AppColors.border, width: AppChrome.outlineWidth),
            boxShadow: AppChrome.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (quest != null) ...[
                FafoQuestTags(difficulty: quest.difficulty),
                const SizedBox(height: 12),
              ],
              const FafoDisplay('What’s the plan?'),
              const SizedBox(height: 10),
              if (quest == null) ...[
                TextField(
                  controller: _title,
                  maxLength: _titleMax,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTypography.ui(17, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: 'Coffee downstairs?',
                    hintStyle: AppTypography.ui(17, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                    counterText: '',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.rule, width: 2)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.rule, width: 2)),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accentPrimary, width: 2)),
                  ),
                ),
                if (length >= _counterFrom)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '$length/$_titleMax',
                        style: AppTypography.label(fontSize: 11, color: AppColors.textSecondary).copyWith(letterSpacing: 0),
                      ),
                    ),
                  ),
              ] else ...[
                // Side quests go out as written: the title is locked.
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.rule, width: 2)),
                  ),
                  child: Text(quest.title, style: AppTypography.ui(17, fontWeight: FontWeight.w700)),
                ),
                if (quest.description != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    quest.description!,
                    style: AppTypography.ui(14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
                  ),
                ],
              ],
              const SizedBox(height: 26),
              const FafoEyebrow('Invite', fontSize: 10.5),
              const SizedBox(height: 12),
              _InviteGrid(
                picks: picks,
                loading: (friends.isLoading || groups.isLoading) && picks.isEmpty,
                selected: _target,
                onPick: (t) => setState(() => _target = t),
                onShowAll: () => _showAll(picks),
                onAddFriends: _addFriends,
              ),
              const SizedBox(height: 26),
              const FafoEyebrow('Countdown after yes', fontSize: 10.5),
              const SizedBox(height: 12),
              FafoChipGrid(
                children: [
                  for (final m in const [5, 10, 15])
                    FafoChip(
                      selected: countdown == m,
                      onTap: () => setState(() => _countdown = m),
                      child: Text('$m min', style: AppTypography.ui(15, fontWeight: FontWeight.w700, color: countdown == m ? AppColors.onAccent : AppColors.textPrimary)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One choice in the Invite grid: a friend or a group.
class _Pick {
  const _Pick({required this.target, required this.people, required this.enabled, this.offLabel, this.free = false});

  final _Target target;

  /// One person for a friend, the members for a group.
  final List<(String, String?)> people;
  final bool enabled;
  final String? offLabel;
  final bool free;

  bool get isGroup => target.feedType == NudgeFeedType.group;
}

/// Free friends first, then by the last plan between you; groups after.
List<_Pick> _picks(List<FriendResponse> friends, List<GroupResponse> groups, _QuestInfo? quest, String? myUid) {
  final ordered = friendsByRecentNudge(friends);
  final byFree = [...ordered.where((f) => f.user.freeNow), ...ordered.where((f) => !f.user.freeNow)];
  return [
    for (final f in byFree)
      _Pick(
        target: _Target.friend(f.user.uid, _firstName(f.user.displayName)),
        people: [(f.user.displayName, f.user.photoUrl)],
        // Friends who turned off side quest invites can't be picked for one.
        enabled: quest == null || f.user.sideQuestInvites,
        offLabel: quest != null && !f.user.sideQuestInvites ? 'Quests off' : null,
        free: f.user.freeNow,
      ),
    for (final g in groups)
      _Pick(
        target: _Target.group(g.id, g.name),
        // Everyone but you.
        people: [for (final m in g.members) if (m.user.uid != myUid) (m.user.displayName, m.user.photoUrl)],
        enabled: true,
      ),
  ];
}

/// Eight picks and "Show all", three to a row. The selected pick always shows.
class _InviteGrid extends StatelessWidget {
  const _InviteGrid({
    required this.picks,
    required this.loading,
    required this.selected,
    required this.onPick,
    required this.onShowAll,
    required this.onAddFriends,
  });

  final List<_Pick> picks;
  final bool loading;
  final _Target? selected;
  final ValueChanged<_Target> onPick;
  final VoidCallback onShowAll;
  final VoidCallback onAddFriends;

  static const _shown = 8;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (picks.isEmpty) return _NoFriends(onAddFriends: onAddFriends);
    var shown = picks;
    final overflow = picks.length > _shown + 1;
    if (overflow) {
      final sel = selected;
      final selIndex = sel == null ? -1 : picks.indexWhere((p) => sel.matches(p.target.feedType, p.target.id));
      shown = picks.take(_shown).toList();
      if (selIndex >= _shown) shown = [picks[selIndex], ...picks.take(_shown - 1)];
    }
    return FafoChipGrid(
      children: [
        for (final p in shown)
          _PickChip(
            pick: p,
            selected: selected?.matches(p.target.feedType, p.target.id) ?? false,
            onTap: () => onPick(p.target),
          ),
        if (overflow)
          FafoChip(
            selected: false,
            minHeight: 72,
            semanticLabel: 'Show all',
            onTap: onShowAll,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.grid_view_rounded, size: 18, color: AppColors.textSecondary),
                const SizedBox(height: 6),
                Text(
                  'Show all',
                  style: AppTypography.ui(12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PickChip extends StatelessWidget {
  const _PickChip({required this.pick, required this.selected, required this.onTap});

  final _Pick pick;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ring = selected ? AppColors.accentPrimary : AppColors.surface;
    return FafoChip(
      selected: selected,
      enabled: pick.enabled,
      minHeight: 72,
      semanticLabel: pick.target.name,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pick.isGroup)
            FafoAvatarStack(people: pick.people, dimension: 26, ring: ring)
          else
            FafoAvatar(name: pick.people.first.$1, photoUrl: pick.people.first.$2),
          const SizedBox(height: 6),
          Text(
            pick.target.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.ui(
              12.5,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.onAccent : AppColors.textPrimary,
            ),
          ),
          if (pick.offLabel != null)
            Text(
              pick.offLabel!.toUpperCase(),
              style: AppTypography.label(fontSize: 9, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }
}

/// No friends yet: a dashed box pointing at Add friends.
class _NoFriends extends StatelessWidget {
  const _NoFriends({required this.onAddFriends});

  final VoidCallback onAddFriends;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorder(color: AppColors.softLine, radius: AppChrome.chipRadius + 3),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add a friend first', style: AppTypography.ui(15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'Plans need someone on the other end.',
              style: AppTypography.ui(13.5, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
            ),
            FafoInlineLink(label: 'Add friends', onTap: onAddFriends),
          ],
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorder old) => old.color != color;
}

/// Everyone you can invite, as a single-select list.
class _ShowAllSheet extends StatefulWidget {
  const _ShowAllSheet({required this.picks, required this.selected});

  final List<_Pick> picks;
  final _Target? selected;

  @override
  State<_ShowAllSheet> createState() => _ShowAllSheetState();
}

class _ShowAllSheetState extends State<_ShowAllSheet> {
  final _search = TextEditingController();
  late _Target? _selected = widget.selected;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final shown = [for (final p in widget.picks) if (q.isEmpty || p.target.name.toLowerCase().contains(q)) p];
    final people = shown.where((p) => !p.isGroup).toList();
    final groups = shown.where((p) => p.isGroup).toList();
    Widget row(_Pick p) {
      final selected = _selected?.matches(p.target.feedType, p.target.id) ?? false;
      return FafoCheckRow(
        title: p.target.name,
        subtitle: p.isGroup ? '${p.people.length} members' : p.offLabel,
        leading: p.isGroup
            ? FafoAvatarStack(people: p.people, dimension: 32)
            : FafoAvatar(name: p.people.first.$1, photoUrl: p.people.first.$2, size: FafoAvatarSize.md, free: p.free),
        checked: selected,
        onTap: p.enabled ? () => setState(() => _selected = p.target) : null,
      );
    }

    return FafoSheetBody(
      tall: true,
      footer: FafoPill(
        label: 'Done',
        block: true,
        onPressed: _selected == null ? null : () => Navigator.of(context).pop(_selected),
      ),
      children: [
        FafoSearchField(controller: _search),
        if (people.isNotEmpty) ...[
          const FafoSectionLabel('Friends', top: 22, bottom: 4),
          for (final p in people) row(p),
        ],
        if (groups.isNotEmpty) ...[
          const FafoSectionLabel('Groups', top: 22, bottom: 4),
          for (final p in groups) row(p),
        ],
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Text(
              'No one called “${_search.text.trim()}”.',
              style: AppTypography.ui(14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}

String _firstName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'friend';
  return trimmed.split(RegExp(r'\s+')).first;
}

/// What the composer needs to know about a side quest.
class _QuestInfo {
  const _QuestInfo(this.id, this.title, this.description, this.difficulty);

  final String id;
  final String title;
  final String? description;
  final String? difficulty;
}
