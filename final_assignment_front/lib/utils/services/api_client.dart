import 'dart:convert';
import 'package:final_assignment_front/utils/services/http_bearer_auth.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/features/model/backup_restore.dart';
import 'package:final_assignment_front/features/model/deduction_information.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/features/model/fine_information.dart';
import 'package:final_assignment_front/features/model/login_log.dart';
import 'package:final_assignment_front/features/model/login_request.dart';
import 'package:final_assignment_front/features/model/offense_information.dart';
import 'package:final_assignment_front/features/model/operation_log.dart';
import 'package:final_assignment_front/features/model/permission_management.dart';
import 'package:final_assignment_front/features/model/register_request.dart';
import 'package:final_assignment_front/features/model/role_management.dart';
import 'package:final_assignment_front/features/model/system_logs.dart';
import 'package:final_assignment_front/features/model/system_settings.dart';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/authentication.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// 用于表达 Query 参数的结构
class QueryParam {
  String name;
  String value;

  QueryParam(this.name, this.value);
}

/// 通用的 API 客户端，用于发起 HTTP 请求或 WebSocket 连接
class ApiClient {
  /// 默认的 BaseURL，一般写成后端服务的地址
  String basePath;

  /// http.Client，用于执行 HTTP 请求
  http.Client client;

  /// 默认请求头
  final Map<String, String> _defaultHeaderMap = {};

  /// 认证集合 (token 等)
  final Map<String, Authentication> _authentications = {
    'bearerAuth': HttpBearerAuth(), // 添加默认 Bearer 认证
  };

  /// 正则，用于匹配 List<T> 的类型
  final RegExp _regList = RegExp(r'^List<(.*)>$');

  /// 正则，用于匹配 Map<String, T> 的类型
  final RegExp _regMap = RegExp(r'^Map<String,(.*)>$');

  /// WebSocketChannel 引用
  WebSocketChannel? _wsChannel;

  /// 当前 WebSocket 连接对应的 URL
  String? _wsUrl;

  /// 连接后端的构造函数
  ApiClient({this.basePath = "http://localhost:8081"}) : client = http.Client();

  /// 添加默认的 Header，可在后续请求中自动带上
  void addDefaultHeader(String key, String value) {
    _defaultHeaderMap[key] = value;
  }

  void setJwtToken(String token) {
    final bearerAuth = _authentications['bearerAuth'] as HttpBearerAuth;
    bearerAuth.setAccessToken(token);
    debugPrint('JWT Token set in ApiClient: $token');
  }

  /// Helper to strip extra quotes from strings
  String? _stripQuotes(String? value) {
    if (value == null) return null;
    return value.replaceAll('"', '').trim();
  }

