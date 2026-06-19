import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:maplibre/maplibre.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fafu/src/core/config/map_config.dart';
import 'package:fafu/src/core/constants/app_spacing.dart';
import 'package:fafu/src/core/theme/app_chrome.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/events/data/events_repository.dart';
import 'package:fafu/src/features/events/domain/event.dart';
import 'package:fafu/src/features/home/data/mock_events.dart';
import 'package:fafu/src/shared/widgets/app_pressable.dart';
import 'package:fafu/src/shared/widgets/negative_action_dialog.dart';

class EventDetailPage extends ConsumerStatefulWidget {
  const EventDetailPage({super.key, required this.eventId, this.initialEvent});

  final String eventId;
  final MockEvent? initialEvent;

  static const routeName = 'event-detail';
  static const routePath = '/event/:id';

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage>
    with SingleTickerProviderStateMixin {
  static const _celebrationLottieAsset = 'assets/gifs/Confetti.lottie';

  bool _saved = false;
  bool _showCelebration = false;
  bool _loading = true;
  bool _joining = false;
  bool _joined = false;
  String? _error;
  EventResponse? _backendEvent;
  Timer? _celebrationTimer;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  @override
  void dispose() {
    _celebrationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadEvent() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final event = await ref
          .read(eventsRepositoryProvider)
          .getEvent(widget.eventId);
      if (mounted) {
        setState(() {
          _backendEvent = event;
          _joined = event.isJoined;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleRegisterTap() async {
    if (_joining) return;

    // Organizers attend their own event implicitly and can't RSVP as attendees.
    if (_isOwner) return;

    if (_joined) {
      await _handleUnjoinTap();
      return;
    }

    if (_isFull || !_registrationOpen || _joinWindowClosed) return;

    // PRD: a confirmation popup appears on joining.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join this event?'),
        content: const Text('You can leave anytime up to 10 minutes after it starts.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Join')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _joining = true;
      _error = null;
    });

    try {
      await ref.read(eventsRepositoryProvider).joinEvent(widget.eventId);
      if (!mounted) return;
      _celebrationTimer?.cancel();
      setState(() {
        _joined = true;
        _showCelebration = true;
      });
      await _loadEvent();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('You joined this event.')));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _handleUnjoinTap() async {
    final reason = await showModalBottomSheet<UnjoinReason>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Why are you leaving this event?')),
            for (final option in UnjoinReason.values)
              ListTile(
                title: Text(_unjoinReasonLabel(option)),
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
      ),
    );
    if (reason == null || !mounted) return;

    // PRD: every negative action requires a 3-to-5 question questionnaire gate.
    final answers = await showNegativeActionQuestionnaire(
      context,
      title: 'Leave this event?',
      confirmLabel: 'Leave event',
      questions: const [
        'What changed since you joined?',
        'Could anything have kept you in?',
        'Anything the organizer should know?',
      ],
    );
    if (answers == null || !mounted) return;

    setState(() {
      _joining = true;
      _error = null;
    });

    try {
      await ref
          .read(eventsRepositoryProvider)
          .unjoinEvent(widget.eventId, reason: reason, answers: answers);
      if (!mounted) return;
      setState(() => _joined = false);
      await _loadEvent();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You left this event.')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  String _unjoinReasonLabel(UnjoinReason reason) {
    return switch (reason) {
      UnjoinReason.changeOfPlans => 'Change of plans',
      UnjoinReason.schedulingConflict => 'Scheduling conflict',
      UnjoinReason.noLongerInterested => 'No longer interested',
      UnjoinReason.other => 'Other',
    };
  }

  MockEvent? get _displayEvent {
    final backend = _backendEvent;
    if (backend == null) return widget.initialEvent;

    final initial = widget.initialEvent;
    final dateTime = backend.dateTime.toLocal();
    return MockEvent(
      id: backend.id,
      title: backend.title,
      category: initial?.category ?? backend.categoryId,
      time: DateFormat('h:mm a').format(dateTime),
      venue: backend.locationName,
      lat: backend.lat,
      lng: backend.lng,
      attendees: backend.joineeCount,
      isFree: initial?.isFree ?? true,
      friendsOnly: false,
      rating: initial?.rating ?? 4.7,
      timing: initial?.timing ?? MockEventTiming.today,
      organizerName: initial?.organizerName ?? 'Fafo Creator',
      organizerContact: initial?.organizerContact ?? '',
      organizerInstagram: initial?.organizerInstagram ?? '',
      organizerVerified: true,
      imageUrl:
          backend.bannerUrl ??
          initial?.imageUrl ??
          'https://picsum.photos/seed/${backend.id}/600/800',
      eventType: backend.eventType.name,
      customEmoji: backend.customEmoji,
    );
  }

  String get _dateLabel {
    final backend = _backendEvent;
    if (backend == null) return 'Date loading';
    return DateFormat('EEE, MMM d, yyyy').format(backend.dateTime.toLocal());
  }

  bool get _isFull {
    final backend = _backendEvent;
    if (backend?.capacity == null) return false;
    return (backend?.joineeCount ?? 0) >= backend!.capacity!;
  }

  bool get _registrationOpen => _backendEvent?.registrationOpen ?? true;

  /// PRD: users can join only up to 10 minutes after an event starts.
  bool get _joinWindowClosed {
    final backend = _backendEvent;
    if (backend == null) return false;
    return DateTime.now().isAfter(
      backend.dateTime.toLocal().add(const Duration(minutes: 10)),
    );
  }

  /// True when the signed-in user is the event's organizer. Organizers attend
  /// implicitly and can't join their own event as an attendee.
  bool get _isOwner {
    final me = FirebaseAuth.instance.currentUser?.uid;
    final creator = _backendEvent?.creatorUid;
    return me != null && creator != null && me == creator;
  }

  String get _joinLabel {
    if (_isOwner) return 'You\'re hosting this event';
    if (_joining) return 'Joining...';
    if (_joined) return 'Leave event';
    if (_joinWindowClosed) return 'Join window closed';
    if (_isFull) return 'Full';
    if (!_registrationOpen) return 'Registration Closed';
    return 'Join';
  }

  Future<void> _viewOnMap() async {
    final event = _displayEvent;
    if (event == null) return;
    final lat = event.lat;
    final lng = event.lng;
    final label = Uri.encodeComponent(event.venue);
    // Open the location in the device's maps app. Try a geo: URI first (Android),
    // then fall back to a Google Maps web URL that works everywhere.
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');
    final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the map.')),
        );
      }
    }
  }

