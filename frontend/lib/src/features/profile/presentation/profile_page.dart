import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/events/data/events_repository.dart';
import 'package:fafu/src/features/events/domain/event.dart';
import 'package:fafu/src/features/home/data/mock_events.dart';
import 'package:fafu/src/features/notifications/data/notifications_repository.dart';
import 'package:fafu/src/features/notifications/presentation/notifications_page.dart';
import 'package:fafu/src/features/profile/presentation/edit_profile_page.dart';
import 'package:fafu/src/features/quests/data/quests_providers.dart';
import 'package:fafu/src/features/quests/data/quests_repository.dart';
import 'package:fafu/src/features/quests/domain/quest.dart';
import 'package:fafu/src/features/quests/presentation/quests_page.dart';
import 'package:fafu/src/features/settings/presentation/settings_page.dart';
import 'package:fafu/src/features/users/data/users_providers.dart';
import 'package:fafu/src/features/users/data/users_repository.dart';
import 'package:fafu/src/features/users/domain/profile.dart';
import 'package:fafu/src/shared/widgets/location_search_sheet.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key, required this.savedEvents});

  final List<MockEvent> savedEvents;

  static const _pastExperiences = [
    _PastExperience(
      title: 'Warehouse Rave',
      summary: 'Went with 6 friends and stayed till the closing set.',
      tag: 'Nightlife',
      detail: 'Last weekend',
    ),
    _PastExperience(
      title: 'Street Art Walk',
      summary: 'Explored murals, saved 4 new spots, and met two creators.',
      tag: 'Art & Culture',
      detail: '2 weeks ago',
    ),
    _PastExperience(
      title: 'Ramen Festival',
      summary: 'Tried 3 stalls and posted your first group review.',
      tag: 'Food & Drinks',
      detail: 'Last month',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final joinedEvents = ref.watch(_joinedEventsProvider);
    final stats = ref.watch(profileStatsProvider);
    final profile = ref.watch(currentProfileProvider);
    final quests = ref.watch(questsListProvider);
    final activations = ref.watch(questActivationsProvider);
    final activationById = <String, QuestActivation>{
      for (final a in activations.asData?.value ?? const <QuestActivation>[])
        a.quest.id: a,
    };
    final activeCount = activationById.values.where((a) => a.isActive).length;
    final atQuestLimit = activeCount >= kMaxActiveQuests;
    final rsvpedEvents = savedEvents.take(3).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(eventsRevisionProvider, (_, _) {
      ref.invalidate(_joinedEventsProvider);
      ref.invalidate(profileStatsProvider);
    });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1F1F1F) : AppColors.bgPrimary,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
          children: [
            Row(
              children: [
                Text(
                  'Profile',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppColors.accentPrimary,
                    fontSize: 28,
                    height: 1,
                  ),
                ),
                const Spacer(),
                _NotificationBell(isDark: isDark),
                const SizedBox(width: 10),
                if (profile.hasValue)
                  _HeaderIconButton(
                    icon: Icons.edit_outlined,
                    isDark: isDark,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            EditProfilePage(profile: profile.value!),
                      ),
                    ),
                  ),
                if (profile.hasValue) const SizedBox(width: 10),
                _HeaderIconButton(
                  icon: Icons.settings_outlined,
                  isDark: isDark,
                  onTap: () => context.push(SettingsPage.routePath),
                ),
              ],
            ),
            const SizedBox(height: 16),
            profile.when(
              loading: () => const SizedBox(
                height: 64,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accentPrimary,
                  ),
                ),
              ),
              error: (_, _) => const SizedBox.shrink(),
              data: (p) => _IdentityHeader(profile: p, isDark: isDark),
            ),
            const SizedBox(height: 18),
            stats.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (s) => Row(
                children: [
                  Expanded(
                    child: _StatPill(
                      label: 'Upcoming',
                      value: '${s.upcomingEvents}',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _StatPill(
                      label: 'Joined',
                      value: '${s.eventsJoined}',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _StatPill(
                      label: 'Quests',
                      value: '${s.sideQuestsActivated}',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _StatPill(
                      label: 'Friends',
                      value: '${s.friendsCount}',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _StatPill(
                      label: 'Streak',
                      value: '${s.currentStreak}',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SectionHeader(title: 'Joined events', actionLabel: 'View All'),
            const SizedBox(height: 12),
            joinedEvents.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(bottom: 18),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accentPrimary,
                  ),
                ),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Text(
                  error.toString(),
                  style: const TextStyle(color: Color(0xFFE5484D)),
                ),
              ),
              data: (events) {
                if (events.isEmpty && rsvpedEvents.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 18),
                    child: Text('Join an event to see it here.'),
                  );
                }
                if (events.isNotEmpty) {
                  return Column(
                    children: events
                        .take(3)
                        .map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: _JoinedEventCard(event: event),
                          ),
                        )
                        .toList(),
                  );
                }
                return Column(
                  children: rsvpedEvents
                      .map(
                        (event) => Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: _RsvpCard(event: event),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 12),
            _SectionHeader(
              title: 'Side Quests',
              actionLabel: 'View All',
              onAction: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const QuestsPage())),
            ),
            const SizedBox(height: 12),
            quests.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(bottom: 18),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accentPrimary,
                  ),
                ),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Text(
                  error.toString(),
                  style: const TextStyle(color: Color(0xFFE5484D)),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 18),
                    child: Text('No side quests published yet.'),
                  );
                }
                return Column(
                  children: items
                      .take(4)
                      .map(
                        (quest) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SideQuestCard(
                            quest: quest,
                            isDark: isDark,
                            activation: activationById[quest.id],
                            atLimit: atQuestLimit,
                            onStart: () => _startQuest(ref, context, quest.id),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 6),
            _QuestHistorySection(activations: activations, isDark: isDark),
            const SizedBox(height: 6),
            _SectionHeader(
              title: 'Past Experiences',
              actionLabel: 'See History',
            ),
            const SizedBox(height: 12),
            ..._pastExperiences.map(
              (experience) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _PastExperienceCard(experience: experience),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _joinedEventsProvider = FutureProvider.autoDispose<List<EventResponse>>(
  (ref) => ref.watch(eventsRepositoryProvider).getJoinedEvents(limit: 20),
);

/// Reverse-geocoded label for the profile's area coordinate.
final _areaLabelProvider = FutureProvider.autoDispose
    .family<String?, ({double lat, double lng})>(
      (ref, coord) => reverseGeocodeLabel(coord.lat, coord.lng),
    );

Future<void> _startQuest(
  WidgetRef ref,
  BuildContext context,
  String questId,
) async {
  try {
    await ref.read(questsRepositoryProvider).activateQuest(questId);
    ref.invalidate(profileStatsProvider);
    ref.invalidate(questActivationsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Quest activated.')));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
}

/// "Quest History" — the quests the user has actually started, with their
/// status. Reads from [questActivationsProvider] so it survives refreshes.
class _QuestHistorySection extends StatelessWidget {
  const _QuestHistorySection({required this.activations, required this.isDark});

  final AsyncValue<List<QuestActivation>> activations;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Quest History'),
        const SizedBox(height: 12),
        activations.when(
          loading: () => const Padding(
            padding: EdgeInsets.only(bottom: 18),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.accentPrimary),
            ),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Text(
              error.toString(),
              style: const TextStyle(color: Color(0xFFE5484D)),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 18),
                child: Text("You haven't started any quests yet."),
              );
            }
            return Column(
              children: items
                  .map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _QuestHistoryRow(activation: a, isDark: isDark),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _QuestHistoryRow extends StatelessWidget {
  const _QuestHistoryRow({required this.activation, required this.isDark});

  final QuestActivation activation;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final completed = activation.isCompleted;
    final when = completed ? activation.completedAt : activation.activatedAt;
    final whenLabel = when == null
        ? ''
        : DateFormat('MMM d').format(when.toLocal());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.5)
              : const Color(0xFFE2E2E6),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.bolt,
            color: completed
                ? const Color(0xFF35B45A)
                : AppColors.accentPrimary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              activation.quest.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF171717),
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            completed
                ? 'Completed${whenLabel.isEmpty ? '' : ' • $whenLabel'}'
                : 'In progress',
            style: TextStyle(
              color: completed
                  ? const Color(0xFF35B45A)
                  : const Color(0xFF8A8A92),
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252525) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.8)
                : const Color(0xFF171717),
          ),
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white : const Color(0xFF171717),
          size: 20,
        ),
      ),
    );
  }
}

