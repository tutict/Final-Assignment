import 'dart:convert';

import 'package:final_assignment_front/features/model/appeal_management.dart';
import 'package:final_assignment_front/features/model/backup_restore.dart';
import 'package:final_assignment_front/features/model/category.dart';
import 'package:final_assignment_front/features/model/deduction_information.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/features/model/fine_information.dart';
import 'package:final_assignment_front/features/model/int.dart';
import 'package:final_assignment_front/features/model/integer.dart';
import 'package:final_assignment_front/features/model/login_log.dart';
import 'package:final_assignment_front/features/model/login_request.dart';
import 'package:final_assignment_front/features/model/offense_information.dart';
import 'package:final_assignment_front/features/model/operation_log.dart';
import 'package:final_assignment_front/features/model/permission_management.dart';
import 'package:final_assignment_front/features/model/register_request.dart';
import 'package:final_assignment_front/features/model/role_management.dart';
import 'package:final_assignment_front/features/model/security_context.dart';
import 'package:final_assignment_front/features/model/system_logs.dart';
import 'package:final_assignment_front/features/model/system_settings.dart';
import 'package:final_assignment_front/features/model/tag.dart';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/authentication.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// 用于表达Query参数的结构
class QueryParam {
  String name;
  String value;

  QueryParam(this.name, this.value);
}

/// 通用的 API 客户端，用于发起 HTTP 请求或 WebSocket 连接
class ApiClient {
  /// 默认的 BaseURL，一般写成后端服务的地址
  String basePath;

  /// http.Client，用于执行HTTP请求
  Client client;

  /// 默认请求头
  final Map<String, String> _defaultHeaderMap = {};

  /// 认证集合 (token等)
  final Map<String, Authentication> _authentications = {};

  /// 正则，用于匹配 List<T> 的类型
  final RegExp _regList = RegExp(r'^List<(.*)>$');

  /// 正则，用于匹配 Map<String, T> 的类型
  final RegExp _regMap = RegExp(r'^Map<String,(.*)>$');

  /// =================== 新增: WebSocket 相关字段 ====================
  /// WebSocketChannel 引用
  WebSocketChannel? _wsChannel;

  /// 当前 WebSocket 连接对应的URL
  String? _wsUrl;

  /// 连接后端的构造函数
  ApiClient({this.basePath = "http://localhost:8081"}) : client = Client();

  /// 添加默认的Header，可在后续请求中自动带上
  void addDefaultHeader(String key, String value) {
    _defaultHeaderMap[key] = value;
  }

  /// 主要的反序列化方法，将 JSON 数据反序列化成对应的模型
  dynamic _deserialize(dynamic value, String targetType) {
    try {
      switch (targetType) {
        case 'String':
          return '$value';
        case 'int':
          return value is int ? value : int.parse('$value');
        case 'bool':
          return value is bool ? value : '$value'.toLowerCase() == 'true';
        case 'double':
          return value is double ? value : double.parse('$value');
        case 'AppealManagement':
          return AppealManagement.fromJson(value);
        case 'BackupRestore':
          return BackupRestore.fromJson(value);
        case 'Category':
          return Category.fromJson(value);
        case 'DeductionInformation':
          return DeductionInformation.fromJson(value);
        case 'DriverInformation':
          return DriverInformation.fromJson(value);
        case 'FineInformation':
          return FineInformation.fromJson(value);
        case 'Int':
          return Int.fromJson(value);
        case 'Integer':
          return Integer.fromJson(value);
        case 'LoginLog':
          return LoginLog.fromJson(value);
        case 'LoginRequest':
          return LoginRequest.fromJson(value);
        case 'OffenseInformation':
          return OffenseInformation.fromJson(value);
        case 'OperationLog':
          return OperationLog.fromJson(value);
        case 'PermissionManagement':
          return PermissionManagement.fromJson(value);
        case 'RegisterRequest':
          return RegisterRequest.fromJson(value);
        case 'RoleManagement':
          return RoleManagement.fromJson(value);
        case 'SecurityContext':
          return SecurityContext.fromJson(value);
        case 'SystemLogs':
          return SystemLogs.fromJson(value);
        case 'SystemSettings':
          return SystemSettings.fromJson(value);
        case 'Tag':
          return Tag.fromJson(value);
        case 'UserManagement':
          return UserManagement.fromJson(value);
        case 'VehicleInformation':
          return VehicleInformation.fromJson(value);

        default:
          {
            RegExpMatch? match;
            // 如果是 List<T>
            if (value is List &&
                (match = _regList.firstMatch(targetType)) != null) {
              var newTargetType = match!.group(1)!; // match 不会是 null
              return value.map((v) => _deserialize(v, newTargetType)).toList();
            }
            // 如果是 Map<String, T>
            else if (value is Map &&
                (match = _regMap.firstMatch(targetType)) != null) {
              var newTargetType = match!.group(1)!;
              return Map<String, dynamic>.fromIterables(
                value.keys.cast<String>(),
                value.values.map((v) => _deserialize(v, newTargetType)),
              );
            }
          }
      }
    } on Exception catch (e, stack) {
      throw ApiException.withInner(
          500, 'Exception during deserialization.', e, stack);
    }
    throw ApiException(
        500, 'Could not find a suitable class for deserialization');
  }

  /// 将 JSON 字符串解析为对应类型的对象
  dynamic deserialize(String jsonStr, String targetType) {
    // 先去掉空格，防止一些不必要的问题
    targetType = targetType.replaceAll(' ', '');

    if (targetType == 'String') return jsonStr;

    var decodedJson = jsonDecode(jsonStr);
    return _deserialize(decodedJson, targetType);
  }

