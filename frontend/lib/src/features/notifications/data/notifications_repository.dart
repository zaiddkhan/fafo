import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/network/dio_provider.dart';
import 'package:fafu/src/features/notifications/domain/notification.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(dioProvider));
});

/// Talks to the in-app notification inbox endpoints.
class NotificationsRepository {
  NotificationsRepository(this._dio);

  final Dio _dio;

  Future<NotificationList> list({int limit = 30}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/notifications',
        queryParameters: {'limit': limit},
      );
      return NotificationList.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<int> unreadCount() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/notifications/unread-count',
      );
      return res.data?['unread_count'] as int? ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _dio.post('/notifications/${Uri.encodeComponent(id)}/read');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.post('/notifications/read-all');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

/// The inbox feed (newest first) + unread count.
final notificationsListProvider =
    FutureProvider.autoDispose<NotificationList>((ref) {
  return ref.watch(notificationsRepositoryProvider).list();
});

/// Lightweight unread count for the Profile-header badge. Kept separate so the
/// badge can refresh without loading the whole feed.
final unreadNotificationsProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(notificationsRepositoryProvider).unreadCount();
});
