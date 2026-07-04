import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/config/app_config.dart';
import 'package:fafu/src/core/network/auth_token_provider.dart';
import 'package:fafu/src/core/network/session_expired_provider.dart';
import 'package:fafu/src/core/services/logger_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final logger = ref.watch(loggerProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        var token = ref.read(authTokenProvider);

        // Be resilient across refreshes/hot restarts: Riverpod state can be
        // empty before SharedPreferences has hydrated, while Firebase Auth may
        // already have the signed-in user.
        token ??= await FirebaseAuth.instance.currentUser?.getIdToken();
        if (token != null) {
          ref.read(authTokenProvider.notifier).setToken(token);
          options.headers['Authorization'] = 'Bearer $token';
        }

        logger.i(
          'REQ ${options.method} ${options.uri} auth=${token != null}',
        );
        handler.next(options);
      },
      onResponse: (response, handler) {
        logger.i('RES ${response.statusCode} ${response.requestOptions.uri}');
        handler.next(response);
      },
      onError: (error, handler) async {
        logger.e(
          'ERR ${error.requestOptions.method} ${error.requestOptions.uri}',
          error: error,
          stackTrace: error.stackTrace,
        );

        final alreadyRetried = error.requestOptions.extra['authRetry'] == true;
        if (error.response?.statusCode == 401 && !alreadyRetried) {
          final currentUser = FirebaseAuth.instance.currentUser;

          // No signed-in user: this isn't an expired session, it's an
          // unauthenticated request (e.g. previewing a shared event link).
          // Let the normal routing/UI handle it — don't force a sign-out.
          if (currentUser == null) {
            handler.next(error);
            return;
          }

          String? freshToken;
          try {
            freshToken = await currentUser.getIdToken(true);
          } catch (_) {
            // Refresh token is gone/revoked (signed out elsewhere, account
            // disabled/deleted). Unrecoverable.
            freshToken = null;
          }

          if (freshToken != null) {
            ref.read(authTokenProvider.notifier).setToken(freshToken);
            final retryOptions = error.requestOptions;
            retryOptions.extra['authRetry'] = true;
            retryOptions.headers['Authorization'] = 'Bearer $freshToken';

            try {
              final response = await dio.fetch<dynamic>(retryOptions);
              handler.resolve(response);
              return;
            } on DioException catch (retryError) {
              // A second 401 after a freshly minted token means the backend
              // has revoked this session outright.
              if (retryError.response?.statusCode == 401) {
                ref.read(sessionExpiredProvider.notifier).markExpired();
              }
              handler.next(retryError);
              return;
            }
          }

          // Had a user but couldn't get a usable token — session is dead.
          ref.read(sessionExpiredProvider.notifier).markExpired();
        }

        handler.next(error);
      },
    ),
  );

  return dio;
});
