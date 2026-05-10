import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../utils/helpers/api_exception.dart';
import '../../utils/services/auth_token_store.dart';
import '../../utils/services/authentication.dart';
import '../../utils/services/http_bearer_auth.dart';
import '../../utils/services/query_param.dart';
import '../auth/auth_service.dart';
import '../config/app_config.dart';
import 'client_factory.dart' as client_factory;
import 'interceptor.dart';

export '../../utils/services/query_param.dart';

class ApiClient {
  ApiClient({String? basePath, http.Client? client})
      : basePath = basePath ?? AppConfig.apiBaseUrl,
        client = client ?? _createHttpClient();

  String basePath;
  http.Client client;

  final Map<String, String> _defaultHeaderMap = {};
  final Map<String, Authentication> _authentications = {
    'bearerAuth': HttpBearerAuth(),
  };

  final RegExp _regList = RegExp(r'^List<(.*)>$');
  final RegExp _regMap = RegExp(r'^Map<String,(.*)>$');

  WebSocketChannel? _wsChannel;
  Stream<dynamic>? _wsStream;
  String? _wsUrl;

  static http.Client _createHttpClient() {
    final rawClient = client_factory.createHttpClient();
    if (Get.isRegistered<ApiRequestLoggingInterceptor>()) {
      return Get.find<ApiRequestLoggingInterceptor>().wrap(rawClient);
    }
    return rawClient;
  }

  void addDefaultHeader(String key, String value) {
    _defaultHeaderMap[key] = value;
  }

  void setJwtToken(String token) {
    final bearerAuth = _authentications['bearerAuth'] as HttpBearerAuth;
    bearerAuth.setAccessToken(token);
    if (kDebugMode) {
      debugPrint('JWT Token set in ApiClient');
    }
  }

  String? get jwtToken {
    final bearerAuth = _authentications['bearerAuth'] as HttpBearerAuth;
    return bearerAuth.getAccessTokenString();
  }

  String? _stripQuotes(String? value) {
    if (value == null) return null;
    return value.replaceAll('"', '').trim();
  }

  dynamic _deserialize(dynamic value, String targetType) {
    try {
      switch (targetType) {
        case 'String':
          return value is String ? _stripQuotes(value) : '$value';
        case 'int':
          return value is int ? value : int.tryParse('$value');
        case 'bool':
          return value is bool ? value : '$value'.toLowerCase() == 'true';
        case 'double':
          return value is double ? value : double.tryParse('$value');
        case 'DateTime':
          return value != null ? DateTime.tryParse(value as String) : null;
        case 'Map<String, dynamic>':
          return value as Map<String, dynamic>;
        case 'List<dynamic>':
          return value as List<dynamic>;
        default:
          RegExpMatch? match;
          if (value is List &&
              (match = _regList.firstMatch(targetType)) != null) {
            final newTargetType = match!.group(1)!;
            return value.map((v) => _deserialize(v, newTargetType)).toList();
          } else if (value is Map &&
              (match = _regMap.firstMatch(targetType)) != null) {
            final newTargetType = match!.group(1)!;
            if (newTargetType == 'dynamic') {
              return value as Map<String, dynamic>;
            }
            return Map<String, dynamic>.fromIterables(
              value.keys.cast<String>(),
              value.values.map((v) => _deserialize(v, newTargetType)),
            );
          }
          return value;
      }
    } on Exception catch (error, stackTrace) {
      debugPrint('Deserialization error for $targetType: $error');
      throw ApiException.withInner(
        500,
        'Exception during deserialization: $error',
        error,
        stackTrace,
      );
    }
  }

  dynamic deserialize(String jsonStr, String targetType) {
    targetType = targetType.replaceAll(' ', '');
    if (targetType == 'String') return jsonStr;
    return _deserialize(jsonDecode(jsonStr), targetType);
  }

  String serialize(Object obj) => jsonEncode(obj);

  Future<http.Response> invokeAPI(
    String path,
    String method,
    Iterable<QueryParam> queryParams,
    Object? body,
    Map<String, String> headerParams,
    Map<String, String> formParams,
    String? nullableContentType,
    List<String> authNames,
  ) async {
    final normalizedMethod = method.toUpperCase();
    if (normalizedMethod == 'WS_CONNECT') {
      await connectWebSocket(path, queryParams);
      return http.Response('', 200);
    }
    if (normalizedMethod == 'WS_SEND') {
      await sendWsMessage(body as Map<String, dynamic>);
      return http.Response('', 200);
    }
    if (normalizedMethod == 'WS_CLOSE') {
      closeWebSocket();
      return http.Response('', 200);
    }

    final queryParamsList = queryParams.toList();
    await _refreshJwtForAuth(authNames);
    await _loadJwtForAuth(authNames);
    _updateParamsForAuth(authNames, queryParamsList, headerParams);

    headerParams.addAll(_defaultHeaderMap);
    final contentType =
        nullableContentType ?? 'application/json; charset=utf-8';
    headerParams['Content-Type'] = contentType;

    final uri = _buildUri(path, queryParamsList);
    if (kDebugMode) {
      debugPrint('Request URL: $uri');
      debugPrint('Final Request Headers: $headerParams');
    }

    final msgBody = contentType.startsWith('application/x-www-form-urlencoded')
        ? formParams
        : serialize(body ?? {});

    final response = await _sendHttp(
      normalizedMethod,
      uri,
      headerParams,
      msgBody,
    ).timeout(const Duration(seconds: 30));

    if (kDebugMode) {
      debugPrint('Response: ${response.statusCode} - ${response.body}');
    }
    return response;
  }

