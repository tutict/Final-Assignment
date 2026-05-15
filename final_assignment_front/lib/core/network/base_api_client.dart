import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../utils/services/auth_token_store.dart';
import 'app_exception.dart';
import 'api_client.dart';

class PageResult<T> {
  const PageResult({
    required this.content,
    required this.total,
    required this.page,
    required this.size,
  });

  final List<T> content;
  final int total;
  final int page;
  final int size;
}

abstract mixin class BaseApiClient {
  static const String defaultContentType = 'application/json; charset=utf-8';
  static const Set<int> defaultSuccessStatusCodes = {
    200,
    201,
    202,
    204,
  };

  static const _uuid = Uuid();

  ApiClient get apiClient;

  Future<void> initializeClientWithJwt() async {
    final jwtToken = await AuthTokenStore.instance.getJwtToken();
    if (jwtToken == null || jwtToken.isEmpty) {
      throw const AppException(
        type: AppErrorType.unauthorized,
        message: '登录已过期，请重新登录',
        statusCode: 401,
      );
    }
    apiClient.setJwtToken(jwtToken);
    if (kDebugMode) {
      AppLogger.debug('Initialized $runtimeType with token');
    }
  }

  Future<Map<String, String>> getHeaders({
    String? contentType = defaultContentType,
    String? idempotencyKey,
    bool generateIdempotencyKey = false,
  }) async {
    final token = await AuthTokenStore.instance.getJwtToken();
    if (token != null && token.isNotEmpty) {
      apiClient.setJwtToken(token);
    }

    final headers = <String, String>{
      if (contentType != null && contentType.isNotEmpty)
        'Content-Type': contentType,
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final resolvedKey = resolveIdempotencyKey(
      idempotencyKey,
      generateIfMissing: generateIdempotencyKey,
    );
    if (resolvedKey != null) {
      headers['Idempotency-Key'] = resolvedKey;
    }

    return headers;
  }

  String generateIdempotencyKey() => _uuid.v4();

  String? resolveIdempotencyKey(
    String? idempotencyKey, {
    bool generateIfMissing = true,
  }) {
    final trimmed = idempotencyKey?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    return generateIfMissing ? generateIdempotencyKey() : null;
  }

  List<QueryParam> idempotencyParams([String? idempotencyKey]) => const [];

  /// Unwraps `ApiResponse<T>` and returns the response data.
  T unwrapApiResponse<T>(
    Map<String, dynamic> body,
    T Function(dynamic data) fromData,
  ) {
    final success = body['success'] as bool? ?? false;
    if (!success) {
      final code = body['errorCode'] as String? ?? 'UNKNOWN';
      final message = body['message'] as String? ?? '操作失败';
      throw AppException(
        type: _mapErrorCode(code),
        message: message,
        errorCode: code,
        originalError: body,
      );
    }
    return fromData(body['data']);
  }

  /// Unwraps `ApiResponse<PageResponse<T>>`.
  PageResult<T> unwrapPageResponse<T>(
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    return unwrapApiResponse(body, (data) {
      if (data is! Map) {
        throw AppException(
          type: AppErrorType.businessError,
          message: 'Expected page response, got ${data.runtimeType}',
          originalError: body,
        );
      }
      final page = Map<String, dynamic>.from(data);
      final content = page['content'];
      return PageResult<T>(
        content: content is List
            ? content
                .map((item) => itemFromJson(
                    Map<String, dynamic>.from(item as Map<dynamic, dynamic>)))
                .toList()
            : <T>[],
        total: _asInt(page['total']),
        page: _asInt(page['page']),
        size: _asInt(page['size'], fallback: 20),
      );
    });
  }

  String decodeBodyBytes(http.Response response) {
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }

  dynamic decodeJsonBody(http.Response response) {
    final body = decodeBodyBytes(response).trim();
    if (body.isEmpty) {
      return null;
    }
    return jsonDecode(body);
  }

  void ensureSuccess(
    http.Response response, {
    Set<int>? successStatusCodes,
    Map<int, String> statusMessages = const {},
  }) {
    final success = successStatusCodes?.contains(response.statusCode) ??
        (response.statusCode >= 200 && response.statusCode < 400);
    if (!success) {
      throw AppException.fromStatusCode(
        response.statusCode,
        message: statusMessages[response.statusCode] ??
            extractErrorMessage(response),
        originalError: response,
      );
    }

    final decoded = _tryDecodeJson(response);
    if (decoded is Map && decoded['success'] == false) {
      throw AppException(
        type: AppErrorType.businessError,
        message: _messageFromMap(decoded),
        statusCode: response.statusCode,
        originalError: response,
      );
    }
  }

  Never throwResponseError(
    http.Response response, {
    Map<int, String> statusMessages = const {},
  }) {
    throw AppException.fromStatusCode(
      response.statusCode,
      message:
          statusMessages[response.statusCode] ?? extractErrorMessage(response),
      originalError: response,
    );
  }

  T parseResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic> json) fromJson, {
    Set<int>? successStatusCodes,
    Map<int, String> statusMessages = const {},
  }) {
    ensureSuccess(
      response,
      successStatusCodes: successStatusCodes,
      statusMessages: statusMessages,
    );
    final payload = unwrapPayload(decodeJsonBody(response));
    if (payload is Map<String, dynamic>) {
      return fromJson(payload);
    }
    if (payload is Map) {
      return fromJson(Map<String, dynamic>.from(payload));
    }
    throw AppException(
      type: AppErrorType.businessError,
      message: 'Expected JSON object response, got ${payload.runtimeType}',
      statusCode: response.statusCode,
      originalError: response,
    );
  }

  T? parseNullableResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic> json) fromJson, {
    Set<int> nullStatusCodes = const {404},
    Set<int>? successStatusCodes,
    Map<int, String> statusMessages = const {},
  }) {
    if (nullStatusCodes.contains(response.statusCode)) {
      return null;
    }
    ensureSuccess(
      response,
      successStatusCodes: successStatusCodes,
      statusMessages: statusMessages,
    );
    final payload = unwrapPayload(decodeJsonBody(response));
    if (payload == null) {
      return null;
    }
    if (payload is Map<String, dynamic>) {
      return fromJson(payload);
    }
    if (payload is Map) {
      return fromJson(Map<String, dynamic>.from(payload));
    }
    throw AppException(
      type: AppErrorType.businessError,
      message: 'Expected JSON object response, got ${payload.runtimeType}',
      statusCode: response.statusCode,
      originalError: response,
    );
  }

  List<T> parseListResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic> json) fromJson, {
    Set<int> emptyStatusCodes = const {204},
    Set<int>? successStatusCodes,
    Map<int, String> statusMessages = const {},
  }) {
    if (emptyStatusCodes.contains(response.statusCode)) {
      return <T>[];
    }
    ensureSuccess(
      response,
      successStatusCodes: successStatusCodes,
      statusMessages: statusMessages,
    );
    final payload = unwrapPayload(decodeJsonBody(response));
    if (payload == null) {
      return <T>[];
    }

    final list = switch (payload) {
      List<dynamic> value => value,
      Map<String, dynamic> value when value['items'] is List<dynamic> =>
        value['items'] as List<dynamic>,
      Map<String, dynamic> value when value['records'] is List<dynamic> =>
        value['records'] as List<dynamic>,
      Map<String, dynamic> value when value['content'] is List<dynamic> =>
        value['content'] as List<dynamic>,
      Map value when value['items'] is List<dynamic> =>
        value['items'] as List<dynamic>,
      Map value when value['records'] is List<dynamic> =>
        value['records'] as List<dynamic>,
      Map value when value['content'] is List<dynamic> =>
        value['content'] as List<dynamic>,
      _ => throw AppException(
          type: AppErrorType.businessError,
          message: 'Expected JSON list response, got ${payload.runtimeType}',
          statusCode: response.statusCode,
          originalError: response,
        ),
    };

    return list.map((item) {
      if (item is Map<String, dynamic>) {
        return fromJson(item);
      }
      if (item is Map) {
        return fromJson(Map<String, dynamic>.from(item));
      }
      throw AppException(
        type: AppErrorType.businessError,
        message: 'Expected JSON object in list, got ${item.runtimeType}',
        statusCode: response.statusCode,
        originalError: response,
      );
    }).toList();
  }

  Map<String, dynamic> parseMapResponse(
    http.Response response, {
    Set<int>? successStatusCodes,
    Map<int, String> statusMessages = const {},
  }) {
    ensureSuccess(
      response,
      successStatusCodes: successStatusCodes,
      statusMessages: statusMessages,
    );
    final payload = unwrapPayload(decodeJsonBody(response));
    if (payload == null) {
      return <String, dynamic>{};
    }
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    throw AppException(
      type: AppErrorType.businessError,
      message: 'Expected JSON object response, got ${payload.runtimeType}',
      statusCode: response.statusCode,
      originalError: response,
    );
  }

  dynamic unwrapPayload(dynamic decoded) {
    if (decoded is Map) {
      if (decoded['success'] == false) {
        final code = decoded['errorCode']?.toString() ?? 'UNKNOWN';
        throw AppException(
          type: _mapErrorCode(code),
          message: _messageFromMap(decoded),
          errorCode: code,
          statusCode: 400,
          originalError: decoded,
        );
      }
      if (decoded.containsKey('success') && decoded.containsKey('data')) {
        return decoded['data'];
      }
    }
    return decoded;
  }

  String extractErrorMessage(http.Response response) {
    final body = decodeBodyBytes(response).trim();
    if (body.isEmpty) {
      return 'Request failed with status ${response.statusCode}';
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return _messageFromMap(decoded);
      }
      if (decoded is List) {
        return jsonEncode(decoded);
      }
    } catch (_) {
      // Non-JSON error bodies are returned as-is.
    }

    return body;
  }

  AppErrorType _mapErrorCode(String code) {
    return switch (code) {
      'UNAUTHORIZED' => AppErrorType.unauthorized,
      'FORBIDDEN' => AppErrorType.forbidden,
      'NOT_FOUND' => AppErrorType.notFound,
      'CONFLICT' => AppErrorType.conflict,
      'DUPLICATE_REQUEST' => AppErrorType.duplicate,
      _ => AppErrorType.businessError,
    };
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  dynamic _tryDecodeJson(http.Response response) {
    try {
      return decodeJsonBody(response);
    } catch (_) {
      return null;
    }
  }

  String _messageFromMap(Map<dynamic, dynamic> map) {
    for (final key in const [
      'message',
      'error',
      'detail',
      'title',
      'error_description',
    ]) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    final errors = map['errors'];
    if (errors != null) {
      return errors is String ? errors : jsonEncode(errors);
    }
    return jsonEncode(map);
  }
}
