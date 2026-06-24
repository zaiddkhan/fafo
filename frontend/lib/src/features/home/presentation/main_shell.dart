import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/constants/app_spacing.dart';
import 'package:fafu/src/core/theme/app_chrome.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/theme_mode_controller.dart';
import 'package:fafu/src/features/friends/presentation/friends_page.dart';
import 'package:fafu/src/features/create/presentation/create_tab.dart';
import 'package:fafu/src/features/events/presentation/events_list_page.dart';
import 'package:fafu/src/features/home/presentation/home_page.dart';
import 'package:fafu/src/features/profile/presentation/profile_page.dart';
import 'package:fafu/src/features/notifications/data/push_service.dart';
import 'package:fafu/src/features/quests/presentation/quests_page.dart';
import 'package:fafu/src/features/users/data/users_repository.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  static const routeName = 'main';
  static const routePath = '/main';

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final _questsKey = GlobalKey();
  final _friendsKey = GlobalKey();

  int _stackIndex = 0; // Index into IndexedStack (0-5)
  int _navIndex = 0; // Index in bottom nav (0-5)
  OverlayEntry? _tooltipOverlay;
  _FirstLaunchTooltipStep _tooltipStep = _FirstLaunchTooltipStep.map;
  bool _tooltipStarted = false;
  bool _tooltipCompleting = false;

  @override
  void initState() {
    super.initState();
    // The user is signed in and in the app shell — set up push (permission,
    // FCM token registration, timezone). Fire-and-forget; never blocks the UI.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(pushServiceProvider).initialize();
    });
  }

  @override
  void dispose() {
    _tooltipOverlay?.remove();
    super.dispose();
  }

  void _maybeStartFirstLaunchTooltips() {
    if (_tooltipStarted || _tooltipCompleting) return;

    // Only show the tooltip sequence to users who haven't completed it. While
    // the profile is still loading we hold off (treat as "done" so we never
    // flash tips at a returning user before their flag arrives).
    final profile = ref.read(currentProfileProvider);
    final alreadySeen = profile.value?.firstLaunchTooltipComplete ?? true;
    if (alreadySeen) return;

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
    } else if (_tooltipStep == _FirstLaunchTooltipStep.sideQuests) {
      _tooltipStep = _FirstLaunchTooltipStep.nudgeFeed;
      _showTooltipOverlay();
    } else {
      _completeFirstLaunchTooltips();
    }
  }

  void _showTooltipOverlay() {
    _tooltipOverlay?.remove();

    final targetRect = _tooltipStep == _FirstLaunchTooltipStep.map
        ? Rect.fromLTWH(
            16,
            MediaQuery.paddingOf(context).top + 88,
            MediaQuery.sizeOf(context).width - 32,
            120,
          )
        : _rectFor(switch (_tooltipStep) {
            _FirstLaunchTooltipStep.map => _questsKey,
            _FirstLaunchTooltipStep.sideQuests => _questsKey,
            _FirstLaunchTooltipStep.nudgeFeed => _friendsKey,
          });
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
    // Watch the profile so this rebuilds (and re-evaluates the tooltip gate)
    // once the first-launch flag loads.
    ref.watch(currentProfileProvider);
    _maybeStartFirstLaunchTooltips();

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _stackIndex,
            children: [
              const HomePage(),
              const EventsListPage(events: []),
              const QuestsPage(),
              const CreateTab(),
              const FriendsPage(showBackButton: false),
              const ProfilePage(savedEvents: []),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomNav(
              currentIndex: _navIndex,
              questsKey: _questsKey,
              friendsKey: _friendsKey,
              onTap: (index) {
                setState(() {
                  _navIndex = index;
                  _stackIndex = index;
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
    required this.questsKey,
    required this.friendsKey,
    required this.onTap,
  });

  final int currentIndex;
  final GlobalKey questsKey;
  final GlobalKey friendsKey;
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
                label: 'Map',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.list_outlined,
                activeIcon: Icons.list,
                label: 'Explore',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                key: questsKey,
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore,
                label: 'Quests',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.add_circle_outline,
                activeIcon: Icons.add_circle,
                label: 'Create',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                key: friendsKey,
                icon: Icons.people_alt_outlined,
                activeIcon: Icons.people_alt,
                label: 'Friends',
                isActive: currentIndex == 4,
                onTap: () => onTap(4),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                isActive: currentIndex == 5,
                onTap: () => onTap(5),
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

enum _FirstLaunchTooltipStep { map, sideQuests, nudgeFeed }

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
    final isNudgeStep = step == _FirstLaunchTooltipStep.nudgeFeed;
    // Nudge step shows a taller card (it embeds a sample friend screen), so it
    // needs to sit higher above the bottom-nav target.
    final liftAbove = isNudgeStep ? 360.0 : 178.0;
    final tooltipTop = isMapStep
        ? 92.0
        : (targetRect.top - liftAbove).clamp(16.0, size.height - 190.0);
    // Keep the instructional card centered on every step. Anchoring it to
    // edge nav items made the card appear randomly left/right aligned.
    final tooltipLeft = ((size.width - tooltipWidth) / 2).clamp(
      16.0,
      size.width - tooltipWidth - 16.0,
    );

    final (title, body) = switch (step) {
      _FirstLaunchTooltipStep.map => (
        'Explore what\'s popping',
        'Use the map to discover nearby events, hangs, and pop-ups around you.',
      ),
      _FirstLaunchTooltipStep.sideQuests => (
        'Take on Side Quests',
        'Tap Quests for Fafo challenges around your city — quick solo missions to fill your free time.',
      ),
      _FirstLaunchTooltipStep.nudgeFeed => (
        'Nudge your friends',
        'Add friends to swap time-bound nudge cards. Here\'s what a feed looks like:',
      ),
    };

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
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (isNudgeStep) ...[
                    const SizedBox(height: AppSpacing.md),
                    const _SampleNudgeFeed(),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(onPressed: onSkip, child: const Text('Skip')),
                      FilledButton(
                        onPressed: onNext,
                        child: Text(isNudgeStep ? 'Got it' : 'Next'),
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

/// A non-interactive preview of a friend's nudge feed, shown during onboarding
/// so a brand-new user understands the feed before they have any friends.
class _SampleNudgeFeed extends StatelessWidget {
  const _SampleNudgeFeed();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1B1B1B)
            : const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7EEFB),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: Colors.black, width: 1.2),
                ),
                child: const Center(
                  child: Text('☕', style: TextStyle(fontSize: 15)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Aanya',
                style: TextStyle(
                  color: AppColors.accentPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const _SampleNudgeCard(
            title: 'Meet at coffee place',
            subtitle: 'Starting in 15 min',
            accepted: false,
          ),
          const SizedBox(height: 8),
          const _SampleNudgeCard(
            title: 'Catch the 6pm gig?',
            subtitle: 'Accepted • 04:58',
            accepted: true,
          ),
        ],
      ),
    );
  }
}

class _SampleNudgeCard extends StatelessWidget {
  const _SampleNudgeCard({
    required this.title,
    required this.subtitle,
    required this.accepted,
  });
  final String title;
  final String subtitle;
  final bool accepted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF111111)
            : Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.black, width: 1.2),
      ),
      child: Row(
        children: [
          const Text('👉', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: accepted
                        ? const Color(0xFFE5484D)
                        : const Color(0xFF6D6D78),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accepted
                  ? const Color(0xFF38A849)
                  : AppColors.accentPrimary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              accepted ? 'YES' : 'Yes / No',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
