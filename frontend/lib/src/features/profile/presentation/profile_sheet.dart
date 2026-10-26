import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/theme/app_chrome.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/features/groups/data/groups_providers.dart';
import 'package:fafu/src/features/groups/presentation/group_sheet.dart';
import 'package:fafu/src/features/quests/data/quests_providers.dart';
import 'package:fafu/src/features/quests/domain/quest.dart';
import 'package:fafu/src/features/settings/presentation/settings_page.dart';
import 'package:fafu/src/features/users/data/users_repository.dart';
import 'package:fafu/src/features/users/domain/profile.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';

/// Opens the profile sheet. Resolves with a quest when the user taps Invite,
/// so home can open the composer in its place (as the prototype does).
Future<QuestResponse?> showProfileSheet(BuildContext context) =>
    showFafoSheet<QuestResponse>(context, builder: (_) => const ProfileSheet());

/// Profile, from the home header (V3 brief 6.1-6.4, 5.1): header, Quick
/// defaults, Groups, then the admin-curated side quests. Stats, streaks, area
/// and events stay parked.
class ProfileSheet extends ConsumerWidget {
  const ProfileSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    return profile.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(friendlyErrorMessage(e), textAlign: TextAlign.center),
        ),
      ),
      data: (p) => FafoSheetBody(
        children: [
          _Header(profile: p),
          _QuickDefaults(profile: p),
          const _Section(
            eyebrow: 'Your groups',
            title: 'Groups',
            child: _GroupsList(),
          ),
          const _Section(
            eyebrow: '15 minutes, no excuses',
            title: 'Side quests',
            child: _QuestList(),
          ),
          // Inferred: sign-out, account deletion and legal links have to live
          // somewhere; the prototype has no other route to them.
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.push(SettingsPage.routePath),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(
                'Settings',
                style: AppTypography.ui(14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)
                    .copyWith(decoration: TextDecoration.underline, decorationColor: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});

  final ProfileResponse profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(right: 44, bottom: 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.rule, width: 2)),
      ),
      child: Row(
        children: [
          FafoAvatar(
            name: profile.displayName,
            size: FafoAvatarSize.lg,
            photoUrl: profile.photoUrl,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FafoEyebrow('Profile'),
                const SizedBox(height: 6),
                FafoDisplay(profile.displayName, fontSize: 44, maxLines: 2),
                const SizedBox(height: 6),
                Text(
                  '@${profile.username}',
                  style: AppTypography.ui(15, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick defaults (brief 6.2). Changes apply only after "Save settings".
class _QuickDefaults extends ConsumerStatefulWidget {
  const _QuickDefaults({required this.profile});

  final ProfileResponse profile;

  @override
  ConsumerState<_QuickDefaults> createState() => _QuickDefaultsState();
}

class _QuickDefaultsState extends ConsumerState<_QuickDefaults> {
  late int _countdown = widget.profile.defaultCountdownMinutes;
  late bool _quests = widget.profile.sideQuestInvites;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final updated = await ref.read(usersRepositoryProvider).setQuickDefaults(
        defaultCountdownMinutes: _countdown,
        sideQuestInvites: _quests,
      );
      ref.read(currentProfileProvider.notifier).setProfile(updated);
      messenger.showSnackBar(const SnackBar(content: Text('Settings saved.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FafoSectionHeader(eyebrow: 'Account settings', title: 'Quick defaults'),
        const SizedBox(height: 18),
        const FafoEyebrow('Default countdown', fontSize: 10.5),
        const SizedBox(height: 14),
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
        const SizedBox(height: 14),
        FafoCheckRow(
          title: 'Side quest invites',
          subtitle: 'Let friends send you 15-minute quests',
          checked: _quests,
          topBorder: true,
          onTap: () => setState(() => _quests = !_quests),
        ),
        const SizedBox(height: 14),
        FafoPill(
          label: 'Save settings',
          small: true,
          height: 44,
          busy: _saving,
          // Always enabled, as in the prototype; saving unchanged values is harmless.
          onPressed: _save,
        ),
      ],
    );
  }
}

/// A profile section: 2px rule above, eyebrow + display title, content.
class _Section extends StatelessWidget {
  const _Section({required this.eyebrow, required this.title, required this.child});

  final String eyebrow;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 22),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.rule, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FafoSectionHeader(eyebrow: eyebrow, title: title),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _GroupsList extends ConsumerWidget {
  const _GroupsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsListProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...groups.when(
          loading: () => const [
            Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
          error: (e, _) => [
            Text(friendlyErrorMessage(e), style: AppTypography.ui(13, color: AppColors.signalRed)),
          ],
          data: (items) => [
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Nudge a few friends in one go.',
                  style: AppTypography.ui(13.5, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
                ),
              ),
            for (final g in items)
              FafoListRow(
                title: g.name,
                subtitle: '${g.members.length} members',
                leading: FafoAvatar(name: g.name, square: true, size: FafoAvatarSize.md),
                onTap: () => showGroupSheet(context, group: g),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: FafoPill(
            label: '+ New group',
            primary: false,
            small: true,
            height: 44,
            onPressed: () => showGroupSheet(context),
          ),
        ),
      ],
    );
  }
}

/// Admin-curated quests grouped Easy, Medium, Hard (brief 5.1). Read-only;
/// Invite shares one as a tagged nudge (5.3).
class _QuestList extends ConsumerWidget {
  const _QuestList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quests = ref.watch(questsListProvider);
    return quests.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(friendlyErrorMessage(e), style: AppTypography.ui(13, color: AppColors.signalRed)),
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
                const SizedBox(height: 10),
                for (final q in items.where((q) => q.difficulty == level)) ...[
                  _QuestRow(quest: q),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 4),
              ],
          ],
        );
      },
    );
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({required this.quest});

  final QuestResponse quest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppChrome.rowRadius),
        border: Border.all(color: AppColors.border, width: AppChrome.outlineWidth),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quest.title, style: AppTypography.ui(15.5, fontWeight: FontWeight.w700)),
                if (quest.description != null) ...[
                  const SizedBox(height: 3),
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
            height: 40,
            small: true,
            onPressed: () => Navigator.of(context).pop(quest),
          ),
        ],
      ),
    );
  }
}
