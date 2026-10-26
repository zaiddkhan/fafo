import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/theme/app_chrome.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/features/friends/data/friends_repository.dart';
import 'package:fafu/src/features/friends/domain/friend.dart';
import 'package:fafu/src/features/right_now/data/right_now_providers.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';

final _referralCodeProvider = FutureProvider.autoDispose<ReferralCode>(
  (ref) => ref.watch(friendsRepositoryProvider).getReferralCode(),
);

Future<void> showCodeSheet(BuildContext context) =>
    showFafoSheet<void>(context, builder: (_) => const CodeSheet());

/// "Code" from the home header (V3 brief 3.8). The user's referral code with
/// share and copy. Redeeming a code makes both people friends.
class CodeSheet extends ConsumerStatefulWidget {
  const CodeSheet({super.key});

  @override
  ConsumerState<CodeSheet> createState() => _CodeSheetState();
}

class _CodeSheetState extends ConsumerState<CodeSheet> {
  final _redeem = TextEditingController();
  bool _redeeming = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void dispose() {
    _redeem.dispose();
    super.dispose();
  }

  Future<void> _share(ReferralCode code) async {
    await SharePlus.instance.share(
      ShareParams(
        text: 'Add me on FaFo. My code: ${code.code}\n${code.shareUrl}',
      ),
    );
  }

  Future<void> _copy(ReferralCode code) async {
    await Clipboard.setData(ClipboardData(text: code.code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code copied.')),
      );
    }
  }

  Future<void> _submitRedeem() async {
    final code = _redeem.text.trim();
    if (code.isEmpty || _redeeming) return;
    setState(() {
      _redeeming = true;
      _message = null;
    });
    try {
      final result = await ref.read(friendsRepositoryProvider).redeemReferralCode(code);
      // The sheet may have been closed while the request was in flight.
      if (!mounted) return;
      ref.invalidate(liveFriendsProvider);
      final name = result.friend.displayName;
      _redeem.clear();
      setState(() {
        _messageIsError = false;
        _message = result.alreadyFriends
            ? 'You and $name are already friends.'
            : 'You and $name are friends now.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messageIsError = true;
        _message = friendlyErrorMessage(e);
      });
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = ref.watch(_referralCodeProvider);
    return FafoSheetBody(
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 44),
          child: FafoSectionHeader(eyebrow: 'Referral code', title: 'Bring a friend.'),
        ),
        Text(
          'Friends who sign up with your code show up in your invites, and you show up in theirs.',
          style: AppTypography.ui(15, fontWeight: FontWeight.w400),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border, width: AppChrome.outlineWidth),
            boxShadow: AppChrome.cardShadow,
          ),
          child: Column(
            children: [
              FafoEyebrow('Your code', color: AppColors.textSecondary),
              const SizedBox(height: 6),
              code.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
                error: (e, _) => Text(
                  friendlyErrorMessage(e),
                  textAlign: TextAlign.center,
                  style: AppTypography.ui(13, color: AppColors.signalRed),
                ),
                data: (c) => SelectableText(
                  c.code,
                  style: AppTypography.timer(46).copyWith(letterSpacing: 46 * 0.04),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: FafoPill(
                label: 'Share code',
                onPressed: code.hasValue ? () => _share(code.value!) : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FafoPill(
                label: 'Copy',
                primary: false,
                onPressed: code.hasValue ? () => _copy(code.value!) : null,
              ),
            ),
          ],
        ),
        // Inferred (brief 3.8): somewhere to enter a friend's code.
        Container(
          padding: const EdgeInsets.only(top: 22),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.rule, width: 2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FafoEyebrow('Got a code?'),
              const SizedBox(height: 4),
              TextField(
                controller: _redeem,
                textCapitalization: TextCapitalization.characters,
                style: AppTypography.ui(17, fontWeight: FontWeight.w700),
                onSubmitted: (_) => _submitRedeem(),
                decoration: const InputDecoration(
                  hintText: 'MAYA-7K2',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 14),
              FafoPill(
                label: 'Add friend',
                small: true,
                height: 44,
                busy: _redeeming,
                onPressed: _submitRedeem,
              ),
              if (_message != null) ...[
                const SizedBox(height: 10),
                Text(
                  _message!,
                  style: AppTypography.ui(
                    13.5,
                    color: _messageIsError ? AppColors.signalRed : AppColors.textPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