  Future<void> _refreshJwtForAuth(List<String> authNames) async {
    if (!authNames.contains('bearerAuth')) return;
    if (!Get.isRegistered<AuthService>()) return;
    await Get.find<AuthService>().ensureValidSession(redirectIfInvalid: true);
  }

  Future<void> _loadJwtForAuth(List<String> authNames) async {
    if (!authNames.contains('bearerAuth')) return;

    final token = await AuthTokenStore.instance.getJwtToken();
    if (token != null && token.isNotEmpty) {
      setJwtToken(token);
    }
  }

  Uri _buildUri(String path, Iterable<QueryParam> queryParams) {
    final rawUri = Uri.parse(_joinBasePath(path));
    final mergedQuery = <String, String>{
      ...rawUri.queryParameters,
      for (final p in queryParams)
        if (p.value.isNotEmpty) p.name: p.value,
    };
    return rawUri.replace(
      queryParameters: mergedQuery.isEmpty ? null : mergedQuery,
    );
  }

  String _joinBasePath(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final normalizedBase = basePath.endsWith('/')
        ? basePath.substring(0, basePath.length - 1)
        : basePath;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return normalizedBase + normalizedPath;
  }

  Future<http.Response> _sendHttp(
    String method,
    Uri uri,
    Map<String, String> headers,
    Object body,
  ) {
    switch (method) {
      case 'POST':
        return client.post(uri, headers: headers, body: body);
      case 'PUT':
        return client.put(uri, headers: headers, body: body);
      case 'PATCH':
        return client.patch(uri, headers: headers, body: body);
      case 'DELETE':
        return client.delete(uri, headers: headers);
      case 'HEAD':
        return client.head(uri, headers: headers);
      case 'GET':
      default:
        return client.get(uri, headers: headers);
    }
  }

  void _updateParamsForAuth(
    List<String> authNames,
    List<QueryParam> queryParams,
    Map<String, String> headerParams,
  ) {
    for (final authName in authNames) {
      final auth = _authentications[authName];
      if (auth == null) {
        throw ArgumentError('Authentication undefined: $authName');
      }
      auth.applyToParams(queryParams, headerParams);
    }
  }

  T? getAuthentication<T extends Authentication>(String name) {
    final authentication = _authentications[name];
    return authentication is T ? authentication : null;
  }

  Future<void> connectWs(
    String path, {
    List<QueryParam> params = const [],
  }) async {
    await connectWebSocket(path, params);
  }

  Future<void> connectWebSocket(
    String path,
    Iterable<QueryParam> queryParams,
  ) async {
    final token = await AuthTokenStore.instance.getJwtToken();
    if (token != null && token.isNotEmpty) {
      setJwtToken(token);
    }

    final wsUri = _buildWsUri(path, queryParams, token);
    final headers = <String, dynamic>{};
    if (!AppConfig.isWeb && token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    _wsChannel = connectWebSocketFactory(
      wsUri,
      headers: headers.isEmpty ? null : headers,
    );
    _wsUrl = wsUri.toString();
    _wsStream = _wsChannel!.stream.asBroadcastStream();

    if (kDebugMode) {
      debugPrint('[WebSocket connected] $_wsUrl');
    }
  }

  Uri _buildWsUri(
    String path,
    Iterable<QueryParam> queryParams,
    String? token,
  ) {
    final base = Uri.parse(
      _joinBasePath(path).replaceFirst(
        RegExp(r'^https?'),
        basePath.startsWith('https') ? 'wss' : 'ws',
      ),
    );
    final mergedQuery = <String, String>{
      ...base.queryParameters,
      for (final p in queryParams)
        if (p.value.isNotEmpty) p.name: p.value,
      if (token != null && token.isNotEmpty) 'access_token': token,
    };
    return base.replace(
        queryParameters: mergedQuery.isEmpty ? null : mergedQuery);
  }

  WebSocketChannel connectWebSocketFactory(
    Uri uri, {
    Map<String, dynamic>? headers,
  }) {
    return client_factory.connectWebSocket(uri, headers: headers);
  }

  Future<Map<String, dynamic>> sendWs(Map<String, dynamic> message) {
    return sendWsMessage(message);
  }

  Future<Map<String, dynamic>> sendWsMessage(
    Map<String, dynamic> message,
  ) async {
    final channel = _wsChannel;
    final stream = _wsStream;
    if (channel == null || stream == null) {
      throw ApiException(500, 'WebSocket not connected');
    }

    channel.sink.add(jsonEncode(message));

    try {
      final responseRaw =
          await stream.first.timeout(const Duration(seconds: 30));
      final decoded = jsonDecode(responseRaw as String);
      if (decoded is! Map<String, dynamic>) {
        throw ApiException(400, 'WebSocket response is not a JSON object');
      }
      if (decoded.containsKey('error')) {
        throw ApiException(400, decoded['error'].toString());
      }
      return decoded;
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(500, 'WebSocket read error: $error');
    }
  }

  void closeWebSocket() {
    final channel = _wsChannel;
    if (channel == null) {
      if (kDebugMode) {
        debugPrint('[WebSocket] no active connection');
      }
      return;
    }

    channel.sink.close();
    if (kDebugMode) {
      debugPrint('[WebSocket closed] ${_wsUrl ?? ''}');
    }
    _wsChannel = null;
    _wsStream = null;
    _wsUrl = null;
  }
}
