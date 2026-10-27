// Renders every V3 screen and nudge state with fake data, for side-by-side
// review against the client prototype. Not a pass/fail suite (skipped by
// default, see dart_test.yaml): run with
//   flutter test test/screenshots --update-goldens --run-skipped
// and look at test/screenshots/goldens/*.png.
@Tags(['screenshots'])
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_theme.dart';
import 'package:fafu/src/features/auth/presentation/login_page.dart';
import 'package:fafu/src/features/auth/presentation/otp_page.dart';
import 'package:fafu/src/features/auth/presentation/signup_page.dart';
import 'package:fafu/src/features/friends/presentation/friends_tab.dart';
import 'package:fafu/src/features/friends/presentation/invite_landing_page.dart';
import 'package:fafu/src/features/onboarding/presentation/profile_setup_page.dart';
import 'package:fafu/src/features/profile/presentation/edit_profile_page.dart';
import 'package:fafu/src/features/settings/presentation/settings_page.dart';
import 'package:fafu/src/features/splash/presentation/splash_page.dart';
import 'package:fafu/src/features/friends/data/friends_providers.dart';
import 'package:fafu/src/features/friends/data/friends_repository.dart';
import 'package:fafu/src/features/friends/domain/friend.dart';
import 'package:fafu/src/features/groups/data/groups_providers.dart';
import 'package:fafu/src/features/groups/domain/group.dart';
import 'package:fafu/src/features/groups/presentation/group_sheet.dart';
import 'package:fafu/src/features/nudges/domain/nudge.dart';
import 'package:fafu/src/features/nudges/presentation/compose_nudge_sheet.dart';
import 'package:fafu/src/features/profile/presentation/profile_sheet.dart';
import 'package:fafu/src/features/quests/data/quests_providers.dart';
import 'package:fafu/src/features/quests/domain/quest.dart';
import 'package:fafu/src/features/right_now/data/right_now_providers.dart';
import 'package:fafu/src/features/right_now/presentation/code_sheet.dart';
import 'package:fafu/src/features/right_now/presentation/preview_sheet.dart';
import 'package:fafu/src/features/right_now/presentation/right_now_page.dart';
import 'package:fafu/src/features/users/data/users_repository.dart';
import 'package:fafu/src/features/users/domain/profile.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_toast.dart';
import 'package:fafu/src/core/services/network_status.dart';
import 'package:fafu/src/features/notifications/data/notification_nag.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_status_bars.dart';

// --- Fonts ----------------------------------------------------------------------

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File(f).readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await load('Anton', ['assets/fonts/Anton-Regular.ttf']);
  await load('Archivo', ['assets/fonts/Archivo-Variable.ttf']);
  await load('IBMPlexMono', ['assets/fonts/IBMPlexMono-Medium.ttf', 'assets/fonts/IBMPlexMono-SemiBold.ttf']);
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '/opt/homebrew/share/flutter';
  await load('MaterialIcons', ['$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf']);
}

// --- Fake data ------------------------------------------------------------------

const _me = 'me';
final _now = DateTime.now().toUtc();

ProfileResponse _profile({bool free = false}) => ProfileResponse(
  uid: _me,
  phone: '+910000000000',
  displayName: 'Liloorx',
  username: 'liloorx',
  onboardingComplete: true,
  freeNow: free,
);

PublicUserResponse _user(String id, String name, {bool free = false, bool quests = true}) => PublicUserResponse(
  uid: id,
  displayName: name,
  username: id,
  online: false,
  friendshipStatus: FriendshipStatus.friends,
  freeNow: free,
  sideQuestInvites: quests,
);

final _friends = [
  FriendResponse(user: _user('maya', 'Maya', free: true), friendsSince: _now),
  FriendResponse(user: _user('leo', 'Leo'), friendsSince: _now),
  FriendResponse(user: _user('nina', 'Nina', free: true), friendsSince: _now),
  FriendResponse(user: _user('sam', 'Sam', quests: false), friendsSince: _now),
];

