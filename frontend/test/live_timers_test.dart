import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fafu/src/features/notifications/data/live_timers.dart';
import 'package:fafu/src/features/nudges/domain/nudge.dart';
import 'package:fafu/src/features/nudges/domain/nudge_view.dart';

const _me = 'me';
const _friend = 'sara';
final _now = DateTime.utc(2026, 11, 8, 20);

NudgeResponse _nudge({
  required String id,
  String sender = _me,
  NudgeStatus status = NudgeStatus.active,
  Duration sentAgo = const Duration(minutes: 1),
  DateTime? goAt,
  Map<String, String> votes = const {},
  String? questId,
}) {
  final sent = _now.subtract(sentAgo);
  return NudgeResponse(
    id: id,
    senderUid: sender,
    title: 'Chai at Sharma’s',
    responseWindowMinutes: 10,
    status: status,
    expiresAt: sent.add(const Duration(minutes: 10)),
    answerBy: sent.add(const Duration(minutes: 10)),
    goAt: goAt,
    reminderCount: 0,
    reminderLimit: 1,
    votes: votes,
    yesCount: votes.values.where((v) => v == 'yes').length,
    voterCount: votes.length,
    expectedVoterCount: 1,
    createdAt: sent,
    questId: questId,
    senderName: sender == _me ? 'Me' : 'Sara',
    targetName: sender == _me ? 'Sara' : 'Me',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('fafo/live_activity');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() async {
    await LiveTimers.endAll(); // resets the dedupe between tests
    debugDefaultTargetPlatformOverride = null;
  });

  List<Map<Object?, Object?>> lastPayload() =>
      (calls.lastWhere((c) => c.method == 'sync').arguments as List)
          .cast<Map<Object?, Object?>>();

  test('maps each running state and puts an answer I owe first', () {
    final views = [
      NudgeView(_nudge(id: 'sent'), myUid: _me),
      NudgeView(
        _nudge(
          id: 'yes',
          sender: _friend,
          status: NudgeStatus.acceptedTimer,
          goAt: _now.add(const Duration(minutes: 3)),
          votes: {_me: 'yes'},
          questId: 'q1',
        ),
        myUid: _me,
      ),
      NudgeView(_nudge(id: 'incoming', sender: _friend, sentAgo: const Duration(minutes: 2)), myUid: _me),
      // Expired and unanswered: no timer.
      NudgeView(_nudge(id: 'old', sender: _friend, sentAgo: const Duration(minutes: 30)), myUid: _me),
    ];

    LiveTimers.sync(views, _now);

    final payload = lastPayload();
    expect(payload.map((e) => e['id']), ['incoming', 'yes', 'sent']);
    final byId = {for (final e in payload) e['id']: e};
    expect(byId['incoming']!['head'], 'From Sara');
    expect(byId['incoming']!['label'], 'left to answer');
    expect(byId['sent']!['head'], 'Waiting for Sara');
    expect(byId['yes']!['head'], 'You said yes');
    expect(byId['yes']!['label'], 'to get there');
    expect(byId['yes']!['red'], true);
    expect(byId['yes']!['quest'], true);
    expect(byId['yes']!['doneLabel'], 'Go time');
  });

  test('only messages iOS when the set of timers changes', () {
    final views = [NudgeView(_nudge(id: 'sent'), myUid: _me)];
    LiveTimers.sync(views, _now);
    LiveTimers.sync(views, _now.add(const Duration(seconds: 1)));
    expect(calls.where((c) => c.method == 'sync'), hasLength(1));

    // Past the answer window: nothing running, so it syncs an empty list.
    LiveTimers.sync(views, _now.add(const Duration(minutes: 20)));
    expect(calls.where((c) => c.method == 'sync'), hasLength(2));
    expect(lastPayload(), isEmpty);
  });

  test('does nothing off iOS', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    LiveTimers.sync([NudgeView(_nudge(id: 'sent'), myUid: _me)], _now);
    expect(calls, isEmpty);
  });
}
