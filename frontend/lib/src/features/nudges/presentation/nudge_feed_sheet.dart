import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/nudges/data/nudges_providers.dart';
import 'package:fafu/src/features/nudges/data/nudges_repository.dart';
import 'package:fafu/src/features/nudges/domain/nudge.dart';
import 'package:fafu/src/features/nudges/presentation/create_nudge_page.dart';

class NudgeFeedSheet extends ConsumerStatefulWidget {
  const NudgeFeedSheet({
    required this.feedType,
    required this.targetId,
    required this.title,
    this.photoUrl,
    this.online = false,
    super.key,
  });

  final NudgeFeedType feedType;
  final String targetId;
  final String title;
  final String? photoUrl;
  final bool online;

  @override
  ConsumerState<NudgeFeedSheet> createState() => _NudgeFeedSheetState();
}

class _NudgeFeedSheetState extends ConsumerState<NudgeFeedSheet> {
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  NudgeFeedKey get _key => NudgeFeedKey(widget.feedType, widget.targetId);

  Future<void> _createNudge(List<NudgeResponse> nudges) async {
    if (nudges.any((n) => !n.isResolved)) {
      _messengerKey.currentState
        ?..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Resolve the active nudge first.')),
        );
      return;
    }

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateNudgePage(
          feedType: widget.feedType,
          targetId: widget.targetId,
          accent: _activePalette().primary,
        ),
      ),
    );

    if (created == true) ref.invalidate(nudgeFeedProvider(_key));
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(nudgeFeedProvider(_key));
    final palette = _activePalette();

    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Material(
      color: AppColors.bgPrimary,
      child: SafeArea(
        child: Column(
          children: [
            _NudgeHeader(
              title: widget.title,
              photoUrl: widget.photoUrl,
              online: widget.online,
              accent: palette.primary,
            ),
            Divider(height: 1, color: AppColors.border),
            Expanded(
              child: feed.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary)),
                error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(e.toString(), style: TextStyle(color: AppColors.textPrimary)))),
                data: (items) {
                  final ordered = [...items]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
                  if (ordered.isEmpty) {
                    return Center(child: Text('No nudges yet. Tap + Nudge to start.', style: TextStyle(color: AppColors.textPrimary)));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                    itemCount: ordered.length,
                    itemBuilder: (context, index) => _NudgeBubble(
                      nudge: ordered[index],
                      friendName: widget.title,
                      palette: palette,
                      onChanged: () => ref.invalidate(nudgeFeedProvider(_key)),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
              child: feed.maybeWhen(
                data: (items) => SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _createNudge(items),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nudge', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                orElse: () => const SizedBox(height: 46),
              ),
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }
}

class _NudgeHeader extends StatelessWidget {
  const _NudgeHeader({required this.title, required this.accent, this.photoUrl, this.online = false});

  final String title;
  final String? photoUrl;
  final bool online;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: Row(
        children: [
          IconButton(icon: Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => Navigator.of(context).pop()),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(6),
                  image: photoUrl == null ? null : DecorationImage(image: NetworkImage(photoUrl!), fit: BoxFit.cover),
                  color: AppColors.surface,
                ),
                child: photoUrl == null ? Center(child: Text('☕', style: TextStyle(fontSize: 18, color: AppColors.textPrimary))) : null,
              ),
              if (online)
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ED164),
                      border: Border.all(color: AppColors.bgPrimary, width: 1.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(color: accent, fontSize: 24),
            ),
          ),
        ],
      ),
    );
  }
}

class _NudgeBubble extends ConsumerWidget {
  const _NudgeBubble({required this.nudge, required this.friendName, required this.palette, required this.onChanged});

  final NudgeResponse nudge;
  final String friendName;
  final _NudgePalette palette;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final isMine = nudge.senderUid == myUid;
    final remaining = nudge.expiresAt.difference(DateTime.now());
    final seconds = remaining.inSeconds.clamp(0, 99999);
    final timerLabel = '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    final createdDate = DateFormat('EEE, MMM d').format(nudge.createdAt.toLocal());
    final createdTime = DateFormat('h:mm a').format(nudge.createdAt.toLocal());
    final isExpired = nudge.status == NudgeStatus.expired;
    final isAccepted = nudge.status == NudgeStatus.acceptedTimer || (nudge.isResolved && nudge.yesCount > 0);
    final canVote = !isMine && !nudge.isResolved && !nudge.votes.containsKey(myUid);
    final used = nudge.reminderCount;
    final total = nudge.reminderLimit;
    final canRemind = isMine && !nudge.isResolved && total > used && (nudge.nextReminderAvailableAt == null || !DateTime.now().isBefore(nudge.nextReminderAvailableAt!));

