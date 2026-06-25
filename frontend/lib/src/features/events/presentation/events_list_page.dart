import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/blogs/data/blogs_repository.dart';
import 'package:fafu/src/features/blogs/domain/blog.dart';
import 'package:fafu/src/features/categories/data/categories_repository.dart';
import 'package:fafu/src/features/categories/domain/category.dart';
import 'package:fafu/src/features/events/data/events_repository.dart';
import 'package:fafu/src/features/events/domain/event.dart';
import 'package:fafu/src/features/home/data/mock_events.dart';
import 'package:fafu/src/shared/widgets/app_pressable.dart';

class EventsListPage extends ConsumerStatefulWidget {
  const EventsListPage({super.key, required this.events});

  // Kept for route compatibility. The Events Index now loads live backend data.
  final List<MockEvent> events;

  @override
  ConsumerState<EventsListPage> createState() => _EventsListPageState();
}

class _EventsListPageState extends ConsumerState<EventsListPage> {
  static const double _bottomNavClearance = 112;
  static const _mumbaiLat = 19.0760;
  static const _mumbaiLng = 72.8777;
  static const _bangaloreLat = 12.9716;
  static const _bangaloreLng = 77.5946;

  bool _loading = true;
  String? _error;
  String? _selectedCategoryId;
  List<CategoryResponse> _categories = const [];
  List<EventResponse> _events = const [];
  List<BlogResponse> _blogs = const [];

  @override
  void initState() {
    super.initState();
    _loadEventsIndex();
  }

