import 'package:dio/dio.dart';

enum ApiErrorType {
  network,
  unauthorized,
  forbidden,
  notFound,
  validation,
  conflict,
  server,
  unknown,
}

class ApiException implements Exception {
  ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.errors,
    this.code,
  });

  factory ApiException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return ApiException(
          type: ApiErrorType.network,
          message: 'Unable to connect to server',
        );
      case DioExceptionType.badResponse:
        return _fromResponse(error.response);
      case DioExceptionType.cancel:
        return ApiException(
          type: ApiErrorType.unknown,
          message: 'Request cancelled',
        );
      default:
        return ApiException(
          type: ApiErrorType.unknown,
          message: error.message ?? 'Something went wrong',
        );
    }
  }

  static ApiException _fromResponse(Response? response) {
    final statusCode = response?.statusCode ?? 0;
    final data = response?.data;
    final detail = data is Map ? (data['detail'] as String?) : null;

    return switch (statusCode) {
      401 => ApiException(
          type: ApiErrorType.unauthorized,
          message: detail ?? 'Session expired',
          statusCode: statusCode,
        ),
      403 => ApiException(
          type: ApiErrorType.forbidden,
          message: detail ?? 'Access denied',
          statusCode: statusCode,
        ),
      404 => ApiException(
          type: ApiErrorType.notFound,
          message: detail ?? 'Not found',
          statusCode: statusCode,
        ),
      409 => ApiException(
          type: ApiErrorType.conflict,
          message: detail ?? 'Conflict',
          statusCode: statusCode,
        ),
      422 => ApiException(
          type: ApiErrorType.validation,
          message: detail ?? 'Invalid input',
          statusCode: statusCode,
          errors: _extractValidationErrors(data),
        ),
      >= 500 => ApiException(
          type: ApiErrorType.server,
          message: detail ?? 'Server error',
          statusCode: statusCode,
        ),
      _ => ApiException(
          type: ApiErrorType.unknown,
          message: detail ?? 'Request failed',
          statusCode: statusCode,
        ),
    };
  }

  static Map<String, String>? _extractValidationErrors(dynamic data) {
    if (data is! Map) return null;
    final detail = data['detail'];
    if (detail is! List) return null;

    final errors = <String, String>{};
    for (final item in detail) {
      if (item is Map) {
        final loc = item['loc'] as List?;
        final msg = item['msg'] as String?;
        if (loc != null && msg != null) {
          final field = loc.length > 1 ? loc.last.toString() : 'unknown';
          errors[field] = msg;
        }
      }
    }
    return errors.isEmpty ? null : errors;
  }

  final ApiErrorType type;
  final String message;
  final int? statusCode;
  final Map<String, String>? errors;

  /// Underlying provider error code (e.g. a Firebase Auth code such as
  /// `invalid-verification-code`). Used to derive a clean [friendlyMessage].
  final String? code;

  /// A clean, user-facing version of the error suitable for display in the UI.
  ///
  /// Maps known Firebase Auth error codes (and common raw error text) to
  /// friendly strings so the raw exception details are never shown to the user.
  /// Falls back to [message] for already-clean backend messages.
  String get friendlyMessage {
    switch (code?.toLowerCase()) {
      case 'invalid-verification-code':
      case 'invalid-code':
        return 'Incorrect code. Please check and try again.';
      case 'session-expired':
      case 'code-expired':
      case 'expired-action-code':
        return 'This code has expired. Please request a new one.';
      case 'too-many-requests':
      case 'quota-exceeded':
        return 'Too many attempts. Please try again later.';
      case 'invalid-phone-number':
      case 'missing-phone-number':
        return 'Please enter a valid phone number.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
    }

    // Some paths (e.g. web sign-in) carry no code, so match on the raw text.
    final lower = message.toLowerCase();
    if (lower.contains('verification code') || lower.contains('invalid otp')) {
      return 'Incorrect code. Please check and try again.';
    }
    if (lower.contains('blocked all requests') ||
        lower.contains('unusual activity') ||
        lower.contains('too many')) {
      return 'Too many attempts. Please try again later.';
    }
    if (lower.contains('expired')) {
      return 'This code has expired. Please request a new one.';
    }

    return message;
  }

  @override
  String toString() => 'ApiException($type): $message';
}