final _flatmates = GroupResponse(
  id: 'flat',
  name: 'Flatmates',
  adminUid: _me,
  createdAt: _now,
  updatedAt: _now,
  members: [
    for (final u in [_user(_me, 'Liloorx'), _user('maya', 'Maya'), _user('leo', 'Leo'), _user('nina', 'Nina'), _user('sam', 'Sam')])
      GroupMemberResponse(user: u, joinedAt: _now, isAdmin: u.uid == _me),
  ],
);

QuestResponse _quest(String id, String title, String prompt, QuestDifficulty d) => QuestResponse(
  id: id,
  title: title,
  description: prompt,
  difficulty: d,
  published: true,
  createdAt: _now,
  updatedAt: _now,
);

final _quests = [
  _quest('walk', 'Walk one block', 'Meet outside and walk one block with me?', QuestDifficulty.easy),
  _quest('snack', 'Snack run', 'Pick a snack spot and meet me there?', QuestDifficulty.easy),
  _quest('photo', 'Photo hunt', 'Find the weirdest thing nearby and take a photo together?', QuestDifficulty.medium),
  _quest('route', 'Take a new route', 'Meet me and take a route neither of us usually walks?', QuestDifficulty.medium),
  _quest('lap', 'Phone-free lap', 'Leave our phones away and take a 15-minute lap?', QuestDifficulty.hard),
  _quest('song', 'Tiny performance', 'Meet me outside and perform a 30-second made-up song?', QuestDifficulty.hard),
];

/// A nudge [age] old. Status and votes decide the state.
NudgeResponse _nudge({
  required String id,
  required String title,
  bool sent = true,
  NudgeStatus status = NudgeStatus.active,
  Duration age = const Duration(seconds: 2),
  Map<String, String> votes = const {},
  int countdown = 15,
  Duration? acceptedAfter,
  String? outcome,
  bool group = false,
  int groupSize = 1,
  String? questDifficulty,
  String? description,
}) {
  final created = _now.subtract(age);
  final answerBy = created.add(const Duration(minutes: 10));
  final acceptedAt = acceptedAfter == null ? null : created.add(acceptedAfter);
  final goAt = acceptedAt?.add(Duration(minutes: countdown));
  final yes = votes.values.where((v) => v == 'yes').length;
  return NudgeResponse(
    id: id,
    senderUid: sent ? _me : 'maya',
    title: title,
    responseWindowMinutes: countdown,
    status: status,
    expiresAt: goAt ?? answerBy,
    answerBy: answerBy,
    goAt: goAt,
    acceptedTimerStartedAt: acceptedAt,
    outcome: outcome,
    resolvedAt: status == NudgeStatus.resolved || status == NudgeStatus.expired ? created.add(const Duration(minutes: 1)) : null,
    reminderCount: 0,
    reminderLimit: 0,
    votes: votes,
    yesCount: yes,
    voterCount: votes.length,
    expectedVoterCount: group ? groupSize : 1,
    createdAt: created,
    feedType: group ? NudgeFeedType.group : NudgeFeedType.friend,
    senderName: sent ? 'Liloorx' : 'Maya',
    targetName: group ? 'Flatmates' : (sent ? 'Maya' : 'Liloorx'),
    questId: questDifficulty == null ? null : 'walk',
    questDifficulty: questDifficulty,
    description: description,
    yesNames: [for (final e in votes.entries) if (e.value == 'yes') e.key[0].toUpperCase() + e.key.substring(1)],
  );
}

