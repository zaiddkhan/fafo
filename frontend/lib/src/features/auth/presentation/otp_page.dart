import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show PhoneAuthCredential;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fafu/src/core/network/auth_token_provider.dart';
import 'package:fafu/src/core/network/session_expired_provider.dart';
import 'package:fafu/src/core/router/app_router.dart';
import 'package:fafu/src/core/services/deep_link_service.dart';
import 'package:fafu/src/core/theme/app_chrome.dart';
import 'package:fafu/src/core/theme/app_colors.dart';
import 'package:fafu/src/core/theme/app_typography.dart';
import 'package:fafu/src/features/auth/data/auth_repository.dart';
import 'package:fafu/src/features/auth/data/session_reset.dart';
import 'package:fafu/src/features/home/presentation/main_shell.dart';
import 'package:fafu/src/features/onboarding/presentation/profile_setup_page.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_ui.dart';
import 'package:fafu/src/shared/widgets/fafo/fafo_toast.dart';

class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({
    super.key,
    required this.phoneNumber,
    this.verificationId = '',
    this.resendToken,
    this.pendingVerification,
  });

  final String phoneNumber;
  final String verificationId;
  final int? resendToken;
  final Future<PhoneVerificationResult>? pendingVerification;

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
  bool _waitingForCode = false;
  late String _verificationId = widget.verificationId;
  int? _resendToken;

  @override
  void initState() {
    super.initState();
    _resendToken = widget.resendToken;
    _waitingForCode =
        widget.pendingVerification != null && _verificationId.isEmpty;
    _startTimer();
    _attachPendingVerification();
  }

  Future<void> _attachPendingVerification() async {
    final pending = widget.pendingVerification;
    if (pending == null) return;

    try {
      final result = await pending;
      if (!mounted) return;
      // Firebase auto-verified the device — sign in directly, no SMS needed.
      if (result.autoCredential != null) {
        await _completeWithCredential(result.autoCredential!);
        return;
      }
      setState(() {
        _verificationId = result.verificationId;
        _resendToken = result.resendToken;
        _waitingForCode = false;
      });
      _focusNodes.first.requestFocus();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _waitingForCode = false;
      });
      FafoToasts.show(friendlyAuthError(e), kind: FafoToastKind.error);
    }
  }

  void _clearOtpFields() {
    for (final c in _controllers) {
      c.clear();
    }
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

  /// Inline error under the boxes (red borders too) after a failed verify.
  String? _codeError;

  void _onChanged(int index, String value) {
    _codeError = null;
    if (value.length == 1 && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    // Rebuild so Verify lights up once all six digits are in.
    setState(() {});
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
    if (_resendSeconds > 0 || _waitingForCode) return;
    setState(() {
      _waitingForCode = true;
    });
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .verifyPhoneNumber(
            phoneNumber: widget.phoneNumber,
            forceResendingToken: _resendToken,
          );
      if (!mounted) return;
      // Auto-verified during resend — sign in directly.
      if (result.autoCredential != null) {
        await _completeWithCredential(result.autoCredential!);
        return;
      }
      // A new code was sent — the old one is now invalid, so drop any digits
      // the user already typed to avoid verifying a stale code.
      _clearOtpFields();
      setState(() {
        _verificationId = result.verificationId;
        _resendToken = result.resendToken;
        _waitingForCode = false;
      });
      _startTimer();
      ScaffoldMessenger.of(context).toast('Code sent.');
    } catch (e) {
      if (mounted) {
        setState(() {
          _waitingForCode = false;
        });
        FafoToasts.show(friendlyAuthError(e), kind: FafoToastKind.error);
      }
    }
  }

  Future<void> _verify() async {
    if (!_isComplete ||
        _verifying ||
        _waitingForCode ||
        _verificationId.isEmpty) {
      return;
    }
    setState(() {
      _verifying = true;
    });

    try {
      final idToken = await ref
          .read(authRepositoryProvider)
          .signInWithOtp(verificationId: _verificationId, smsCode: _otp);
      await _completeSession(idToken);
    } catch (e) {
      // A wrong code is shown under the boxes, not as a toast.
      if (mounted) setState(() => _codeError = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  /// Handles Firebase instant/auto verification: signs in with the returned
  /// credential and completes the session without an SMS code.
  Future<void> _completeWithCredential(PhoneAuthCredential credential) async {
    setState(() {
      _waitingForCode = false;
      _verifying = true;
    });
    try {
      final idToken = await ref
          .read(authRepositoryProvider)
          .signInWithCredential(credential);
      await _completeSession(idToken);
    } catch (e) {
      if (mounted) FafoToasts.show(friendlyAuthError(e), kind: FafoToastKind.error);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  /// Exchanges a Firebase ID token for a backend session and navigates onward.
  Future<void> _completeSession(String idToken) async {
    final repo = ref.read(authRepositoryProvider);
    ref.read(authTokenProvider.notifier).setToken(idToken);
    // Clear any prior "session expired" state so the router stops forcing us
    // back to sign-in once this new session is live.
    ref.read(sessionExpiredProvider.notifier).reset();
    final session = await repo.createSession(idToken: idToken);

    // Drop any cached data from a previously signed-in account so the profile
    // and other user-scoped screens load fresh for this account.
    resetUserScopedData(ref);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingCompleteKey, session.onboardingComplete);

    if (!mounted) return;
    if (session.onboardingComplete) {
      final pendingPath = await consumePendingDeepLinkPath();
      if (!mounted) return;
      context.go(pendingPath ?? MainShell.routePath);
    } else {
      context.go(ProfileSetupPage.routePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final otpBoxWidth =
        ((MediaQuery.sizeOf(context).width - 40 - (8 * (_otpLength - 1))) / _otpLength)
            .clamp(38.0, 52.0);
    final resendLabel = _waitingForCode
        ? 'Sending code…'
        : _resendSeconds > 0
        ? 'Resend in 0:${_resendSeconds.toString().padLeft(2, '0')}'
        : 'Resend code';

    return FafoFormPage(
      title: 'Enter the code',
      step: 2,
      subtitle: _waitingForCode
          ? 'Sending it to ${_pretty(widget.phoneNumber)}…'
          : 'Sent to ${_pretty(widget.phoneNumber)}.',
      footer: FafoPill(
        label: _waitingForCode
            ? 'Waiting for the code…'
            : _verifying
            ? 'Verifying…'
            : 'Verify',
        block: true,
        busy: _verifying,
        onPressed: _isComplete && !_verifying && !_waitingForCode ? _verify : null,
      ),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_otpLength, (i) {
            return SizedBox(
              width: otpBoxWidth,
              child: KeyboardListener(
                focusNode: FocusNode(skipTraversal: true),
                onKeyEvent: (event) => _onKeyDown(i, event),
                // Card boxes; blue edge on the one being typed into.
                child: ListenableBuilder(
                  listenable: _focusNodes[i],
                  builder: (context, child) => Container(
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _codeError != null
                            ? AppColors.signalRed
                            : _focusNodes[i].hasFocus
                            ? AppColors.accentPrimary
                            : AppColors.softLine,
                        width: AppChrome.softOutlineWidth,
                      ),
                    ),
                    child: child,
                  ),
                  child: TextField(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    cursorColor: AppColors.textPrimary,
                    style: AppTypography.ui(22, fontWeight: FontWeight.w700).copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    onChanged: (v) => _onChanged(i, v),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isCollapsed: true,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        if (_codeError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_codeError!, style: AppTypography.ui(13, fontWeight: FontWeight.w500, color: AppColors.errorText)),
          ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FafoTextButton(label: 'Change number', onTap: () => Navigator.of(context).maybePop()),
            FafoTextButton(
              label: resendLabel,
              color: _resendSeconds == 0 && !_waitingForCode ? AppColors.textPrimary : AppColors.textSecondary,
              onTap: _resendSeconds == 0 && !_waitingForCode ? _resendOtp : null,
            ),
          ],
        ),
      ],
    );
  }
}

/// "+91 98450 12873".
String _pretty(String phone) {
  final m = RegExp(r'^\+91(\d{5})(\d{5})$').firstMatch(phone);
  return m == null ? phone : '+91 ${m.group(1)} ${m.group(2)}';
}
