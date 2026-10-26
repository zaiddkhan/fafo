import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fafu/src/core/config/feature_flags.dart';
import 'package:fafu/src/core/network/session_expired_provider.dart';
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
import 'package:fafu/src/features/friends/presentation/invite_landing_page.dart';
import 'package:fafu/src/features/groups/presentation/groups_page.dart';
import 'package:fafu/src/features/home/data/mock_events.dart';
import 'package:fafu/src/features/home/presentation/main_shell.dart';
import 'package:fafu/src/features/notifications/presentation/notifications_page.dart';
import 'package:fafu/src/features/nudges/domain/nudge.dart';
import 'package:fafu/src/features/nudges/presentation/nudge_feed_sheet.dart';
import 'package:fafu/src/features/onboarding/presentation/profile_setup_page.dart';
import 'package:fafu/src/features/profile/presentation/public_profile_page.dart';
import 'package:fafu/src/features/friends/domain/friend.dart';
import 'package:fafu/src/features/search/presentation/search_page.dart';
import 'package:fafu/src/features/settings/presentation/settings_page.dart';
import 'package:fafu/src/features/splash/presentation/brand_splash_page.dart';
import 'package:fafu/src/features/splash/presentation/splash_page.dart';

const onboardingCompleteKey = 'onboarding_complete';

/// Screens parked in V3 (brief 1.1): a deep link or stale notification aimed at
/// one lands on home instead. Routes stay registered so un-parking is a flag flip.
bool _isParkedPath(String path) {
  if (!FeatureFlags.events &&
      (path.startsWith('/event/') ||
          path == SearchPage.routePath ||
          path.startsWith('/creator'))) {
    return true;
  }
  if (!FeatureFlags.chat && path == ChatPage.routePath) return true;
  if (!FeatureFlags.publicProfiles && path == PublicProfilePage.routePath) return true;
  return false;
}

// Fallback search centre (Bengaluru) used only if the search route is opened
// without a resolved location; callers normally pass the map's current area.
const _defaultSearchLat = 12.9716;
const _defaultSearchLng = 77.5946;

// Auth-flow destinations. A user whose session has expired is allowed to sit
// on any of these (they're already on the way to signing in); anywhere else,
// the redirect below bounces them to the login screen.
const _authRoutePaths = <String>{
  BrandSplashPage.routePath,
  SplashPage.routePath,
  LoginPage.routePath,
  SignupPage.routePath,
  OtpPage.routePath,
  ProfileSetupPage.routePath,
};

final appRouterProvider = Provider<GoRouter>((ref) {
  final prefs = ref.read(sharedPreferencesProvider).value;

  // Bridge the Riverpod session-expired flag to a Listenable GoRouter can watch,
  // so `redirect` re-runs the moment the session dies mid-use.
  final expiredListenable = ValueNotifier<bool>(ref.read(sessionExpiredProvider));
  ref.onDispose(expiredListenable.dispose);
  ref.listen<bool>(sessionExpiredProvider, (_, next) {
    expiredListenable.value = next;
  });

  return GoRouter(
    initialLocation: BrandSplashPage.routePath,
    refreshListenable: expiredListenable,
    redirect: (context, state) {
      final path = state.matchedLocation;

      // Highest priority: a revoked/unrefreshable session sends the user to
      // sign-in from wherever they are. Auth screens are exempt so re-login can
      // proceed.
      if (ref.read(sessionExpiredProvider) && !_authRoutePaths.contains(path)) {
        return LoginPage.routePath;
      }

      final isOnboarded = prefs?.getBool(onboardingCompleteKey) ?? false;

      // A referral link opened before sign-up: keep the code for onboarding.
      if (!isOnboarded && path.startsWith('/invite/') && prefs != null) {
        final code = state.pathParameters['token'] ?? path.substring('/invite/'.length);
        if (code.isNotEmpty) prefs.setString(pendingReferralCodeKey, code);
        return SplashPage.routePath;
      }

      if (_isParkedPath(path)) {
        return isOnboarded ? MainShell.routePath : SplashPage.routePath;
      }

      // If onboarded *and still signed in* and on splash, skip straight to
      // main. Without a Firebase user every request would 401, so stay on the
      // welcome screen to sign in again.
      if (isOnboarded && path == SplashPage.routePath && FirebaseAuth.instance.currentUser != null) {
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
      // Friend invite deep link (`https://getfafo.app/invite/<token>`).
      GoRoute(
        path: InviteLandingPage.routePath,
        name: InviteLandingPage.routeName,
        builder: (context, state) =>
            InviteLandingPage(token: state.pathParameters['token'] ?? ''),
      ),
      GoRoute(
        path: SearchPage.routePath,
        name: SearchPage.routeName,
        builder: (context, state) {
          final args = state.extra as ({double lat, double lng})?;
          return SearchPage(
            lat: args?.lat ?? _defaultSearchLat,
            lng: args?.lng ?? _defaultSearchLng,
          );
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
      // Deep-link target for group notifications: opens the Groups page with the
      // specific group expanded and scrolled into view.
      GoRoute(
        path: '${GroupsPage.routePath}/:groupId',
        name: GroupsPage.focusRouteName,
        builder: (context, state) =>
            GroupsPage(focusGroupId: state.pathParameters['groupId']),
      ),
      // Deep-link target for nudge notifications: opens the nudge feed for the
      // friend/group the nudge belongs to (feed_type + target_id in the payload).
      GoRoute(
        path: NudgeFeedSheet.routePath,
        name: NudgeFeedSheet.routeName,
        builder: (context, state) => NudgeFeedSheet(
          feedType: nudgeFeedTypeFromJson(
            state.uri.queryParameters['feed_type'],
          ),
          targetId: state.uri.queryParameters['target_id'] ?? '',
          title: state.uri.queryParameters['title'] ?? 'Nudges',
        ),
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
