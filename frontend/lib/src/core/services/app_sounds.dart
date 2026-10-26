import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'package:fafu/src/core/config/feature_flags.dart';

/// The five V3 sounds (brief 7.4). File names live in assets/sounds/README.md.
enum FafoSound {
  /// N: a nudge arrives (push; in-app when a live notification is drawn).
  notification('n'),

  /// NS: the sender's nudge goes out.
  nudgeSent('ns'),

  /// YN: tapping Yes or No.
  answer('yn'),

  /// FR: switching "I'm free rn" on.
  free('fr'),

  /// EXP: a timer hits zero (expiry and go time).
  timerDone('exp');

  const FafoSound(this.file);

  final String file;
}

/// Plays in-app sounds. Silent until [FeatureFlags.customSounds] is on, and
/// never throws: a missing file or audio error must not break a tap.
class AppSounds {
  AppSounds._();

  static final _player = AudioPlayer();
  static bool _configured = false;

  static Future<void> play(FafoSound sound) async {
    if (!FeatureFlags.customSounds || kIsWeb) return;
    try {
      if (!_configured) {
        _configured = true;
        // Ambient: respects the iOS silent switch and mixes with other audio
        // instead of pausing the user's music.
        await _player.setAudioContext(
          AudioContext(
            iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
            android: const AudioContextAndroid(
              contentType: AndroidContentType.sonification,
              usageType: AndroidUsageType.notificationEvent,
              audioFocus: AndroidAudioFocus.none,
            ),
          ),
        );
      }
      await _player.stop();
      await _player.play(AssetSource('sounds/${sound.file}.mp3'));
    } catch (e) {
      debugPrint('Sound ${sound.file} failed: $e');
    }
  }
}
