import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../utils/helpers/api_exception.dart';
import 'app_exception.dart';

class ExceptionMapper {
  const ExceptionMapper._();

  static AppException map(Object error) {
    if (error is AppException) {
      return error;
    }

    if (error is ApiException) {
      return AppException(
        _friendlyMessage(error.code, _extractMessage(error.message)),
        statusCode: error.code,
        cause: error,
      );
    }

    if (_isNetworkError(error)) {
      return AppException(
        '网络连接失败，请检查后端服务或网关地址',
        cause: error,
      );
    }

    if (error is TimeoutException) {
      return AppException('请求超时，请稍后重试', cause: error);
    }

    if (error is FormatException) {
      return AppException('响应数据格式错误', cause: error);
    }

    return AppException('未知错误：$error', cause: error);
  }

  static bool _isNetworkError(Object error) {
    final type = error.runtimeType.toString();
    return error is http.ClientException ||
        error is WebSocketChannelException ||
        type == 'SocketException' ||
        type == 'HandshakeException' ||
        type == 'HttpException';
  }

  static String _friendlyMessage(int? statusCode, String fallback) {
    switch (statusCode) {
      case 400:
        return fallback.isEmpty ? '请求参数有误' : fallback;
      case 401:
        return '登录已过期，请重新登录';
      case 403:
        return '当前账号没有权限执行此操作';
      case 404:
        return fallback.isEmpty ? '请求的资源不存在' : fallback;
      case 409:
        return fallback.isEmpty ? '数据冲突，请刷新后重试' : fallback;
      case 500:
      case 502:
      case 503:
      case 504:
        return fallback.isEmpty ? '服务暂时不可用，请稍后重试' : fallback;
      default:
        return fallback.isEmpty ? '请求失败' : fallback;
    }
  }

  static String _extractMessage(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return '';
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded['message']?.toString() ??
            decoded['error']?.toString() ??
            raw;
      }
      return decoded.toString();
    } catch (_) {
      return raw;
    }
  }
}
