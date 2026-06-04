import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fafu/src/core/constants/app_spacing.dart';
import 'package:fafu/src/core/theme/app_chrome.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/theme_mode_controller.dart';
import 'package:fafu/src/features/friends/presentation/friends_page.dart';
import 'package:fafu/src/features/create/presentation/create_tab.dart';
import 'package:fafu/src/features/events/presentation/events_list_page.dart';
import 'package:fafu/src/features/home/presentation/home_page.dart';
import 'package:fafu/src/features/profile/presentation/profile_page.dart';
import 'package:fafu/src/features/users/data/users_repository.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  static const routeName = 'main';
  static const routePath = '/main';

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final _mapKey = GlobalKey();
  final _sideQuestsKey = GlobalKey();

  int _stackIndex = 0; // Index into IndexedStack (0-3)
  int _navIndex = 0; // Index in bottom nav (0-4)
  OverlayEntry? _tooltipOverlay;
  _FirstLaunchTooltipStep _tooltipStep = _FirstLaunchTooltipStep.map;
  bool _tooltipStarted = false;
  bool _tooltipCompleting = false;

  @override
  void dispose() {
    _tooltipOverlay?.remove();
    super.dispose();
  }

  void _maybeStartFirstLaunchTooltips() {
    if (_tooltipStarted || _tooltipCompleting) return;

    // TEST MODE: always show the tooltip sequence whenever the main/home shell
    // is opened. Restore the profile flag check before release.
    _tooltipStarted = true;
    _tooltipStep = _FirstLaunchTooltipStep.map;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showTooltipOverlay();
    });
  }

  Rect? _rectFor(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return null;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    final offset = renderObject.localToGlobal(Offset.zero);
    return offset & renderObject.size;
  }

  Future<void> _completeFirstLaunchTooltips() async {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
    if (_tooltipCompleting) return;
    _tooltipCompleting = true;

    try {
      await ref.read(usersRepositoryProvider).completeFirstLaunchTooltip();
      ref.invalidate(currentProfileProvider);
    } catch (_) {
      // The user has already seen the tips in this session. If the network
      // update fails, the server flag will remain false and can retry later.
    }
  }

  void _nextTooltipStep() {
    if (_tooltipStep == _FirstLaunchTooltipStep.map) {
      _tooltipStep = _FirstLaunchTooltipStep.sideQuests;
      _showTooltipOverlay();
    } else {
      _completeFirstLaunchTooltips();
    }
  }

  void _showTooltipOverlay() {
    _tooltipOverlay?.remove();

    final targetRect = _rectFor(
      _tooltipStep == _FirstLaunchTooltipStep.map
          ? _mapKey
          : _sideQuestsKey,
    );
    if (targetRect == null) return;

    _tooltipOverlay = OverlayEntry(
      builder: (context) => _FirstLaunchTooltipOverlay(
        targetRect: targetRect,
        step: _tooltipStep,
        onNext: _nextTooltipStep,
        onSkip: _completeFirstLaunchTooltips,
      ),
    );
    Overlay.of(context).insert(_tooltipOverlay!);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeControllerProvider);
    _maybeStartFirstLaunchTooltips();

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: KeyedSubtree(
              key: ValueKey(_stackIndex),
              child: IndexedStack(
                index: _stackIndex,
                children: [
                  KeyedSubtree(key: _mapKey, child: const HomePage()),
                  const EventsListPage(events: []),
                  const CreateTab(),
                  const ProfilePage(savedEvents: []),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomNav(
              currentIndex: _navIndex,
              sideQuestsKey: _sideQuestsKey,
              onTap: (index) {
                if (index == 3) {
                  context.push(FriendsPage.routePath);
                  return;
                }
                setState(() {
                  _navIndex = index;
                  // Map nav index to stack index (skip chat at 3)
                  _stackIndex = index > 3 ? index - 1 : index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.currentIndex,
    required this.sideQuestsKey,
    required this.onTap,
  });

  final int currentIndex;
  final GlobalKey sideQuestsKey;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF050505) : const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(AppChrome.cardRadiusLg),
            border: AppChrome.outlineBorder,
            boxShadow: isDark
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 0,
                      offset: Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavItem(
                icon: Icons.map_outlined,
                activeIcon: Icons.map,
                label: 'Explore',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                key: sideQuestsKey,
                icon: Icons.list_outlined,
                activeIcon: Icons.list,
                label: 'Side Quests',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.add_circle_outline,
                activeIcon: Icons.add_circle,
                label: 'Create',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.people_alt_outlined,
                activeIcon: Icons.people_alt,
                label: 'Friends',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                isActive: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isActive
        ? Colors.white
        : (isDark ? const Color(0xFF8D8D98) : const Color(0xFF666874));

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: isActive ? 56 : 44,
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, color: color, size: 22),
            if (isActive) ...[
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _FirstLaunchTooltipStep { map, sideQuests }

class _FirstLaunchTooltipOverlay extends StatelessWidget {
  const _FirstLaunchTooltipOverlay({
    required this.targetRect,
    required this.step,
    required this.onNext,
    required this.onSkip,
  });

  final Rect targetRect;
  final _FirstLaunchTooltipStep step;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final tooltipWidth = size.width < 420 ? size.width - 32 : 360.0;
    final isMapStep = step == _FirstLaunchTooltipStep.map;
    final tooltipTop = isMapStep
        ? 92.0
        : (targetRect.top - 178).clamp(16.0, size.height - 190.0);
    final tooltipLeft = isMapStep
        ? ((size.width - tooltipWidth) / 2).clamp(16.0, size.width)
        : (targetRect.center.dx - tooltipWidth / 2).clamp(
            16.0,
            size.width - tooltipWidth - 16.0,
          );

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.56)),
          ),
          Positioned.fromRect(
            rect: targetRect.inflate(isMapStep ? -12 : 8),
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isMapStep ? 24 : 18),
                  border: Border.all(color: AppColors.accentPrimary, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: tooltipLeft,
            top: tooltipTop,
            width: tooltipWidth,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF111111)
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppChrome.cardRadiusLg),
                border: AppChrome.outlineBorder,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isMapStep ? 'Explore what\'s popping' : 'Find Side Quests',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    isMapStep
                        ? 'Use the map to discover nearby events, hangs, and pop-ups around you.'
                        : 'Tap Side Quests to see events in a list when you want to browse faster.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(onPressed: onSkip, child: const Text('Skip')),
                      FilledButton(
                        onPressed: onNext,
                        child: Text(isMapStep ? 'Next' : 'Got it'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
