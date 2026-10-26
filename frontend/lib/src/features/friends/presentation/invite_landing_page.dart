import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/features/friends/data/friends_repository.dart';
import 'package:fafu/src/features/home/presentation/main_shell.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';

/// Landing screen for a `/invite/<code>` link, the link shared from the Code
/// sheet. Redeems the referral code, which makes both people friends straight
/// away (V3 brief 3.8).
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
  String? _friendName;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _redeem();
  }

  Future<void> _redeem() async {
    try {
      final result = await ref
          .read(friendsRepositoryProvider)
          .redeemReferralCode(widget.token);
      if (mounted) setState(() => _friendName = result.friend.displayName);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is ApiException && e.statusCode == 401
            ? 'Sign in first, then enter ${widget.token} under Code.'
            : friendlyErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                FafoDisplay(
                  _friendName != null ? 'You and $_friendName are in.' : 'That code didn’t work.',
                  fontSize: 52,
                ),
                const SizedBox(height: 12),
                Text(
                  _friendName != null
                      ? 'You show up in each other’s invites now. Send one clear plan.'
                      : _error ?? '',
                  style: AppTypography.ui(15, fontWeight: FontWeight.w400),
                ),
              ],
              const Spacer(),
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
