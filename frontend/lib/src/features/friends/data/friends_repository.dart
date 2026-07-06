import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/network/dio_provider.dart';
import 'package:fafu/src/features/friends/domain/friend.dart';

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FriendsRepository(ref.watch(dioProvider));
});

class FriendsRepository {
  FriendsRepository(this._dio);

  final Dio _dio;

  Future<void> updatePresence() async {
    try {
      await _dio.post('/friends/presence');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Max phone numbers the backend accepts per request. Address books larger
  /// than this are sent in batches so a big contact list can't fail the whole
  /// sync (the backend rejects lists outside 1..500 with HTTP 422).
  static const int _kContactSyncBatchSize = 500;

  Future<List<ContactMatchResponse>> syncContacts(
    List<String> phoneNumbers,
  ) async {
    // Nothing to match — skip the call (an empty list would 422) and return no
    // matches rather than surfacing an error.
    if (phoneNumbers.isEmpty) return const [];

    try {
      final matchesByUid = <String, ContactMatchResponse>{};
      for (var i = 0; i < phoneNumbers.length; i += _kContactSyncBatchSize) {
        final batch = phoneNumbers.sublist(
          i,
          (i + _kContactSyncBatchSize).clamp(0, phoneNumbers.length),
        );
        final response = await _dio.post(
          '/friends/contacts/sync',
          data: {'phone_numbers': batch},
        );
        final data = response.data as Map<String, dynamic>;
        for (final e in data['matches'] as List) {
          final match = ContactMatchResponse.fromJson(
            e as Map<String, dynamic>,
          );
          matchesByUid[match.user.uid] = match;
        }
      }
      return matchesByUid.values.toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<PublicUserResponse>> searchUsers(String query) async {
    try {
      final response = await _dio.get(
        '/friends/search',
        queryParameters: {'query': query},
      );
      final data = response.data as Map<String, dynamic>;
      return (data['users'] as List)
          .map((e) => PublicUserResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<FriendStatsResponse> getStats() async {
    try {
      final response = await _dio.get('/friends/stats');
      return FriendStatsResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<FriendResponse>> getFriends() async {
    try {
      final response = await _dio.get('/friends');
      return (response.data as List)
          .map((e) => FriendResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<FriendRequestResponse>> getIncomingRequests() async {
    try {
      final response = await _dio.get('/friends/requests/incoming');
      return (response.data as List)
          .map((e) => FriendRequestResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<FriendRequestResponse>> getOutgoingRequests() async {
    try {
      final response = await _dio.get('/friends/requests/outgoing');
      return (response.data as List)
          .map((e) => FriendRequestResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> sendFriendRequest({String? uid, String? username}) async {
    try {
      await _dio.post(
        '/friends/requests',
        data: {'recipient_uid': ?uid, 'username': ?username},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> acceptRequest(String requestId) async {
    try {
      await _dio.post('/friends/requests/$requestId/accept');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> declineRequest(String requestId) async {
    try {
      await _dio.post('/friends/requests/$requestId/decline');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> unfriend(String uid, {required List<String> answers}) async {
    try {
      await _dio.delete('/friends/$uid', data: {'answers': answers});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<BlockedUserResponse>> getBlockedUsers() async {
    try {
      final response = await _dio.get('/friends/blocks');
      return (response.data as List)
          .map((e) => BlockedUserResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> blockUser(String uid, {required List<String> answers}) async {
    try {
      await _dio.post('/friends/blocks/$uid', data: {'answers': answers});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> unblockUser(String uid, {required List<String> answers}) async {
    try {
      await _dio.delete('/friends/blocks/$uid', data: {'answers': answers});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<FriendInviteCreateResponse> createInvite() async {
    try {
      final response = await _dio.post('/friends/invites');
      return FriendInviteCreateResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
