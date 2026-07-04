import 'package:flutter/material.dart';

import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/events/domain/event.dart';

/// Human-readable label for an [UnjoinReason], shared across the event detail
/// page and the profile RSVP card so the copy never drifts.
String unjoinReasonLabel(UnjoinReason reason) {
  return switch (reason) {
    UnjoinReason.changeOfPlans => 'Change of plans',
    UnjoinReason.schedulingConflict => 'Scheduling conflict',
    UnjoinReason.noLongerInterested => 'No longer interested',
    UnjoinReason.other => 'Other',
  };
}

/// Shows the "pick an optional reason" bottom sheet and returns the chosen
/// [UnjoinReason], or `null` if the user dismisses / keeps the event.
Future<UnjoinReason?> showUnjoinReasonSheet(
  BuildContext context, {
  required String title,
  required String keepLabel,
}) {
  return showModalBottomSheet<UnjoinReason>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Pick an optional reason. No typing required.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in UnjoinReason.values)
                  ChoiceChip(
                    label: Text(unjoinReasonLabel(option)),
                    selected: false,
                    onSelected: (_) => Navigator.of(context).pop(option),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(keepLabel),
            ),
          ],
        ),
      ),
    ),
  );
}