    return Padding(
      padding: EdgeInsets.only(bottom: 18, left: isMine ? 82 : 0, right: isMine ? 0 : 82),
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 3, right: 3),
            child: Text(
              isMine ? 'You' : friendName,
              style: TextStyle(color: palette.primary, fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
          Opacity(
            opacity: isExpired ? 0.55 : 1,
            child: GestureDetector(
              onTap: () => _showDetails(context, timerLabel),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Transform.translate(
                      offset: const Offset(4, 4),
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(7)),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border, width: 1.2),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black45),
                                borderRadius: BorderRadius.circular(4),
                                color: palette.soft,
                              ),
                              child: const Center(child: Text('👉', style: TextStyle(fontSize: 18))),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nudge.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(createdDate, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                      ),
                                      Text(createdTime, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (canVote)
                          Row(
                            children: [
                              Text('Attending?', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _VoteToggle(
                                  yesColor: palette.yes,
                                  noColor: palette.no,
                                  onYes: () async {
                                    await ref.read(nudgesRepositoryProvider).respond(nudge.id, NudgeVote.yes);
                                    onChanged();
                                  },
                                  onNo: () async {
                                    await ref.read(nudgesRepositoryProvider).respond(nudge.id, NudgeVote.no);
                                    onChanged();
                                  },
                                ),
                              ),
                            ],
                          )
                        else if (isMine && !nudge.isResolved && total > 0)
                          SizedBox(
                            width: double.infinity,
                            height: 28,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor: canRemind ? palette.primary : const Color(0xFFCFCFCF),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              onPressed: canRemind
                                  ? () async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      try {
                                        await ref.read(nudgesRepositoryProvider).remind(nudge.id);
                                        messenger.showSnackBar(
                                          const SnackBar(content: Text('Reminder sent')),
                                        );
                                      } catch (e) {
                                        messenger.showSnackBar(
                                          SnackBar(content: Text(e.toString())),
                                        );
                                      }
                                      onChanged();
                                    }
                                  : null,
                              child: Text('Send Reminder (${total - used}/$total)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                            ),
                          )
                        else
                          _StateBar(
                            label: _stateLabel(timerLabel, isAccepted),
                            color: isAccepted ? Colors.red : const Color(0xFFBDBDBD),
                          ),
                        if (nudge.expectedVoterCount > 1) ...[
                          const SizedBox(height: 7),
                          Text('${nudge.yesCount}/${nudge.expectedVoterCount} in', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _stateLabel(String timerLabel, bool isAccepted) {
    if (nudge.status == NudgeStatus.expired) return 'Expired';
    if (isAccepted && !nudge.isResolved) return 'Accepted • $timerLabel';
    if (isAccepted) return 'Accepted';
    if (nudge.isResolved) return 'Resolved';
    return timerLabel;
  }

  void _showDetails(BuildContext context, String timerLabel) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final isMine = nudge.senderUid == myUid;
    final isAccepted = nudge.status == NudgeStatus.acceptedTimer ||
        (nudge.isResolved && nudge.yesCount > 0);
    final location = nudge.location?.trim() ?? '';
    final hasLocation = location.isNotEmpty;
    final isLink = location.startsWith('http://') || location.startsWith('https://');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.bgPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final bottom = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(18, 4, 18, 18 + bottom),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: palette.soft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 1.2),
                      ),
                      child: const Center(child: Text('👉', style: TextStyle(fontSize: 22))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nudge.title,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isMine ? 'Sent by you' : 'From $friendName',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _NudgeDetailRow(icon: Icons.timer_outlined, label: 'Time left', value: _stateLabel(timerLabel, isAccepted)),
                if (nudge.expectedVoterCount > 1) ...[
                  const SizedBox(height: 10),
                  _NudgeDetailRow(icon: Icons.groups_outlined, label: 'Tally', value: '${nudge.yesCount}/${nudge.expectedVoterCount} in'),
                ],
                if (hasLocation) ...[
                  const SizedBox(height: 10),
                  _NudgeDetailRow(
                    icon: Icons.place_outlined,
                    label: 'Location',
                    value: isLink ? 'Map location shared' : location,
                  ),
                ],
                const SizedBox(height: 18),
                if (hasLocation && isLink)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('Open location'),
                      onPressed: () async {
                        final uri = Uri.tryParse(location);
                        if (uri != null) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NudgeDetailRow extends StatelessWidget {
  const _NudgeDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.accentPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoteToggle extends StatelessWidget {
  const _VoteToggle({required this.yesColor, required this.noColor, required this.onYes, required this.onNo});

  final Color yesColor;
  final Color noColor;
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF4C8DFF)),
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onYes,
              child: Container(
                color: yesColor,
                alignment: Alignment.center,
                child: const Text('YES', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onNo,
              child: Container(
                color: AppColors.surface,
                alignment: Alignment.center,
                child: Text('NO', style: TextStyle(color: noColor, fontSize: 9, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StateBar extends StatelessWidget {
  const _StateBar({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }
}

class _NudgePalette {
  const _NudgePalette({required this.primary, required this.soft, required this.yes, required this.no});
  final Color primary;
  final Color soft;
  final Color yes;
  final Color no;
}

_NudgePalette _activePalette() {
  // Keep the nudge flow on the app's primary brand color rather than a
  // rotating per-week accent, so it matches the rest of the app.
  return const _NudgePalette(
    primary: AppColors.accentPrimary,
    soft: AppColors.accentLightest,
    yes: Color(0xFF38A849),
    no: Color(0xFFE5484D),
  );
}
