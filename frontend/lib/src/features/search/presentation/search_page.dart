import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fafu/src/core/constants/app_spacing.dart';
import 'package:fafu/src/core/theme/app_chrome.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/home/data/mock_events.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.events});

  final List<MockEvent> events;

  static const routeName = 'search';
  static const routePath = '/search';

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  String? _selectedCategory;

  static const _categories = [
    'All',
    'Live Music',
    'Nightlife',
    'Food & Drinks',
    'Comedy',
    'Art & Culture',
    'Wellness',
    'Sports',
    'Tech',
  ];

  List<MockEvent> get _filtered {
    var results = widget.events;

    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      results = results
          .where(
            (e) =>
                e.title.toLowerCase().contains(query) ||
                e.venue.toLowerCase().contains(query) ||
                e.category.toLowerCase().contains(query),
          )
          .toList();
    }

    if (_selectedCategory != null && _selectedCategory != 'All') {
      results = results.where((e) => e.category == _selectedCategory).toList();
    }

    return results;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = _filtered;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: theme.textTheme.bodyLarge,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search events, places...',
                        prefixIcon: Icon(Icons.search, size: 20),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Category chips
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: _categories.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected =
                      _selectedCategory == cat ||
                      (cat == 'All' && _selectedCategory == null);

                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedCategory = cat == 'All' ? null : cat;
                    }),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentPrimary
                            : AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(
                          AppChrome.controlRadius,
                        ),
                        border: isSelected ? null : AppChrome.outlineBorder,
                        boxShadow: isSelected ? AppChrome.cardShadowSoft : null,
                      ),
                      child: Text(
                        cat,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Results
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Text(
                        'No events found',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      itemCount: results.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final event = results[index];
                        return GestureDetector(
                          onTap: () =>
                              context.push('/event/${event.id}', extra: event),
                          child: _SearchResultCard(event: event),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.event});

  final MockEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 88,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppChrome.cardRadius),
        border: AppChrome.outlineBorder,
        boxShadow: AppChrome.cardShadowSoft,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppChrome.controlRadius),
            child: Image.network(
              event.imageUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, e, s) =>
                  Container(width: 72, height: 72, color: AppColors.bgTertiary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${event.time}  ·  ${event.venue}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  event.category,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.accentLight1,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}
