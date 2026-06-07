import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
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

    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            _NudgeHeader(
              title: widget.title,
              photoUrl: widget.photoUrl,
              online: widget.online,
              accent: palette.primary,
            ),
            const Divider(height: 1, color: Color(0xFF111111)),
            Expanded(
              child: feed.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary)),
                error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(e.toString()))),
                data: (items) {
                  final ordered = [...items]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
                  if (ordered.isEmpty) {
                    return const Center(child: Text('No nudges yet. Tap + Nudge to start.'));
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
                      backgroundColor: AppColors.ink,
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
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.ink),
                  borderRadius: BorderRadius.circular(6),
                  image: photoUrl == null ? null : DecorationImage(image: NetworkImage(photoUrl!), fit: BoxFit.cover),
                  color: const Color(0xFFF5F5F5),
                ),
                child: photoUrl == null ? const Center(child: Text('☕', style: TextStyle(fontSize: 18))) : null,
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
                      border: Border.all(color: Colors.white, width: 1.5),
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
                      color: Colors.white,
                      border: Border.all(color: AppColors.ink, width: 1.2),
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
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.ink),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(createdDate, style: const TextStyle(fontSize: 10, color: Color(0xFF666666))),
                                      ),
                                      Text(createdTime, style: const TextStyle(fontSize: 10, color: Color(0xFF666666))),
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
                              const Text('Attending?', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
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
                                      await ref.read(nudgesRepositoryProvider).remind(nudge.id);
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
                          Text('${nudge.yesCount}/${nudge.expectedVoterCount} in', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
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
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nudge.title),
        content: Text([
          if (nudge.location?.isNotEmpty == true) 'Location: ${nudge.location}',
          'Remaining: $timerLabel',
          if (nudge.expectedVoterCount > 1) 'Tally: ${nudge.yesCount}/${nudge.expectedVoterCount} in',
        ].join('\n')),
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
                color: Colors.white,
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
      child: Text(label, style: const TextStyle(color: AppColors.ink, fontSize: 10, fontWeight: FontWeight.w900)),
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
  final week = ((DateTime.now().day - 1) ~/ 7) % 4;
  return switch (week) {
    0 => const _NudgePalette(primary: Color(0xFF3F86D9), soft: Color(0xFFEAF3FF), yes: Color(0xFF38A849), no: Color(0xFFE5484D)),
    1 => const _NudgePalette(primary: Color(0xFF7A67F8), soft: Color(0xFFF0EDFF), yes: Color(0xFF16A085), no: Color(0xFFD35400)),
    2 => const _NudgePalette(primary: Color(0xFFFF8A00), soft: Color(0xFFFFF1DA), yes: Color(0xFF5B7C00), no: Color(0xFFC0392B)),
    _ => const _NudgePalette(primary: Color(0xFF16A085), soft: Color(0xFFE7F8F3), yes: Color(0xFF1472B8), no: Color(0xFFE5484D)),
  };
}
