import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/network/dio_provider.dart';
import 'package:fafu/src/features/auth/domain/session.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider), FirebaseAuth.instance);
});

/// Converts any error thrown by the auth flow into a clean, user-facing string.
/// Never exposes raw exception details (e.g. `ApiException(...)`) to the UI.
String friendlyAuthError(Object error) {
  if (error is ApiException) {
    // In debug builds, append the raw Firebase error code so resend/verify
    // failures can be diagnosed on-device. Release builds stay clean.
    if (kDebugMode && error.code != null) {
      return '${error.friendlyMessage} [${error.code}]';
    }
    return error.friendlyMessage;
  }
  return 'Something went wrong. Please try again.';
}

class PhoneVerificationResult {
  const PhoneVerificationResult({
    required this.verificationId,
    this.resendToken,
    this.autoCredential,
  });

  final String verificationId;
  final int? resendToken;

  /// Set only when Firebase auto-verified the device (instant verification).
  /// When present, the caller should sign in directly with this credential
  /// instead of waiting for the user to type an SMS code.
  final PhoneAuthCredential? autoCredential;
}

class AuthRepository {
  AuthRepository(this._dio, this._firebaseAuth);

  final Dio _dio;
  final FirebaseAuth _firebaseAuth;

  /// Holds the in-flight web sign-in. On web, OTP confirmation goes through
  /// [ConfirmationResult.confirm] rather than rebuilding a credential.
  ConfirmationResult? _webConfirmationResult;

  Future<PhoneVerificationResult> verifyPhoneNumber({
    required String phoneNumber,
    int? forceResendingToken,
  }) async {
    // Web phone auth requires a reCAPTCHA app verifier (this is mandatory and
    // cannot be disabled). signInWithPhoneNumber renders an *invisible*
    // reCAPTCHA — no widget is shown to the user unless the request looks
    // suspicious — and manages its lifecycle. verifyPhoneNumber on web is the
    // unreliable path (single-use token that often expires before use), so we
    // only use it on mobile, where verification is silent (Play Integrity /
    // APNs) and reCAPTCHA is not involved.
    if (kIsWeb) {
      return _verifyPhoneNumberWeb(phoneNumber);
    }

    final completer = Completer<PhoneVerificationResult>();

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        forceResendingToken: forceResendingToken,
        verificationCompleted: (credential) {
          // Instant / auto verification: Firebase validated the device without
          // an SMS round-trip. Surface the credential so the caller can sign in
          // directly instead of hanging forever waiting for `codeSent`.
          debugPrint('[auth] verifyPhoneNumber: auto-verification completed');
          if (!completer.isCompleted) {
            completer.complete(
              PhoneVerificationResult(
                verificationId: credential.verificationId ?? '',
                autoCredential: credential,
              ),
            );
          }
        },
        verificationFailed: (exception) {
          debugPrint(
            '[auth] verifyPhoneNumber failed: '
            'code=${exception.code} message=${exception.message}',
          );
          if (!completer.isCompleted) {
            completer.completeError(
              ApiException(
                type: ApiErrorType.unknown,
                message: exception.message ?? 'Phone verification failed',
                code: exception.code,
              ),
            );
          }
        },
        codeSent: (verificationId, resendToken) {
          debugPrint('[auth] verifyPhoneNumber: codeSent');
          if (!completer.isCompleted) {
            completer.complete(
              PhoneVerificationResult(
                verificationId: verificationId,
                resendToken: resendToken,
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (verificationId) {
          debugPrint('[auth] verifyPhoneNumber: codeAutoRetrievalTimeout');
        },
      );
      // Guard against callbacks that never fire (e.g. instant verification that
      // silently drops, or a stalled native request) so the UI can't hang.
      return completer.future.timeout(
        const Duration(seconds: 90),
        onTimeout: () => throw ApiException(
          type: ApiErrorType.unknown,
          message: 'Verification timed out. Please try again.',
          code: 'timeout',
        ),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '[auth] verifyPhoneNumber threw: code=${e.code} message=${e.message}',
      );
      throw ApiException(
        type: ApiErrorType.unknown,
        message: e.message ?? 'Phone verification failed',
        code: e.code,
      );
    }
  }

  Future<PhoneVerificationResult> _verifyPhoneNumberWeb(
    String phoneNumber,
  ) async {
    try {
      final confirmationResult = await _firebaseAuth.signInWithPhoneNumber(
        phoneNumber,
      );
      _webConfirmationResult = confirmationResult;
      return PhoneVerificationResult(
        verificationId: confirmationResult.verificationId,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '[auth] _verifyPhoneNumberWeb failed: code=${e.code} message=${e.message}',
      );
      throw ApiException(
        type: ApiErrorType.unknown,
        message: e.message ?? 'Phone verification failed',
        code: e.code,
      );
    }
  }

  Future<String> signInWithOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final UserCredential userCredential;
      final webResult = _webConfirmationResult;
      if (kIsWeb && webResult != null) {
        // On web the SMS code is confirmed against the in-flight
        // ConfirmationResult, which already carries the verified reCAPTCHA.
        userCredential = await webResult.confirm(smsCode);
      } else {
        final credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode,
        );
        userCredential = await _firebaseAuth.signInWithCredential(credential);
      }
      final token = await userCredential.user?.getIdToken();
      if (token == null) {
        throw ApiException(
          type: ApiErrorType.unknown,
          message: 'Could not create session',
        );
      }
      return token;
    } on FirebaseAuthException catch (e) {
      debugPrint('[auth] signInWithOtp failed: code=${e.code} message=${e.message}');
      throw ApiException(
        type: ApiErrorType.unknown,
        message: e.message ?? 'Invalid OTP',
        code: e.code,
      );
    }
  }

  /// Signs in with a credential produced by Firebase auto-verification
  /// (instant verification) and returns the Firebase ID token.
  Future<String> signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final token = await userCredential.user?.getIdToken();
      if (token == null) {
        throw ApiException(
          type: ApiErrorType.unknown,
          message: 'Could not create session',
        );
      }
      return token;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '[auth] signInWithCredential failed: code=${e.code} message=${e.message}',
      );
      throw ApiException(
        type: ApiErrorType.unknown,
        message: e.message ?? 'Sign-in failed',
        code: e.code,
      );
    }
  }

  Future<SessionResponse> createSession({required String idToken}) async {
    try {
      final response = await _dio.post(
        '/auth/session',
        data: SessionRequest(idToken: idToken).toJson(),
      );
      return SessionResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
