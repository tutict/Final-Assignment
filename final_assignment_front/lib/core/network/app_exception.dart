import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'field_validation_error.dart';

enum AppErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  duplicate,
  validationError,
  serverError,
  businessError,
  unknown,
}

class AppException implements Exception {
  const AppException({
    required this.type,
    required this.message,
    this.statusCode,
    this.errorCode,
    this.fieldErrors,
    this.originalError,
  });

  final AppErrorType type;
  final String message;
  final int? statusCode;
  final String? errorCode;
  final List<FieldValidationError>? fieldErrors;
  final Object? originalError;

  int get code => statusCode ?? 0;

  @override
  String toString() => 'AppException(${type.name}): $message';

  factory AppException.fromError(Object error, {String? fallbackMessage}) {
    if (error is AppException) return error;
    if (error is TimeoutException) {
      return AppException(
        type: AppErrorType.timeout,
        message: 'Request timed out. Please check your network connection.',
        originalError: error,
      );
    }
    if (error is http.ClientException || _isSocketException(error)) {
      return AppException(
        type: AppErrorType.network,
        message: 'Network request failed. Please check your connection.',
        originalError: error,
      );
    }
    return AppException(
      type: AppErrorType.unknown,
      message: fallbackMessage?.trim().isNotEmpty == true
          ? fallbackMessage!.trim()
          : error.toString(),
      originalError: error,
    );
  }

  factory AppException.fromResponse(http.Response response) {
    final parsed = _extractApiResponseError(response);
    if (parsed != null) {
      return AppException(
        type: _mapErrorCode(parsed.errorCode, response.statusCode),
        message: parsed.message,
        statusCode: response.statusCode,
        errorCode: parsed.errorCode,
        fieldErrors: parsed.fieldErrors,
        originalError: response,
      );
    }
    return AppException.fromStatusCode(
      response.statusCode,
      message: _extractResponseMessage(response),
      originalError: response,
    );
  }

  factory AppException.http(
    int statusCode,
    String message, {
    Object? originalError,
  }) {
    return AppException.fromStatusCode(
      statusCode,
      message: message,
      originalError: originalError,
    );
  }

  factory AppException.withInner(
    int statusCode,
    String message,
    Exception? innerException,
    StackTrace? stackTrace,
  ) {
    return AppException.fromStatusCode(
      statusCode,
      message: message,
      originalError: innerException ?? stackTrace,
    );
  }

  factory AppException.fromStatusCode(
    int statusCode, {
    String? message,
    Object? originalError,
  }) {
    final fallback = message?.trim();
    if (statusCode == 401) {
      return AppException(
        type: AppErrorType.unauthorized,
        message: fallback?.isNotEmpty == true ? fallback! : 'Login expired.',
        statusCode: statusCode,
        originalError: originalError,
      );
    }
    if (statusCode == 403) {
      return AppException(
        type: AppErrorType.forbidden,
        message: fallback?.isNotEmpty == true ? fallback! : 'Forbidden.',
        statusCode: statusCode,
        originalError: originalError,
      );
    }
    if (statusCode == 404) {
      return AppException(
        type: AppErrorType.notFound,
        message: fallback?.isNotEmpty == true ? fallback! : 'Resource not found.',
        statusCode: statusCode,
        originalError: originalError,
      );
    }
    if (statusCode == 409) {
      return AppException(
        type: AppErrorType.conflict,
        message: fallback?.isNotEmpty == true ? fallback! : 'Request conflict.',
        statusCode: statusCode,
        originalError: originalError,
      );
    }
    if (statusCode >= 500) {
      return AppException(
        type: AppErrorType.serverError,
        message: fallback?.isNotEmpty == true ? fallback! : 'Server error.',
        statusCode: statusCode,
        originalError: originalError,
      );
    }
    if (statusCode >= 400) {
      return AppException(
        type: AppErrorType.businessError,
        message: fallback?.isNotEmpty == true ? fallback! : 'Request failed.',
        statusCode: statusCode,
        originalError: originalError,
      );
    }
    return AppException(
      type: AppErrorType.unknown,
      message: fallback?.isNotEmpty == true ? fallback! : 'Unknown error.',
      statusCode: statusCode,
      originalError: originalError,
    );
  }

  static bool isErrorStatus(int statusCode) => statusCode >= 400;

  static bool _isSocketException(Object error) {
    final type = error.runtimeType.toString();
    return type == 'SocketException' ||
        type == 'HandshakeException' ||
        type == 'HttpException';
  }

  static String _extractResponseMessage(http.Response response) {
    final body = utf8.decode(response.bodyBytes, allowMalformed: true).trim();
    if (body.isEmpty) return '';
    return _extractMessage(body);
  }

  static String _extractMessage(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) {
        for (final key in const [
          'message',
          'error',
          'detail',
          'title',
          'error_description',
        ]) {
          final value = decoded[key];
          if (value != null && value.toString().trim().isNotEmpty) {
            return value.toString();
          }
        }
        final errors = decoded['errors'];
        if (errors != null) {
          return errors is String ? errors : jsonEncode(errors);
        }
      }
      if (decoded is List) return jsonEncode(decoded);
      return decoded.toString();
    } catch (_) {
      return trimmed;
    }
  }

  static _ApiResponseError? _extractApiResponseError(http.Response response) {
    final body = utf8.decode(response.bodyBytes, allowMalformed: true).trim();
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return null;
      if (decoded['success'] != false && decoded['errorCode'] == null) {
        return null;
      }
      final errorCode = decoded['errorCode']?.toString() ?? 'UNKNOWN';
      final message = decoded['message']?.toString().trim();
      return _ApiResponseError(
        errorCode: errorCode,
        message: message?.isNotEmpty == true ? message! : 'Request failed.',
        fieldErrors: _extractFieldErrors(decoded['data']),
      );
    } catch (_) {
      return null;
    }
  }

  static List<FieldValidationError>? _extractFieldErrors(dynamic data) {
    if (data is! List) return null;
    return data
        .whereType<Map>()
        .map((item) => FieldValidationError.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .where((item) => item.field.isNotEmpty || item.message.isNotEmpty)
        .toList();
  }

  static AppErrorType _mapErrorCode(String code, int statusCode) {
    return switch (code) {
      'UNAUTHORIZED' => AppErrorType.unauthorized,
      'FORBIDDEN' => AppErrorType.forbidden,
      'NOT_FOUND' => AppErrorType.notFound,
      'CONFLICT' => AppErrorType.conflict,
      'DUPLICATE_REQUEST' => AppErrorType.duplicate,
      'VALIDATION_ERROR' => AppErrorType.validationError,
      _ => _typeFromStatusCode(statusCode),
    };
  }

  static AppErrorType _typeFromStatusCode(int statusCode) {
    if (statusCode == 401) return AppErrorType.unauthorized;
    if (statusCode == 403) return AppErrorType.forbidden;
    if (statusCode == 404) return AppErrorType.notFound;
    if (statusCode == 409) return AppErrorType.conflict;
    if (statusCode >= 500) return AppErrorType.serverError;
    if (statusCode >= 400) return AppErrorType.businessError;
    return AppErrorType.unknown;
  }
}

class _ApiResponseError {
  const _ApiResponseError({
    required this.errorCode,
    required this.message,
    required this.fieldErrors,
  });

  final String errorCode;
  final String message;
  final List<FieldValidationError>? fieldErrors;
}
