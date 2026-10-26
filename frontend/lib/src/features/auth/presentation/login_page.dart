import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/features/auth/data/auth_repository.dart';
import 'package:fafu/src/features/auth/presentation/otp_page.dart';
import 'package:fafu/src/features/auth/presentation/signup_page.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  static const routeName = 'login';
  static const routePath = '/login';

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  bool _sendingOtp = false;
  String? _error;

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
      _error = null;
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
      eyebrow: 'Log in',
      title: 'Welcome back.',
      subtitle: 'Enter your phone number to log in.',
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
                "Don't have an account? ",
                style: AppTypography.ui(14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
              ),
              FafoInlineLink(
                label: 'Sign up',
                onTap: () => context.pushReplacement(SignupPage.routePath),
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
          onChanged: (_) => setState(() => _error = null),
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
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: AppTypography.ui(13.5, color: AppColors.signalRed)),
        ],
      ],
    );
  }
}
