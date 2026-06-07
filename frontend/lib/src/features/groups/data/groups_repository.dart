import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/network/dio_provider.dart';
import 'package:fafu/src/features/groups/domain/group.dart';

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  return GroupsRepository(ref.watch(dioProvider));
});

class GroupsRepository {
  GroupsRepository(this._dio);

  final Dio _dio;

  Future<List<GroupResponse>> getGroups() async {
    try {
      final response = await _dio.get('/groups');
      return (response.data as List)
          .map((e) => GroupResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<GroupResponse> createGroup(String name) async {
    try {
      final response = await _dio.post('/groups', data: {'name': name});
      return GroupResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<GroupResponse> updateGroup(String groupId, String name) async {
    try {
      final response = await _dio.put('/groups/$groupId', data: {'name': name});
      return GroupResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<GroupInviteResponse>> getIncomingInvites() async {
    try {
      final response = await _dio.get('/groups/invites/incoming');
      return (response.data as List)
          .map((e) => GroupInviteResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> inviteMember(String groupId, String recipientUid) async {
    try {
      await _dio.post(
        '/groups/$groupId/invites',
        data: {'recipient_uid': recipientUid},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> acceptInvite(String inviteId) async {
    try {
      await _dio.post('/groups/invites/$inviteId/accept');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> declineInvite(String inviteId) async {
    try {
      await _dio.post('/groups/invites/$inviteId/decline');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> transferOwnership(String groupId, String newAdminUid) async {
    try {
      await _dio.post('/groups/$groupId/transfer', data: {'new_admin_uid': newAdminUid});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> removeMember(String groupId, String memberUid, {required List<String> answers}) async {
    try {
      await _dio.delete('/groups/$groupId/members/$memberUid', data: {'answers': answers});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> leaveGroup(String groupId, {required List<String> answers}) async {
    try {
      await _dio.delete('/groups/$groupId/leave', data: {'answers': answers});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> dissolveGroup(String groupId, {required List<String> answers}) async {
    try {
      await _dio.delete('/groups/$groupId', data: {'answers': answers});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
