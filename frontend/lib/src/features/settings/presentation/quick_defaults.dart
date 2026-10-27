import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/features/users/data/users_repository.dart';
import 'package:fafu/src/features/users/domain/profile.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_toast.dart';

/// Quick defaults (brief 6.2): default countdown and side quest invites.
/// Lives in Settings. Changes apply only after "Save defaults".
class QuickDefaults extends ConsumerStatefulWidget {
  const QuickDefaults({super.key, required this.profile});

  final ProfileResponse profile;

  @override
  ConsumerState<QuickDefaults> createState() => _QuickDefaultsState();
}

class _QuickDefaultsState extends ConsumerState<QuickDefaults> {
  late int _countdown = widget.profile.defaultCountdownMinutes;
  late bool _quests = widget.profile.sideQuestInvites;
  bool _saving = false;

  bool get _dirty =>
      _countdown != widget.profile.defaultCountdownMinutes || _quests != widget.profile.sideQuestInvites;

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final updated = await ref.read(usersRepositoryProvider).setQuickDefaults(
        defaultCountdownMinutes: _countdown,
        sideQuestInvites: _quests,
      );
      ref.read(currentProfileProvider.notifier).setProfile(updated);
      messenger.toast('Defaults saved.');
    } catch (e) {
      messenger.toastError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const FafoEyebrow('Default countdown', fontSize: 10.5),
        const SizedBox(height: 12),
        FafoChipGrid(
          children: [
            for (final m in const [5, 10, 15])
              FafoChip(
                selected: _countdown == m,
                onTap: () => setState(() => _countdown = m),
                child: Text('$m min'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        FafoCheckRow(
          title: 'Side quest invites',
          subtitle: 'Let friends send you 15-minute quests',
          checked: _quests,
          onTap: () => setState(() => _quests = !_quests),
        ),
        if (_dirty) ...[
          const SizedBox(height: 14),
          FafoPill(label: 'Save defaults', small: true, height: 44, busy: _saving, onPressed: _save),
        ],
      ],
    );
  }
}
