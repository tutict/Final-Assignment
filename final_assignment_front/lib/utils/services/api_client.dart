import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/authentication.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';
import 'package:final_assignment_front/utils/services/http_bearer_auth.dart';
import 'package:final_assignment_front/utils/services/query_param.dart';

export 'package:final_assignment_front/utils/services/query_param.dart';

/// Generic API client for HTTP/WebSocket
class ApiClient {
  static final http.Client _sharedClient = IOClient(_buildHttpClient());

  static HttpClient _buildHttpClient() {
    final client = HttpClient();
    client.idleTimeout = const Duration(seconds: 30);
    client.connectionTimeout = const Duration(seconds: 10);
    client.maxConnectionsPerHost = 6;
    return client;
  }

  /// Base URL (defaults to the Vert.x gateway 8081)
  String basePath;

  /// HTTP client
  http.Client client;

  /// Default headers
  final Map<String, String> _defaultHeaderMap = {};

  /// Auth scheme map
  final Map<String, Authentication> _authentications = {
    'bearerAuth': HttpBearerAuth(), // default Bearer auth
  };

  /// Regex helpers
  final RegExp _regList = RegExp(r'^List<(.*)>$');
  final RegExp _regMap = RegExp(r'^Map<String,(.*)>$');

  /// WebSocket channel
  WebSocketChannel? _wsChannel;
  String? _wsUrl;

  ApiClient({this.basePath = "http://localhost:8081", http.Client? client})
      : client = client ?? _sharedClient;

  void addDefaultHeader(String key, String value) {
    _defaultHeaderMap[key] = value;
  }

  void setJwtToken(String token) {
    final bearerAuth = _authentications['bearerAuth'] as HttpBearerAuth;
    bearerAuth.setAccessToken(token);
    if (kDebugMode) {
      debugPrint('JWT Token set in ApiClient: $token');
    }
  }

  String? get jwtToken {
    final bearerAuth = _authentications['bearerAuth'] as HttpBearerAuth;
    try {
      return bearerAuth.getAccessTokenString();
    } catch (_) {
      return null;
    }
  }

  String? _stripQuotes(String? value) {
    if (value == null) return null;
    return value.replaceAll('"', '').trim();
  }

