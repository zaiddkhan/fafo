import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/services/network_status.dart';
import 'package:fafu/src/core/theme/app_chrome.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/features/notifications/data/notification_nag.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';

/// Persistent strips above the bottom nav: "No connection" while the server
/// can't be reached (then a brief "Back online"), and "Notifications are off"
/// once the permission has been refused a couple of times.
class FafoStatusBars extends ConsumerStatefulWidget {
  const FafoStatusBars({super.key});

  @override
  ConsumerState<FafoStatusBars> createState() => _FafoStatusBarsState();
}

class _FafoStatusBarsState extends ConsumerState<FafoStatusBars> with WidgetsBindingObserver {
  bool _backOnline = false;
  Timer? _backTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _backTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from system settings: maybe they just switched notifications on.
    if (state == AppLifecycleState.resumed) ref.read(notificationNagProvider.notifier).recheck();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(networkStatusProvider, (was, online) {
      if (was == false && online) {
        _backTimer?.cancel();
        setState(() => _backOnline = true);
        _backTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _backOnline = false);
        });
      }
    });
    final online = ref.watch(networkStatusProvider);
    final notificationsOff = ref.watch(notificationNagProvider);

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!online)
            const _OfflineBar()
          else if (_backOnline)
            const _BackOnlineBar(),
          if (notificationsOff)
            _NotificationsOffBar(onTap: () => ref.read(notificationNagProvider.notifier).openSettings()),
        ],
      ),
    );
  }
}

/// Ink strip with a blinking red dot: you can't send or get plans right now.
class _OfflineBar extends StatelessWidget {
  const _OfflineBar();

  @override
  Widget build(BuildContext context) {
    // Inverted strip: ink on light, paper on dark.
    final bg = AppColors.textPrimary;
    final fg = AppColors.bgPrimary;
    return Semantics(
      liveRegion: true,
      label: 'No connection. Plans can’t send or arrive until you’re back online.',
      child: Container(
        width: double.infinity,
        color: bg,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Row(
          children: [
            const _Blink(child: _Dot(color: AppColors.signalRed)),
            const SizedBox(width: 10),
            FafoEyebrow('No connection', fontSize: 10.5, color: fg),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Plans can’t send or arrive. Retrying…',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.ui(12.5, fontWeight: FontWeight.w600, color: fg.withValues(alpha: 0.8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackOnlineBar extends StatelessWidget {
  const _BackOnlineBar();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Back online.',
      child: Container(
        width: double.infinity,
        color: AppColors.accentPrimary,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Row(
          children: [
            const _Dot(color: AppColors.onAccent),
            const SizedBox(width: 10),
            const FafoEyebrow('Back online', fontSize: 10.5, color: AppColors.onAccent),
          ],
        ),
      ),
    );
  }
}

/// Tap anywhere to open the app's notification settings.
class _NotificationsOffBar extends StatelessWidget {
  const _NotificationsOffBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Notifications are off. You won’t hear when someone nudges you. Turn on in settings.',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 10, 14, 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.rule, width: AppChrome.outlineWidth)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.signalRed,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.ink, width: AppChrome.outlineWidth),
                ),
                child: const Icon(Icons.notifications_off_outlined, size: 17, color: AppColors.onAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Notifications are off', style: AppTypography.ui(14, fontWeight: FontWeight.w700)),
                    Text(
                      'Friends’ nudges won’t reach you.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.ui(12.5, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              IgnorePointer(child: FafoPill(label: 'Turn on', small: true, height: 36, onPressed: onTap)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

/// Slow on/off blink; still under reduce-motion.
class _Blink extends StatefulWidget {
  const _Blink({required this.child});

  final Widget child;

  @override
  State<_Blink> createState() => _BlinkState();
}

class _BlinkState extends State<_Blink> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return FadeTransition(opacity: Tween(begin: 1.0, end: 0.25).animate(_controller), child: widget.child);
  }
}
