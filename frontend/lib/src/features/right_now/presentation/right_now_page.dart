import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:fafu/src/features/nudges/presentation/plan_detail_sheet.dart';
import 'package:fafu/src/features/friends/presentation/friends_tab.dart';
import 'package:fafu/src/features/home/presentation/main_shell.dart';
import 'package:fafu/src/features/groups/data/groups_repository.dart';
import 'package:fafu/src/features/groups/domain/group.dart';
import 'package:fafu/src/features/groups/presentation/group_sheet.dart';
import 'package:fafu/src/features/quests/domain/quest.dart';
import 'package:fafu/src/features/right_now/data/home_focus.dart';
import 'package:fafu/src/features/right_now/data/right_now_providers.dart';
import 'package:fafu/src/features/right_now/presentation/preview_sheet.dart';
import 'package:fafu/src/features/users/data/users_repository.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_toast.dart';

/// Home: the free pill, the live plan card (or the empty state), "Send an
/// invite" once nothing is live, and Recent. Sits under the shell's header
/// and floating menu; everything else opens as a sheet.
class RightNowPage extends ConsumerStatefulWidget {
  const RightNowPage({super.key, this.showProfileLink = false});

  /// Kept for the parked single-screen layout; the Profile tab replaces it.
  final bool showProfileLink;

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
          if (group == null || !mounted) return;
          final result = await showGroupSheet(context, group: group);
          if (!mounted) return;
          switch (result) {
            case GroupSendNudge(:final group):
              await _compose(group: group);
            case GroupSendAgain(:final nudge):
              await _compose(again: nudge);
            case GroupOpenFriend(:final user):
              final friend = await showFriendSheet(context, user: user);
              if (!mounted) return;
              switch (friend) {
                case FriendSendNudge():
                  await _compose(friend: user);
                case FriendSendAgain(:final nudge):
                  await _compose(again: nudge);
                case null:
                  break;
              }
            case null:
              break;
          }
        } catch (_) {}
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the background: catch up on answers immediately.
    if (state == AppLifecycleState.resumed) {
      ref.read(currentProfileProvider.notifier).retryIfFailed();
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
      ScaffoldMessenger.of(context).toastError(e);
    } finally {
      if (mounted) setState(() => _freeBusy = false);
    }
  }

  Future<void> _compose({
    QuestResponse? quest,
    NudgeResponse? again,
    PublicUserResponse? friend,
    GroupResponse? group,
  }) async {
    final nudge = await showComposeNudgeSheet(
      context,
      quest: quest,
      again: again,
      friend: friend,
      group: group,
      onAddFriends: () {
        ref.read(mainShellTabProvider.notifier).setTab(1);
        showAddFriendsSheet(context);
      },
    );
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
        ScaffoldMessenger.of(context).toastError(e);
      }
      ref.read(myNudgesProvider.notifier).refresh();
    } finally {
      if (mounted) setState(() => _answering.remove(nudge.id));
    }
  }

  Future<void> _cancel(NudgeResponse nudge) async {
    final who = nudge.targetName ?? (nudge.isGroup ? 'your group' : 'your friend');
    final sure = await showFafoConfirm(
      context,
      title: 'Cancel this plan?',
      message: nudge.isAccepted
          ? '$who already said yes. They’ll get a heads-up that it’s off.'
          : '“${nudge.title}” goes away for $who. You can send a new one straight after.',
      confirmLabel: 'Cancel plan',
      cancelLabel: 'Keep it',
    );
    if (!sure || !mounted) return;
    try {
      final updated = await ref.read(nudgesRepositoryProvider).cancel(nudge.id);
      ref.read(myNudgesProvider.notifier).upsert(updated);
      ref.read(pushServiceProvider).liveNudges.cancel(nudge.id);
      FafoToasts.show('Plan cancelled.');
    } catch (e) {
      FafoToasts.error(e);
      ref.read(myNudgesProvider.notifier).refresh();
    }
  }

  Future<void> _openRecent(NudgeView view, String handle) async {
    final again = await showPlanDetailSheet(context, view);
    if (again != null && mounted) await _compose(again: again);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    final nudges = ref.watch(myNudgesProvider);
    final friends = ref.watch(liveFriendsProvider).value ?? const <FriendResponse>[];
    // Fall back to the signed-in account so a profile that hasn't loaded
    // can't hide which answers are yours.
    final myUid = profile?.uid ?? _signedInUid() ?? '';
    final handle = profile?.username ?? 'you';
    final free = _freeOverride ?? profile?.freeNow ?? false;
    final freeFriends = friends.where((f) => f.user.freeNow).toList();

    return RefreshIndicator(
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
          ]..sort((a, b) => b.nudge.createdAt.compareTo(a.nudge.createdAt));
          _playTimerSounds(views, now);
          final live = views.where((v) => v.isInLiveArea(now)).toList()
            // Something waiting on my answer goes first.
            ..sort((a, b) {
              final ap = !a.isSender && a.state(now) == NudgeCardState.pending ? 0 : 1;
              final bp = !b.isSender && b.state(now) == NudgeCardState.pending ? 0 : 1;
              return ap.compareTo(bp);
            });
          // "Send an invite" steps aside while a plan is running and comes
          // back once it ends.
          final running = live.any((v) {
            final st = v.state(now);
            return st == NudgeCardState.pending || st == NudgeCardState.accepted;
          });
          return ListView(
            padding: EdgeInsets.fromLTRB(20, 24, 20, FafoBottomNav.clearance(context)),
            children: [
              FafoFreePill(free: free, onTap: profile == null ? null : () => _toggleFree(free)),
              if (FeatureFlags.homeAlsoFree && freeFriends.isNotEmpty) _AlsoFree(freeFriends: freeFriends),
              Padding(
                padding: live.isEmpty
                    ? const EdgeInsets.only(top: 48, bottom: 36)
                    : const EdgeInsets.only(top: 40, bottom: 46),
                child: _LiveArea(
                  loading: nudges.isLoading && !nudges.hasValue,
                  error: nudges.hasError && !nudges.hasValue ? nudges.error : null,
                  onRetry: () => ref.invalidate(myNudgesProvider),
                  live: live,
                  handle: handle,
                  myName: profile?.displayName,
                  answering: _answering,
                  onAnswer: _answer,
                  onCancel: _cancel,
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
              if (!running)
                Padding(
                  padding: EdgeInsets.only(bottom: views.isEmpty ? 0 : 44),
                  child: FafoPill(label: 'Send an invite', block: true, onPressed: () => _compose()),
                ),
              if (views.isNotEmpty)
                _Recent(views: views, now: now, onOpen: (v) => _openRecent(v, handle)),
            ],
          );
        },
      ),
    );
  }
}