  /// 主要的反序列化方法，将 JSON 数据反序列化成对应的模型
  dynamic _deserialize(dynamic value, String targetType) {
    try {
      switch (targetType) {
        case 'String':
          return value is String ? _stripQuotes(value) : '$value';
        case 'int':
          return value is int ? value : int.parse('$value');
        case 'bool':
          return value is bool ? value : '$value'.toLowerCase() == 'true';
        case 'double':
          return value is double ? value : double.parse('$value');
        case 'DateTime':
          return value != null ? DateTime.parse(value as String) : null;
        case 'Map<String, dynamic>':
          return value as Map<String, dynamic>;
        case 'BackupRestore':
          return BackupRestore.fromJson(value as Map<String, dynamic>);
        case 'DeductionInformation':
          return DeductionInformation.fromJson(value as Map<String, dynamic>);
        case 'DriverInformation':
          return DriverInformation.fromJson(value as Map<String, dynamic>);
        case 'FineInformation':
          return FineInformation.fromJson(value as Map<String, dynamic>);
        case 'LoginLog':
          return LoginLog.fromJson(value as Map<String, dynamic>);
        case 'LoginRequest':
          return LoginRequest.fromJson(value as Map<String, dynamic>);
        case 'OffenseInformation':
          return OffenseInformation.fromJson(value as Map<String, dynamic>);
        case 'OperationLog':
          return OperationLog.fromJson(value as Map<String, dynamic>);
        case 'PermissionManagement':
          return PermissionManagement.fromJson(value as Map<String, dynamic>);
        case 'RegisterRequest':
          return RegisterRequest.fromJson(value as Map<String, dynamic>);
        case 'RoleManagement':
          return RoleManagement.fromJson(value as Map<String, dynamic>);
        case 'SystemLogs':
          return SystemLogs.fromJson(value as Map<String, dynamic>);
        case 'SystemSettings':
          return SystemSettings.fromJson(value as Map<String, dynamic>);
        case 'UserManagement':
          return UserManagement.fromJson(value as Map<String, dynamic>);
        case 'VehicleInformation':
          return VehicleInformation.fromJson(value as Map<String, dynamic>);
        case 'List<DriverInformation>':
          if (value is List) {
            return value
                .map((item) =>
                    DriverInformation.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          throw ApiException(
              500, 'Expected a List for List<DriverInformation>, got $value');
        case 'dynamic':
          if (value is Map<String, dynamic>) {
            debugPrint('Dynamic Map encountered: $value');
            return value;
          } else if (value is List) {
            debugPrint('Dynamic List encountered: $value');
            return value;
          }
          return value; // Return primitive types as-is
        default:
          {
            RegExpMatch? match;
            if (value is List &&
                (match = _regList.firstMatch(targetType)) != null) {
              var newTargetType = match!.group(1)!;
              debugPrint('Deserializing List with inner type: $newTargetType');
              return value.map((v) => _deserialize(v, newTargetType)).toList();
            } else if (value is Map &&
                (match = _regMap.firstMatch(targetType)) != null) {
              var newTargetType = match!.group(1)!;
              debugPrint('Deserializing Map with inner type: $newTargetType');
              if (newTargetType == 'dynamic') {
                return value as Map<String, dynamic>;
              }
              return Map<String, dynamic>.fromIterables(
                value.keys.cast<String>(),
                value.values.map((v) => _deserialize(v, newTargetType)),
              );
            }
            debugPrint('Unknown target type: $targetType, value: $value');
            throw ApiException(500,
                'Could not find a suitable class for deserialization: $targetType');
          }
      }
    } on Exception catch (e, stack) {
      debugPrint('Deserialization error for $targetType: $e');
      throw ApiException.withInner(
          500, 'Exception during deserialization: $e', e, stack);
    }
  }

  /// 将 JSON 字符串解析为对应类型的对象
  dynamic deserialize(String jsonStr, String targetType) {
    targetType = targetType.replaceAll(' ', '');
    if (targetType == 'String') return jsonStr;
    var decodedJson = jsonDecode(jsonStr);
    debugPrint('Deserializing JSON: $decodedJson to $targetType');
    return _deserialize(decodedJson, targetType);
  }

  /// 将 Dart 对象序列化为 JSON 字符串
  String serialize(Object obj) {
    return json.encode(obj);
  }

  /// 发起 HTTP / WebSocket 调用的通用方法
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
    if (method.toUpperCase() == 'WS_CONNECT') {
      await connectWebSocket(path, queryParams);
      return http.Response('', 200);
    }
    if (method.toUpperCase() == 'WS_SEND') {
      sendWsMessage(body as Map<String, dynamic>);
      return http.Response('', 200);
    }
    if (method.toUpperCase() == 'WS_CLOSE') {
      closeWebSocket();
      return http.Response('', 200);
    }

    List<QueryParam> queryParamsList = queryParams.toList();
    _updateParamsForAuth(authNames, queryParamsList, headerParams);
    debugPrint('Headers after auth: $headerParams');

    var ps = queryParamsList.where((p) => p.value.isNotEmpty).map((p) =>
        '${Uri.encodeQueryComponent(p.name)}=${Uri.encodeQueryComponent(p.value)}');
    String queryString = ps.isNotEmpty ? '?${ps.join('&')}' : '';

    String url = basePath + path + queryString;
    headerParams.addAll(_defaultHeaderMap);
    final contentType =
        nullableContentType ?? 'application/json; charset=utf-8';
    headerParams['Content-Type'] = contentType;

    Uri uri = Uri.parse(url);
    debugPrint('Request URL: $url');
    debugPrint('Final Request Headers: $headerParams');

    var msgBody = (contentType == "application/x-www-form-urlencoded")
        ? formParams
        : serialize(body ?? {});

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

    debugPrint('Response: ${response.statusCode} - ${response.body}');
    return response;
  }

  /// 更新鉴权参数
  void _updateParamsForAuth(List<String> authNames,
      List<QueryParam> queryParams, Map<String, String> headerParams) {
    for (var authName in authNames) {
      Authentication? auth = _authentications[authName];
      if (auth == null) {
        throw ArgumentError("Authentication undefined: $authName");
      }
      auth.applyToParams(queryParams, headerParams);
      debugPrint('Applied $authName authentication: $headerParams');
    }
  }

  T? getAuthentication<T extends Authentication>(String name) {
    var authentication = _authentications[name];
    return authentication is T ? authentication : null;
  }

  // ================= WebSocket 相关方法 =================

  /// 发起 WebSocket 连接
  Future<void> connectWebSocket(
      String path, Iterable<QueryParam> queryParams) async {
    var paramsList = queryParams.toList();
    var ps = paramsList.where((p) => p.value.isNotEmpty).map((p) =>
        '${Uri.encodeQueryComponent(p.name)}=${Uri.encodeQueryComponent(p.value)}');
    String queryString = ps.isNotEmpty ? '?${ps.join('&')}' : '';

    String wsScheme = basePath.startsWith('https') ? 'wss://' : 'ws://';
    String stripped = basePath.replaceFirst(RegExp(r'^https?://'), '');
    String wsUrl = wsScheme + stripped + path + queryString;

    _wsChannel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
    _wsUrl = wsUrl;

    _wsChannel?.stream.listen(
      (message) {
        debugPrint('【WebSocket收到消息】: $message');
      },
      onDone: () {
        debugPrint('【WebSocket连接已关闭】');
        _wsChannel = null;
      },
      onError: (error) {
        debugPrint('【WebSocket错误】: $error');
      },
    );

    debugPrint('【WebSocket连接已建立】: $_wsUrl');
  }

  /// 发送 WebSocket 消息并接收响应
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
        throw ApiException(400, 'Response is not a JSON object');
      }
    } catch (e) {
      throw ApiException(500, 'WebSocket read error: $e');
    }
  }

  /// 关闭 WebSocket 连接
  void closeWebSocket() {
    if (_wsChannel == null) {
      debugPrint('【WebSocket当前无连接，无需关闭】');
      return;
    }
    _wsChannel?.sink.close();
    debugPrint('【WebSocket连接已主动关闭】: $_wsUrl');
    _wsChannel = null;
    _wsUrl = null;
  }
}
