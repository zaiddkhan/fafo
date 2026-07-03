import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fafu/src/core/constants/app_spacing.dart';
import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/theme/app_chrome.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/categories/data/categories_providers.dart';
import 'package:fafu/src/features/categories/domain/category.dart';
import 'package:fafu/src/features/events/data/events_repository.dart';
import 'package:fafu/src/features/events/domain/event.dart';

/// Live events search with server-side text/category filtering and cursor-based
/// lazy pagination. [lat]/[lng] scope the search to the user's current area.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key, required this.lat, required this.lng});

  final double lat;
  final double lng;

  static const routeName = 'search';
  static const routePath = '/search';

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  String? _selectedCategoryId;

  final List<EventResponse> _items = [];
  String? _cursor;
  bool _hasMore = true;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;

  /// Bumps on every reset so stale in-flight responses can be discarded.
  int _searchSeq = 0;

  static const _radiusKm = 50.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _search(reset: true));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 320) {
      _search(reset: false);
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _search(reset: true);
    });
  }

  void _onCategorySelected(String? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    setState(() => _selectedCategoryId = categoryId);
    _search(reset: true);
  }

  Future<void> _search({required bool reset}) async {
    if (reset) {
      _searchSeq++;
      setState(() {
        _loading = true;
        _error = null;
        _items.clear();
        _cursor = null;
        _hasMore = true;
      });
    } else {
      if (!_hasMore || _loadingMore) return;
      setState(() => _loadingMore = true);
    }
    final seq = _searchSeq;

    try {
      final page = await ref.read(eventsRepositoryProvider).searchEvents(
            lat: widget.lat,
            lng: widget.lng,
            radiusKm: _radiusKm,
            categoryId: _selectedCategoryId,
            query: _searchController.text,
            cursor: reset ? null : _cursor,
          );
      // Discard results from a superseded search.
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _items.addAll(page.items);
        _cursor = page.nextCursor;
        _hasMore = page.hasMore && page.nextCursor != null;
      });
    } catch (e) {
      if (!mounted || seq != _searchSeq) return;
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted && seq == _searchSeq) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  String _friendlyError(Object e) {
    if (e is ApiException) return e.message;
    return 'Something went wrong. Pull to retry.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ref.watch(categoriesProvider).asData?.value ?? const [];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
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
                      textInputAction: TextInputAction.search,
                      onChanged: _onSearchChanged,
                      onSubmitted: (_) => _search(reset: true),
                      decoration: const InputDecoration(
                        hintText: 'Search live events, places...',
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
            _CategoryChips(
              categories: categories,
              selectedId: _selectedCategoryId,
              onSelected: _onCategorySelected,
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(child: _buildBody(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentPrimary),
      );
    }
    if (_error != null && _items.isEmpty) {
      return _CenteredMessage(
        message: _error!,
        actionLabel: 'Retry',
        onAction: () => _search(reset: true),
      );
    }
    if (_items.isEmpty) {
      return const _CenteredMessage(message: 'No live events found');
    }

    return RefreshIndicator(
      onRefresh: () => _search(reset: true),
      child: ListView.separated(
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        // One trailing slot for the load-more spinner / end-of-list marker.
        itemCount: _items.length + 1,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          if (index >= _items.length) return _buildFooter(theme);
          final event = _items[index];
          return GestureDetector(
            onTap: () => context.push('/event/${event.id}'),
            child: _SearchResultCard(event: event),
          );
        },
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(
          child: SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accentPrimary,
            ),
          ),
        ),
      );
    }
    if (!_hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(
          child: Text(
            'That\'s everything nearby',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: AppSpacing.md);
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<CategoryResponse> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // "All" (null id) followed by each backend category.
    final chips = <({String? id, String label})>[
      (id: null, label: 'All'),
      for (final c in categories) (id: c.id, label: c.name),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: chips.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final chip = chips[index];
          final isSelected = chip.id == selectedId;
          return GestureDetector(
            onTap: () => onSelected(chip.id),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentPrimary
                    : AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(AppChrome.controlRadius),
                border: isSelected ? null : AppChrome.outlineBorder,
                boxShadow: isSelected ? AppChrome.cardShadowSoft : null,
              ),
              child: Text(
                chip.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.event});

  final EventResponse event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final when = DateFormat('EEE, MMM d • h:mm a').format(event.dateTime.toLocal());

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
          _Thumbnail(event: event),
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
                  when,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  event.locationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.event});

  final EventResponse event;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppChrome.controlRadius);
    final banner = event.bannerUrl;
    if (banner != null && banner.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          banner,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (_, e, s) => _placeholder(radius),
        ),
      );
    }
    return _placeholder(radius);
  }

  Widget _placeholder(BorderRadius radius) {
    final emoji = (event.customEmoji != null && event.customEmoji!.isNotEmpty)
        ? event.customEmoji!
        : '📍';
    return Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: radius),
      child: Text(emoji, style: const TextStyle(fontSize: 28)),
    );
  }
}
