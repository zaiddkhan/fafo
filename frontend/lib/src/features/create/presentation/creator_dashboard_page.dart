import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:fafu/src/core/constants/app_spacing.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/create/presentation/create_event_page.dart';
import 'package:fafu/src/features/events/data/events_repository.dart';
import 'package:fafu/src/features/events/domain/event.dart';
import 'package:fafu/src/shared/widgets/app_button.dart';

class CreatorDashboardPage extends ConsumerStatefulWidget {
  const CreatorDashboardPage({super.key});

  @override
  ConsumerState<CreatorDashboardPage> createState() => _CreatorDashboardPageState();
}

class _CreatorDashboardPageState extends ConsumerState<CreatorDashboardPage> {
  bool _loading = true;
  String? _error;
  List<EventResponse> _events = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final events = await ref.read(eventsRepositoryProvider).getMyEvents();
      if (mounted) setState(() => _events = events);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCreate() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateEventPage()));
    if (mounted) _load();
  }

  Future<void> _toggleRegistration(EventResponse event) async {
    await ref.read(eventsRepositoryProvider).updateEvent(
      event.id,
      EventUpdateRequest(registrationOpen: !event.registrationOpen),
    );
    await _load();
  }

  Future<void> _edit(EventResponse event) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CreateEventPage(event: event)),
    );
    if (mounted) _load();
  }

  Future<void> _cancel(EventResponse event) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CancelEventPage(event: event)),
    );
    if (mounted) _load();
  }

  Future<void> _openJoinees(EventResponse event) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EventJoineesPage(event: event)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Re-fetch when an event is created/edited elsewhere (this tab is kept
    // alive in the shell's IndexedStack).
    ref.listen(eventsRevisionProvider, (_, _) => _load());
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 120),
            children: [
              Text('Creator Dashboard', style: theme.textTheme.displayLarge),
              const SizedBox(height: AppSpacing.sm),
              Text('Create and manage the events you have published.', style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: 'Create new event', variant: AppButtonVariant.featured, onPressed: _openCreate),
              const SizedBox(height: AppSpacing.xl),
              if (_loading)
                const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary))
              else if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red))
              else if (_events.isEmpty)
                const Text('No events created yet.')
              else
                ..._events.map((event) => _CreatorEventCard(
                  event: event,
                  onEdit: () => _edit(event),
                  onToggleRegistration: () => _toggleRegistration(event),
                  onCancel: () => _cancel(event),
                  onJoinees: () => _openJoinees(event),
                )),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreatorEventCard extends StatelessWidget {
  const _CreatorEventCard({
    required this.event,
    required this.onEdit,
    required this.onToggleRegistration,
    required this.onCancel,
    required this.onJoinees,
  });

  final EventResponse event;
  final VoidCallback onEdit;
  final VoidCallback onToggleRegistration;
  final VoidCallback onCancel;
  final VoidCallback onJoinees;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canEditDetails = DateTime.now().isBefore(
      event.dateTime.toLocal().subtract(const Duration(hours: 1)),
    );
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text('${DateFormat('EEE, MMM d • h:mm a').format(event.dateTime.toLocal())} • ${event.locationName}'),
            const SizedBox(height: 6),
            Text('${event.joineeCount} joined • Registration ${event.registrationOpen ? 'open' : 'stopped'}'),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: canEditDetails ? onEdit : null,
                  child: Text(canEditDetails ? 'Edit' : 'Edit locked'),
                ),
                OutlinedButton(onPressed: onToggleRegistration, child: Text(event.registrationOpen ? 'Stop registration' : 'Reopen registration')),
                OutlinedButton(onPressed: onJoinees, child: const Text('Joinees')),
                OutlinedButton(onPressed: onCancel, child: const Text('Cancel')),
              ],
            ),
            if (!canEditDetails) ...[
              const SizedBox(height: 8),
              Text(
                'Details are locked within 1 hour of start time.',
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


class EventJoineesPage extends ConsumerStatefulWidget {
  const EventJoineesPage({super.key, required this.event});

  final EventResponse event;

  @override
  ConsumerState<EventJoineesPage> createState() => _EventJoineesPageState();
}

class _EventJoineesPageState extends ConsumerState<EventJoineesPage> {
  bool _loading = true;
  String? _error;
  List<JoineeResponse> _joinees = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final joinees = await ref
          .read(eventsRepositoryProvider)
          .getJoinees(widget.event.id, limit: 100);
      if (mounted) setState(() => _joinees = joinees);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(title: const Text('Joinees')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(widget.event.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              '${widget.event.joineeCount} people joined',
              style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_loading)
              const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary))
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red))
            else if (_joinees.isEmpty)
              const Text('No joinees yet.')
            else
              ..._joinees.map(
                (j) => Card(
                  child: ListTile(
                    leading: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          backgroundImage: j.photoUrl == null ? null : NetworkImage(j.photoUrl!),
                          child: j.photoUrl == null ? Text(j.displayName.isNotEmpty ? j.displayName[0] : '@') : null,
                        ),
                        if (j.online)
                          Positioned(
                            right: -1,
                            bottom: -1,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4ED164),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.bgSecondary, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(j.displayName.isEmpty ? '@${j.username}' : j.displayName),
                    subtitle: Text('@${j.username} • joined ${DateFormat('MMM d, h:mm a').format(j.joinedAt.toLocal())}'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CancelEventPage extends ConsumerStatefulWidget {
  const CancelEventPage({super.key, required this.event});

  final EventResponse event;

  @override
  ConsumerState<CancelEventPage> createState() => _CancelEventPageState();
}

class _CancelEventPageState extends ConsumerState<CancelEventPage> {
  final _reasonController = TextEditingController();
  final _preventionController = TextEditingController();
  final _messageController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    _preventionController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _cancelEvent() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = 'Please add a cancellation reason.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final answers = [
      reason,
      _preventionController.text.trim(),
      _messageController.text.trim(),
    ].where((a) => a.isNotEmpty).toList(growable: false);
    try {
      await ref.read(eventsRepositoryProvider).cancelEvent(
            widget.event.id,
            reason: reason,
            answers: answers,
          );
      if (!mounted) return;
      bumpEventsRevision(ref);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(title: const Text('Cancel event')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5484D), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This cannot be undone', style: theme.textTheme.titleLarge?.copyWith(color: const Color(0xFFE5484D))),
                  const SizedBox(height: 8),
                  Text(
                    'Cancelling “${widget.event.title}” will remove it from discovery and notify everyone who joined.',
                    style: theme.textTheme.bodyLarge?.copyWith(color: const Color(0xFF551B1B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Why are you cancelling?', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Give attendees a clear reason',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Could anything have kept it running?', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _preventionController,
              maxLines: 2,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Optional'),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Anything attendees should know?', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 2,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Optional'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: _submitting ? 'Cancelling...' : 'Cancel event permanently',
              variant: AppButtonVariant.featured,
              onPressed: _submitting ? null : _cancelEvent,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
              child: const Text('Keep event'),
            ),
          ],
        ),
      ),
    );
  }
}