  /// 将 Dart 对象序列化为 JSON 字符串
  String serialize(Object obj) {
    return json.encode(obj);
  }

  /// 发起 HTTP / WebSocket 调用的通用方法
  /// 这里加了判断：如果 method == 'WS_CONNECT' / 'WS_SEND' / 'WS_CLOSE' 等，就走 WebSocket 逻辑；
  /// 否则走传统的 HTTP 请求逻辑。
  Future<Response> invokeAPI(
    String path,
    String method,
    Iterable<QueryParam> queryParams,
    Object? body,
    Map<String, String> headerParams,
    Map<String, String> formParams,
    String? nullableContentType,
    List<String> authNames,
  ) async {
    // ============ 判断是否为 WebSocket 相关操作 =============
    if (method.toUpperCase() == 'WS_CONNECT') {
      await connectWebSocket(path, queryParams);
      return Response('', 200); // 模拟成功
    }
    if (method.toUpperCase() == 'WS_SEND') {
      sendWsMessage(body as Map<String, dynamic>);
      return Response('', 200);
    }
    if (method.toUpperCase() == 'WS_CLOSE') {
      closeWebSocket();
      return Response('', 200);
    }

    // ============ 如果不是 WebSocket，则按原有HTTP逻辑处理 =============
    List<QueryParam> queryParamsList = queryParams.toList();

    // 根据 authNames 更新鉴权参数
    _updateParamsForAuth(authNames, queryParamsList, headerParams);

    // 构建 queryString
    var ps = queryParamsList.where((p) => p.value.isNotEmpty).map((p) =>
        '${Uri.encodeQueryComponent(p.name)}=${Uri.encodeQueryComponent(p.value)}');
    String queryString = ps.isNotEmpty ? '?${ps.join('&')}' : '';

    String url = basePath + path + queryString;

    // 合并 header
    headerParams.addAll(_defaultHeaderMap);
    final contentType = nullableContentType ?? 'application/json';
    headerParams['Content-Type'] = contentType;

    // 解析为 URI
    Uri uri;
    try {
      uri = Uri.parse(url);
    } catch (e) {
      throw ApiException(500, 'Invalid URL: $url');
    }

    // 如果是 MultipartRequest
    if (body is MultipartRequest) {
      var request = MultipartRequest(method, uri);
      request.fields.addAll(body.fields);
      request.files.addAll(body.files);
      request.headers.addAll(body.headers);
      request.headers.addAll(headerParams);

      var streamedResponse = await client.send(request);
      return Response.fromStream(streamedResponse);
    }
    // 否则是普通 body
    else {
      var msgBody = (nullableContentType == "application/x-www-form-urlencoded")
          ? formParams
          : serialize(body ?? {});

      final Map<String, String>? finalHeaderParams =
          headerParams.isEmpty ? null : headerParams;

      switch (method.toUpperCase()) {
        case "POST":
          return client.post(uri, headers: finalHeaderParams, body: msgBody);
        case "PUT":
          return client.put(uri, headers: finalHeaderParams, body: msgBody);
        case "DELETE":
          return client.delete(uri, headers: finalHeaderParams);
        case "PATCH":
          return client.patch(uri, headers: finalHeaderParams, body: msgBody);
        case "HEAD":
          return client.head(uri, headers: finalHeaderParams);
        case "GET":
        default:
          return client.get(uri, headers: finalHeaderParams);
      }
    }
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
    }
  }

  /// 获取指定类型的 Authentication
  T? getAuthentication<T extends Authentication>(String name) {
    var authentication = _authentications[name];
    return authentication is T ? authentication : null;
  }

  // ================= WebSocket 相关方法 =================

  /// 发起 WebSocket 连接
  Future<void> connectWebSocket(
      String path, Iterable<QueryParam> queryParams) async {
    // 组装 queryString
    var paramsList = queryParams.toList();
    var ps = paramsList.where((p) => p.value.isNotEmpty).map((p) =>
        '${Uri.encodeQueryComponent(p.name)}=${Uri.encodeQueryComponent(p.value)}');
    String queryString = ps.isNotEmpty ? '?${ps.join('&')}' : '';

    // 将 http:// 或 https:// 替换为 ws:// 或 wss://
    // 假设 basePath = http://localhost:8081
    // 那么就改成 ws://localhost:8081
    String wsScheme = basePath.startsWith('https') ? 'wss://' : 'ws://';
    String stripped = basePath.replaceFirst(RegExp(r'^https?://'), '');
    String wsUrl = wsScheme + stripped + path + queryString;

    // 创建 WebSocketChannel
    _wsChannel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
    _wsUrl = wsUrl;

    // 监听服务端消息
    _wsChannel?.stream.listen(
      (message) {
        // 收到服务端消息
        debugPrint('【WebSocket收到消息】: $message');
        // TODO: 可在这里写事件分发或自定义处理逻辑
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

  Future<Map<String, dynamic>> sendWsMessage(
      Map<String, dynamic> message) async {
    if (_wsChannel == null) {
      throw ApiException(500, 'WebSocket not connected');
    }
    final encoded = jsonEncode(message);
    _wsChannel!.sink.add(encoded);

    try {
      final responseRaw = await _wsChannel!.stream.first; // simplistic approach
      final respMap = jsonDecode(responseRaw as String);
      if (respMap is Map<String, dynamic>) {
        // check error
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
