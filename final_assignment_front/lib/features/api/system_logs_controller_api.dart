import 'package:final_assignment_front/features/model/system_logs.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class SystemLogsControllerApi {
  final ApiClient apiClient;

  /// 构造函数，可传入 ApiClient，否则使用全局默认实例
  SystemLogsControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  /// 从 SharedPreferences 中读取 jwtToken 并设置到 ApiClient 中
  Future<void> initializeWithJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('未登录，请重新登录');
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint('Initialized SystemLogsControllerApi with token: $jwtToken');
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

  /// GET /api/systemLogs - 获取所有系统日志
  Future<List<SystemLogs>> apiSystemLogsGet() async {
    final response = await apiClient.invokeAPI(
      '/api/systemLogs',
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
    final List<dynamic> data = apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return SystemLogs.listFromJson(data);
  }

  /// DELETE /api/systemLogs/{logId} - 删除系统日志 (仅管理员)
  Future<void> apiSystemLogsLogIdDelete({required String logId}) async {
    if (logId.isEmpty) {
      throw ApiException(400, "Missing required param: logId");
    }
    final response = await apiClient.invokeAPI(
      '/api/systemLogs/$logId',
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

  /// GET /api/systemLogs/{logId} - 根据ID获取系统日志
  Future<SystemLogs?> apiSystemLogsLogIdGet({required String logId}) async {
    if (logId.isEmpty) {
      throw ApiException(400, "Missing required param: logId");
    }
    final response = await apiClient.invokeAPI(
      '/api/systemLogs/$logId',
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
    final data = apiClient.deserialize(_decodeBodyBytes(response), 'Map<String, dynamic>');
    return SystemLogs.fromJson(data);
  }

  /// PUT /api/systemLogs/{logId} - 更新系统日志 (仅管理员)
  Future<SystemLogs> apiSystemLogsLogIdPut({
    required String logId,
    required SystemLogs systemLogs,
  }) async {
    if (logId.isEmpty) {
      throw ApiException(400, "Missing required param: logId");
    }
    final response = await apiClient.invokeAPI(
      '/api/systemLogs/$logId',
      'PUT',
      [],
      systemLogs.toJson(),
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final data = apiClient.deserialize(_decodeBodyBytes(response), 'Map<String, dynamic>');
    return SystemLogs.fromJson(data);
  }

  /// GET /api/systemLogs/operationUser/{operationUser} - 根据操作用户获取日志
  Future<List<SystemLogs>> apiSystemLogsOperationUserOperationUserGet({required String operationUser}) async {
    if (operationUser.isEmpty) {
      throw ApiException(400, "Missing required param: operationUser");
    }
    final response = await apiClient.invokeAPI(
      '/api/systemLogs/operationUser/$operationUser',
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
    final List<dynamic> data = apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return SystemLogs.listFromJson(data);
  }

  /// POST /api/systemLogs - 创建系统日志
  Future<SystemLogs> apiSystemLogsPost({required SystemLogs systemLogs}) async {
    final response = await apiClient.invokeAPI(
      '/api/systemLogs',
      'POST',
      [],
      systemLogs.toJson(),
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final data = apiClient.deserialize(_decodeBodyBytes(response), 'Map<String, dynamic>');
    return SystemLogs.fromJson(data);
  }

  /// GET /api/systemLogs/timeRange - 根据时间范围获取系统日志
  Future<List<SystemLogs>> apiSystemLogsTimeRangeGet({String? startTime, String? endTime}) async {
    final response = await apiClient.invokeAPI(
      '/api/systemLogs/timeRange',
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
    final List<dynamic> data = apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return SystemLogs.listFromJson(data);
  }

  /// GET /api/systemLogs/type/{logType} - 根据日志类型获取系统日志
  Future<List<SystemLogs>> apiSystemLogsTypeLogTypeGet({required String logType}) async {
    if (logType.isEmpty) {
      throw ApiException(400, "Missing required param: logType");
    }
    final response = await apiClient.invokeAPI(
      '/api/systemLogs/type/$logType',
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
    final List<dynamic> data = apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return SystemLogs.listFromJson(data);
  }

  // WebSocket Methods (Aligned with HTTP Endpoints)

  /// GET /api/systemLogs (WebSocket)
  /// 对应后端: @WsAction(service="SystemLogsService", action="getAllSystemLogs")
  Future<List<Object>?> eventbusSystemLogsGet() async {
    final msg = {
      "service": "SystemLogsService",
      "action": "getAllSystemLogs",
      "args": []
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

  /// DELETE /api/systemLogs/{logId} (WebSocket)
  /// 对应后端: @WsAction(service="SystemLogsService", action="deleteSystemLog")
  Future<bool> eventbusSystemLogsLogIdDelete({required String logId}) async {
    if (logId.isEmpty) {
      throw ApiException(400, "Missing required param: logId");
    }
    final msg = {
      "service": "SystemLogsService",
      "action": "deleteSystemLog",
      "args": [int.parse(logId)]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return true; // Success if no error
  }

  /// GET /api/systemLogs/{logId} (WebSocket)
  /// 对应后端: @WsAction(service="SystemLogsService", action="getSystemLogById")
  Future<Object?> eventbusSystemLogsLogIdGet({required String logId}) async {
    if (logId.isEmpty) {
      throw ApiException(400, "Missing required param: logId");
    }
    final msg = {
      "service": "SystemLogsService",
      "action": "getSystemLogById",
      "args": [int.parse(logId)]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// PUT /api/systemLogs/{logId} (WebSocket)
  /// 对应后端: @WsAction(service="SystemLogsService", action="updateSystemLog")
  Future<Object?> eventbusSystemLogsLogIdPut({
    required String logId,
    required SystemLogs systemLogs,
  }) async {
    if (logId.isEmpty) {
      throw ApiException(400, "Missing required param: logId");
    }
    final msg = {
      "service": "SystemLogsService",
      "action": "updateSystemLog",
      "args": [int.parse(logId), systemLogs.toJson()]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/systemLogs/operationUser/{operationUser} (WebSocket)
  /// 对应后端: @WsAction(service="SystemLogsService", action="getSystemLogsByOperationUser")
  Future<List<Object>?> eventbusSystemLogsOperationUserOperationUserGet({required String operationUser}) async {
    if (operationUser.isEmpty) {
      throw ApiException(400, "Missing required param: operationUser");
    }
    final msg = {
      "service": "SystemLogsService",
      "action": "getSystemLogsByOperationUser",
      "args": [operationUser]
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

  /// POST /api/systemLogs (WebSocket)
  /// 对应后端: @WsAction(service="SystemLogsService", action="createSystemLog")
  Future<Object?> eventbusSystemLogsPost({required SystemLogs systemLogs}) async {
    final msg = {
      "service": "SystemLogsService",
      "action": "createSystemLog",
      "args": [systemLogs.toJson()]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/systemLogs/timeRange (WebSocket)
  /// 对应后端: @WsAction(service="SystemLogsService", action="getSystemLogsByTimeRange")
  Future<List<Object>?> eventbusSystemLogsTimeRangeGet({String? startTime, String? endTime}) async {
    final msg = {
      "service": "SystemLogsService",
      "action": "getSystemLogsByTimeRange",
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

  /// GET /api/systemLogs/type/{logType} (WebSocket)
  /// 对应后端: @WsAction(service="SystemLogsService", action="getSystemLogsByType")
  Future<List<Object>?> eventbusSystemLogsTypeLogTypeGet({required String logType}) async {
    if (logType.isEmpty) {
      throw ApiException(400, "Missing required param: logType");
    }
    final msg = {
      "service": "SystemLogsService",
      "action": "getSystemLogsByType",
      "args": [logType]
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