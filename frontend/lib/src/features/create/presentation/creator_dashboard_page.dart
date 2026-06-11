import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:fafu/src/core/constants/app_spacing.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/create/presentation/create_event_page.dart';
import 'package:fafu/src/features/events/data/events_repository.dart';
import 'package:fafu/src/features/events/domain/event.dart';
import 'package:fafu/src/shared/widgets/app_button.dart';
import 'package:fafu/src/shared/widgets/negative_action_dialog.dart';

class CreatorDashboardPage extends ConsumerStatefulWidget {
  const CreatorDashboardPage({super.key});

  @override
  ConsumerState<CreatorDashboardPage> createState() => _CreatorDashboardPageState();
}

class _CreatorDashboardPageState extends ConsumerState<CreatorDashboardPage> {
  bool _loading = true;
  String? _error;
  List<EventResponse> _events = const [];
  final Map<String, List<JoineeResponse>> _joineesByEvent = {};

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
    final title = TextEditingController(text: event.title);
    final description = TextEditingController(text: event.description ?? '');
    final capacity = TextEditingController(text: event.capacity?.toString() ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: description, decoration: const InputDecoration(labelText: 'Description')),
            TextField(controller: capacity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Capacity')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved != true) return;
    await ref.read(eventsRepositoryProvider).updateEvent(
      event.id,
      EventUpdateRequest(
        title: title.text.trim(),
        description: description.text.trim().isEmpty ? null : description.text.trim(),
        capacity: capacity.text.trim().isEmpty ? null : int.tryParse(capacity.text.trim()),
      ),
    );
    await _load();
  }

  Future<void> _cancel(EventResponse event) async {
    // PRD: cancelling an event is a negative action gated by a 3-to-5 question flow.
    final answers = await showNegativeActionQuestionnaire(
      context,
      title: 'Cancel "${event.title}"?',
      intro: 'Cancellation is irreversible and notifies everyone who joined. Confirm with a few questions.',
      confirmLabel: 'Cancel event',
      questions: const [
        'Why are you cancelling this event?',
        'Could anything have kept it running?',
        'Anything attendees should know?',
      ],
    );
    if (answers == null) return;
    await ref.read(eventsRepositoryProvider).cancelEvent(
          event.id,
          reason: answers.first,
          answers: answers,
        );
    await _load();
  }

  Future<void> _loadJoinees(EventResponse event) async {
    if (_joineesByEvent.containsKey(event.id)) {
      setState(() => _joineesByEvent.remove(event.id));
      return;
    }
    final joinees = await ref.read(eventsRepositoryProvider).getJoinees(event.id, limit: 50);
    if (mounted) setState(() => _joineesByEvent[event.id] = joinees);
  }

  @override
  Widget build(BuildContext context) {
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
                  joinees: _joineesByEvent[event.id],
                  onEdit: () => _edit(event),
                  onToggleRegistration: () => _toggleRegistration(event),
                  onCancel: () => _cancel(event),
                  onJoinees: () => _loadJoinees(event),
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
    required this.joinees,
    required this.onEdit,
    required this.onToggleRegistration,
    required this.onCancel,
    required this.onJoinees,
  });

  final EventResponse event;
  final List<JoineeResponse>? joinees;
  final VoidCallback onEdit;
  final VoidCallback onToggleRegistration;
  final VoidCallback onCancel;
  final VoidCallback onJoinees;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                OutlinedButton(onPressed: onEdit, child: const Text('Edit')),
                OutlinedButton(onPressed: onToggleRegistration, child: Text(event.registrationOpen ? 'Stop registration' : 'Reopen registration')),
                OutlinedButton(onPressed: onJoinees, child: const Text('Joinees')),
                OutlinedButton(onPressed: onCancel, child: const Text('Cancel')),
              ],
            ),
            if (joinees != null) ...[
              const Divider(height: 24),
              if (joinees!.isEmpty)
                const Text('No joinees yet.')
              else
                ...joinees!.map((j) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(backgroundImage: j.photoUrl == null ? null : NetworkImage(j.photoUrl!)),
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
                  subtitle: Text('@${j.username}'),
                )),
            ],
          ],
        ),
      ),
    );
  }
}
