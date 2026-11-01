import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/features/users/data/users_repository.dart';
import 'package:fafu/src/features/users/domain/profile.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_toast.dart';

/// Quick defaults: the countdown new plans start with, and whether friends
/// can send you side quests. Saves as you change them.
class QuickDefaults extends ConsumerStatefulWidget {
  const QuickDefaults({super.key, required this.profile});

  final ProfileResponse profile;

  @override
  ConsumerState<QuickDefaults> createState() => _QuickDefaultsState();
}

class _QuickDefaultsState extends ConsumerState<QuickDefaults> {
  late int _countdown = widget.profile.defaultCountdownMinutes;
  late bool _quests = widget.profile.sideQuestInvites;

  /// Bumped per save; only the latest save's answer (or failure) counts, so
  /// quick taps can't land out of order.
  int _seq = 0;

  /// The last values the server confirmed, to roll back to on failure.
  late (int, bool) _saved = (widget.profile.defaultCountdownMinutes, widget.profile.sideQuestInvites);

  Future<void> _save({int? countdown, bool? quests}) async {
    final seq = ++_seq;
    setState(() {
      _countdown = countdown ?? _countdown;
      _quests = quests ?? _quests;
    });
    try {
      final updated = await ref.read(usersRepositoryProvider).setQuickDefaults(
        defaultCountdownMinutes: _countdown,
        sideQuestInvites: _quests,
      );
      if (seq != _seq || !mounted) return;
      _saved = (updated.defaultCountdownMinutes, updated.sideQuestInvites);
      ref.read(currentProfileProvider.notifier).setProfile(updated);
    } catch (e) {
      if (seq != _seq || !mounted) return;
      setState(() {
        _countdown = _saved.$1;
        _quests = _saved.$2;
      });
      FafoToasts.error(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 12, 2, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Default countdown', style: AppTypography.ui(16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final m in const [5, 10, 15]) ...[
                    if (m != 5) const SizedBox(width: 8),
                    Expanded(
                      child: FafoFilterChip(
                        label: '$m min',
                        selected: _countdown == m,
                        onTap: () => _save(countdown: m),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        FafoListRow(
          title: 'Side quest invites',
          subtitle: 'Let friends send you 15-minute quests',
          trailing: FafoSwitch(
            value: _quests,
            label: 'Side quest invites',
            onChanged: (v) => _save(quests: v),
          ),
        ),
      ],
    );
  }
}
