import 'package:flutter/material.dart';

import 'package:fafu/src/core/constants/app_spacing.dart';
import 'package:fafu/src/core/theme/app_colors.dart';

class QuestsPage extends StatelessWidget {
  const QuestsPage({super.key});

  static const _quests = [
    _Quest(
      difficulty: _QuestDifficulty.easy,
      title: 'First Timer',
      description: 'Attend your first event',
      emoji: '🎉',
      progress: 1,
      total: 1,
      xp: 50,
      gradientColors: [Color(0xFF1A87DA), Color(0xFF0E5C96)],
    ),
    _Quest(
      difficulty: _QuestDifficulty.easy,
      title: 'Night Owl',
      description: 'Go to 3 events after 10 PM',
      emoji: '🦉',
      progress: 1,
      total: 3,
      xp: 150,
      gradientColors: [Color(0xFF0A2540), Color(0xFF1472B8)],
    ),
    _Quest(
      difficulty: _QuestDifficulty.easy,
      title: 'Explorer',
      description: 'Visit 5 different venues',
      emoji: '🧭',
      progress: 2,
      total: 5,
      xp: 200,
      gradientColors: [Color(0xFF0F2027), Color(0xFF2C5364)],
    ),
    _Quest(
      difficulty: _QuestDifficulty.medium,
      title: 'Social Butterfly',
      description: 'Attend events in 4 categories',
      emoji: '🦋',
      progress: 1,
      total: 4,
      xp: 250,
      gradientColors: [Color(0xFF1472B8), Color(0xFF5EAEE8)],
    ),
    _Quest(
      difficulty: _QuestDifficulty.medium,
      title: 'Foodie',
      description: 'Check out 3 food events',
      emoji: '🍜',
      progress: 0,
      total: 3,
      xp: 100,
      gradientColors: [Color(0xFFFF8A00), Color(0xFFFFC837)],
    ),
    _Quest(
      difficulty: _QuestDifficulty.medium,
      title: 'Culture Vulture',
      description: 'Attend 3 art & culture events',
      emoji: '🎨',
      progress: 0,
      total: 3,
      xp: 100,
      gradientColors: [Color(0xFF5B7C00), Color(0xFFB8E04A)],
    ),
    _Quest(
      difficulty: _QuestDifficulty.hard,
      title: 'Weekend Warrior',
      description: '4 consecutive weekends out',
      emoji: '⚔️',
      progress: 0,
      total: 4,
      xp: 300,
      gradientColors: [Color(0xFFFFB703), Color(0xFFFB8500)],
    ),
    _Quest(
      difficulty: _QuestDifficulty.hard,
      title: 'Host with the Most',
      description: 'Create and publish your own event',
      emoji: '👑',
      progress: 0,
      total: 1,
      xp: 200,
      gradientColors: [Color(0xFFFFB000), Color(0xFFFFE066)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = _quests.where((q) => q.isComplete).length;
    final totalXp = _quests
        .where((q) => q.isComplete)
        .fold(0, (s, q) => s + q.xp);
    final questSections = {
      for (final difficulty in _QuestDifficulty.values)
        difficulty: _quests
            .where((quest) => quest.difficulty == difficulty)
            .toList(),
    };

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Side Quests', style: theme.textTheme.displayLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Complete quests to earn XP and unlock badges.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Stats bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary,
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                ),
                child: Row(
                  children: [
                    _StatBubble(
                      value: '$completed/${_quests.length}',
                      label: 'Completed',
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _StatBubble(value: '$totalXp', label: 'XP Earned'),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Level 1',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Quest list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  for (final entry in questSections.entries) ...[
                    _QuestSectionHeader(
                      title: entry.key.label,
                      count: entry.value.length,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final quest in entry.value)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _QuestCard(quest: quest),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _QuestDifficulty {
  easy('Easy'),
  medium('Medium'),
  hard('Hard');

  const _QuestDifficulty(this.label);

  final String label;
}

class _Quest {
  const _Quest({
    required this.difficulty,
    required this.title,
    required this.description,
    required this.emoji,
    required this.progress,
    required this.total,
    required this.xp,
    required this.gradientColors,
  });

  final _QuestDifficulty difficulty;
  final String title;
  final String description;
  final String emoji;
  final int progress;
  final int total;
  final int xp;
  final List<Color> gradientColors;

  bool get isComplete => progress >= total;
}

class _StatBubble extends StatelessWidget {
  const _StatBubble({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.displayMedium?.copyWith(color: Colors.white),
        ),
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _QuestSectionHeader extends StatelessWidget {
  const _QuestSectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(title, style: theme.textTheme.headlineSmall),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({required this.quest});

  final _Quest quest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = quest.total > 0 ? quest.progress / quest.total : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        border: Border.all(
          color: quest.isComplete
              ? quest.gradientColors.first.withValues(alpha: 0.5)
              : AppColors.border,
        ),
        boxShadow: quest.isComplete
            ? [
                BoxShadow(
                  color: quest.gradientColors.first.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Emoji icon with gradient bg
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: quest.isComplete
                  ? quest.gradientColors.first
                  : AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(AppSpacing.md),
            ),
            alignment: Alignment.center,
            child: Text(
              quest.emoji,
              style: const TextStyle(fontFamily: 'Tomorrow', fontSize: 24),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        quest.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: quest.isComplete
                              ? AppColors.textPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (quest.isComplete)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: quest.gradientColors.first,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '✓ Done',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      Text(
                        '+${quest.xp} XP',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.accentLight1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  quest.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 6,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.bgTertiary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: quest.gradientColors,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${quest.progress} of ${quest.total}',
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