  Future<void> _loadEventsIndex() async {
    setState(() {
      // Only show the full-page loading state for the first load. Later refreshes
      // keep the current content on screen and use pull-to-refresh / silent
      // revision refreshes instead of flashing a loader on every tab visit.
      _loading = _events.isEmpty && _blogs.isEmpty;
      _error = null;
    });

    try {
      final categoriesRepo = ref.read(categoriesRepositoryProvider);
      final eventsRepo = ref.read(eventsRepositoryProvider);
      final blogsRepo = ref.read(blogsRepositoryProvider);
      final results = await Future.wait([
        categoriesRepo.getCategories(),
        eventsRepo.getEvents(
          lat: _mumbaiLat,
          lng: _mumbaiLng,
          radiusKm: 70,
          limit: 100,
        ),
        eventsRepo.getEvents(
          lat: _bangaloreLat,
          lng: _bangaloreLng,
          radiusKm: 70,
          limit: 100,
        ),
        blogsRepo.getBlogs(city: 'Bengaluru', limit: 10),
      ]);

      final categoriesResult = results[0] as List<CategoryResponse>;
      final mumbaiEvents = results[1] as List<EventResponse>;
      final bangaloreEvents = results[2] as List<EventResponse>;
      final blogsResult = results[3] as List<BlogResponse>;
      final eventsById = <String, EventResponse>{
        for (final event in [...mumbaiEvents, ...bangaloreEvents])
          event.id: event,
      };
      final events = eventsById.values.toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      final usingDemoEvents = events.isEmpty;
      final categories = usingDemoEvents || categoriesResult.isEmpty
          ? _demoCategories
          : categoriesResult;
      final displayEvents = usingDemoEvents ? _demoEvents : events;
      final blogs = blogsResult.isEmpty ? _demoBlogs : blogsResult;

      if (!mounted) return;
      setState(() {
        _categories = categories;
        _events = displayEvents;
        _blogs = blogs;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static List<CategoryResponse> get _demoCategories => const [
    CategoryResponse(
      id: 'demo-music',
      name: 'Live Music',
      emoji: '🎸',
      sortOrder: 1,
    ),
    CategoryResponse(
      id: 'demo-food',
      name: 'Food & Drinks',
      emoji: '🍜',
      sortOrder: 2,
    ),
    CategoryResponse(
      id: 'demo-art',
      name: 'Art & Culture',
      emoji: '🎨',
      sortOrder: 3,
    ),
  ];

  static List<EventResponse> get _demoEvents {
    final now = DateTime.now();
    return [
      EventResponse(
        id: 'demo-spotlight-jazz',
        creatorUid: 'demo',
        title: 'Rooftop indie night',
        description: 'A small live set with city views and new artists.',
        categoryId: 'demo-music',
        eventType: EventType.spotlight,
        customEmoji: '🎸',
        lat: _bangaloreLat,
        lng: _bangaloreLng,
        locationName: 'Indiranagar Social',
        dateTime: DateTime(now.year, now.month, now.day, 20),
        capacity: 80,
        joineeCount: 42,
        registrationOpen: true,
        cancelled: false,
        organizerName: 'Fafo Picks',
        createdAt: now,
        updatedAt: now,
      ),
      EventResponse(
        id: 'demo-volunteer-cleanup',
        creatorUid: 'demo',
        title: 'Cubbon Park cleanup quest',
        description: 'Meet new people while doing something useful.',
        categoryId: 'demo-art',
        eventType: EventType.volunteering,
        customEmoji: '🤝',
        lat: _bangaloreLat,
        lng: _bangaloreLng,
        locationName: 'Cubbon Park',
        dateTime: now.add(const Duration(days: 1, hours: 3)),
        capacity: 40,
        joineeCount: 18,
        registrationOpen: true,
        cancelled: false,
        organizerName: 'Fafo Community',
        createdAt: now,
        updatedAt: now,
      ),
      EventResponse(
        id: 'demo-food-walk',
        creatorUid: 'demo',
        title: 'Late night dosa crawl',
        description: 'A tiny food walk across local favourites.',
        categoryId: 'demo-food',
        eventType: EventType.normal,
        customEmoji: '🍜',
        lat: _bangaloreLat,
        lng: _bangaloreLng,
        locationName: 'Church Street',
        dateTime: now.add(const Duration(days: 2, hours: 5)),
        capacity: 24,
        joineeCount: 11,
        registrationOpen: true,
        cancelled: false,
        organizerName: 'Fafo Foodies',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  static List<BlogResponse> get _demoBlogs {
    final now = DateTime.now();
    return [
      BlogResponse(
        id: 'demo-blog-weekend',
        city: 'Bengaluru',
        title: 'What to do this weekend',
        subtitle: 'Music, food walks, and low-effort hangs around the city.',
        body: 'A quick guide to easy weekend plans.',
        readTime: '3 min read',
        published: true,
        createdAt: now,
        updatedAt: now,
      ),
      BlogResponse(
        id: 'demo-blog-first-hang',
        city: 'Bengaluru',
        title: 'How to pick your first Fafo hang',
        subtitle:
            'Start with small groups, public venues, and shared interests.',
        body: 'Tips for new users choosing their first event.',
        readTime: '2 min read',
        published: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  List<EventResponse> get _filteredEvents {
    return _events
        .where((event) {
          return _selectedCategoryId == null ||
              event.categoryId == _selectedCategoryId;
        })
        .toList(growable: false);
  }

  List<EventResponse> get _spotlightEvents {
    final today = DateTime.now();
    return _events
        .where((event) {
          final local = event.dateTime.toLocal();
          return event.eventType == EventType.spotlight ||
              DateUtils.isSameDay(local, today);
        })
        .toList(growable: false);
  }

  Map<String, CategoryResponse> get _categoriesById => {
    for (final category in _categories) category.id: category,
  };

  @override
  Widget build(BuildContext context) {
    // Re-fetch when an event is created/edited elsewhere (this tab is kept
    // alive in the shell's IndexedStack, so initState only runs once).
    ref.listen(eventsRevisionProvider, (_, _) => _loadEventsIndex());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pageBackground = isDark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFFFFEF8);
    final titleColor = AppColors.accentPrimary;
    final headingColor = isDark ? Colors.white : const Color(0xFF181818);
    final bodyColor = isDark
        ? const Color(0xFF8D8D96)
        : const Color(0xFF737373);
    final cardSurface = isDark ? const Color(0xFF212121) : Colors.white;
    final cardShadow = isDark ? Colors.white : const Color(0xFF0F0F0F);
    final borderColor = isDark ? Colors.white : const Color(0xFF171717);
    final bottomInset =
        MediaQuery.paddingOf(context).bottom + _bottomNavClearance;

    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadEventsIndex,
          child: ListView(
            padding: EdgeInsets.fromLTRB(22, 18, 22, bottomInset),
            children: [
              Text(
                'Events',
                style: theme.textTheme.displayLarge?.copyWith(
                  color: titleColor,
                  fontSize: 34,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Live and upcoming things to do around you',
                style: theme.textTheme.bodyLarge?.copyWith(color: bodyColor),
              ),
              const SizedBox(height: 22),
              if (_loading)
                _EventsIndexSkeleton(
                  surfaceColor: cardSurface,
                  borderColor: borderColor,
                  mutedColor: bodyColor.withValues(alpha: 0.18),
                )
              else if (_error != null)
                _ErrorState(message: _error!, onRetry: _loadEventsIndex)
              else ...[
                _SectionTitle('Fafo Today', color: headingColor),
                const SizedBox(height: 12),
                if (_spotlightEvents.isEmpty)
                  _EmptyInline(
                    text:
                        'No spotlight events today. Check all listings below.',
                    textColor: bodyColor,
                    borderColor: borderColor,
                  )
                else
                  SizedBox(
                    height: 218,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 1,
                        vertical: 4,
                      ),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) => _SpotlightCard(
                        event: _spotlightEvents[index],
                        category:
                            _categoriesById[_spotlightEvents[index].categoryId],
                        borderColor: borderColor,
                      ),
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemCount: _spotlightEvents.length.clamp(0, 10),
                    ),
                  ),
                const SizedBox(height: 28),
                _SectionTitle('City Reads', color: headingColor),
                const SizedBox(height: 12),
                SizedBox(height: 180, child: _BlogStrip(blogs: _blogs)),
                const SizedBox(height: 28),
                _SectionTitle('Categories', color: headingColor),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _CategoryChip(
                      label: 'All',
                      isSelected: _selectedCategoryId == null,
                      isDark: isDark,
                      borderColor: borderColor,
                      onTap: () => setState(() => _selectedCategoryId = null),
                    ),
                    ..._categories.map(
                      (category) => _CategoryChip(
                        label: '${category.emoji} ${category.name}',
                        isSelected: category.id == _selectedCategoryId,
                        isDark: isDark,
                        borderColor: borderColor,
                        onTap: () => setState(() {
                          _selectedCategoryId =
                              _selectedCategoryId == category.id
                              ? null
                              : category.id;
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _SectionTitle('All Event Listings', color: headingColor),
                const SizedBox(height: 14),
                if (_filteredEvents.isEmpty)
                  _EmptyInline(
                    text: 'No events found for this category.',
                    textColor: bodyColor,
                    borderColor: borderColor,
                  )
                else
                  ..._filteredEvents.map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _EventListingCard(
                        event: event,
                        category: _categoriesById[event.categoryId],
                        surfaceColor: cardSurface,
                        shadowColor: cardShadow,
                        borderColor: borderColor,
                        titleColor: headingColor,
                        subtitleColor: bodyColor,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EventsIndexSkeleton extends StatelessWidget {
  const _EventsIndexSkeleton({
    required this.surfaceColor,
    required this.borderColor,
    required this.mutedColor,
  });

  final Color surfaceColor;
  final Color borderColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonLine(width: 118, height: 18, color: mutedColor),
        const SizedBox(height: 12),
        SizedBox(
          height: 218,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 2,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (_, _) => _SkeletonBox(
              width: 250,
              height: 210,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              mutedColor: mutedColor,
            ),
          ),
        ),
        const SizedBox(height: 28),
        _SkeletonLine(width: 96, height: 18, color: mutedColor),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 2,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, _) => _SkeletonBox(
              width: 230,
              height: 112,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              mutedColor: mutedColor,
            ),
          ),
        ),
        const SizedBox(height: 28),
        _SkeletonLine(width: 104, height: 18, color: mutedColor),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            7,
            (index) => _SkeletonLine(
              width: index.isEven ? 82 : 112,
              height: 28,
              color: mutedColor,
              radius: 6,
            ),
          ),
        ),
        const SizedBox(height: 28),
        _SkeletonLine(width: 156, height: 18, color: mutedColor),
        const SizedBox(height: 14),
        for (var i = 0; i < 3; i++) ...[
          _SkeletonBox(
            width: double.infinity,
            height: 96,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            mutedColor: mutedColor,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.surfaceColor,
    required this.borderColor,
    required this.mutedColor,
  });

  final double width;
  final double height;
  final Color surfaceColor;
  final Color borderColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonLine(width: 64, height: 42, color: mutedColor, radius: 10),
          const Spacer(),
          _SkeletonLine(width: double.infinity, height: 14, color: mutedColor),
          const SizedBox(height: 8),
          _SkeletonLine(width: 150, height: 14, color: mutedColor),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({
    required this.width,
    required this.height,
    required this.color,
    this.radius = 999,
  });

  final double width;
  final double height;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.displayMedium?.copyWith(
        color: color,
        fontSize: 18,
      ),
    );
  }
}

String _eventEmoji(EventResponse event, CategoryResponse? category) {
  if (event.customEmoji?.isNotEmpty == true) return event.customEmoji!;
  if (category?.emoji.isNotEmpty == true) return category!.emoji;
  return switch (event.eventType) {
    EventType.spotlight => '⭐',
    EventType.volunteering => '🤝',
    EventType.normal => '🎉',
  };
}

class _EventIconTile extends StatelessWidget {
  const _EventIconTile({
    required this.emoji,
    required this.eventType,
    required this.iconSize,
  });

  final String emoji;
  final EventType eventType;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final accent = switch (eventType) {
      EventType.spotlight => AppColors.accentWarm,
      EventType.volunteering => const Color(0xFF4ADE80),
      EventType.normal => AppColors.accentLight1,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            accent.withValues(alpha: 0.24),
          ],
        ),
      ),
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: iconSize)),
      ),
    );
  }
}

class _EventListingCard extends StatelessWidget {
  const _EventListingCard({
    required this.event,
    required this.category,
    required this.surfaceColor,
    required this.shadowColor,
    required this.borderColor,
    required this.titleColor,
    required this.subtitleColor,
  });

  final EventResponse event;
  final CategoryResponse? category;
  final Color surfaceColor;
  final Color shadowColor;
  final Color borderColor;
  final Color titleColor;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emoji = _eventEmoji(event, category);

    return GestureDetector(
      onTap: () => context.push('/event/${event.id}'),
      child: Padding(
        // Keep enough breathing room for the offset shadow and rounded right
        // corners so the card is not clipped by the list viewport.
        padding: const EdgeInsets.only(right: 12, bottom: 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Transform.translate(
                offset: const Offset(4, 4),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: shadowColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.7),
              ),
              child: Row(
                children: [
                  Container(
                    width: 82,
                    height: 62,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor, width: 1.2),
                    ),
                    child: _EventIconTile(
                      emoji: emoji,
                      eventType: event.eventType,
                      iconSize: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${category?.emoji ?? '📍'} ${category?.name ?? event.categoryId}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.accentPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (event.eventType == EventType.volunteering) ...[
                              const SizedBox(width: 6),
                              const _VolunteeringTag(),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: titleColor,
                            fontSize: 17,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${DateFormat('EEE, MMM d • h:mm a').format(event.dateTime.toLocal())} • ${event.locationName}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: subtitleColor,
                            fontWeight: FontWeight.w600,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 82,
                    child: Column(
                      children: [
                        _CountPill(count: event.joineeCount),
                        const SizedBox(height: 10),
                        _CardButton(
                          label: event.isJoined
                              ? 'JOINED'
                              : event.registrationOpen
                              ? 'JOIN'
                              : 'FULL',
                          filled: event.registrationOpen || event.isJoined,
                          onTap: () => context.push('/event/${event.id}'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotlightCard extends StatelessWidget {
  const _SpotlightCard({
    required this.event,
    required this.category,
    required this.borderColor,
  });

  final EventResponse event;
  final CategoryResponse? category;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emoji = _eventEmoji(event, category);

    return GestureDetector(
      onTap: () => context.push('/event/${event.id}'),
      child: Container(
        width: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.7),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.3),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _EventIconTile(
                emoji: emoji,
                eventType: event.eventType,
                iconSize: 72,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.ink.withValues(alpha: 0.05),
                      AppColors.ink.withValues(alpha: 0.82),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'TODAY • ${category?.emoji ?? '⚡'} ${category?.name ?? 'Event'}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        // Light blue reads on the photo's dark scrim; the medium
                        // brand blue was invisible over images.
                        color: AppColors.accentLight2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 21,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('h:mm a').format(event.dateTime.toLocal()),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlogStrip extends StatelessWidget {
  const _BlogStrip({required this.blogs});

  final List<BlogResponse> blogs;

  @override
  Widget build(BuildContext context) {
    if (blogs.isEmpty) {
      return const Center(child: Text('No city reads yet.'));
    }
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      padding: const EdgeInsets.fromLTRB(1, 0, 28, 8),
      itemBuilder: (context, index) => _BlogCard(blog: blogs[index]),
      separatorBuilder: (_, _) => const SizedBox(width: 14),
      itemCount: blogs.length,
    );
  }
}

class _BlogCard extends StatelessWidget {
  const _BlogCard({required this.blog});

  final BlogResponse blog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF161616), width: 1.8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 0,
              offset: Offset(4, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              blog.imageUrl ??
                  'https://picsum.photos/seed/blog-${blog.id}/900/600',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Container(color: AppColors.accentPrimary),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.ink.withValues(alpha: 0.05),
                    AppColors.ink.withValues(alpha: 0.32),
                    AppColors.ink.withValues(alpha: 0.88),
                  ],
                  stops: const [0, 0.48, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    blog.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 22,
                      height: 0.95,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.accentPrimary, width: 1.4),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count in',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.accentPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _VolunteeringTag extends StatelessWidget {
  const _VolunteeringTag();

  // Matches the green volunteering pin color used on the map.
  static const Color _green = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        'Volunteering',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: const Color(0xFF0A2540),
          fontWeight: FontWeight.w800,
          fontSize: 9,
        ),
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = filled ? AppColors.accentPrimary : Colors.grey;
    final textColor = filled ? Colors.white : Colors.grey;

    return AppPressable(
      onTap: onTap,
      child: Container(
        height: 28,
        decoration: BoxDecoration(
          color: filled ? AppColors.accentPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: 1.4),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isDark;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: borderColor, width: 1.1),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: isSelected
                ? Colors.white
                : isDark
                ? Colors.white
                : const Color(0xFF303030),
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _EmptyInline extends StatelessWidget {
  const _EmptyInline({
    required this.text,
    required this.textColor,
    required this.borderColor,
  });

  final String text;
  final Color textColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Text(text, style: TextStyle(color: textColor)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Text(
            'Could not load events',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
