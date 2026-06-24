import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig._();

  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';

  /// Public HTTPS origin used for shareable links and app/universal links.
  static String get publicWebBaseUrl =>
      dotenv.env['PUBLIC_WEB_BASE_URL'] ?? 'https://getfafo.app';

  /// Public Mapbox access token, used for place search/autocomplete (Search Box API).
  static String get mapboxAccessToken =>
      dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
}