/// Parked (FeatureFlags.homeAlsoFree): free friends under the free pill. The
/// design shows them on Friends (Free now) instead.
class _AlsoFree extends StatelessWidget {
  const _AlsoFree({required this.freeFriends});

  final List<FriendResponse> freeFriends;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SingleChildScrollView(
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
    this.myName,
    required this.answering,
    required this.onAnswer,
    required this.onCancel,
    required this.onPreview,
  });

  final bool loading;
  final Object? error;
  final VoidCallback onRetry;
  final List<NudgeView> live;
  final String handle;
  final String? myName;
  final Set<String> answering;
  final void Function(NudgeResponse, NudgeVote) onAnswer;
  final void Function(NudgeResponse) onCancel;
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
              myName: myName,
              answering: answering.contains(live[i].nudge.id),
              onYes: () => onAnswer(live[i].nudge, NudgeVote.yes),
              onNo: () => onAnswer(live[i].nudge, NudgeVote.no),
              onCancel: () => onCancel(live[i].nudge),
            ),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FafoEyebrow('No plans pending'),
        const SizedBox(height: 14),
        const FafoDisplay('Skip the group chat.', fontSize: 62),
        const SizedBox(height: 16),
        Text(
          'Send one clear plan. Get one clear answer.',
          style: AppTypography.ui(16, fontWeight: FontWeight.w400),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            friendlyErrorMessage(error),
            style: AppTypography.ui(13, color: AppColors.errorText),
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

/// Every plan, newest first: Active while live, Expired once over.
class _Recent extends StatelessWidget {
  const _Recent({required this.views, required this.now, required this.onOpen});

  final List<NudgeView> views;
  final DateTime now;
  final ValueChanged<NudgeView> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Semantics(
            header: true,
            child: Text('Recent', style: AppTypography.ui(17, fontWeight: FontWeight.w500)),
          ),
        ),
        for (final v in views) PlanRow(view: v, now: now, onTap: () => onOpen(v)),
      ],
    );
  }
}

/// The signed-in Firebase account, or null when Firebase isn't set up
/// (widget tests) or nobody is signed in.
String? _signedInUid() {
  try {
    return FirebaseAuth.instance.currentUser?.uid;
  } catch (_) {
    return null;
  }
}
