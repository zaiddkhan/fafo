import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/events/data/events_repository.dart';
import 'package:fafu/src/features/events/domain/event.dart';
import 'package:fafu/src/features/home/data/mock_events.dart';
import 'package:fafu/src/features/settings/presentation/settings_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key, required this.savedEvents});

  final List<MockEvent> savedEvents;

  static const _quests = [
    _ProfileQuest(
      title: 'Plan a night out with friends',
      badge: 'Go Out',
      difficulty: _QuestDifficulty.easy,
    ),
    _ProfileQuest(
      title: 'Check into your first live music group',
      badge: 'First Step',
      badgeColor: Color(0xFF5BA8FF),
      difficulty: _QuestDifficulty.easy,
    ),
    _ProfileQuest(
      title: 'Save 3 spots you want to try this week',
      badge: 'Scout',
      badgeColor: Color(0xFF7A67F8),
      difficulty: _QuestDifficulty.easy,
    ),
    _ProfileQuest(
      title: 'Join a plan outside your usual neighborhood',
      badge: 'Explore',
      badgeColor: Color(0xFF16A085),
      difficulty: _QuestDifficulty.easy,
    ),
    _ProfileQuest(
      title: 'Try a new restaurant with friends this week',
      badge: 'Adventure',
      badgeColor: Color(0xFF44B64A),
      difficulty: _QuestDifficulty.medium,
    ),
    _ProfileQuest(
      title: 'Host a full weekend plan for your crew',
      badge: 'Leader',
      badgeColor: Color(0xFFE08E2B),
      difficulty: _QuestDifficulty.hard,
    ),
    _ProfileQuest(
      title: 'Plan 3 back-to-back group experiences in one weekend',
      badge: 'Marathon',
      badgeColor: Color(0xFFD35400),
      difficulty: _QuestDifficulty.hard,
    ),
    _ProfileQuest(
      title: 'Bring 10 friends into one public event plan',
      badge: 'Connector',
      badgeColor: Color(0xFFC0392B),
      difficulty: _QuestDifficulty.hard,
    ),
    _ProfileQuest(
      title: 'Create a trusted organizer streak for 4 weekends',
      badge: 'Verified',
      badgeColor: Color(0xFFB9770E),
      difficulty: _QuestDifficulty.hard,
    ),
  ];

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
    final rsvpedEvents = savedEvents.take(3).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final questSections = {
      for (final difficulty in _QuestDifficulty.values)
        difficulty: _quests
            .where((quest) => quest.difficulty == difficulty)
            .toList(),
    };

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1F1F1F) : AppColors.bgPrimary,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Profile',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.accentPrimary,
                      fontSize: 28,
                      height: 1,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(SettingsPage.routePath),
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
                      Icons.settings_outlined,
                      color: isDark ? Colors.white : const Color(0xFF171717),
                      size: 20,
                    ),
                  ),
                ),
              ],
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
                    children: events.take(3).map(
                      (event) => Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: _JoinedEventCard(event: event),
                      ),
                    ).toList(),
                  );
                }
                return Column(
                  children: rsvpedEvents.map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _RsvpCard(event: event),
                    ),
                  ).toList(),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Quests for you',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: isDark ? Colors.white : const Color(0xFF171717),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 14),
            ...questSections.entries.expand(
              (entry) => [
                _QuestSectionHeader(
                  title: entry.key.label,
                  count: entry.value.length,
                ),
                const SizedBox(height: 10),
                ...entry.value.map(
                  (quest) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _QuestCard(quest: quest),
                  ),
                ),
              ],
            ),
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

class _JoinedEventCard extends StatelessWidget {
  const _JoinedEventCard({required this.event});

  final EventResponse event;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEE, MMM d • h:mm a').format(event.dateTime.toLocal());
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
      organizerName: event.organizerName ?? 'WhatsPopn Creator',
      organizerContact: event.organizerContact ?? '',
      organizerInstagram: event.organizerInstagram ?? '',
      organizerVerified: true,
      imageUrl: event.bannerUrl ?? 'https://picsum.photos/seed/${event.id}/300/300',
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

enum _QuestDifficulty {
  easy('Easy'),
  medium('Medium'),
  hard('Hard');

  const _QuestDifficulty(this.label);

  final String label;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.actionLabel});

  final String title;
  final String actionLabel;

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
        Text(
          actionLabel,
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.accentPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
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
                  textColor: Color(0xFF252525),
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
                    color: const Color(0xFF171717),
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

class _QuestCard extends StatelessWidget {
  const _QuestCard({required this.quest});

  final _ProfileQuest quest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF252525) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : const Color(0xFF171717);
    final titleColor = isDark ? Colors.white : const Color(0xFF171717);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
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
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: titleColor,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: quest.badgeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  quest.badge,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _QuestButton(
                  label: 'Interested',
                  backgroundColor: AppColors.accentPrimary,
                  textColor: Color(0xFF252525),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuestButton(
                  label: 'Not Interested',
                  backgroundColor: isDark
                      ? const Color(0xFF2C2C2C)
                      : const Color(0xFFF1F1F1),
                  textColor: isDark
                      ? const Color(0xFFC9C9C9)
                      : const Color(0xFF5F5F5F),
                  borderColor: isDark
                      ? Colors.white.withValues(alpha: 0.45)
                      : const Color(0xFF171717),
                  isOutlined: true,
                ),
              ),
            ],
          ),
        ],
      ),
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
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: isDark ? Colors.white : const Color(0xFF171717),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.22)
                  : const Color(0xFF171717),
            ),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.labelLarge?.copyWith(
              color: isDark ? Colors.white70 : const Color(0xFF5F5F5F),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestButton extends StatelessWidget {
  const _QuestButton({
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
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProfileQuest {
  const _ProfileQuest({
    required this.title,
    required this.badge,
    required this.difficulty,
    this.badgeColor = const Color(0xFF2A66F6),
  });

  final String title;
  final String badge;
  final _QuestDifficulty difficulty;
  final Color badgeColor;
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