final _recent = [
  _nudge(id: 'r1', title: 'Grocery run?', age: const Duration(hours: 1), status: NudgeStatus.expired, outcome: 'expired'),
  _nudge(
    id: 'r2',
    title: 'Movie night?',
    age: const Duration(hours: 3),
    status: NudgeStatus.resolved,
    outcome: 'yes',
    group: true,
    groupSize: 4,
    votes: {'maya': 'yes', 'leo': 'yes', 'nina': 'yes', 'sam': 'no'},
    acceptedAfter: const Duration(minutes: 1),
  ),
  _nudge(
    id: 'r3',
    title: 'Pho after work?',
    sent: false,
    age: const Duration(hours: 5),
    status: NudgeStatus.resolved,
    outcome: 'yes',
    votes: {_me: 'yes'},
    acceptedAfter: const Duration(minutes: 2),
  ),
  _nudge(id: 'r5', title: 'Late lunch?', age: const Duration(hours: 3), status: NudgeStatus.resolved, outcome: 'cancelled'),
  _nudge(id: 'r4', title: 'Geri?', age: const Duration(days: 1), status: NudgeStatus.resolved, outcome: 'no', votes: {'maya': 'no'}),
];

// --- Provider fakes ---------------------------------------------------------------

class _FakeProfile extends CurrentProfileNotifier {
  _FakeProfile(this.profile);
  final ProfileResponse profile;
  @override
  Future<ProfileResponse> build() async => profile;
}

class _FakeNudges extends MyNudgesNotifier {
  _FakeNudges(this.items);
  final List<NudgeResponse> items;
  @override
  Future<List<NudgeResponse>> build() async => items;
  @override
  Future<void> refresh() async {}
}

class _FakeLiveFriends extends LiveFriendsNotifier {
  @override
  Future<List<FriendResponse>> build() async => _friends;
  @override
  Future<void> refresh() async {}
}

class _FakeFriendsRepo extends FriendsRepository {
  _FakeFriendsRepo() : super(Dio());
  @override
  Future<PublicUserResponse> previewReferralCode(String code) async =>
      const PublicUserResponse(
        uid: 'maya',
        displayName: 'Maya Rao',
        username: 'maya',
        online: false,
        friendshipStatus: FriendshipStatus.none,
      );
  @override
  Future<ReferralCode> getReferralCode() async =>
      const ReferralCode(code: 'LILO-7K2QX', shareUrl: 'https://getfafo.app/invite/LILO7K2QX');
}

List<Override> _overrides({
  List<NudgeResponse> nudges = const [],
  bool free = false,
  bool online = true,
  bool notificationsOff = false,
}) => [
  currentProfileProvider.overrideWith(() => _FakeProfile(_profile(free: free))),
  myNudgesProvider.overrideWith(() => _FakeNudges(nudges)),
  networkStatusProvider.overrideWith(online ? _Online.new : _Offline.new),
  notificationNagProvider.overrideWith(notificationsOff ? _NagOn.new : _NagOff.new),
  liveFriendsProvider.overrideWith(_FakeLiveFriends.new),
  friendsListProvider.overrideWith((ref) async => _friends),
  groupsListProvider.overrideWith((ref) async => [_flatmates]),
  questsListProvider.overrideWith((ref) async => _quests),
  friendsRepositoryProvider.overrideWithValue(_FakeFriendsRepo()),
];

// --- Harness ----------------------------------------------------------------------

/// A sheet rendered full-screen on paper, as it looks when open.
Widget _asSheet(Widget body) => Builder(
  builder: (context) => Scaffold(
    backgroundColor: AppColors.bgPrimary,
    body: SafeArea(child: body),
  ),
);

/// A tab body with the V3 bottom nav, as the shell lays it out.
Widget _withNav(int index, Widget body) => Builder(
  builder: (context) => Scaffold(
    backgroundColor: AppColors.bgPrimary,
    body: body,
    bottomNavigationBar: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const FafoStatusBars(),
        FafoBottomNav(
          items: const [
            FafoNavItem(icon: Icons.bolt_rounded, label: 'Home'),
            FafoNavItem(icon: Icons.people_alt_outlined, label: 'Friends'),
            FafoNavItem(icon: Icons.person_outline, label: 'Profile'),
          ],
          currentIndex: index,
          onTap: (_) {},
        ),
      ],
    ),
  ),
);

