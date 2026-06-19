enum FriendshipStatus {
  none,
  friends,
  requestSent,
  requestReceived,
  blocked,
  blockedBy,
}

enum FriendRequestStatus { pending, accepted, declined }

FriendshipStatus friendshipStatusFromJson(String? value) {
  return switch (value) {
    'friends' => FriendshipStatus.friends,
    'request_sent' => FriendshipStatus.requestSent,
    'request_received' => FriendshipStatus.requestReceived,
    'blocked' => FriendshipStatus.blocked,
    'blocked_by' => FriendshipStatus.blockedBy,
    _ => FriendshipStatus.none,
  };
}

FriendRequestStatus friendRequestStatusFromJson(String? value) {
  return switch (value) {
    'accepted' => FriendRequestStatus.accepted,
    'declined' => FriendRequestStatus.declined,
    _ => FriendRequestStatus.pending,
  };
}

class PublicUserResponse {
  const PublicUserResponse({
    required this.uid,
    required this.displayName,
    required this.username,
    required this.online,
    required this.friendshipStatus,
    this.photoUrl,
  });

  final String uid;
  final String displayName;
  final String username;
  final String? photoUrl;
  final bool online;
  final FriendshipStatus friendshipStatus;

  factory PublicUserResponse.fromJson(Map<String, dynamic> json) {
    return PublicUserResponse(
      uid: json['uid'] as String,
      displayName: json['display_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
      online: json['online'] as bool? ?? false,
      friendshipStatus: friendshipStatusFromJson(
        json['friendship_status'] as String?,
      ),
    );
  }
}

class FriendRequestResponse {
  const FriendRequestResponse({
    required this.id,
    required this.requester,
    required this.recipient,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  final String id;
  final PublicUserResponse requester;
  final PublicUserResponse recipient;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  factory FriendRequestResponse.fromJson(Map<String, dynamic> json) {
    return FriendRequestResponse(
      id: json['id'] as String,
      requester: PublicUserResponse.fromJson(
        json['requester'] as Map<String, dynamic>,
      ),
      recipient: PublicUserResponse.fromJson(
        json['recipient'] as Map<String, dynamic>,
      ),
      status: friendRequestStatusFromJson(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      respondedAt: json['responded_at'] == null
          ? null
          : DateTime.parse(json['responded_at'] as String),
    );
  }
}

class FriendResponse {
  const FriendResponse({required this.user, required this.friendsSince});

  final PublicUserResponse user;
  final DateTime friendsSince;

  factory FriendResponse.fromJson(Map<String, dynamic> json) {
    return FriendResponse(
      user: PublicUserResponse.fromJson(json['user'] as Map<String, dynamic>),
      friendsSince: DateTime.parse(json['friends_since'] as String),
    );
  }
}

class ContactMatchResponse {
  const ContactMatchResponse({
    required this.phone,
    required this.normalizedPhone,
    required this.user,
  });

  final String phone;
  final String normalizedPhone;
  final PublicUserResponse user;

  factory ContactMatchResponse.fromJson(Map<String, dynamic> json) {
    final phone = json['phone'] as String? ?? '';
    return ContactMatchResponse(
      phone: phone,
      normalizedPhone: json['normalized_phone'] as String? ?? phone,
      user: PublicUserResponse.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class FriendStatsResponse {
  const FriendStatsResponse({
    required this.friendsCount,
    required this.incomingRequestCount,
    required this.outgoingRequestCount,
  });

  final int friendsCount;
  final int incomingRequestCount;
  final int outgoingRequestCount;

  factory FriendStatsResponse.fromJson(Map<String, dynamic> json) {
    return FriendStatsResponse(
      friendsCount: json['friends_count'] as int? ?? 0,
      incomingRequestCount: json['incoming_request_count'] as int? ?? 0,
      outgoingRequestCount: json['outgoing_request_count'] as int? ?? 0,
    );
  }
}

class BlockedUserResponse {
  const BlockedUserResponse({required this.user, required this.blockedAt});

  final PublicUserResponse user;
  final DateTime blockedAt;

  factory BlockedUserResponse.fromJson(Map<String, dynamic> json) {
    return BlockedUserResponse(
      user: PublicUserResponse.fromJson(json['user'] as Map<String, dynamic>),
      blockedAt: DateTime.parse(json['blocked_at'] as String),
    );
  }
}

class FriendInviteCreateResponse {
  const FriendInviteCreateResponse({
    required this.token,
    required this.inviteUrl,
    required this.createdAt,
  });

  final String token;
  final String inviteUrl;
  final DateTime createdAt;

  factory FriendInviteCreateResponse.fromJson(Map<String, dynamic> json) {
    return FriendInviteCreateResponse(
      token: json['token'] as String,
      inviteUrl: json['invite_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
