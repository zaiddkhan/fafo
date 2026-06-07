import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/features/groups/data/groups_repository.dart';
import 'package:fafu/src/features/groups/domain/group.dart';

final groupsListProvider = FutureProvider.autoDispose<List<GroupResponse>>((ref) {
  return ref.watch(groupsRepositoryProvider).getGroups();
});

final incomingGroupInvitesProvider = FutureProvider.autoDispose<List<GroupInviteResponse>>((ref) {
  return ref.watch(groupsRepositoryProvider).getIncomingInvites();
});