  Future<LottieComposition?> _decodeDotLottie(List<int> bytes) {
    return LottieComposition.decodeZip(
      bytes,
      filePicker: (files) {
        for (final file in files) {
          if (file.name.startsWith('animations/') &&
              file.name.endsWith('.json')) {
            return file;
          }
        }
        for (final file in files) {
          if (file.name.endsWith('.json')) {
            return file;
          }
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = _displayEvent;

    if (event == null) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: SafeArea(
          child: Center(
            child: _loading
                ? const CircularProgressIndicator(
                    color: AppColors.accentPrimary,
                  )
                : Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      _error ?? 'Event not found',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
          ),
        ),
      );
    }

    final goingCount = event.attendees;
    final visibleAvatarCount = goingCount.clamp(0, 4);
    final goingCopy = goingCount <= 0
        ? 'Be the first to join.'
        : goingCount <= 3
        ? '$goingCount going'
        : 'Arjun, Priya, Karan, and ${goingCount - 3} more';
    final aboutText = _backendEvent?.description?.trim().isNotEmpty == true
        ? _backendEvent!.description!
        : 'Join us for ${event.title.toLowerCase()} at ${event.venue}. '
              'This is a community event open to everyone. '
              'Come meet new people, discover something new, and have a great time.';

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.bgSecondary,
                            border: AppChrome.outlineBorder,
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: AppColors.textPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Poster image card
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppChrome.cardRadiusLg,
                            ),
                            child: AspectRatio(
                              aspectRatio: 0.85,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    event.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, e, s) =>
                                        Container(color: AppColors.bgTertiary),
                                  ),
                                  // Bottom gradient
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.7),
                                        ],
                                        stops: const [0.0, 0.5, 1.0],
                                      ),
                                    ),
                                  ),
                                  // Date overlay at bottom
                                  Positioned(
                                    left: AppSpacing.md,
                                    bottom: AppSpacing.md,
                                    child: Text(
                                      _dateLabel,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.9,
                                            ),
                                          ),
                                    ),
                                  ),
                                  // Category badge top-left
                                  Positioned(
                                    left: AppSpacing.md,
                                    top: AppSpacing.md,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: AppSpacing.xs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.5,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppChrome.chipRadius,
                                        ),
                                      ),
                                      child: Text(
                                        event.category,
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ),
                                  // Save button top-right
                                  Positioned(
                                    right: AppSpacing.md,
                                    top: AppSpacing.md,
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _saved = !_saved),
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                        child: Icon(
                                          _saved
                                              ? Icons.bookmark
                                              : Icons.bookmark_border,
                                          color: _saved
                                              ? AppColors.accentWarm
                                              : Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Featured badge
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                color: AppColors.accentLight1,
                                size: 16,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                event.eventType == 'spotlight'
                                    ? 'Fafo Today'
                                    : 'Featured nearby',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              const Icon(
                                Icons.auto_awesome,
                                color: AppColors.accentLight1,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Title
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: Text(
                            event.title,
                            style: theme.textTheme.displayLarge,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        // Date + time
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: Text(
                            '$_dateLabel, ${event.time}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            child: Text(
                              _error!,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),

                        // Join button
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: _ActionButton(
                            icon: _isOwner
                                ? Icons.verified_user_outlined
                                : (_joined
                                    ? Icons.check_circle_outline
                                    : Icons.how_to_reg_outlined),
                            label: _joinLabel,
                            isActive: !_isOwner &&
                                (_joined || (!_isFull && _registrationOpen && !_joinWindowClosed)) &&
                                !_joining,
                            onTap: _isOwner ? null : _handleRegisterTap,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Location section
                        _SectionHeader(title: 'Location'),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.venue,
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Lat ${event.lat.toStringAsFixed(4)}, Lng ${event.lng.toStringAsFixed(4)}',
                                style: theme.textTheme.labelMedium,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.md,
                                ),
                                child: Container(
                                  height: 180,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1C2433),
                                    borderRadius: BorderRadius.circular(
                                      AppChrome.cardRadius,
                                    ),
                                  ),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      IgnorePointer(
                                        child: MapLibreMap(
                                          options: MapOptions(
                                            initStyle: MapConfig.vintageStyleUrl,
                                            initCenter: Geographic(
                                              lon: event.lng,
                                              lat: event.lat,
                                            ),
                                            initZoom: 14,
                                          ),
                                        ),
                                      ),
                                      const Center(child: _EventLocationPin()),
                                      // View on map button
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        bottom: AppSpacing.sm,
                                        child: Center(
                                          child: GestureDetector(
                                            onTap: _viewOnMap,
                                            child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.md,
                                              vertical: AppSpacing.sm,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentPrimary,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppChrome.controlRadius,
                                                  ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.4),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.map_outlined,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                                const SizedBox(
                                                  width: AppSpacing.xs,
                                                ),
                                                Text(
                                                  'View on map',
                                                  style: theme
                                                      .textTheme
                                                      .labelLarge
                                                      ?.copyWith(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Organizer verification
                        _SectionHeader(title: 'Organizer'),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: _OrganizerTrustCard(event: event),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Hosts section
                        _SectionHeader(title: 'Hosts'),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: Column(
                            children: [
                              _HostTile(
                                name: event.organizerName,
                                color: AppColors.accentPrimary,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _HostTile(
                                name: event.organizerInstagram,
                                color: AppColors.accentWarm,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Going section
                        _SectionHeader(title: '$goingCount Going'),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar stack
                              SizedBox(
                                height: 40,
                                child: Stack(
                                  children: List.generate(
                                    visibleAvatarCount,
                                    (i) => Positioned(
                                      left: i * 28.0,
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: [
                                            AppColors.accentPrimary,
                                            AppColors.accentWarm,
                                            AppColors.accentSecondary,
                                            AppColors.accentLight1,
                                          ][i % 4],
                                          border: Border.all(
                                            color: AppColors.bgPrimary,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                goingCopy,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // About section
                        _SectionHeader(title: 'About Event'),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: Text(
                            aboutText,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_showCelebration)
              Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Transform.translate(
                      offset: const Offset(0, 36),
                      child: SizedBox(
                        width: MediaQuery.sizeOf(context).width * 1.18,
                        height: 400,
                        child: Lottie.asset(
                          _celebrationLottieAsset,
                          fit: BoxFit.contain,
                          repeat: false,
                          frameRate: FrameRate.max,
                          decoder: _decodeDotLottie,
                          onLoaded: (composition) {
                            _celebrationTimer?.cancel();
                            _celebrationTimer = Timer(composition.duration, () {
                              if (mounted) {
                                setState(() => _showCelebration = false);
                              }
                            });
                          },
                          errorBuilder: (_, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EventLocationPin extends StatelessWidget {
  const _EventLocationPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.accentPrimary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.place_rounded, color: Color(0xFF161616)),
        ),
        Transform.translate(
          offset: const Offset(0, -1),
          child: CustomPaint(
            size: const Size(18, 14),
            painter: _PinTailPainter(),
          ),
        ),
      ],
    );
  }
}

class _PinTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, Paint()..color = AppColors.accentPrimary);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 0.5),
          ),
          const SizedBox(height: AppSpacing.xs),
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _OrganizerTrustCard extends StatelessWidget {
  const _OrganizerTrustCard({required this.event});

  final MockEvent event;

  Future<void> _openInstagram(BuildContext context) async {
    final handle = event.organizerInstagram.replaceAll('@', '').trim();
    if (handle.isEmpty) return;
    final uri = Uri.parse('https://instagram.com/$handle');
    await _launchUri(context, uri);
  }

  Future<void> _openContact(BuildContext context) async {
    final contact = event.organizerContact.trim();
    if (contact.isEmpty) return;
    final uri = contact.contains('@')
        ? Uri(scheme: 'mailto', path: contact)
        : Uri(scheme: 'tel', path: contact.replaceAll(RegExp(r'\s+'), ''));

    await _launchUri(context, uri);
  }

  Future<void> _launchUri(BuildContext context, Uri uri) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open ${uri.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppChrome.cardRadius),
        border: AppChrome.outlineBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        event.organizerName,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    if (event.organizerVerified) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.verified,
                        color: Color(0xFFFFDA37),
                        size: 18,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (event.organizerContact.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _OrganizerMetaRow(
              icon: Icons.mail_outline,
              label: 'Public contact',
              value: event.organizerContact,
              onTap: () => _openContact(context),
            ),
          ],
          if (event.organizerInstagram.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _OrganizerMetaRow(
              icon: Icons.camera_alt_outlined,
              label: 'Instagram',
              value: event.organizerInstagram,
              onTap: () => _openInstagram(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrganizerMetaRow extends StatelessWidget {
  const _OrganizerMetaRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppPressable(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$label: ',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.labelLarge?.copyWith(
                color: const Color(0xFFB07A1A),
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFFB07A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final shadowColor = isDark ? Colors.white : const Color(0xFF111111);
    final activeButton = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentPrimary,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: AppColors.accentPrimary),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF181818), size: 22),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFF181818),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );

    if (!isActive) {
      return AppPressable(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.bgTertiary,
            borderRadius: BorderRadius.circular(AppSpacing.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 6),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Transform.translate(
              offset: const Offset(6, 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: shadowColor,
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                ),
              ),
            ),
          ),
          AppPressable(onTap: onTap, child: activeButton),
        ],
      ),
    );
  }
}

class _HostTile extends StatelessWidget {
  const _HostTile({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.3),
          ),
          child: Icon(Icons.person, color: color, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(name, style: theme.textTheme.titleLarge)),
        Icon(
          Icons.camera_alt_outlined,
          color: AppColors.textTertiary,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.md),
        Icon(Icons.close, color: AppColors.textTertiary, size: 20),
      ],
    );
  }
}
