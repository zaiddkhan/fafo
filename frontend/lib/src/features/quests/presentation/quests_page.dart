import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/quests/data/quests_providers.dart';
import 'package:fafu/src/features/quests/data/quests_repository.dart';
import 'package:fafu/src/features/quests/domain/quest.dart';

class QuestsPage extends ConsumerStatefulWidget {
  const QuestsPage({super.key});

  @override
  ConsumerState<QuestsPage> createState() => _QuestsPageState();
}

/// How many quests to show before the user taps "View All".
const int _kQuestPreviewCount = 3;

class _QuestsPageState extends ConsumerState<QuestsPage> {
  final Set<String> _busyQuestIds = <String>{};

  /// Optimistic active-state overrides keyed by quest id. Lets the card flip
  /// instantly while the activate/abandon request is in flight, instead of
  /// waiting for the activations list to refetch. Cleared once the refetched
  /// server state is in sync (or reverted on error).
  final Map<String, bool> _optimisticActive = <String, bool>{};

  /// Whether the full quest list is revealed (vs. the short preview).
  bool _showAllQuests = false;

  Future<void> _run(
    String questId, {
    required bool activate,
    required Future<void> Function() action,
  }) async {
    if (_busyQuestIds.contains(questId)) return;
    setState(() {
      _busyQuestIds.add(questId);
      _optimisticActive[questId] = activate;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      ref.invalidate(questActivationsProvider);
      // Wait for the refetch so the optimistic override is only dropped once
      // the real server state agrees — avoids a flicker back to the old state.
      await ref.read(questActivationsProvider.future);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(_friendlyError(e))));
    } finally {
      if (mounted) {
        setState(() {
          _busyQuestIds.remove(questId);
          _optimisticActive.remove(questId);
        });
      }
    }
  }

  /// Effective active state for a quest, applying any optimistic override.
  bool _isActive(String questId, Map<String, QuestActivation> byId) {
    return _optimisticActive[questId] ?? (byId[questId]?.isActive ?? false);
  }

  String _friendlyError(Object e) {
    final text = e.toString();
    return text.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final quests = ref.watch(questsListProvider);
    final activations = ref.watch(questActivationsProvider);
    final theme = Theme.of(context);

    // Build a quick lookup of the user's started/completed quests.
    final byId = <String, QuestActivation>{
      for (final a in activations.asData?.value ?? const <QuestActivation>[])
        a.quest.id: a,
    };
    // Count active quests using effective state so the header + limit reflect
    // optimistic start/drop transitions immediately.
    final activeIds = <String>{
      for (final a in byId.values.where((a) => a.isActive)) a.quest.id,
    };
    _optimisticActive.forEach((id, active) {
      if (active) {
        activeIds.add(id);
      } else {
        activeIds.remove(id);
      }
    });
    final activeCount = activeIds.length;
    final atLimit = activeCount >= kMaxActiveQuests;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(questsListProvider);
            ref.invalidate(questActivationsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 120),
            children: [
              Text(
                'Side Quests',
                style: theme.textTheme.displayLarge?.copyWith(
                  color: AppColors.accentPrimary,
                  fontSize: 28,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$activeCount of $kMaxActiveQuests quests active',
                style: const TextStyle(
                  color: Color(0xFF6D6D78),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 22),
              quests.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accentPrimary,
                  ),
                ),
                error: (error, _) => Text(
                  error.toString(),
                  style: const TextStyle(color: Color(0xFFE5484D)),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const Text('No side quests published yet.');
                  }
                  final canExpand = items.length > _kQuestPreviewCount;
                  final visible = (_showAllQuests || !canExpand)
                      ? items
                      : items.take(_kQuestPreviewCount).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (canExpand) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => setState(
                              () => _showAllQuests = !_showAllQuests,
                            ),
                            child: Text(
                              _showAllQuests ? 'Show less' : 'View All',
                              style: TextStyle(
                                color: AppColors.accentPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      ...visible.map((quest) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _QuestCard(
                            quest: quest,
                            isActive: _isActive(quest.id, byId),
                            atLimit: atLimit,
                            busy: _busyQuestIds.contains(quest.id),
                            onStart: () => _run(
                              quest.id,
                              activate: true,
                              action: () => ref
                                  .read(questsRepositoryProvider)
                                  .activateQuest(quest.id),
                            ),
                            onDrop: () => _run(
                              quest.id,
                              activate: false,
                              action: () => ref
                                  .read(questsRepositoryProvider)
                                  .abandonQuest(quest.id),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({
    required this.quest,
    required this.isActive,
    required this.atLimit,
    required this.busy,
    required this.onStart,
    required this.onDrop,
  });
  final QuestResponse quest;
  final bool isActive;
  final bool atLimit;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onDrop;

  @override
  Widget build(BuildContext context) {
    final color = switch (quest.difficulty) {
      QuestDifficulty.easy => const Color(0xFF5A7F2B),
      QuestDifficulty.medium => const Color(0xFFE6B23A),
      QuestDifficulty.hard => const Color(0xFFE5484D),
    };
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : Colors.white;
    final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.ink;
    final subtitleColor = isDark
        ? AppColors.darkTextSecondary
        : const Color(0xFF8D8D8D);
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFD9D6CF);
    final description =
        (quest.description != null && quest.description!.isNotEmpty)
        ? quest.description!
        : quest.city ?? 'Anywhere in your area';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.24 : 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${quest.difficulty.badgeLabel.toUpperCase()} • ${quest.difficulty.timeEstimate.replaceAll('<', 'Under')}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            quest.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isActive ? 'Active in your quest list' : description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: subtitleColor,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          if (!isActive) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: _QuestButton(
                label: atLimit
                    ? 'Limit reached ($kMaxActiveQuests active)'
                    : 'Start',
                filled: true,
                loading: busy,
                onTap: (busy || atLimit) ? null : onStart,
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            _QuestButton(
              label: 'Drop quest',
              filled: false,
              loading: busy,
              onTap: busy ? null : onDrop,
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestButton extends StatelessWidget {
  const _QuestButton({
    required this.label,
    required this.filled,
    required this.onTap,
    this.loading = false,
  });
  final String label;
  final bool filled;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outlineColor = isDark ? AppColors.darkTextPrimary : AppColors.ink;
    final foreground = filled ? Colors.white : outlineColor;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.45 : 1,
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled
                ? AppColors.accentPrimary
                : (isDark ? AppColors.darkSurface : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: filled ? null : Border.all(color: outlineColor, width: 1.4),
          ),
          child: loading
              ? SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(foreground),
                  ),
                )
              : Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
        ),
      ),
    );
  }
}
