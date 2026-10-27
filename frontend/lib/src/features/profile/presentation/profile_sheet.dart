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
Future<QuestResponse?> showProfileSheet(BuildContext context) => showFafoSheet<QuestResponse>(
  context,
  builder: (sheetContext) => ProfileSheet(onInvite: (q) => Navigator.of(sheetContext).pop(q)),
);

/// Profile (V3 brief 6.1-6.4, 5.1): header with the Settings button, Groups,
/// then the admin-curated side quests. Quick defaults live in Settings.
/// Stats, streaks, area and events stay parked.
class ProfileSheet extends ConsumerWidget {
  const ProfileSheet({super.key, required this.onInvite, this.asTab = false});

  /// Invite on a side quest: the sheet closes and hands the quest back; the
  /// Profile tab opens the composer directly.
  final ValueChanged<QuestResponse> onInvite;

  /// Shown as the Profile tab rather than a sheet (no × to clear).
  final bool asTab;

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
          _Header(profile: p, clearClose: !asTab),
          const _Section(
            eyebrow: 'Your groups',
            title: 'Groups',
            child: _GroupsList(),
          ),
          _Section(
            eyebrow: '15 minutes, no excuses',
            title: 'Side quests',
            child: _QuestList(onInvite: onInvite),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile, this.clearClose = true});

  final ProfileResponse profile;

  /// Leave room for the sheet's round × in the top right.
  final bool clearClose;

  @override
  Widget build(BuildContext context) {
    // No rule underneath: the Groups section below draws its own.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: clearClose ? 46 : 0),
          child: Row(
            children: [
              const Expanded(child: FafoEyebrow('Profile')),
              FafoRoundButton(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () => context.push(SettingsPage.routePath),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
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
                  _QuestRow(quest: q, onInvite: onInvite),
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
  const _QuestRow({required this.quest, required this.onInvite});

  final QuestResponse quest;
  final ValueChanged<QuestResponse> onInvite;

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
            onPressed: () => onInvite(quest),
          ),
        ],
      ),
    );
  }
}
