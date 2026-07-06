import 'package:flutter/material.dart';

import 'package:fafu/src/core/constants/app_spacing.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/groups/presentation/groups_body.dart';

/// Standalone groups screen reached via the `/groups` (and `/groups/:groupId`)
/// deep-links. The actual content lives in [GroupsBody], which the Friends
/// screen also embeds as its Groups tab.
class GroupsPage extends StatelessWidget {
  const GroupsPage({this.focusGroupId, super.key});

  /// When set (via a group notification deep-link), that group is auto-expanded
  /// and scrolled into view instead of just landing on the groups list.
  final String? focusGroupId;

  static const routeName = 'groups';
  static const routePath = '/groups';

  /// Named route for the `/groups/:groupId` deep-link variant.
  static const focusRouteName = 'group-detail';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Groups'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          120,
        ),
        children: [GroupsBody(focusGroupId: focusGroupId)],
      ),
    );
  }
}
