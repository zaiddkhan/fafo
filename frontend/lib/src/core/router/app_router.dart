import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fafu/src/core/services/deep_link_service.dart';
import 'package:fafu/src/core/services/shared_preferences_provider.dart';
import 'package:fafu/src/features/auth/data/auth_repository.dart';
import 'package:fafu/src/features/auth/presentation/login_page.dart';
import 'package:fafu/src/features/auth/presentation/otp_page.dart';
import 'package:fafu/src/features/auth/presentation/signup_page.dart';
import 'package:fafu/src/features/chat/presentation/chat_page.dart';
import 'package:fafu/src/features/creators/presentation/creator_application_page.dart';
import 'package:fafu/src/features/events/presentation/event_detail_page.dart';
import 'package:fafu/src/features/friends/presentation/contacts_sync_page.dart';
import 'package:fafu/src/features/friends/presentation/friends_page.dart';
import 'package:fafu/src/features/groups/presentation/groups_page.dart';
import 'package:fafu/src/features/home/data/mock_events.dart';
import 'package:fafu/src/features/home/presentation/main_shell.dart';
import 'package:fafu/src/features/notifications/presentation/notifications_page.dart';
import 'package:fafu/src/features/onboarding/presentation/profile_setup_page.dart';
import 'package:fafu/src/features/profile/presentation/public_profile_page.dart';
import 'package:fafu/src/features/friends/domain/friend.dart';
import 'package:fafu/src/features/search/presentation/search_page.dart';
import 'package:fafu/src/features/settings/presentation/settings_page.dart';
import 'package:fafu/src/features/splash/presentation/brand_splash_page.dart';
import 'package:fafu/src/features/splash/presentation/splash_page.dart';

const onboardingCompleteKey = 'onboarding_complete';

final appRouterProvider = Provider<GoRouter>((ref) {
  final prefs = ref.read(sharedPreferencesProvider).value;

  return GoRouter(
    initialLocation: BrandSplashPage.routePath,
    redirect: (context, state) {
      final isOnboarded = prefs?.getBool(onboardingCompleteKey) ?? false;
      final path = state.matchedLocation;

      // If onboarded and on splash, skip straight to main
      if (isOnboarded && path == SplashPage.routePath) {
        return MainShell.routePath;
      }

      // A non-user following a shared event link must sign in first to see the
      // details ("sign in first to know more"). Gate any deep link behind the
      // splash/sign-in screen until onboarding is complete.
      if (!isOnboarded && isEventDeepLinkPath(path)) {
        if (prefs != null) savePendingDeepLinkPathSync(prefs, state.uri.path);
        return SplashPage.routePath;
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: BrandSplashPage.routePath,
        name: BrandSplashPage.routeName,
        builder: (context, state) => const BrandSplashPage(),
      ),
      GoRoute(
        path: SplashPage.routePath,
        name: SplashPage.routeName,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: LoginPage.routePath,
        name: LoginPage.routeName,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: SignupPage.routePath,
        name: SignupPage.routeName,
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: OtpPage.routePath,
        name: OtpPage.routeName,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? const {};
          return OtpPage(
            phoneNumber: extra['phoneNumber'] as String? ?? '',
            verificationId: extra['verificationId'] as String? ?? '',
            resendToken: extra['resendToken'] as int?,
            pendingVerification:
                extra['pendingVerification']
                    as Future<PhoneVerificationResult>?,
          );
        },
      ),
      GoRoute(
        path: ProfileSetupPage.routePath,
        name: ProfileSetupPage.routeName,
        builder: (context, state) => const ProfileSetupPage(),
      ),
      GoRoute(
        path: MainShell.routePath,
        name: MainShell.routeName,
        builder: (context, state) => const MainShell(),
      ),
      GoRoute(
        path: '/event/:id',
        name: EventDetailPage.routeName,
        builder: (context, state) {
          final event = state.extra is MockEvent
              ? state.extra as MockEvent
              : null;
          return EventDetailPage(
            eventId: state.pathParameters['id']!,
            initialEvent: event,
          );
        },
      ),
      GoRoute(
        path: SearchPage.routePath,
        name: SearchPage.routeName,
        builder: (context, state) {
          final events = state.extra as List<MockEvent>? ?? [];
          return SearchPage(events: events);
        },
      ),
      GoRoute(
        path: SettingsPage.routePath,
        name: SettingsPage.routeName,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: ChatPage.routePath,
        name: ChatPage.routeName,
        builder: (context, state) => const ChatPage(),
      ),
      GoRoute(
        path: FriendsPage.routePath,
        name: FriendsPage.routeName,
        builder: (context, state) => const FriendsPage(),
      ),
      GoRoute(
        path: ContactsSyncPage.routePath,
        name: ContactsSyncPage.routeName,
        builder: (context, state) => const ContactsSyncPage(),
      ),
      GoRoute(
        path: NotificationsPage.routePath,
        name: NotificationsPage.routeName,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: GroupsPage.routePath,
        name: GroupsPage.routeName,
        builder: (context, state) => const GroupsPage(),
      ),
      GoRoute(
        path: PublicProfilePage.routePath,
        name: PublicProfilePage.routeName,
        builder: (context, state) =>
            PublicProfilePage(user: state.extra as PublicUserResponse),
      ),
      GoRoute(
        path: CreatorApplicationPage.routePath,
        name: CreatorApplicationPage.routeName,
        builder: (context, state) => const CreatorApplicationPage(),
      ),
    ],
  );
});
