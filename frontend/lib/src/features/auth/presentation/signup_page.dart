import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fafu/src/core/constants/app_spacing.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/auth/data/auth_repository.dart';
import 'package:fafu/src/features/auth/presentation/login_page.dart';
import 'package:fafu/src/features/auth/presentation/otp_page.dart';
import 'package:fafu/src/shared/widgets/app_button.dart';

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

    try {
      final result = await ref
          .read(authRepositoryProvider)
          .verifyPhoneNumber(phoneNumber: _phoneNumber);
      if (!mounted) return;
      context.push(
        OtpPage.routePath,
        extra: {
          'phoneNumber': _phoneNumber,
          'verificationId': result.verificationId,
          'resendToken': result.resendToken,
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg + viewInsets.bottom,
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Icon(
                          Icons.arrow_back,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Create your\naccount',
                        style: theme.textTheme.displayLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Enter your phone number to get started.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: theme.textTheme.bodyLarge,
                        onChanged: (_) => setState(() => _error = null),
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          prefixText: '+91  ',
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _error!,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        label: _sendingOtp ? 'Sending OTP...' : 'Continue',
                        variant: AppButtonVariant.featured,
                        onPressed: _canContinue && !_sendingOtp
                            ? _sendOtp
                            : null,
                      ),
                      const Spacer(),
                      Center(
                        child: GestureDetector(
                          onTap: () =>
                              context.pushReplacement(LoginPage.routePath),
                          child: Text.rich(
                            TextSpan(
                              text: 'Already have an account? ',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Log in',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: AppColors.accentLight1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
