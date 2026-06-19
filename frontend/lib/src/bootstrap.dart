import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fafu/firebase_options.dart';
import 'package:fafu/src/app.dart';
import 'package:fafu/src/core/services/shared_preferences_provider.dart';
import 'package:fafu/src/features/notifications/data/push_service.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: 'assets/env/.env');

  // Don't let a slow/failed Firebase web SDK load block the first frame.
  // If init hangs or throws, the UI still renders; auth-dependent calls will
  // surface their own errors when used.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 8));
  } catch (e, st) {
    debugPrint('Firebase init failed or timed out: $e\n$st');
  }

  // Register the background/terminated push handler (native platforms only).
  // Must run before runApp so taps from a cold start are delivered.
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(AsyncValue.data(prefs)),
      ],
      child: const FafuApp(),
    ),
  );
}
