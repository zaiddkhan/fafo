import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/theme/app_chrome.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/features/friends/presentation/add_friends_sheet.dart';
import 'package:fafu/src/features/profile/presentation/edit_profile_page.dart';
import 'package:fafu/src/features/settings/presentation/faq_sheet.dart';
import 'package:fafu/src/features/quests/data/quests_providers.dart';
import 'package:fafu/src/features/quests/domain/quest.dart';
import 'package:fafu/src/features/settings/presentation/settings_page.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';

/// Opens the profile sheet. Resolves with a quest when the user taps Invite,
/// so home can open the composer in its place (as the prototype does).
Future<QuestResponse?> showProfileSheet(BuildContext context) => showFafoSheet<QuestResponse>(
  context,
  builder: (sheetContext) => ProfileSheet(onInvite: (q) => Navigator.of(sheetContext).pop(q)),
);

/// Profile: what you can go do. Six quick-action tiles (FAQ, Theme,
/// Notifications, Re-sync, Profile, Settings), then the side quests. Groups
/// live on Friends; your photo and name are edited from the header.
class ProfileSheet extends ConsumerStatefulWidget {
  const ProfileSheet({super.key, required this.onInvite, this.asTab = false});

  /// Invite on a side quest: the sheet closes and hands the quest back; the
  /// Profile tab opens the composer directly.
  final ValueChanged<QuestResponse> onInvite;

  /// Shown as the Profile tab rather than a sheet.
  final bool asTab;

  @override
  ConsumerState<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends ConsumerState<ProfileSheet> {
  bool _syncing = false;

  Future<void> _resync() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    await resyncContacts(ref);
    if (mounted) setState(() => _syncing = false);
  }

  void _settings([String? focus]) => context.push(SettingsPage.routePath, extra: focus);

  @override
  Widget build(BuildContext context) {
    final tiles = [
      FafoTile(icon: Icons.help_outline_rounded, label: 'FAQ', onTap: () => showFaqSheet(context)),
      FafoTile(icon: Icons.contrast_rounded, label: 'Theme', onTap: () => _settings(SettingsPage.focusTheme)),
      FafoTile(
        icon: Icons.notifications_none_rounded,
        label: 'Notifications',
        onTap: () => _settings(SettingsPage.focusNotifications),
      ),
      FafoTile(icon: Icons.sync_rounded, label: 'Re-sync', busy: _syncing, onTap: _resync),
      FafoTile(icon: Icons.person_outline_rounded, label: 'Profile', onTap: () => showEditProfileSheet(context)),
      FafoTile(icon: Icons.settings_outlined, label: 'Settings', onTap: _settings),
    ];
    final children = [
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
        childAspectRatio: 1.27,
        padding: EdgeInsets.zero,
        children: tiles,
      ),
      const SizedBox(height: 44),
      const FafoEyebrow('15 minutes, no excuses', fontSize: 10.5),
      const SizedBox(height: 6),
      const FafoDisplay('Side quests'),
      const SizedBox(height: 16),
      _QuestList(onInvite: widget.onInvite),
    ];
    if (widget.asTab) {
      return ListView(
        padding: EdgeInsets.fromLTRB(20, 24, 20, FafoBottomNav.clearance(context)),
        children: children,
      );
    }
    return FafoSheetBody(children: children);
  }
}

/// Admin-curated quests grouped Easy, Medium, Hard (brief 5.1). Read-only;
/// Invite shares one as a tagged nudge (5.3).
class _QuestList extends ConsumerWidget {
  const _QuestList({required this.onInvite});

  final ValueChanged<QuestResponse> onInvite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quests = ref.watch(questsListProvider);
    return quests.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(friendlyErrorMessage(e), style: AppTypography.ui(13, color: AppColors.errorText)),
      data: (items) {
        if (items.isEmpty) {
          return Text(
            'No side quests right now.',
            style: AppTypography.ui(13.5, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final level in QuestDifficulty.values)
              if (items.any((q) => q.difficulty == level)) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: FafoBadge(level.badgeLabel, kind: FafoBadge.kindFor(level.name)),
                ),
                const SizedBox(height: 12),
                for (final q in items.where((q) => q.difficulty == level)) ...[
                  _QuestRow(quest: q, onInvite: onInvite),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 14),
              ],
          ],
        );
      },
    );
  }
}

/// A quest card: title, one line, Invite. Ink outline, no shadow.
class _QuestRow extends StatelessWidget {
  const _QuestRow({required this.quest, required this.onInvite});

  final QuestResponse quest;
  final ValueChanged<QuestResponse> onInvite;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: AppChrome.outlineWidth),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quest.title, style: AppTypography.ui(16, fontWeight: FontWeight.w700)),
                if (quest.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    quest.description!,
                    style: AppTypography.ui(13.5, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          FafoPill(
            label: 'Invite',
            height: 44,
            onPressed: () => onInvite(quest),
          ),
        ],
      ),
    );
  }
}
