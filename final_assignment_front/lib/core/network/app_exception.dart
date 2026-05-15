import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../utils/helpers/api_exception.dart';

enum AppErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  duplicate,
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
    this.originalError,
  });

  final AppErrorType type;
  final String message;
  final int? statusCode;
  final String? errorCode;
  final Object? originalError;

  @override
  String toString() => 'AppException(${type.name}): $message';

  factory AppException.fromError(Object error) {
    if (error is AppException) return error;
    if (error is ApiException) {
      return AppException.fromStatusCode(
        error.code,
        message: _extractMessage(error.message),
        originalError: error,
      );
    }
    if (error is TimeoutException) {
      return AppException(
        type: AppErrorType.timeout,
        message: '请求超时，请检查网络连接',
        originalError: error,
      );
    }
    if (error is http.ClientException || _isSocketException(error)) {
      return AppException(
        type: AppErrorType.network,
        message: '网络连接失败，请检查网络设置',
        originalError: error,
      );
    }
    return AppException(
      type: AppErrorType.unknown,
      message: error.toString(),
      originalError: error,
    );
  }

  factory AppException.fromResponse(http.Response response) {
    return AppException.fromStatusCode(
      response.statusCode,
      message: _extractResponseMessage(response),
      originalError: response,
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
        message: '登录已过期，请重新登录',
        statusCode: statusCode,
        originalError: originalError,
      );
    }
    if (statusCode == 403) {
      return AppException(
        type: AppErrorType.forbidden,
        message: fallback?.isNotEmpty == true ? fallback! : '您没有权限执行此操作',
        statusCode: statusCode,
        originalError: originalError,
      );
    }
    if (statusCode == 404) {
      return AppException(
        type: AppErrorType.notFound,
        message: fallback?.isNotEmpty == true ? fallback! : '请求的资源不存在',
        statusCode: statusCode,
        originalError: originalError,
      );
    }
    if (statusCode == 409) {
      return AppException(
        type: AppErrorType.conflict,
        message: fallback?.isNotEmpty == true ? fallback! : 'Request conflict',
        statusCode: statusCode,
        originalError: originalError,
      );
    }
    if (statusCode >= 500) {
      return AppException(
        type: AppErrorType.serverError,
        message: '服务器错误，请稍后重试',
        statusCode: statusCode,
        originalError: originalError,
      );
    }
    if (statusCode >= 400) {
      return AppException(
        type: AppErrorType.businessError,
        message: fallback?.isNotEmpty == true ? fallback! : '请求处理失败',
        statusCode: statusCode,
        originalError: originalError,
      );
    }
    return AppException(
      type: AppErrorType.unknown,
      message: fallback?.isNotEmpty == true ? fallback! : '未知错误',
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
}
