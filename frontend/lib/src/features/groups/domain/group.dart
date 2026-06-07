import 'package:fafu/src/features/friends/domain/friend.dart';

enum GroupInviteStatus { pending, accepted, declined }

GroupInviteStatus groupInviteStatusFromJson(String? value) {
  return switch (value) {
    'accepted' => GroupInviteStatus.accepted,
    'declined' => GroupInviteStatus.declined,
    _ => GroupInviteStatus.pending,
  };
}

class GroupMemberResponse {
  const GroupMemberResponse({
    required this.user,
    required this.joinedAt,
    required this.isAdmin,
  });

  final PublicUserResponse user;
  final DateTime joinedAt;
  final bool isAdmin;

  factory GroupMemberResponse.fromJson(Map<String, dynamic> json) {
    return GroupMemberResponse(
      user: PublicUserResponse.fromJson(json['user'] as Map<String, dynamic>),
      joinedAt: DateTime.parse(json['joined_at'] as String),
      isAdmin: json['is_admin'] as bool? ?? false,
    );
  }
}

class GroupResponse {
  const GroupResponse({
    required this.id,
    required this.name,
    required this.adminUid,
    required this.createdAt,
    required this.updatedAt,
    required this.members,
  });

  final String id;
  final String name;
  final String adminUid;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<GroupMemberResponse> members;

  factory GroupResponse.fromJson(Map<String, dynamic> json) {
    return GroupResponse(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      adminUid: json['admin_uid'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      members: ((json['members'] as List?) ?? [])
          .map((e) => GroupMemberResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GroupInviteResponse {
  const GroupInviteResponse({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.inviter,
    required this.recipient,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  final String id;
  final String groupId;
  final String groupName;
  final PublicUserResponse inviter;
  final PublicUserResponse recipient;
  final GroupInviteStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  factory GroupInviteResponse.fromJson(Map<String, dynamic> json) {
    return GroupInviteResponse(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      groupName: json['group_name'] as String? ?? '',
      inviter: PublicUserResponse.fromJson(json['inviter'] as Map<String, dynamic>),
      recipient: PublicUserResponse.fromJson(json['recipient'] as Map<String, dynamic>),
      status: groupInviteStatusFromJson(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      respondedAt: json['responded_at'] == null
          ? null
          : DateTime.parse(json['responded_at'] as String),
    );
  }
}
