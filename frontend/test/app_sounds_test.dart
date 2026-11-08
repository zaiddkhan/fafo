import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fafu/src/core/services/app_sounds.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // AppSounds swallows errors so a bad file never breaks a tap; that also
  // means a misnamed file would just be silent. Catch it here instead.
  test('every sound that can play has its file bundled', () async {
    for (final sound in FafoSound.values.where(AppSounds.isOn)) {
      final data = await rootBundle.load('assets/sounds/${sound.file}.mp3');
      expect(data.lengthInBytes, greaterThan(1000), reason: sound.name);
    }
  });

  test('in-app sounds are on; the push sounds wait for their files', () {
    expect(
      FafoSound.values.where(AppSounds.isOn),
      [FafoSound.nudgeSent, FafoSound.answerYes, FafoSound.answerNo, FafoSound.free],
    );
  });
}
