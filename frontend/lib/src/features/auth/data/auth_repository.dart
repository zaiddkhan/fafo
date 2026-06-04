import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fafu/src/core/network/api_exception.dart';
import 'package:fafu/src/core/network/dio_provider.dart';
import 'package:fafu/src/features/auth/domain/session.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider), FirebaseAuth.instance);
});

class PhoneVerificationResult {
  const PhoneVerificationResult({
    required this.verificationId,
    this.resendToken,
  });

  final String verificationId;
  final int? resendToken;
}

class AuthRepository {
  AuthRepository(this._dio, this._firebaseAuth);

  final Dio _dio;
  final FirebaseAuth _firebaseAuth;

  Future<PhoneVerificationResult> verifyPhoneNumber({
    required String phoneNumber,
    int? forceResendingToken,
  }) async {
    final completer = Completer<PhoneVerificationResult>();

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        forceResendingToken: forceResendingToken,
        verificationCompleted: (_) {},
        verificationFailed: (exception) {
          if (!completer.isCompleted) {
            completer.completeError(
              ApiException(
                type: ApiErrorType.unknown,
                message: exception.message ?? 'Phone verification failed',
              ),
            );
          }
        },
        codeSent: (verificationId, resendToken) {
          if (!completer.isCompleted) {
            completer.complete(
              PhoneVerificationResult(
                verificationId: verificationId,
                resendToken: resendToken,
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (_) {},
      );
      return completer.future;
    } on FirebaseAuthException catch (e) {
      throw ApiException(
        type: ApiErrorType.unknown,
        message: e.message ?? 'Phone verification failed',
      );
    }
  }

  Future<String> signInWithOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
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
      throw ApiException(
        type: ApiErrorType.unknown,
        message: e.message ?? 'Invalid OTP',
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
