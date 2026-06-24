import 'package:shared_preferences/shared_preferences.dart';

const pendingDeepLinkPathKey = 'pending_deep_link_path';

bool isEventDeepLinkPath(String path) => path.startsWith('/event/');

/// Stores a protected route so auth/onboarding can send the user back to the
/// shared content after they finish signing in.
Future<void> savePendingDeepLinkPath(String path) async {
  if (!isEventDeepLinkPath(path)) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(pendingDeepLinkPathKey, path);
}

void savePendingDeepLinkPathSync(SharedPreferences prefs, String path) {
  if (!isEventDeepLinkPath(path)) return;
  prefs.setString(pendingDeepLinkPathKey, path);
}

Future<String?> consumePendingDeepLinkPath() async {
  final prefs = await SharedPreferences.getInstance();
  final path = prefs.getString(pendingDeepLinkPathKey);
  if (path == null || !isEventDeepLinkPath(path)) return null;
  await prefs.remove(pendingDeepLinkPathKey);
  return path;
}
