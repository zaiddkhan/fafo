import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/features/auth/data/auth_repository.dart';
import 'package:fafu/src/features/auth/presentation/login_page.dart';
import 'package:fafu/src/features/auth/presentation/otp_page.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  static const routeName = 'signup';
  static const routePath = '/signup';

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _phoneController = TextEditingController();
  bool _sendingOtp = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _phoneNumber =>
      '+91${_phoneController.text.replaceAll(RegExp(r'\D'), '')}';

  bool get _canContinue =>
      _phoneController.text.replaceAll(RegExp(r'\D'), '').length == 10;

  Future<void> _sendOtp() async {
    if (!_canContinue || _sendingOtp) return;
    setState(() {
      _sendingOtp = true;
    });

    final pendingVerification = ref
        .read(authRepositoryProvider)
        .verifyPhoneNumber(phoneNumber: _phoneNumber);

    if (!mounted) return;
    setState(() => _sendingOtp = false);
    context.push(
      OtpPage.routePath,
      extra: {
        'phoneNumber': _phoneNumber,
        'pendingVerification': pendingVerification,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FafoFormPage(
      eyebrow: 'Sign up',
      title: 'Let’s get you in.',
      subtitle: 'Your number is your login. No passwords, ever.',
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FafoPill(
            label: _sendingOtp ? 'Sending code…' : 'Continue',
            block: true,
            busy: _sendingOtp,
            onPressed: _canContinue && !_sendingOtp ? _sendOtp : null,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: AppTypography.ui(14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
              ),
              FafoInlineLink(
                label: 'Log in',
                onTap: () => context.pushReplacement(LoginPage.routePath),
              ),
            ],
          ),
        ],
      ),
      children: [
        const FafoFieldLabel('Phone number'),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          autofocus: true,
          style: AppTypography.ui(17, fontWeight: FontWeight.w700),
          onSubmitted: (_) => _sendOtp(),
          decoration: InputDecoration(
            hintText: '98765 43210',
            // Always visible, unlike prefixText (which hides until focus).
            prefixIcon: Text('+91  ', style: AppTypography.ui(17, fontWeight: FontWeight.w700)),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'We’ll text you a 6-digit code.',
          style: AppTypography.ui(13, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
