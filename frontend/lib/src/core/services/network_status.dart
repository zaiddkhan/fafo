import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/config/app_config.dart';

/// Whether the backend is reachable. Two signals: the phone's network
/// interfaces (instant on airplane mode / Wi-Fi off) and real requests failing
/// with connection errors (Wi-Fi with no internet, server unreachable). While
/// offline it probes /health every few seconds, so it flips back on its own.
final networkStatusProvider = NotifierProvider<NetworkStatus, bool>(NetworkStatus.new);

class NetworkStatus extends Notifier<bool> {
  static const _probeEvery = Duration(seconds: 5);

  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _probe;
  late final _probeDio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  @override
  bool build() {
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.every((r) => r == ConnectivityResult.none)) {
        reportOffline();
      } else if (!state) {
        // An interface came back; confirm the server answers before saying so.
        _check();
      }
    });
    ref.onDispose(() {
      _sub?.cancel();
      _probe?.cancel();
    });
    return true;
  }

  /// A request failed to reach the server.
  void reportOffline() {
    if (state) state = false;
    _probe ??= Timer.periodic(_probeEvery, (_) => _check());
  }

  /// A request got a response (any status): the server is reachable.
  void reportOnline() {
    _probe?.cancel();
    _probe = null;
    if (!state) state = true;
  }

  Future<void> _check() async {
    try {
      await _probeDio.get<void>('/health');
      reportOnline();
    } catch (_) {
      reportOffline();
    }
  }
}

/// Connection failures, as opposed to the server answering with an error.
bool isConnectionFailure(DioException e) => switch (e.type) {
  DioExceptionType.connectionError || DioExceptionType.connectionTimeout => true,
  // No response at all (DNS, refused socket) surfaces as unknown on some platforms.
  DioExceptionType.unknown => e.response == null,
  _ => false,
};
