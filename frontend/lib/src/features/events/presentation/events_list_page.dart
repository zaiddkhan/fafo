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

enum _AreaFilter {
  all('All areas'),
  mumbai('Mumbai'),
  bengaluru('Bengaluru');

  const _AreaFilter(this.label);

  final String label;
}

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
  _AreaFilter _selectedArea = _AreaFilter.all;
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
      _loading = true;
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
        blogsRepo.getBlogs(city: _selectedBlogCity, limit: 10),
      ]);

      final categories = results[0] as List<CategoryResponse>;
      final mumbaiEvents = results[1] as List<EventResponse>;
      final bangaloreEvents = results[2] as List<EventResponse>;
      final blogs = results[3] as List<BlogResponse>;
      final eventsById = <String, EventResponse>{
        for (final event in [...mumbaiEvents, ...bangaloreEvents])
          event.id: event,
      };
      final events = eventsById.values.toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

      if (!mounted) return;
      setState(() {
        _categories = categories;
        _events = events;
        _blogs = blogs;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _selectedBlogCity => switch (_selectedArea) {
    _AreaFilter.mumbai => 'Mumbai',
    _AreaFilter.bengaluru || _AreaFilter.all => 'Bengaluru',
  };

  List<EventResponse> get _areaFilteredEvents {
    return _events.where(_matchesSelectedArea).toList(growable: false);
  }

  List<EventResponse> get _filteredEvents {
    return _areaFilteredEvents
        .where((event) {
          return _selectedCategoryId == null ||
              event.categoryId == _selectedCategoryId;
        })
        .toList(growable: false);
  }

  bool _matchesSelectedArea(EventResponse event) {
    final location = event.locationName.toLowerCase();
    return switch (_selectedArea) {
      _AreaFilter.all => true,
      _AreaFilter.mumbai => location.contains('mumbai'),
      _AreaFilter.bengaluru =>
        location.contains('bengaluru') || location.contains('bangalore'),
    };
  }

  List<EventResponse> get _spotlightEvents {
    final today = DateTime.now();
    return _areaFilteredEvents
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
                'Live and upcoming things to do around Mumbai and Bengaluru.',
                style: theme.textTheme.bodyLarge?.copyWith(color: bodyColor),
              ),
              const SizedBox(height: 22),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _ErrorState(message: _error!, onRetry: _loadEventsIndex)
              else ...[
                _SectionTitle('WhatsPopn Today', color: headingColor),
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
                    height: 210,
                    child: ListView.separated(
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
                SizedBox(height: 172, child: _BlogStrip(blogs: _blogs)),
                const SizedBox(height: 28),
                _SectionTitle('Areas', color: headingColor),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _AreaFilter.values
                      .map(
                        (area) => _CategoryChip(
                          label: area.label,
                          isSelected: area == _selectedArea,
                          isDark: isDark,
                          borderColor: borderColor,
                          onTap: () {
                            setState(() => _selectedArea = area);
                            _loadEventsIndex();
                          },
                        ),
                      )
                      .toList(),
                ),
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
                    text: 'No events found for this area/category combination.',
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
    final imageUrl =
        event.bannerUrl ?? 'https://picsum.photos/seed/${event.id}/600/600';

    return GestureDetector(
      onTap: () => context.push('/event/${event.id}'),
      child: Padding(
        padding: const EdgeInsets.only(right: 6, bottom: 6),
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
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.7),
              ),
              child: Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor, width: 1.2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.event_rounded,
                        color: titleColor,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${category?.emoji ?? '📍'} ${category?.name ?? event.categoryId}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.accentPrimary,
                            fontWeight: FontWeight.w800,
                          ),
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
                          label: event.registrationOpen ? 'JOIN' : 'FULL',
                          filled: event.registrationOpen,
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
    final imageUrl =
        event.bannerUrl ?? 'https://picsum.photos/seed/${event.id}/700/500';

    return GestureDetector(
      onTap: () => context.push('/event/${event.id}'),
      child: Container(
        width: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.7),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(imageUrl, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.82),
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
                      color: AppColors.accentPrimary,
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
      itemBuilder: (context, index) => _BlogCard(blog: blogs[index]),
      separatorBuilder: (_, _) => const SizedBox(width: 12),
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
              blog.imageUrl ?? 'https://picsum.photos/seed/blog-${blog.id}/900/600',
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
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.32),
                    Colors.black.withValues(alpha: 0.88),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFEF8),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFF161616)),
                    ),
                    child: Text(
                      '${blog.city} • ${blog.readTime ?? '3 min read'}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF161616),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    blog.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 22,
                      height: 0.95,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          blog.subtitle ?? blog.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.86),
                            fontWeight: FontWeight.w700,
                            height: 1.12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.accentPrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF161616),
                          size: 18,
                        ),
                      ),
                    ],
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
    final textColor = filled ? const Color(0xFF1A1A1A) : Colors.grey;

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
                ? const Color(0xFF181818)
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
