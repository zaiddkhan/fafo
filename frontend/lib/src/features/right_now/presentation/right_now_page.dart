import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/config/feature_flags.dart';
import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/services/app_sounds.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/core/utils/server_clock.dart';
import 'package:fafu/src/features/friends/domain/friend.dart';
import 'package:fafu/src/features/notifications/data/push_service.dart';
import 'package:fafu/src/features/nudges/data/nudges_repository.dart';
import 'package:fafu/src/features/nudges/domain/nudge.dart';
import 'package:fafu/src/features/nudges/domain/nudge_view.dart';
import 'package:fafu/src/features/nudges/presentation/compose_nudge_sheet.dart';
import 'package:fafu/src/features/nudges/presentation/nudge_cards.dart';
import 'package:fafu/src/features/groups/data/groups_repository.dart';
import 'package:fafu/src/features/groups/presentation/group_sheet.dart';
import 'package:fafu/src/features/profile/presentation/profile_sheet.dart';
import 'package:fafu/src/features/quests/domain/quest.dart';
import 'package:fafu/src/features/right_now/data/home_focus.dart';
import 'package:fafu/src/features/right_now/data/right_now_providers.dart';
import 'package:fafu/src/features/right_now/presentation/code_sheet.dart';
import 'package:fafu/src/features/right_now/presentation/preview_sheet.dart';
import 'package:fafu/src/features/users/data/users_repository.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';

/// Home, "Right now" (V3 brief 3.1-3.9). The only screen: free status, friends
/// who are also free, the live nudge card (or the empty state), Recent, and a
/// sticky "Send an invite". Everything else opens as a sheet.
class RightNowPage extends ConsumerStatefulWidget {
  const RightNowPage({super.key});

  @override
  ConsumerState<RightNowPage> createState() => _RightNowPageState();
}