Future<void> _shoot(
  WidgetTester tester,
  String name,
  Widget screen, {
  List<Override> overrides = const [],
  Brightness brightness = Brightness.light,
  double width = 390,
  double height = 1500,
  Duration settle = Duration.zero,
}) async {
  AppColors.setBrightness(brightness);
  // Toasts are app-wide state; don't let one test's toast leak into the next.
  FafoToasts.hide();
  tester.view.physicalSize = Size(width * 2, height * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
        builder: (context, child) => FafoToastHost(child: child!),
        home: screen,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
  if (settle > Duration.zero) {
    await tester.pump(settle);
    await tester.pump(settle);
  }
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
  // Unmount so tickers' periodic timers are cancelled before the test ends.
  await tester.pumpWidget(const SizedBox());
  AppColors.setBrightness(Brightness.light);
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await _loadFonts();
  });

  final scenes = <String, ({Widget screen, List<Override> overrides, double height})>{
    // Home
    '01_home_idle': (screen: const RightNowPage(), overrides: _overrides(), height: 1000),
    '02_home_free_recent': (screen: const RightNowPage(), overrides: _overrides(nudges: _recent, free: true), height: 1150),
    '03_sender_waiting': (
      screen: const RightNowPage(),
      overrides: _overrides(nudges: [_nudge(id: 'l', title: 'Coffee downstairs?'), ..._recent], free: true),
      height: 1500,
    ),
    '04_receiver_answering': (
      screen: const RightNowPage(),
      overrides: _overrides(nudges: [_nudge(id: 'l', title: 'Coffee downstairs?', sent: false), ..._recent]),
      height: 1500,
    ),
    '05_sender_said_no': (
      screen: const RightNowPage(),
      overrides: _overrides(nudges: [_nudge(id: 'l', title: 'Coffee downstairs?', status: NudgeStatus.resolved, outcome: 'no', votes: {'maya': 'no'}, age: const Duration(seconds: 50))]),
      height: 1100,
    ),
    '06_receiver_said_no': (
      screen: const RightNowPage(),
      overrides: _overrides(nudges: [_nudge(id: 'l', title: 'Coffee downstairs?', sent: false, status: NudgeStatus.resolved, outcome: 'no', votes: {_me: 'no'}, age: const Duration(seconds: 50))]),
      height: 1100,
    ),
    '07_sender_said_yes': (
      screen: const RightNowPage(),
      overrides: _overrides(nudges: [_nudge(id: 'l', title: 'Coffee downstairs?', status: NudgeStatus.acceptedTimer, votes: {'maya': 'yes'}, acceptedAfter: Duration.zero, age: const Duration(seconds: 30))]),
      height: 1100,
    ),
    '08_receiver_said_yes': (
      screen: const RightNowPage(),
      overrides: _overrides(nudges: [_nudge(id: 'l', title: 'Coffee downstairs?', sent: false, status: NudgeStatus.acceptedTimer, votes: {_me: 'yes'}, acceptedAfter: Duration.zero, age: const Duration(seconds: 30))]),
      height: 1100,
    ),
    '09_sender_expired': (
      screen: const RightNowPage(),
      overrides: _overrides(nudges: [_nudge(id: 'l', title: 'Coffee downstairs?', status: NudgeStatus.expired, outcome: 'expired', age: const Duration(seconds: 50))]),
      height: 1100,
    ),
    '10_sender_go_time': (
      screen: const RightNowPage(),
      overrides: _overrides(nudges: [_nudge(id: 'l', title: 'Coffee downstairs?', status: NudgeStatus.acceptedTimer, votes: {'maya': 'yes'}, countdown: 5, acceptedAfter: Duration.zero, age: const Duration(minutes: 5, seconds: 5))]),
      height: 1100,
    ),
    '11_group_sender_tally': (
      screen: const RightNowPage(),
      overrides: _overrides(nudges: [_nudge(id: 'g', title: 'Movie night?', group: true, groupSize: 4, status: NudgeStatus.acceptedTimer, votes: {'maya': 'yes', 'leo': 'no', 'nina': 'yes'}, acceptedAfter: const Duration(minutes: 1), age: const Duration(minutes: 2))]),
      height: 1200,
    ),
    '12_group_receiver': (
      screen: const RightNowPage(),
      overrides: _overrides(nudges: [_nudge(id: 'g', title: 'Movie night?', sent: false, group: true, groupSize: 4, votes: {'leo': 'yes'})]),
      height: 1250,
    ),
    '14_receiver_cancelled': (
      screen: const RightNowPage(),
      overrides: _overrides(nudges: [_nudge(id: 'l', title: 'Coffee downstairs?', sent: false, status: NudgeStatus.resolved, outcome: 'cancelled', age: const Duration(seconds: 50)), ..._recent]),
      height: 1300,
    ),
    '15_cancel_confirm': (screen: const _ConfirmDemo(), overrides: _overrides(), height: 844),
    '13_quest_receiver': (
      screen: const RightNowPage(),
      overrides: _overrides(nudges: [_nudge(id: 'q', title: 'Walk one block', description: 'Meet outside and walk one block with me?', sent: false, questDifficulty: 'easy')]),
      height: 1250,
    ),
    // Sheets
    '20_composer': (screen: _asSheet(const ComposeNudgeSheet()), overrides: _overrides(), height: 1100),
    '21_composer_quest': (screen: _asSheet(ComposeNudgeSheet(quest: _quests.first)), overrides: _overrides(), height: 1150),
    '22_profile': (screen: _asSheet(ProfileSheet(onInvite: (_) {})), overrides: _overrides(), height: 2000),
    '23_group_new': (screen: _asSheet(const GroupSheet()), overrides: _overrides(), height: 1000),
    '24_group_edit': (screen: _asSheet(GroupSheet(group: _flatmates)), overrides: _overrides(), height: 1100),
    '25_code': (screen: _asSheet(const CodeSheet()), overrides: _overrides(), height: 950),
    '26_preview': (screen: _asSheet(const PreviewSheet()), overrides: _overrides(), height: 1650),
    // Screens the prototype doesn't show, restyled in its language.
    '30_landing': (screen: const SplashPage(), overrides: _overrides(), height: 844),
    '31_login': (screen: const LoginPage(), overrides: _overrides(), height: 844),
    '32_signup': (screen: const SignupPage(), overrides: _overrides(), height: 844),
    '33_otp': (
      screen: const OtpPage(phoneNumber: '+919876543210', verificationId: 'v1'),
      overrides: _overrides(),
      height: 844,
    ),
    '34_onboarding': (screen: const ProfileSetupPage(), overrides: _overrides(), height: 1000),
    '35_settings': (screen: const SettingsPage(), overrides: _overrides(), height: 1100),
    '36_edit_profile': (screen: EditProfilePage(profile: _profile()), overrides: _overrides(), height: 844),
    // V3 shell: Home / Friends / Profile with the bottom nav.
    '40_shell_home': (screen: _withNav(0, const RightNowPage()), overrides: _overrides(nudges: _recent, free: true), height: 1000),
    '43_shell_offline_notifications_off': (
      screen: _withNav(0, const RightNowPage()),
      overrides: _overrides(nudges: _recent, online: false, notificationsOff: true),
      height: 1000,
    ),
    '41_shell_friends': (
      screen: _withNav(1, FriendsTab(onNudge: (_) {})),
      overrides: [
        ..._overrides(),
        incomingFriendRequestsProvider.overrideWith((ref) async => [
          FriendRequestResponse(
            id: 'req1',
            requester: _user('tara', 'Tara Singh'),
            recipient: _user(_me, 'Liloorx'),
            status: FriendRequestStatus.pending,
            createdAt: _now,
          ),
        ]),
      ],
      height: 1000,
    ),
    '42_shell_profile': (
      screen: _withNav(2, Scaffold(backgroundColor: AppColors.bgPrimary, body: SafeArea(bottom: false, child: ProfileSheet(asTab: true, onInvite: (_) {})))),
      overrides: _overrides(),
      height: 1000,
    ),
    '37_invite_link': (screen: const InviteLandingPage(token: 'MAYA7K2QX'), overrides: _overrides(), height: 844),
  };

  for (final entry in scenes.entries) {
    testWidgets(entry.key, (tester) async {
      final s = entry.value;
      await _shoot(tester, entry.key, s.screen, overrides: s.overrides, height: s.height);
    });
  }

  // Toasts: success, error, info, light and dark.
  const toasts = {
    'success': (FafoToastKind.success, 'Defaults saved.'),
    'error': (FafoToastKind.error, 'Your session ended. Please sign in again.'),
    'info': (FafoToastKind.info, 'Profile still loading…'),
  };
  for (final dark in [false, true]) {
    for (final t in toasts.entries) {
      final name = '${dark ? 'dark_' : ''}50_toast_${t.key}';
      testWidgets(name, (tester) async {
        await _shoot(
          tester,
          name,
          _ToastDemo(kind: t.value.$1, message: t.value.$2),
          height: 500,
          brightness: dark ? Brightness.dark : Brightness.light,
          settle: const Duration(milliseconds: 600),
        );
      });
    }
  }

  // Dark theme
  for (final name in ['02_home_free_recent', '04_receiver_answering', '07_sender_said_yes', '20_composer', '22_profile', '30_landing', '33_otp', '35_settings', '40_shell_home', '41_shell_friends']) {
    testWidgets('dark_$name', (tester) async {
      final s = scenes[name]!;
      await _shoot(tester, 'dark_$name', s.screen, overrides: s.overrides, height: s.height, brightness: Brightness.dark);
    });
  }

  // Small phone (320pt wide, e.g. iPhone SE 1st gen)
  for (final name in ['02_home_free_recent', '04_receiver_answering', '11_group_sender_tally', '20_composer', '22_profile', '30_landing', '33_otp', '34_onboarding', '40_shell_home', '41_shell_friends']) {
    testWidgets('small_$name', (tester) async {
      final s = scenes[name]!;
      await _shoot(tester, 'small_$name', s.screen, overrides: s.overrides, height: s.height, width: 320);
    });
  }
}