/// Header bell that opens the in-app inbox, with an unread-count badge.
class _NotificationBell extends ConsumerWidget {
  const _NotificationBell({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsProvider).asData?.value ?? 0;
    return GestureDetector(
      onTap: () async {
        await context.push(NotificationsPage.routePath);
        // Returning from the inbox may have changed read state.
        ref.invalidate(unreadNotificationsProvider);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252525) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.8)
                    : const Color(0xFF171717),
              ),
            ),
            child: Icon(
              Icons.notifications_none,
              color: isDark ? Colors.white : const Color(0xFF171717),
              size: 20,
            ),
          ),
          if (unread > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IdentityHeader extends ConsumerWidget {
  const _IdentityHeader({required this.profile, required this.isDark});
  final ProfileResponse profile;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final area = profile.area;
    final areaLabel = area == null
        ? null
        : ref.watch(_areaLabelProvider((lat: area.lat, lng: area.lng)));
    final name = profile.displayName.isEmpty
        ? '@${profile.username}'
        : profile.displayName;

    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? Colors.white24 : const Color(0xFF171717),
              width: 1.6,
            ),
            image: profile.photoUrl == null
                ? null
                : DecorationImage(
                    image: NetworkImage(profile.photoUrl!),
                    fit: BoxFit.cover,
                  ),
          ),
          child: profile.photoUrl == null
              ? Center(
                  child: Text(
                    (profile.displayName.isEmpty
                            ? profile.username
                            : profile.displayName)
                        .characters
                        .first
                        .toUpperCase(),
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontSize: 24,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.displayMedium?.copyWith(
                  color: isDark ? Colors.white : const Color(0xFF171717),
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '@${profile.username}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      area == null
                          ? 'Area not set'
                          : (areaLabel?.value ??
                                '${area.lat.toStringAsFixed(3)}, ${area.lng.toStringAsFixed(3)}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SideQuestCard extends StatelessWidget {
  const _SideQuestCard({
    required this.quest,
    required this.isDark,
    required this.onStart,
    this.activation,
    this.atLimit = false,
  });
  final QuestResponse quest;
  final bool isDark;
  final VoidCallback onStart;
  final QuestActivation? activation;
  final bool atLimit;

  @override
  Widget build(BuildContext context) {
    final color = switch (quest.difficulty) {
      QuestDifficulty.easy => const Color(0xFF35B45A),
      QuestDifficulty.medium => const Color(0xFFE6B23A),
      QuestDifficulty.hard => const Color(0xFFE5484D),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.85)
              : const Color(0xFF171717),
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF171717),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        quest.difficulty.badgeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      quest.difficulty.timeEstimate,
                      style: const TextStyle(
                        color: Color(0xFF8A8A92),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _buildTrailing(),
        ],
      ),
    );
  }

  Widget _buildTrailing() {
    if (activation?.isCompleted ?? false) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF35B45A).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Color(0xFF35B45A), size: 15),
            SizedBox(width: 4),
            Text(
              'Done',
              style: TextStyle(
                color: Color(0xFF35B45A),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    if (activation?.isActive ?? false) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Started',
          style: TextStyle(
            color: Color(0xFFBFBFBF),
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      );
    }
    final disabled = atLimit;
    return GestureDetector(
      onTap: disabled ? null : onStart,
      child: Opacity(
        opacity: disabled ? 0.45 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.accentPrimary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Start',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _JoinedEventCard extends StatelessWidget {
  const _JoinedEventCard({required this.event});

  final EventResponse event;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat(
      'EEE, MMM d • h:mm a',
    ).format(event.dateTime.toLocal());
    final mock = MockEvent(
      id: event.id,
      title: event.title,
      category: event.categoryId,
      time: DateFormat('h:mm a').format(event.dateTime.toLocal()),
      venue: event.locationName,
      lat: event.lat,
      lng: event.lng,
      attendees: event.joineeCount,
      isFree: true,
      friendsOnly: false,
      rating: 0,
      timing: MockEventTiming.today,
      organizerName: event.organizerName ?? 'Fafo Creator',
      organizerContact: event.organizerContact ?? '',
      organizerInstagram: event.organizerInstagram ?? '',
      organizerVerified: true,
      imageUrl:
          event.bannerUrl ?? 'https://picsum.photos/seed/${event.id}/300/300',
      eventType: event.eventType.name,
      customEmoji: event.customEmoji,
    );

    return GestureDetector(
      onTap: () => context.push('/event/${event.id}', extra: mock),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RsvpCard(event: mock),
          const SizedBox(height: 6),
          Text(
            dateLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.displayMedium?.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel = '',
    this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.displayMedium?.copyWith(
            color: isDark ? Colors.white : const Color(0xFF171717),
            fontSize: 16,
          ),
        ),
        const Spacer(),
        if (actionLabel.isNotEmpty)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.accentPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _RsvpCard extends StatelessWidget {
  const _RsvpCard({required this.event});

  final MockEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF252525) : Colors.white;
    final borderColor = isDark ? Colors.white : const Color(0xFF171717);
    final shadowColor = isDark
        ? const Color(0xFFF2F2F2)
        : const Color(0xFF171717);
    final frameBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : const Color(0xFF171717);
    final venueColor = isDark
        ? const Color(0xFFC9C9C9)
        : const Color(0xFF565656);
    final titleColor = isDark ? Colors.white : const Color(0xFF171717);
    final metaColor = isDark
        ? const Color(0xFF8C8C8C)
        : const Color(0xFF777777);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.8),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 0, offset: Offset(5, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: frameBorderColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.network(
                event.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: isDark
                      ? const Color(0xFF383838)
                      : AppColors.bgTertiary,
                  child: Icon(
                    Icons.mic,
                    color: isDark ? Colors.white70 : const Color(0xFF5B5B5B),
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  event.venue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: venueColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: titleColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Sat 9:00 PM',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: metaColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: Column(
              children: [
                _CardActionButton(
                  label: 'LOCATION',
                  backgroundColor: AppColors.accentPrimary,
                  textColor: Colors.white,
                ),
                const SizedBox(height: 8),
                _CardActionButton(
                  label: 'CANCEL',
                  backgroundColor: isDark
                      ? const Color(0xFF333333)
                      : const Color(0xFFF1F1F1),
                  textColor: isDark
                      ? const Color(0xFFC6C6C6)
                      : const Color(0xFF5F5F5F),
                  borderColor: borderColor.withValues(alpha: isDark ? 0.45 : 1),
                  isOutlined: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.isOutlined = false,
    this.borderColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final bool isOutlined;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: isOutlined
            ? Border.all(
                color: borderColor ?? Colors.white.withValues(alpha: 0.45),
              )
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _PastExperienceCard extends StatelessWidget {
  const _PastExperienceCard({required this.experience});

  final _PastExperience experience;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.85)
              : const Color(0xFF171717),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  experience.title,
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: isDark ? Colors.white : const Color(0xFF171717),
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  experience.tag,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            experience.summary,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark ? const Color(0xFFC9C9C9) : const Color(0xFF5F5F5F),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            experience.detail,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PastExperience {
  const _PastExperience({
    required this.title,
    required this.summary,
    required this.tag,
    required this.detail,
  });

  final String title;
  final String summary;
  final String tag;
  final String detail;
}
