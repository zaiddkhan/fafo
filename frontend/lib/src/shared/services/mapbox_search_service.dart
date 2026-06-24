import 'dart:math';

import 'package:dio/dio.dart';

import 'package:fafu/src/core/config/app_config.dart';

/// A single autocomplete suggestion from the Mapbox Search Box API. Holds the
/// opaque [mapboxId] needed to retrieve full coordinates on selection.
class MapboxSuggestion {
  const MapboxSuggestion({
    required this.mapboxId,
    required this.name,
    required this.placeFormatted,
  });

  /// Opaque id passed to [MapboxSearchService.retrieve] to get coordinates.
  final String mapboxId;

  /// Primary label, e.g. "Phoenix Marketcity".
  final String name;

  /// Secondary context line, e.g. "Whitefield, Bengaluru, Karnataka".
  final String placeFormatted;

  static MapboxSuggestion? fromJson(Map<String, dynamic> json) {
    final id = json['mapbox_id'];
    final name = json['name'];
    if (id is! String || id.isEmpty || name is! String || name.isEmpty) {
      return null;
    }
    final place = json['place_formatted'];
    return MapboxSuggestion(
      mapboxId: id,
      name: name,
      placeFormatted: place is String ? place : '',
    );
  }
}

/// A fully resolved place with coordinates, returned by [MapboxSearchService.retrieve].
class MapboxPlace {
  const MapboxPlace({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });

  final String name;

  /// Full formatted address, may be empty when Mapbox has none.
  final String address;
  final double lat;
  final double lng;
}

/// Thin client over the Mapbox Search Box API (suggest + retrieve). A single
/// [sessionToken] groups the keystrokes and the final retrieve into one billed
/// session, so create one instance per picker session.
///
/// Docs: https://docs.mapbox.com/api/search/search-box/
class MapboxSearchService {
  MapboxSearchService({Dio? dio, String? sessionToken})
    : _dio = dio ?? Dio(),
      sessionToken = sessionToken ?? _generateSessionToken();

  static const _base = 'https://api.mapbox.com/search/searchbox/v1';

  final Dio _dio;
  final String sessionToken;

  String get _token => AppConfig.mapboxAccessToken;

  bool get isConfigured => _token.isNotEmpty;

  static String _generateSessionToken() {
    final rand = Random();
    return List.generate(
      16,
      (_) => rand.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  /// Returns autocomplete suggestions for [query]. [proximityLat]/[proximityLng]
  /// bias results toward the user's current map center. Returns an empty list
  /// when the query is too short or the token is missing.
  Future<List<MapboxSuggestion>> suggest(
    String query, {
    double? proximityLat,
    double? proximityLng,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2 || !isConfigured) return const [];

    final response = await _dio
        .get<Map<String, dynamic>>(
          '$_base/suggest',
          queryParameters: {
            'q': trimmed,
            'access_token': _token,
            'session_token': sessionToken,
            'limit': 7,
            'types': 'poi,address,place,neighborhood,locality',
            if (proximityLat != null && proximityLng != null)
              'proximity': '$proximityLng,$proximityLat',
          },
        )
        .timeout(const Duration(seconds: 10));

    final suggestions = response.data?['suggestions'];
    if (suggestions is! List) return const [];
    return suggestions
        .whereType<Map<String, dynamic>>()
        .map(MapboxSuggestion.fromJson)
        .whereType<MapboxSuggestion>()
        .toList(growable: false);
  }

  /// Resolves a [MapboxSuggestion] into a [MapboxPlace] with coordinates.
  /// Returns null if the place can't be resolved.
  Future<MapboxPlace?> retrieve(MapboxSuggestion suggestion) async {
    if (!isConfigured) return null;

    final response = await _dio
        .get<Map<String, dynamic>>(
          '$_base/retrieve/${suggestion.mapboxId}',
          queryParameters: {
            'access_token': _token,
            'session_token': sessionToken,
          },
        )
        .timeout(const Duration(seconds: 10));

    final features = response.data?['features'];
    if (features is! List || features.isEmpty) return null;
    final feature = features.first;
    if (feature is! Map<String, dynamic>) return null;

    final geometry = feature['geometry'];
    final coords = geometry is Map<String, dynamic>
        ? geometry['coordinates']
        : null;
    if (coords is! List || coords.length < 2) return null;
    final lng = (coords[0] as num?)?.toDouble();
    final lat = (coords[1] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    final props = feature['properties'];
    final propsMap = props is Map<String, dynamic>
        ? props
        : const <String, dynamic>{};
    final name = propsMap['name'] as String? ?? suggestion.name;
    final address =
        (propsMap['full_address'] ?? propsMap['place_formatted']) as String? ??
        '';

    return MapboxPlace(name: name, address: address, lat: lat, lng: lng);
  }
}
