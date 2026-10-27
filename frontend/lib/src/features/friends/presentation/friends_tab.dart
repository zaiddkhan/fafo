import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/theme/app_chrome.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/features/friends/data/friends_providers.dart';
import 'package:fafu/src/features/friends/data/friends_repository.dart';
import 'package:fafu/src/features/friends/domain/friend.dart';
import 'package:fafu/src/features/friends/presentation/friends_page.dart';
import 'package:fafu/src/features/right_now/data/right_now_providers.dart';
import 'package:fafu/src/features/right_now/presentation/code_sheet.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';

final _myCodeProvider = FutureProvider.autoDispose<ReferralCode>(
  (ref) => ref.watch(friendsRepositoryProvider).getReferralCode(),
);

/// Friends tab: requests, who's free right now, everyone else, and your code.
/// Free friends get the primary Nudge; the rest get the outline one, so the
/// screen reads "these people can go now". Tap a row for the friend's sheet
/// (nudge, unfriend, block). Adding friends goes through codes (brief 3.8).
class FriendsTab extends ConsumerStatefulWidget {
  const FriendsTab({super.key, required this.onNudge});

  /// Opens the composer for [friend]; the shell handles what happens after.
  final ValueChanged<PublicUserResponse> onNudge;

  @override
  ConsumerState<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends ConsumerState<FriendsTab> {
  final _search = TextEditingController();

  /// The search field only shows once the list is long enough to need it.
  static const _searchFrom = 8;

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
    final friends = ref.watch(liveFriendsProvider);
    final requests = ref.watch(incomingFriendRequestsProvider);
    final all = friends.value ?? const <FriendResponse>[];
    final query = _search.text.trim().toLowerCase();
    final shown = [
      for (final f in friendsByRecentNudge(all))
        if (query.isEmpty ||
            f.user.displayName.toLowerCase().contains(query) ||
            f.user.username.toLowerCase().contains(query))
          f,
    ];
    final free = [for (final f in shown) if (f.user.freeNow) f];
    final rest = [for (final f in shown) if (!f.user.freeNow) f];
    final pending = requests.value ?? const <FriendRequestResponse>[];
    final freeCount = all.where((f) => f.user.freeNow).length;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(incomingFriendRequestsProvider);
            await ref.read(liveFriendsProvider.notifier).refresh();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
            children: [
              Row(
                children: [
                  const Expanded(child: FafoEyebrow('Friends')),
                  FafoRoundButton(
                    icon: Icons.person_add_alt,
                    label: 'Add friends',
                    onTap: () => showCodeSheet(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const FafoDisplay('Your people', fontSize: 52),
              const SizedBox(height: 6),
              Text(
                all.isEmpty
                    ? 'Nobody here yet.'
                    : '${all.length} ${all.length == 1 ? 'friend' : 'friends'}'
                          '${freeCount > 0 ? ', $freeCount free right now' : ''}.',
                style: AppTypography.ui(15, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
              ),
              if (all.length >= _searchFrom) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  style: AppTypography.ui(16, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Find a friend',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                    prefixIconConstraints: const BoxConstraints(minWidth: 28),
                  ),
                ),
              ],
              if (pending.isNotEmpty) ...[
                const SizedBox(height: 26),
                _RequestsCard(requests: pending),
              ],
              const SizedBox(height: 26),
              if (friends.isLoading && all.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (friends.hasError && all.isEmpty)
                Text(friendlyErrorMessage(friends.error), style: AppTypography.ui(13.5, color: AppColors.signalRed))
              else if (all.isNotEmpty && shown.isEmpty)
                Text(
                  'No one called "${_search.text.trim()}".',
                  style: AppTypography.ui(14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
                )
              else ...[
                if (free.isNotEmpty) ...[
                  _Section(label: 'Free right now', count: free.length, live: true),
                  for (final f in free) _FriendRow(friend: f, onNudge: () => widget.onNudge(f.user)),
                  const SizedBox(height: 26),
                ],
                if (rest.isNotEmpty) ...[
                  _Section(label: free.isEmpty ? 'Everyone' : 'Everyone else', count: rest.length),
                  for (final f in rest) _FriendRow(friend: f, onNudge: () => widget.onNudge(f.user)),
                  const SizedBox(height: 26),
                ],
              ],
              const _CodeCard(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mono label with a count, 2px rule above. [live] adds the blue dot.
class _Section extends StatelessWidget {
  const _Section({required this.label, required this.count, this.live = false});

  final String label;
  final int count;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.rule, width: 2)),
      ),
      child: Row(
        children: [
          if (live) ...[
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: AppColors.accentPrimary, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(child: FafoEyebrow(label, fontSize: 11)),
          FafoEyebrow('$count', fontSize: 11, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({required this.friend, required this.onNudge});

  final FriendResponse friend;
  final VoidCallback onNudge;

  @override
  Widget build(BuildContext context) {
    final user = friend.user;
    return InkWell(
      onTap: () => _showFriendSheet(context, friend, onNudge),
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.hairline)),
        ),
        child: Row(
          children: [
            FafoAvatar(name: user.displayName, size: FafoAvatarSize.md, photoUrl: user.photoUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.ui(15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _statusLine(friend),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.ui(
                      12.5,
                      fontWeight: user.freeNow ? FontWeight.w700 : FontWeight.w400,
                      color: user.freeNow ? AppColors.accentPrimary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FafoPill(label: 'Nudge', small: true, primary: user.freeNow, height: 38, onPressed: onNudge),
          ],
        ),
      ),
    );
  }
}

/// "Free rn", else the last plan between you, else the handle.
String _statusLine(FriendResponse friend) {
  if (friend.user.freeNow) return 'Free rn';
  final nudge = friend.lastNudge;
  if (nudge == null) return '@${friend.user.username}';
  final who = nudge.direction == NudgeDirection.received ? 'From them' : 'You sent';
  return '$who: ${nudge.title} · ${relativeSince(nudge.createdAt)}';
}

/// Incoming requests in one outlined card, so they read as "needs an answer".
class _RequestsCard extends StatelessWidget {
  const _RequestsCard({required this.requests});

  final List<FriendRequestResponse> requests;

  @override
  Widget build(BuildContext context) {
    return FafoCard(
      stripLeft: 'Wants to add you',
      stripRight: '${requests.length}',
      zones: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < requests.length; i++)
                _RequestRow(request: requests[i], last: i == requests.length - 1),
            ],
          ),
        ),
      ],
    );
  }
}

class _RequestRow extends ConsumerStatefulWidget {
  const _RequestRow({required this.request, required this.last});

  final FriendRequestResponse request;
  final bool last;

  @override
  ConsumerState<_RequestRow> createState() => _RequestRowState();
}

class _RequestRowState extends ConsumerState<_RequestRow> {
  bool _busy = false;

  Future<void> _answer(bool accept) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(friendsRepositoryProvider);
      if (accept) {
        await repo.acceptRequest(widget.request.id);
      } else {
        await repo.declineRequest(widget.request.id);
      }
      ref.invalidate(incomingFriendRequestsProvider);
      if (accept) await ref.read(liveFriendsProvider.notifier).refresh();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.request.requester;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: widget.last ? null : Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          FafoAvatar(name: user.displayName, size: FafoAvatarSize.md, photoUrl: user.photoUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.ui(15, fontWeight: FontWeight.w600),
                ),
                Text(
                  '@${user.username}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.ui(12.5, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FafoPill(label: 'Add', small: true, height: 38, busy: _busy, onPressed: () => _answer(true)),
          const SizedBox(width: 8),
          FafoPill(
            label: 'No',
            small: true,
            primary: false,
            height: 38,
            onPressed: _busy ? null : () => _answer(false),
          ),
        ],
      ),
    );
  }
}

/// Your code at the foot of the list: the one way to add people.
class _CodeCard extends ConsumerWidget {
  const _CodeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(_myCodeProvider).value;
    return FafoCard(
      stripLeft: 'Add friends',
      stripRight: 'Your code',
      zones: [
        FafoZone(
          gap: 12,
          children: [
            FafoDisplay(code?.code ?? '·····', fontSize: 44),
            Text(
              'Whoever signs up with your code shows up here, and you show up for them.',
              style: AppTypography.ui(14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                FafoPill(
                  label: 'Share code',
                  small: true,
                  height: 44,
                  onPressed: code == null
                      ? null
                      : () => SharePlus.instance.share(
                          ShareParams(text: 'Add me on FaFo. My code: ${code.code}\n${code.shareUrl}'),
                        ),
                ),
                const SizedBox(width: 14),
                FafoInlineLink(label: 'Have a code?', onTap: () => showCodeSheet(context)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// A friend's sheet: who they are, Nudge, and the rarer Unfriend / Block.
Future<void> _showFriendSheet(BuildContext context, FriendResponse friend, VoidCallback onNudge) {
  return showFafoSheet<void>(
    context,
    builder: (sheetContext) => _FriendSheet(
      friend: friend,
      onNudge: () {
        Navigator.of(sheetContext).pop();
        onNudge();
      },
    ),
  );
}

class _FriendSheet extends ConsumerStatefulWidget {
  const _FriendSheet({required this.friend, required this.onNudge});

  final FriendResponse friend;
  final VoidCallback onNudge;

  @override
  ConsumerState<_FriendSheet> createState() => _FriendSheetState();
}

class _FriendSheetState extends ConsumerState<_FriendSheet> {
  bool _busy = false;

  Future<void> _remove({required bool block}) async {
    final user = widget.friend.user;
    final answers = await showDialog<List<String>>(
      context: context,
      builder: (_) => NegativeAnswersDialog(title: '${block ? 'Block' : 'Unfriend'} ${user.displayName}?'),
    );
    if (answers == null || !mounted) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final repo = ref.read(friendsRepositoryProvider);
      if (block) {
        await repo.blockUser(user.uid, answers: answers);
      } else {
        await repo.unfriend(user.uid, answers: answers);
      }
      await ref.read(liveFriendsProvider.notifier).refresh();
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(block ? '${user.displayName} is blocked.' : '${user.displayName} is no longer a friend.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final friend = widget.friend;
    final user = friend.user;
    final nudge = friend.lastNudge;
    return FafoSheetBody(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 44),
          child: FafoEyebrow(user.freeNow ? 'Free right now' : 'Friend'),
        ),
        Row(
          children: [
            FafoAvatar(name: user.displayName, size: FafoAvatarSize.lg, photoUrl: user.photoUrl),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FafoDisplay(user.displayName, fontSize: 40, maxLines: 2),
                  const SizedBox(height: 4),
                  Text(
                    '@${user.username}',
                    style: AppTypography.ui(15, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppChrome.rowRadius),
            border: Border.all(color: AppColors.border, width: AppChrome.outlineWidth),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FafoEyebrow('Last plan', fontSize: 10.5),
              const SizedBox(height: 8),
              Text(
                nudge == null ? 'Nothing yet. Be the first.' : nudge.title,
                style: AppTypography.ui(16, fontWeight: FontWeight.w700),
              ),
              if (nudge != null) ...[
                const SizedBox(height: 2),
                Text(
                  '${nudge.direction == NudgeDirection.received ? 'From them' : 'You sent it'}, '
                  '${relativeSince(nudge.createdAt)}',
                  style: AppTypography.ui(13, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Friends since ${_monthYear(friend.friendsSince)}',
                style: AppTypography.ui(13, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        FafoPill(label: 'Nudge ${_firstName(user.displayName)}', block: true, onPressed: _busy ? null : widget.onNudge),
        Row(
          children: [
            FafoInlineLink(label: 'Unfriend', onTap: _busy ? null : () => _remove(block: false)),
            const SizedBox(width: 22),
            FafoInlineLink(
              label: 'Block',
              color: AppColors.signalRed,
              onTap: _busy ? null : () => _remove(block: true),
            ),
          ],
        ),
      ],
    );
  }
}

String _firstName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'them';
  return trimmed.split(RegExp(r'\s+')).first;
}

String _monthYear(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[d.toLocal().month - 1]} ${d.toLocal().year}';
}
