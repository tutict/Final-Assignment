import 'package:final_assignment_front/features/model/login_log.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class LoginLogControllerApi {
  final ApiClient apiClient;

  /// 构造函数，可传入 ApiClient，否则使用全局默认实例
  LoginLogControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  /// 从 SharedPreferences 中读取 jwtToken 并设置到 ApiClient 中
  Future<void> initializeWithJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('未登录，请重新登录');
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint('Initialized LoginLogControllerApi with token: $jwtToken');
  }

  /// 解码响应体字节到字符串
  String _decodeBodyBytes(Response response) => response.body;

  /// 辅助方法：添加查询参数（如时间范围）
  List<QueryParam> _addQueryParams({String? startTime, String? endTime}) {
    final queryParams = <QueryParam>[];
    if (startTime != null) queryParams.add(QueryParam('startTime', startTime));
    if (endTime != null) queryParams.add(QueryParam('endTime', endTime));
    return queryParams;
  }

  /// GET /api/loginLogs - 获取所有登录日志
  Future<List<LoginLog>> apiLoginLogsGet() async {
    final response = await apiClient.invokeAPI(
      '/api/loginLogs',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return LoginLog.listFromJson(data);
  }

  /// DELETE /api/loginLogs/{logId} - 删除登录日志 (仅管理员)
  Future<void> apiLoginLogsLogIdDelete({required String logId}) async {
    if (logId.isEmpty) {
      throw ApiException(400, "Missing required param: logId");
    }
    final response = await apiClient.invokeAPI(
      '/api/loginLogs/$logId',
      'DELETE',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// GET /api/loginLogs/{logId} - 根据ID获取登录日志
  Future<LoginLog?> apiLoginLogsLogIdGet({required String logId}) async {
    if (logId.isEmpty) {
      throw ApiException(400, "Missing required param: logId");
    }
    final response = await apiClient.invokeAPI(
      '/api/loginLogs/$logId',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return LoginLog.fromJson(data);
  }

  /// PUT /api/loginLogs/{logId} - 更新登录日志 (仅管理员)
  Future<LoginLog> apiLoginLogsLogIdPut({
    required String logId,
    required LoginLog loginLog,
  }) async {
    if (logId.isEmpty) {
      throw ApiException(400, "Missing required param: logId");
    }
    final response = await apiClient.invokeAPI(
      '/api/loginLogs/$logId',
      'PUT',
      [],
      loginLog.toJson(),
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return LoginLog.fromJson(data);
  }

  /// GET /api/loginLogs/loginResult/{loginResult} - 根据登录结果获取日志
  Future<List<LoginLog>> apiLoginLogsLoginResultLoginResultGet(
      {required String loginResult}) async {
    if (loginResult.isEmpty) {
      throw ApiException(400, "Missing required param: loginResult");
    }
    final response = await apiClient.invokeAPI(
      '/api/loginLogs/loginResult/$loginResult',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return LoginLog.listFromJson(data);
  }

  /// POST /api/loginLogs - 创建登录日志
  Future<LoginLog> apiLoginLogsPost({required LoginLog loginLog}) async {
    final response = await apiClient.invokeAPI(
      '/api/loginLogs',
      'POST',
      [],
      loginLog.toJson(),
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return LoginLog.fromJson(data);
  }

  /// GET /api/loginLogs/timeRange - 根据时间范围获取登录日志
  Future<List<LoginLog>> apiLoginLogsTimeRangeGet(
      {String? startTime, String? endTime}) async {
    final response = await apiClient.invokeAPI(
      '/api/loginLogs/timeRange',
      'GET',
      _addQueryParams(startTime: startTime, endTime: endTime),
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return LoginLog.listFromJson(data);
  }

  /// GET /api/loginLogs/username/{username} - 根据用户名获取登录日志
  Future<List<LoginLog>> apiLoginLogsUsernameUsernameGet(
      {required String username}) async {
    if (username.isEmpty) {
      throw ApiException(400, "Missing required param: username");
    }
    final response = await apiClient.invokeAPI(
      '/api/loginLogs/username/$username',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return LoginLog.listFromJson(data);
  }

  // WebSocket Methods (Aligned with HTTP Endpoints)

  /// DELETE /api/loginLogs/{logId} (WebSocket)
  /// 对应后端: @WsAction(service="LoginLogService", action="deleteLoginLog")
  Future<bool> eventbusLoginLogsLogIdDelete({required String logId}) async {
    if (logId.isEmpty) {
      throw ApiException(400, "Missing required param: logId");
    }
    final msg = {
      "service": "LoginLogService",
      "action": "deleteLoginLog",
      "args": [int.parse(logId)]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return true; // Success if no error
  }

  /// GET /api/loginLogs/{logId} (WebSocket)
  /// 对应后端: @WsAction(service="LoginLogService", action="getLoginLog")
  Future<Object?> eventbusLoginLogsLogIdGet({required String logId}) async {
    if (logId.isEmpty) {
      throw ApiException(400, "Missing required param: logId");
    }
    final msg = {
      "service": "LoginLogService",
      "action": "getLoginLog",
      "args": [int.parse(logId)]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// PUT /api/loginLogs/{logId} (WebSocket)
  /// 对应后端: @WsAction(service="LoginLogService", action="updateLoginLog")
  Future<Object?> eventbusLoginLogsLogIdPut({
    required String logId,
    required LoginLog loginLog,
  }) async {
    if (logId.isEmpty) {
      throw ApiException(400, "Missing required param: logId");
    }
    final msg = {
      "service": "LoginLogService",
      "action": "updateLoginLog",
      "args": [int.parse(logId), loginLog.toJson()]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/loginLogs/loginResult/{loginResult} (WebSocket)
  /// 对应后端: @WsAction(service="LoginLogService", action="getLoginLogsByLoginResult")
  Future<List<Object>?> eventbusLoginLogsLoginResultLoginResultGet(
      {required String loginResult}) async {
    if (loginResult.isEmpty) {
      throw ApiException(400, "Missing required param: loginResult");
    }
    final msg = {
      "service": "LoginLogService",
      "action": "getLoginLogsByLoginResult",
      "args": [loginResult]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    if (respMap["result"] is List) {
      return (respMap["result"] as List).cast<Object>();
    }
    return null;
  }

  /// POST /api/loginLogs (WebSocket)
  /// 对应后端: @WsAction(service="LoginLogService", action="createLoginLog")
  Future<Object?> eventbusLoginLogsPost({required LoginLog loginLog}) async {
    final msg = {
      "service": "LoginLogService",
      "action": "createLoginLog",
      "args": [loginLog.toJson()]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/loginLogs/timeRange (WebSocket)
  /// 对应后端: @WsAction(service="LoginLogService", action="getLoginLogsByTimeRange")
  Future<List<Object>?> eventbusLoginLogsTimeRangeGet(
      {String? startTime, String? endTime}) async {
    final msg = {
      "service": "LoginLogService",
      "action": "getLoginLogsByTimeRange",
      "args": [startTime ?? "", endTime ?? ""]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    if (respMap["result"] is List) {
      return (respMap["result"] as List).cast<Object>();
    }
    return null;
  }

  /// GET /api/loginLogs/username/{username} (WebSocket)
  /// 对应后端: @WsAction(service="LoginLogService", action="getLoginLogsByUsername")
  Future<List<Object>?> eventbusLoginLogsUsernameUsernameGet(
      {required String username}) async {
    if (username.isEmpty) {
      throw ApiException(400, "Missing required param: username");
    }
    final msg = {
      "service": "LoginLogService",
      "action": "getLoginLogsByUsername",
      "args": [username]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    if (respMap["result"] is List) {
      return (respMap["result"] as List).cast<Object>();
    }
    return null;
  }
}