/// Shows one toast over an empty page once mounted.
class _ToastDemo extends StatefulWidget {
  const _ToastDemo({required this.kind, required this.message});

  final FafoToastKind kind;
  final String message;

  @override
  State<_ToastDemo> createState() => _ToastDemoState();
}

class _ToastDemoState extends State<_ToastDemo> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => showFafoToast(context, widget.message, kind: widget.kind));
  }

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: AppColors.bgPrimary);
}

/// The sender's "Cancel plan" confirm, opened once mounted.
class _ConfirmDemo extends StatefulWidget {
  const _ConfirmDemo();

  @override
  State<_ConfirmDemo> createState() => _ConfirmDemoState();
}

class _ConfirmDemoState extends State<_ConfirmDemo> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => showFafoConfirm(
        context,
        title: 'Cancel this plan?',
        message: '“Coffee downstairs?” goes away for Maya. You can send a new one straight after.',
        confirmLabel: 'Cancel plan',
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: AppColors.bgPrimary);
}

class _Online extends NetworkStatus {
  @override
  bool build() => true;
}

class _Offline extends NetworkStatus {
  @override
  bool build() => false;
}

class _NagOff extends NotificationNag {
  @override
  bool build() => false;
}

class _NagOn extends NotificationNag {
  @override
  bool build() => true;
}
