import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/features/friends/data/friends_repository.dart';
import 'package:fafu/src/features/friends/domain/friend.dart';
import 'package:fafu/src/features/home/presentation/main_shell.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';

/// Landing screen for a `/invite/<code>` link, the link shared from the Code
/// sheet. Shows whose code it is and asks first: redeeming makes both people
/// friends straight away (V3 brief 3.8), so a tap on a link alone must not.
class InviteLandingPage extends ConsumerStatefulWidget {
  const InviteLandingPage({required this.token, super.key});

  static const routeName = 'invite-landing';
  static const routePath = '/invite/:token';

  /// The referral code from the link.
  final String token;

  @override
  ConsumerState<InviteLandingPage> createState() => _InviteLandingPageState();
}

class _InviteLandingPageState extends ConsumerState<InviteLandingPage> {
  PublicUserResponse? _owner;
  String? _error;
  bool _loading = true;
  bool _adding = false;
  bool _added = false;

  @override
  void initState() {
    super.initState();
    _preview();
  }

  Future<void> _preview() async {
    try {
      final owner = await ref.read(friendsRepositoryProvider).previewReferralCode(widget.token);
      if (mounted) setState(() => _owner = owner);
    } catch (e) {
      if (mounted) setState(() => _error = _describe(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    setState(() {
      _adding = true;
      _error = null;
    });
    try {
      await ref.read(friendsRepositoryProvider).redeemReferralCode(widget.token);
      if (mounted) setState(() => _added = true);
    } catch (e) {
      if (mounted) setState(() => _error = _describe(e));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  String _describe(Object e) => e is ApiException && e.statusCode == 401
      ? 'Sign in first, then enter ${widget.token} under Code.'
      : friendlyErrorMessage(e);

  @override
  Widget build(BuildContext context) {
    final owner = _owner;
    final name = owner?.displayName.split(' ').first ?? '';
    final alreadyFriends = owner?.friendshipStatus == FriendshipStatus.friends;
    final String headline;
    final String line;
    if (_added || alreadyFriends) {
      headline = 'You and $name are in.';
      line = 'You show up in each other’s invites. Send one clear plan.';
    } else if (owner != null) {
      headline = 'Add $name?';
      line = 'You’ll show up in each other’s invites, and either of you can send a plan.';
    } else {
      headline = 'That code didn’t work.';
      line = _error ?? '';
    }

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const FafoEyebrow('Referral code'),
              const SizedBox(height: 12),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                if (owner != null) ...[
                  FafoAvatar(name: owner.displayName, size: FafoAvatarSize.lg, photoUrl: owner.photoUrl),
                  const SizedBox(height: 16),
                ],
                FafoDisplay(headline, fontSize: 52),
                const SizedBox(height: 12),
                Text(line, style: AppTypography.ui(15, fontWeight: FontWeight.w400)),
                if (_error != null && owner != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: AppTypography.ui(13.5, color: AppColors.signalRed)),
                ],
              ],
              const Spacer(),
              if (owner != null && !_added && !alreadyFriends) ...[
                FafoPill(
                  label: 'Add $name',
                  block: true,
                  busy: _adding,
                  onPressed: _add,
                ),
                const SizedBox(height: 10),
                FafoPill(
                  label: 'Not now',
                  primary: false,
                  block: true,
                  onPressed: _adding ? null : () => context.go(MainShell.routePath),
                ),
              ] else
                FafoPill(
                  label: 'Continue',
                  block: true,
                  onPressed: () => context.go(MainShell.routePath),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
