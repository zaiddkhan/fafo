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

class _QuestsPageState extends ConsumerState<QuestsPage> {
  final Set<String> _busyQuestIds = <String>{};

  Future<void> _run(String questId, Future<void> Function() action) async {
    if (_busyQuestIds.contains(questId)) return;
    setState(() => _busyQuestIds.add(questId));
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      ref.invalidate(questActivationsProvider);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(_friendlyError(e))));
    } finally {
      if (mounted) setState(() => _busyQuestIds.remove(questId));
    }
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
    final activeCount = byId.values.where((a) => a.isActive).length;
    final atLimit = activeCount >= kMaxActiveQuests;
    final isDark = theme.brightness == Brightness.dark;
    final headingColor = isDark ? AppColors.textPrimary : AppColors.ink;

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
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Normal',
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: headingColor,
                              fontSize: 18,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              'View All',
                              style: TextStyle(
                                color: AppColors.accentPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ...items.map((quest) {
                        final activation = byId[quest.id];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _QuestCard(
                            quest: quest,
                            activation: activation,
                            atLimit: atLimit,
                            busy: _busyQuestIds.contains(quest.id),
                            onStart: () => _run(
                              quest.id,
                              () => ref
                                  .read(questsRepositoryProvider)
                                  .activateQuest(quest.id),
                            ),
                            onDrop: () => _run(
                              quest.id,
                              () => ref
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
    required this.activation,
    required this.atLimit,
    required this.busy,
    required this.onStart,
    required this.onDrop,
  });
  final QuestResponse quest;
  final QuestActivation? activation;
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
    final isActive = activation?.isActive ?? false;
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
                onTap: (busy || atLimit) ? null : onStart,
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            _QuestButton(
              label: 'Drop quest',
              filled: false,
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
  });
  final String label;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outlineColor = isDark ? AppColors.darkTextPrimary : AppColors.ink;
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
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: filled ? Colors.white : outlineColor,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