class _RightNowPageState extends ConsumerState<RightNowPage>
    with WidgetsBindingObserver {
  /// Last card state seen per live nudge, to play EXP once when a timer hits
  /// zero on screen.
  final Map<String, NudgeCardState> _seenStates = {};
  bool? _freeOverride;
  bool _freeBusy = false;
  final Set<String> _answering = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HomeFocus.request.addListener(_onFocusRequest);
    HomeFocus.refreshTick.addListener(_onRefreshTick);
    // A push tap that cold-started the app may have set a request already.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onFocusRequest());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HomeFocus.request.removeListener(_onFocusRequest);
    HomeFocus.refreshTick.removeListener(_onRefreshTick);
    super.dispose();
  }

  void _playTimerSounds(List<NudgeView> views, DateTime now) {
    var fire = false;
    for (final v in views) {
      final state = v.state(now);
      final before = _seenStates[v.nudge.id];
      final wasRunning = before == NudgeCardState.pending || before == NudgeCardState.accepted;
      final hitZero = state == NudgeCardState.expired || state == NudgeCardState.goTime;
      if (wasRunning && hitZero) fire = true;
      _seenStates[v.nudge.id] = state;
    }
    if (fire) {
      WidgetsBinding.instance.addPostFrameCallback((_) => AppSounds.play(FafoSound.timerDone));
    }
  }

  void _onRefreshTick() {
    if (mounted) ref.read(myNudgesProvider.notifier).refresh();
  }

  /// A notification tap: show that nudge's card (if it isn't already on home)
  /// or that group's sheet.
  Future<void> _onFocusRequest() async {
    final request = HomeFocus.request.value;
    if (request == null || !mounted) return;
    HomeFocus.request.value = null;
    // Close any sheet that's open so the target is on top.
    Navigator.of(context).popUntil((route) => route is! PopupRoute);
    switch (request) {
      case FocusNudge(:final nudgeId):
        try {
          final nudge = await ref.read(nudgesRepositoryProvider).get(nudgeId);
          ref.read(myNudgesProvider.notifier).upsert(nudge);
          final profile = ref.read(currentProfileProvider).value;
          if (!mounted || profile == null) return;
          final view = NudgeView(nudge, myUid: profile.uid);
          // Live cards are already on home; resolved ones open like Recent.
          if (!view.isInLiveArea(ServerClock.now())) _openRecent(view, profile.username);
        } catch (_) {
          ref.read(myNudgesProvider.notifier).refresh();
        }
      case FocusGroup(:final groupId):
        try {
          final groups = await ref.read(groupsRepositoryProvider).getGroups();
          final group = groups.where((g) => g.id == groupId).firstOrNull;
          if (group != null && mounted) await showGroupSheet(context, group: group);
        } catch (_) {}
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the background: catch up on answers immediately.
    if (state == AppLifecycleState.resumed) {
      ref.read(myNudgesProvider.notifier).refresh();
      ref.read(liveFriendsProvider.notifier).refresh();
    }
  }

  Future<void> _toggleFree(bool current) async {
    if (_freeBusy) return;
    final next = !current;
    if (next) AppSounds.play(FafoSound.free);
    setState(() {
      _freeOverride = next;
      _freeBusy = true;
    });
    try {
      final profile = await ref.read(usersRepositoryProvider).setFree(next);
      ref.read(currentProfileProvider.notifier).setProfile(profile);
      if (mounted) setState(() => _freeOverride = null);
    } catch (e) {
      if (!mounted) return;
      setState(() => _freeOverride = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _freeBusy = false);
    }
  }

  Future<void> _compose({QuestResponse? quest}) async {
    final nudge = await showComposeNudgeSheet(context, quest: quest);
    if (nudge == null) return;
    ref.read(myNudgesProvider.notifier).upsert(nudge);
    ref.read(pushServiceProvider).liveNudges.showSenderWaiting(nudge);
  }

  Future<void> _answer(NudgeResponse nudge, NudgeVote vote) async {
    if (_answering.contains(nudge.id)) return;
    AppSounds.play(FafoSound.answer);
    setState(() => _answering.add(nudge.id));
    try {
      final updated = await ref.read(nudgesRepositoryProvider).respond(nudge.id, vote);
      ref.read(myNudgesProvider.notifier).upsert(updated);
      // Answered: the red "you have 10 minutes" bar has done its job.
      ref.read(pushServiceProvider).liveNudges.cancel(nudge.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(e))),
        );
      }
      ref.read(myNudgesProvider.notifier).refresh();
    } finally {
      if (mounted) setState(() => _answering.remove(nudge.id));
    }
  }

  Future<void> _openProfile() async {
    // Invite on a side quest closes the profile and opens the composer.
    final quest = await showProfileSheet(context);
    if (quest != null && mounted) await _compose(quest: quest);
  }

  void _openRecent(NudgeView view, String handle) {
    showFafoSheet<void>(
      context,
      builder: (_) => FafoSheetBody(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 44),
            child: FafoEyebrow('Recent · ${view.outcomeLabel(ServerClock.now())}'),
          ),
          NudgeCard(view: view, myHandle: handle),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    final nudges = ref.watch(myNudgesProvider);
    final friends = ref.watch(liveFriendsProvider).value ?? const <FriendResponse>[];
    final myUid = profile?.uid ?? '';
    final handle = profile?.username ?? 'you';
    final free = _freeOverride ?? profile?.freeNow ?? false;
    final freeFriends = friends.where((f) => f.user.freeNow).toList();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  ref.read(myNudgesProvider.notifier).refresh(),
                  ref.read(liveFriendsProvider.notifier).refresh(),
                ]);
              },
              child: FafoTicker(
                builder: (context, now) {
                  final views = [
                    for (final n in nudges.value ?? const <NudgeResponse>[])
                      NudgeView(n, myUid: myUid),
                  ];
                  _playTimerSounds(views, now);
                  final live = views.where((v) => v.isInLiveArea(now)).toList()
                    // Something waiting on my answer goes first.
                    ..sort((a, b) {
                      final ap = !a.isSender && a.state(now) == NudgeCardState.pending ? 0 : 1;
                      final bp = !b.isSender && b.state(now) == NudgeCardState.pending ? 0 : 1;
                      return ap.compareTo(bp);
                    });
                  final recent = views.where((v) => !v.isInLiveArea(now)).toList();
                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      0,
                      20,
                      120 + MediaQuery.paddingOf(context).bottom,
                    ),
                    children: [
                      _Header(
                        onCode: () => showCodeSheet(context),
                        onProfile: _openProfile,
                      ),
                      _FreeBox(
                        free: free,
                        freeFriends: freeFriends,
                        onToggle: profile == null ? null : () => _toggleFree(free),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 34, bottom: 26),
                        child: _LiveArea(
                          loading: nudges.isLoading && !nudges.hasValue,
                          error: nudges.hasError && !nudges.hasValue ? nudges.error : null,
                          onRetry: () => ref.invalidate(myNudgesProvider),
                          live: live,
                          handle: handle,
                          answering: _answering,
                          onAnswer: _answer,
                          onPreview: () => showPreviewSheet(context),
                        ),
                      ),
                      if (FeatureFlags.previewBothSides && live.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 28),
                          child: FafoTextLink(
                            label: 'Preview both sides',
                            onTap: () => showPreviewSheet(context),
                          ),
                        ),
                      _Recent(
                        views: recent,
                        now: now,
                        onOpen: (v) => _openRecent(v, handle),
                      ),
                    ],
                  );
                },
              ),
            ),
            // Sticky primary action, above the safe area (brief 3.7).
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: AppColors.bgPrimary,
                padding: EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  14 + MediaQuery.paddingOf(context).bottom,
                ),
                child: FafoPill(
                  label: 'Send an invite',
                  block: true,
                  onPressed: () => _compose(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onCode, required this.onProfile});

  final VoidCallback onCode;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final linkStyle = AppTypography.ui(14, fontWeight: FontWeight.w600);
    return Container(
      padding: const EdgeInsets.only(top: 22, bottom: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.rule, width: 2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(child: FafoEyebrow('Right now')),
          InkWell(
            onTap: onCode,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text('Code', style: linkStyle),
            ),
          ),
          const SizedBox(width: 18),
          InkWell(
            onTap: onProfile,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text('Profile', style: linkStyle),
            ),
          ),
        ],
      ),
    );
  }
}

