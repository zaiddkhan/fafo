import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fafu/src/core/constants/app_spacing.dart';
import 'package:fafu/src/core/network/auth_token_provider.dart';
import 'package:fafu/src/core/router/app_router.dart';
import 'package:fafu/src/core/theme/app_chrome.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/features/auth/data/auth_repository.dart';
import 'package:fafu/src/features/home/presentation/main_shell.dart';
import 'package:fafu/src/features/onboarding/presentation/profile_setup_page.dart';
import 'package:fafu/src/shared/widgets/app_button.dart';

class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.resendToken,
  });

  final String phoneNumber;
  final String verificationId;
  final int? resendToken;

  static const routeName = 'verify-otp';
  static const routePath = '/verify-otp';

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  static const _otpLength = 6;
  final _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final _focusNodes = List.generate(_otpLength, (_) => FocusNode());
  int _resendSeconds = 30;
  Timer? _timer;
  bool _verifying = false;
  String? _error;
  late String _verificationId = widget.verificationId;
  int? _resendToken;

  @override
  void initState() {
    super.initState();
    _resendToken = widget.resendToken;
    _startTimer();
  }

  void _startTimer() {
    _resendSeconds = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();
  bool get _isComplete => _otp.length == _otpLength;

  void _onChanged(int index, String value) {
    if (value.length == 1 && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() => _error = null);
  }

  void _onKeyDown(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _resendOtp() async {
    if (_resendSeconds > 0) return;
    setState(() => _error = null);
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .verifyPhoneNumber(
            phoneNumber: widget.phoneNumber,
            forceResendingToken: _resendToken,
          );
      if (!mounted) return;
      setState(() {
        _verificationId = result.verificationId;
        _resendToken = result.resendToken;
      });
      _startTimer();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _verify() async {
    if (!_isComplete || _verifying) return;
    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      final idToken = await repo.signInWithOtp(
        verificationId: _verificationId,
        smsCode: _otp,
      );
      ref.read(authTokenProvider.notifier).setToken(idToken);
      final session = await repo.createSession(idToken: idToken);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(onboardingCompleteKey, session.onboardingComplete);

      if (!mounted) return;
      if (session.onboardingComplete) {
        context.go(MainShell.routePath);
      } else {
        context.go(ProfileSetupPage.routePath);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),
              GestureDetector(
                onTap: () => context.pop(),
                child: Icon(Icons.arrow_back, color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Verify your\nnumber', style: theme.textTheme.displayLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'We sent a 6-digit code to ${widget.phoneNumber}.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_otpLength, (i) {
                  return SizedBox(
                    width: 48,
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) => _onKeyDown(i, event),
                      child: TextField(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: theme.textTheme.displayMedium,
                        onChanged: (v) => _onChanged(i, v),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          filled: true,
                          fillColor: _controllers[i].text.isNotEmpty
                              ? AppColors.bgTertiary
                              : AppColors.surface,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppChrome.controlRadius,
                            ),
                            borderSide: AppChrome.outlineSide.copyWith(
                              color: _controllers[i].text.isNotEmpty
                                  ? AppColors.accentPrimary
                                  : AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppChrome.controlRadius,
                            ),
                            borderSide: AppChrome.outlineSide,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: GestureDetector(
                  onTap: _resendSeconds == 0 ? _resendOtp : null,
                  child: Text(
                    _resendSeconds > 0
                        ? 'Resend code in ${_resendSeconds}s'
                        : 'Resend code',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: _resendSeconds > 0
                          ? AppColors.textTertiary
                          : AppColors.accentLight1,
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.red,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: _verifying ? 'Verifying...' : 'Verify',
                variant: AppButtonVariant.featured,
                onPressed: _isComplete && !_verifying ? _verify : null,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
