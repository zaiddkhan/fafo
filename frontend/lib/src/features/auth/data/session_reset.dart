import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/features/events/data/saved_events_controller.dart';
import 'package:fafu/src/features/friends/data/friends_providers.dart';
import 'package:fafu/src/features/notifications/data/notifications_repository.dart';
import 'package:fafu/src/features/quests/data/quests_providers.dart';
import 'package:fafu/src/features/users/data/users_providers.dart';
import 'package:fafu/src/features/users/data/users_repository.dart';

/// Invalidates every user-scoped cached provider so the next account to sign in
/// loads its own data instead of reusing the previous user's.
///
/// Some of these providers (notably [currentProfileProvider] and
/// [questActivationsProvider]) are intentionally *not* auto-disposed so their
/// state survives navigation — which means they also survive an account switch
/// unless we invalidate them explicitly here.
void resetUserScopedData(WidgetRef ref) {
  ref.invalidate(currentProfileProvider);
  ref.invalidate(profileStatsProvider);
  ref.invalidate(questActivationsProvider);
  ref.invalidate(questsListProvider);
  ref.invalidate(savedEventIdsProvider);
  ref.invalidate(unreadNotificationsProvider);
  ref.invalidate(friendsListProvider);
}