class _FreeBox extends StatelessWidget {
  const _FreeBox({
    required this.free,
    required this.freeFriends,
    required this.onToggle,
  });

  final bool free;
  final List<FriendResponse> freeFriends;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // "Receive one" is not shipped; the free pill takes the full row.
          FafoFreePill(free: free, onTap: onToggle),
          if (freeFriends.isNotEmpty) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in freeFriends) ...[
                    FafoAvatar(name: f.user.displayName, photoUrl: f.user.photoUrl),
                    const SizedBox(width: 6),
                    Text(
                      f.user.displayName.split(' ').first,
                      style: AppTypography.ui(12.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 14),
                  ],
                  FafoEyebrow('also free', fontSize: 10, color: AppColors.textSecondary),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LiveArea extends StatelessWidget {
  const _LiveArea({
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.live,
    required this.handle,
    required this.answering,
    required this.onAnswer,
    required this.onPreview,
  });

  final bool loading;
  final Object? error;
  final VoidCallback onRetry;
  final List<NudgeView> live;
  final String handle;
  final Set<String> answering;
  final void Function(NudgeResponse, NudgeVote) onAnswer;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (live.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < live.length; i++) ...[
            if (i > 0) const SizedBox(height: 22),
            NudgeCard(
              view: live[i],
              myHandle: handle,
              answering: answering.contains(live[i].nudge.id),
              onYes: () => onAnswer(live[i].nudge, NudgeVote.yes),
              onNo: () => onAnswer(live[i].nudge, NudgeVote.no),
            ),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FafoEyebrow('No plans pending'),
        const SizedBox(height: 12),
        const FafoDisplay('Skip the group chat.', fontSize: 62),
        const SizedBox(height: 12),
        Text(
          'Send one clear plan. Get one clear answer.',
          style: AppTypography.ui(15, fontWeight: FontWeight.w400),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            friendlyErrorMessage(error),
            style: AppTypography.ui(13, color: AppColors.signalRed),
          ),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
        // Demo-only (parked): the prototype used it to play both phones.
        if (FeatureFlags.previewBothSides) ...[
          const SizedBox(height: 14),
          FafoTextLink(label: 'Preview both sides', onTap: onPreview),
        ],
      ],
    );
  }
}

class _Recent extends StatelessWidget {
  const _Recent({required this.views, required this.now, required this.onOpen});

  final List<NudgeView> views;
  final DateTime now;
  final ValueChanged<NudgeView> onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.hairline)),
            ),
            child: Text('Recent', style: AppTypography.ui(17, fontWeight: FontWeight.w500)),
          ),
          if (views.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Answered and expired plans land here.',
                style: AppTypography.ui(13.5, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
              ),
            ),
          for (final v in views)
            FafoListRow(
              title: v.nudge.title,
              subtitle: [
                v.outcomeLabel(now),
                if (v.nudge.isGroup) v.targetName,
                if (v.nudge.isQuest) 'Side quest · ${FafoQuestTags.levelLabel(v.nudge.questDifficulty)}',
              ].join(' · '),
              onTap: () => onOpen(v),
            ),
        ],
      ),
    );
  }
}
