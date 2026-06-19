import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig._();

  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';

  /// Public Mapbox access token, used for place search/autocomplete (Search Box API).
  static String get mapboxAccessToken => dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
}
