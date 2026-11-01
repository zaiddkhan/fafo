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

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _phoneNumber =>
      '+91${_phoneController.text.replaceAll(RegExp(r'\D'), '')}';

  String get _digits => _phoneController.text.replaceAll(RegExp(r'\D'), '');

  /// Indian mobile numbers are 10 digits starting 6 to 9.
  bool get _canContinue => RegExp(r'^[6-9]\d{9}$').hasMatch(_digits);

  String? get _phoneError =>
      _digits.length == 10 && !_canContinue ? 'Indian mobile numbers start with 6, 7, 8 or 9.' : null;

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
      title: 'What’s your number?',
      subtitle: 'We’ll text you a code to log you back in.',
      footer: FafoPill(
        label: 'Send code',
        block: true,
        busy: _sendingOtp,
        onPressed: _canContinue && !_sendingOtp ? _sendOtp : null,
      ),
      children: [
        FafoInput(
          controller: _phoneController,
          prefix: '+91',
          hint: '98450 12873',
          keyboardType: TextInputType.phone,
          autofocus: true,
          error: _phoneError,
          // Rebuild so the button lights up at 10 digits.
          onChanged: (_) => setState(() {}),
        ),
        if (_phoneError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_phoneError!, style: AppTypography.ui(13, fontWeight: FontWeight.w500, color: AppColors.errorText)),
          ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text(
              'New to FaFo? ',
              style: AppTypography.ui(14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
            ),
            FafoInlineLink(label: 'Get started', onTap: () => context.pushReplacement(SignupPage.routePath)),
          ],
        ),
      ],
    );
  }
}
