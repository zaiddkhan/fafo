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
  final Set<String> _started = <String>{};

  Future<void> _startQuest(String id) async {
    setState(() => _started.add(id));
    try {
      await ref.read(questsRepositoryProvider).activateQuest(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quests = ref.watch(questsListProvider);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(questsListProvider),
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
              const SizedBox(height: 22),
              quests.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary)),
                error: (error, _) => Text(error.toString(), style: const TextStyle(color: Color(0xFFE5484D))),
                data: (items) {
                  if (items.isEmpty) return const Text('No side quests published yet.');
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Normal',
                            style: theme.textTheme.displayMedium?.copyWith(color: AppColors.ink, fontSize: 18),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              'View All',
                              style: TextStyle(color: AppColors.accentPrimary, fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ...items.map((quest) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _QuestCard(
                              quest: quest,
                              started: _started.contains(quest.id),
                              onStart: () => _startQuest(quest.id),
                            ),
                          )),
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
  const _QuestCard({required this.quest, required this.started, required this.onStart});
  final QuestResponse quest;
  final bool started;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final color = switch (quest.difficulty) {
      QuestDifficulty.easy => const Color(0xFF35B45A),
      QuestDifficulty.medium => const Color(0xFFE6B23A),
      QuestDifficulty.hard => const Color(0xFFE5484D),
    };
    final description = (quest.description != null && quest.description!.isNotEmpty)
        ? quest.description!
        : 'Once you start, you will have 24 hrs to complete this quest';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink, width: 1.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  quest.title,
                  style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 16, height: 1.2),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      quest.difficulty.badgeLabel,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    quest.difficulty.timeEstimate,
                    style: const TextStyle(color: Color(0xFF6D6D78), fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (started) ...[
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Color(0xFF3A3A40), fontWeight: FontWeight.w700, fontSize: 13, height: 1.3),
                children: const [
                  TextSpan(text: 'You have '),
                  TextSpan(text: '24 hrs', style: TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.w900)),
                  TextSpan(text: ' to complete this quest'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(8)),
              child: const Text('Started', style: TextStyle(color: Color(0xFFBFBFBF), fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ] else ...[
            Text(
              description,
              style: const TextStyle(color: Color(0xFF6D6D78), fontWeight: FontWeight.w600, fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: _QuestButton(
                label: 'Start',
                filled: true,
                onTap: onStart,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestButton extends StatelessWidget {
  const _QuestButton({required this.label, required this.filled, required this.onTap});
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.accentPrimary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: filled ? null : Border.all(color: AppColors.ink, width: 1.4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.white : AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