  /// Main JSON deserializer into target model (kept lean; most API files call model.fromJson themselves)
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
          if (value is List && (match = _regList.firstMatch(targetType)) != null) {
            var newTargetType = match!.group(1)!;
            return value.map((v) => _deserialize(v, newTargetType)).toList();
          } else if (value is Map && (match = _regMap.firstMatch(targetType)) != null) {
            var newTargetType = match!.group(1)!;
            if (newTargetType == 'dynamic') {
              return value as Map<String, dynamic>;
            }
            return Map<String, dynamic>.fromIterables(
              value.keys.cast<String>(),
              value.values.map((v) => _deserialize(v, newTargetType)),
            );
          }
          // Fallback: return as-is
          return value;
      }
    } on Exception catch (e, stack) {
      debugPrint('Deserialization error for $targetType: $e');
      throw ApiException.withInner(
          500, 'Exception during deserialization: $e', e, stack);
    }
  }

  dynamic deserialize(String jsonStr, String targetType) {
    targetType = targetType.replaceAll(' ', '');
    if (targetType == 'String') return jsonStr;
    var decodedJson = jsonDecode(jsonStr);
    return _deserialize(decodedJson, targetType);
  }

  String serialize(Object obj) {
    return json.encode(obj);
  }

  /// Invoke HTTP / WebSocket (WS_CONNECT, WS_SEND, WS_CLOSE) calls
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
    // Handle WebSocket helpers
    if (method.toUpperCase() == 'WS_CONNECT') {
      await connectWebSocket(path, queryParams);
      return http.Response('', 200);
    }
    if (method.toUpperCase() == 'WS_SEND') {
      await sendWsMessage(body as Map<String, dynamic>);
      return http.Response('', 200);
    }
    if (method.toUpperCase() == 'WS_CLOSE') {
      closeWebSocket();
      return http.Response('', 200);
    }

    // HTTP
    final queryParamsList = queryParams.toList();
    if (authNames.contains('bearerAuth')) {
      final cachedToken = jwtToken;
      if (cachedToken == null || cachedToken.isEmpty) {
        final token = await AuthTokenStore.instance.getJwtToken();
        if (token != null && token.isNotEmpty) {
          setJwtToken(token);
        }
      }
    }
    _updateParamsForAuth(authNames, queryParamsList, headerParams);

    var ps = queryParamsList
        .where((p) => p.value.isNotEmpty)
        .map((p) =>
            '${Uri.encodeQueryComponent(p.name)}=${Uri.encodeQueryComponent(p.value)}');
    final queryString = ps.isNotEmpty ? '?${ps.join('&')}' : '';

    final url = basePath + path + queryString;
    headerParams.addAll(_defaultHeaderMap);
    final contentType =
        nullableContentType ?? 'application/json; charset=utf-8';
    headerParams['Content-Type'] = contentType;

    final uri = Uri.parse(url);
    if (kDebugMode) {
      debugPrint('Request URL: $url');
      debugPrint('Final Request Headers: $headerParams');
    }

    final msgBody =
        (contentType == "application/x-www-form-urlencoded") ? formParams : serialize(body ?? {});

    http.Response response;
    switch (method.toUpperCase()) {
      case "POST":
        response = await client.post(uri, headers: headerParams, body: msgBody);
        break;
      case "PUT":
        response = await client.put(uri, headers: headerParams, body: msgBody);
        break;
      case "DELETE":
        response = await client.delete(uri, headers: headerParams);
        break;
      case "PATCH":
        response =
            await client.patch(uri, headers: headerParams, body: msgBody);
        break;
      case "HEAD":
        response = await client.head(uri, headers: headerParams);
        break;
      case "GET":
      default:
        response = await client.get(uri, headers: headerParams);
        break;
    }

    if (kDebugMode) {
      debugPrint('Response: ${response.statusCode} - ${response.body}');
    }
    return response;
  }

  void _updateParamsForAuth(List<String> authNames,
      List<QueryParam> queryParams, Map<String, String> headerParams) {
    for (var authName in authNames) {
      final auth = _authentications[authName];
      if (auth == null) {
        throw ArgumentError("Authentication undefined: $authName");
      }
      auth.applyToParams(queryParams, headerParams);
    }
  }

  T? getAuthentication<T extends Authentication>(String name) {
    final authentication = _authentications[name];
    return authentication is T ? authentication : null;
  }

  /// Connect WebSocket (auto add Authorization header)
  Future<void> connectWebSocket(
      String path, Iterable<QueryParam> queryParams) async {
    final paramsList = queryParams.toList();
    final ps = paramsList
        .where((p) => p.value.isNotEmpty)
        .map((p) =>
            '${Uri.encodeQueryComponent(p.name)}=${Uri.encodeQueryComponent(p.value)}');
    final queryString = ps.isNotEmpty ? '?${ps.join('&')}' : '';

    final wsScheme = basePath.startsWith('https') ? 'wss://' : 'ws://';
    final stripped = basePath.replaceFirst(RegExp(r'^https?://'), '');
    final wsUrl = wsScheme + stripped + path + queryString;

    final headers = <String, dynamic>{};
    final token = jwtToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    _wsChannel = IOWebSocketChannel.connect(Uri.parse(wsUrl), headers: headers);
    _wsUrl = wsUrl;

    _wsChannel?.stream.listen(
      (message) {
        if (kDebugMode) {
          debugPrint('[WebSocket recv] $message');
        }
      },
      onDone: () {
        if (kDebugMode) {
          debugPrint('[WebSocket closed]');
        }
        _wsChannel = null;
      },
      onError: (error) {
        if (kDebugMode) {
          debugPrint('[WebSocket error] $error');
        }
      },
    );

    if (kDebugMode) {
      debugPrint('[WebSocket connected] $_wsUrl');
    }
  }

  /// Send a WebSocket message and wait for first JSON response map
  Future<Map<String, dynamic>> sendWsMessage(
      Map<String, dynamic> message) async {
    if (_wsChannel == null) {
      throw ApiException(500, 'WebSocket not connected');
    }
    final encoded = jsonEncode(message);
    _wsChannel!.sink.add(encoded);

    try {
      final responseRaw = await _wsChannel!.stream.first;
      final respMap = jsonDecode(responseRaw as String);
      if (respMap is Map<String, dynamic>) {
        if (respMap.containsKey('error')) {
          throw ApiException(400, respMap['error']);
        }
        return respMap;
      } else {
        throw ApiException(400, 'WebSocket response is not a JSON object');
      }
    } catch (e) {
      throw ApiException(500, 'WebSocket read error: $e');
    }
  }

  /// Close WebSocket connection
  void closeWebSocket() {
    if (_wsChannel == null) {
      if (kDebugMode) {
        debugPrint('[WebSocket] no active connection');
      }
      return;
    }
    _wsChannel?.sink.close();
    if (kDebugMode) {
      debugPrint('[WebSocket closed] ${_wsUrl ?? ''}');
    }
    _wsChannel = null;
    _wsUrl = null;
  }
}
