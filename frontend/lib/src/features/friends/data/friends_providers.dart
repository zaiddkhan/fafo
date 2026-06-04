import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/features/friends/data/friends_repository.dart';
import 'package:fafu/src/features/friends/domain/friend.dart';

final friendsListProvider = FutureProvider.autoDispose<List<FriendResponse>>((ref) {
  return ref.watch(friendsRepositoryProvider).getFriends();
});

final incomingFriendRequestsProvider =
    FutureProvider.autoDispose<List<FriendRequestResponse>>((ref) {
  return ref.watch(friendsRepositoryProvider).getIncomingRequests();
});

final outgoingFriendRequestsProvider =
    FutureProvider.autoDispose<List<FriendRequestResponse>>((ref) {
  return ref.watch(friendsRepositoryProvider).getOutgoingRequests();
});

final friendStatsProvider = FutureProvider.autoDispose<FriendStatsResponse>((ref) {
  return ref.watch(friendsRepositoryProvider).getStats();
});

final friendSearchProvider =
    FutureProvider.autoDispose.family<List<PublicUserResponse>, String>((ref, query) {
  if (query.trim().length < 2) return const [];
  return ref.watch(friendsRepositoryProvider).searchUsers(query.trim());
});
