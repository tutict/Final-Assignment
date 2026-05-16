import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../utils/services/auth_token_store.dart';
import '../../utils/services/authentication.dart';
import '../../utils/services/http_bearer_auth.dart';
import '../../utils/services/query_param.dart';
import '../auth/auth_service.dart';
import '../config/app_config.dart';
import 'app_exception.dart';
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

  static const _uuid = Uuid();
  final RegExp _regList = RegExp(r'^List<(.*)>$');
  final RegExp _regMap = RegExp(r'^Map<String,(.*)>$');

  WebSocketChannel? _wsChannel;
  StreamSubscription<dynamic>? _wsSubscription;
  String? _wsUrl;
  final Map<String, Completer<Map<String, dynamic>>> _pendingRequests = {};
  final StreamController<String> _wsMessageController =
      StreamController<String>.broadcast();
  static Completer<bool>? _refreshCompleter;

  Stream<String> get wsMessageStream => _wsMessageController.stream;

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
      AppLogger.debug('JWT Token set in ApiClient');
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
      AppLogger.error('Deserialization error for $targetType: $error');
      throw AppException.withInner(
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
      {Set<int> passThroughStatusCodes = const {},
      bool isRetry = false}) async {
    try {
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
        AppLogger.debug('Request URL: $uri');
        AppLogger.debug('Final Request Headers: $headerParams');
      }

      final msgBody =
          contentType.startsWith('application/x-www-form-urlencoded')
              ? formParams
              : serialize(body ?? {});

      final response = await _sendHttp(
        normalizedMethod,
        uri,
        headerParams,
        msgBody,
      ).timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        AppLogger.debug('Response: ${response.statusCode} - ${response.body}');
      }

      if (response.statusCode == 208) {
        return http.Response(
          jsonEncode({'success': true, 'data': null}),
          response.statusCode,
          headers: response.headers,
          request: response.request,
          reasonPhrase: response.reasonPhrase,
        );
      }

      if (response.statusCode == 401 &&
          !isRetry &&
          authNames.contains('bearerAuth') &&
          !passThroughStatusCodes.contains(401)) {
        final refreshed = await _safeRefreshToken();
        if (refreshed) {
          return invokeAPI(
            path,
            method,
            queryParams,
            body,
            Map<String, String>.from(headerParams),
            formParams,
            nullableContentType,
            authNames,
            passThroughStatusCodes: passThroughStatusCodes,
            isRetry: true,
          );
        }
        await _clearSessionAndRedirect();
        throw const AppException(
          type: AppErrorType.unauthorized,
          message: 'Login expired',
          statusCode: 401,
        );
      }

      _throwIfErrorResponse(
        response,
        passThroughStatusCodes: passThroughStatusCodes,
      );
      return response;
    } on AppException catch (e) {
      await _handleAppException(e);
      rethrow;
    } on TimeoutException catch (e) {
      final exception = AppException.fromError(e);
      await _handleAppException(exception);
      throw exception;
    } on http.ClientException catch (e) {
      final exception = AppException.fromError(e);
      await _handleAppException(exception);
      throw exception;
    } catch (e) {
      final exception = AppException.fromError(e);
      await _handleAppException(exception);
      throw exception;
    }
  }

  void _throwIfErrorResponse(
    http.Response response, {
    Set<int> passThroughStatusCodes = const {},
  }) {
    if (passThroughStatusCodes.contains(response.statusCode)) return;
    if (!AppException.isErrorStatus(response.statusCode)) return;
    throw AppException.fromResponse(response);
  }

  Future<void> _handleAppException(AppException exception) async {
    if (!Get.isRegistered<AuthService>()) return;
    final authService = Get.find<AuthService>();
    if (exception.type == AppErrorType.unauthorized) {
      await authService.handleUnauthorized();
      return;
    }
    if (exception.type == AppErrorType.forbidden) {
      await authService.handleForbidden(message: exception.message);
    }
  }

  Future<bool> _safeRefreshToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();
    try {
      if (!Get.isRegistered<AuthService>()) {
        _refreshCompleter!.complete(false);
        return false;
      }
      final result = await Get.find<AuthService>().refreshJwtToken();
      if (result) {
        final token = await AuthTokenStore.instance.getJwtToken();
        if (token != null && token.isNotEmpty) {
          setJwtToken(token);
        }
      }
      _refreshCompleter!.complete(result);
      return result;
    } catch (_) {
      if (!_refreshCompleter!.isCompleted) {
        _refreshCompleter!.complete(false);
      }
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<void> _clearSessionAndRedirect() async {
    if (!Get.isRegistered<AuthService>()) return;
    final authService = Get.find<AuthService>();
    await authService.clearTokens();
    await authService.redirectToLogin(clearStoredTokens: false);
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
    closeWebSocket();

    final token = await AuthTokenStore.instance.getJwtToken();
    if (token != null && token.isNotEmpty) {
      setJwtToken(token);
    }

    final wsUri = _buildWsUri(_normalizeWsPath(path), queryParams, token);
    final headers = <String, dynamic>{};
    if (!AppConfig.isWeb && token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    _wsChannel = connectWebSocketFactory(
      wsUri,
      headers: headers.isEmpty ? null : headers,
    );
    _wsUrl = wsUri.toString();
    _wsSubscription = _wsChannel!.stream.listen(
      _handleWsData,
      onError: (Object error) {
        _completePendingWithError(
          AppException.http(500, 'WebSocket error: $error'),
        );
      },
      onDone: () {
        _completePendingWithError(AppException.http(500, 'WebSocket closed'));
      },
    );

    if (kDebugMode) {
      AppLogger.debug(
        '[WebSocket connected] ${_sanitizeWsUrl(_wsUrl ?? '')}',
      );
    }
  }

  Uri _buildWsUri(
    String path,
    Iterable<QueryParam> queryParams,
    String? token,
  ) {
    final base = Uri.parse(AppConfig.wsBaseUrl);
    final wsPath = _joinWsPath(base.path, path);
    final mergedQuery = <String, String>{
      ...base.queryParameters,
      for (final p in queryParams)
        if (p.value.isNotEmpty) p.name: p.value,
      if (token != null && token.isNotEmpty) 'access_token': token,
    };
    return base.replace(
      path: wsPath,
      queryParameters: mergedQuery.isEmpty ? null : mergedQuery,
    );
  }

  String _normalizeWsPath(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return normalized == '/eventbus' ? '/eventbus/websocket' : normalized;
  }

  String _joinWsPath(String basePath, String path) {
    final normalizedBase = basePath == '/' || basePath.isEmpty
        ? ''
        : (basePath.startsWith('/') ? basePath : '/$basePath')
            .replaceFirst(RegExp(r'/+$'), '');
    final normalizedPath = path.isEmpty
        ? ''
        : (path.startsWith('/') ? path : '/$path')
            .replaceFirst(RegExp(r'/+$'), '');

    if (normalizedPath.isEmpty) {
      return normalizedBase.isEmpty ? '/' : normalizedBase;
    }
    if (normalizedBase.isEmpty) {
      return normalizedPath;
    }
    if (normalizedPath == normalizedBase ||
        normalizedPath.startsWith('$normalizedBase/')) {
      return normalizedPath;
    }
    return '$normalizedBase$normalizedPath';
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
    if (channel == null || _wsSubscription == null) {
      throw AppException.http(500, 'WebSocket not connected');
    }

    final requestId = message['requestId']?.toString() ?? _uuid.v4();
    final outbound = Map<String, dynamic>.from(message)
      ..['requestId'] = requestId;
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[requestId] = completer;

    try {
      channel.sink.add(jsonEncode(outbound));
      final decoded = await completer.future.timeout(
        const Duration(seconds: 30),
      );
      if (decoded.containsKey('error')) {
        throw AppException.http(400, decoded['error'].toString());
      }
      return decoded;
    } on TimeoutException {
      _pendingRequests.remove(requestId);
      throw AppException.http(504, 'WebSocket request timed out');
    } on AppException {
      rethrow;
    } catch (error) {
      _pendingRequests.remove(requestId);
      throw AppException.http(500, 'WebSocket read error: $error');
    }
  }

  void _handleWsData(dynamic data) {
    try {
      final rawMessage = data as String;
      final decoded = jsonDecode(rawMessage);
      if (decoded is! Map<String, dynamic>) {
        throw AppException.http(400, 'WebSocket response is not a JSON object');
      }

      final requestId = decoded['requestId']?.toString();
      Completer<Map<String, dynamic>>? completer;
      if (requestId != null) {
        completer = _pendingRequests.remove(requestId);
      } else if (!_isBusinessPushMessage(decoded) &&
          _pendingRequests.length == 1) {
        final fallbackId = _pendingRequests.keys.single;
        completer = _pendingRequests.remove(fallbackId);
      }

      if (completer == null) {
        if (_isBusinessPushMessage(decoded)) {
          _wsMessageController.add(rawMessage);
          return;
        }
        AppLogger.debug('Unmatched WebSocket response: $decoded');
        return;
      }
      if (!completer.isCompleted) {
        completer.complete(decoded);
      }
    } catch (error) {
      _completePendingWithError(
        error is AppException
            ? error
            : AppException.http(
                500,
                'WebSocket response parse error: $error',
              ),
      );
    }
  }

  bool _isBusinessPushMessage(Map<String, dynamic> decoded) {
    final type = decoded['type']?.toString();
    return type == 'APPEAL_STATUS_CHANGED' ||
        type == 'PAYMENT_STATUS_CHANGED' ||
        type == 'ASYNC_OPERATION_FAILED';
  }

  void _completePendingWithError(Object error) {
    final pending = Map<String, Completer<Map<String, dynamic>>>.from(
      _pendingRequests,
    );
    _pendingRequests.clear();
    for (final completer in pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    }
  }

  String _sanitizeWsUrl(String value) {
    return value.replaceAll(
      RegExp(r'access_token=[^&]+'),
      'access_token=***',
    );
  }

  void closeWebSocket() {
    final channel = _wsChannel;
    if (channel == null) {
      if (kDebugMode) {
        AppLogger.debug('[WebSocket] no active connection');
      }
      return;
    }

    channel.sink.close();
    _wsSubscription?.cancel();
    _completePendingWithError(AppException.http(500, 'WebSocket closed'));
    if (kDebugMode) {
      AppLogger.debug('[WebSocket closed] ${_sanitizeWsUrl(_wsUrl ?? '')}');
    }
    _wsChannel = null;
    _wsSubscription = null;
    _wsUrl = null;
  }
}
