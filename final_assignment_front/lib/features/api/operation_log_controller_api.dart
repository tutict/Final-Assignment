import 'package:final_assignment_front/features/model/operation_log.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class OperationLogControllerApi {
  final ApiClient apiClient;

  /// 构造函数，可传入 ApiClient，否则使用全局默认实例
  OperationLogControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  /// 从 SharedPreferences 中读取 jwtToken 并设置到 ApiClient 中
  Future<void> initializeWithJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('未登录，请重新登录');
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint('Initialized OperationLogControllerApi with token: $jwtToken');
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

  /// GET /api/operationLogs - 获取所有操作日志
  Future<List<OperationLog>> apiOperationLogsGet() async {
    final response = await apiClient.invokeAPI(
      '/api/operationLogs',
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
    return OperationLog.listFromJson(data);
  }

  /// DELETE /api/operationLogs/{logId} - 删除操作日志 (仅管理员)
  Future<void> apiOperationLogsLogIdDelete({required String logId}) async {
    if (logId.isEmpty) {
      throw ApiException(400, "Missing required param: logId");
    }
    final response = await apiClient.invokeAPI(
      '/api/operationLogs/$logId',
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

  /// GET /api/operationLogs/{logId} - 根据ID获取操作日志
  Future<OperationLog?> apiOperationLogsLogIdGet(
      {required String logId}) async {
    if (logId.isEmpty) {
      throw ApiException(400, "Missing required param: logId");
    }
    final response = await apiClient.invokeAPI(
      '/api/operationLogs/$logId',
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
    return OperationLog.fromJson(data);
  }

  /// PUT /api/operationLogs/{logId} - 更新操作日志 (仅管理员)
  Future<OperationLog> apiOperationLogsLogIdPut({
    required String logId,
    required OperationLog operationLog,
  }) async {
    if (logId.isEmpty) {
      throw ApiException(400, "Missing required param: logId");
    }
    final response = await apiClient.invokeAPI(
      '/api/operationLogs/$logId',
      'PUT',
      [],
      operationLog.toJson(),
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
    return OperationLog.fromJson(data);
  }

  /// POST /api/operationLogs - 创建操作日志
  Future<OperationLog> apiOperationLogsPost(
      {required OperationLog operationLog}) async {
    final response = await apiClient.invokeAPI(
      '/api/operationLogs',
      'POST',
      [],
      operationLog.toJson(),
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
    return OperationLog.fromJson(data);
  }

  /// GET /api/operationLogs/result/{result} - 根据操作结果获取日志
  Future<List<OperationLog>> apiOperationLogsResultResultGet(
      {required String result}) async {
    if (result.isEmpty) {
      throw ApiException(400, "Missing required param: result");
    }
    final response = await apiClient.invokeAPI(
      '/api/operationLogs/result/$result',
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
    return OperationLog.listFromJson(data);
  }

  /// GET /api/operationLogs/timeRange - 根据时间范围获取操作日志
  Future<List<OperationLog>> apiOperationLogsTimeRangeGet(
      {String? startTime, String? endTime}) async {
    final response = await apiClient.invokeAPI(
      '/api/operationLogs/timeRange',
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
    return OperationLog.listFromJson(data);
  }

  /// GET /api/operationLogs/userId/{userId} - 根据用户ID获取操作日志
  Future<List<OperationLog>> apiOperationLogsUserIdUserIdGet(
      {required String userId}) async {
    if (userId.isEmpty) {
      throw ApiException(400, "Missing required param: userId");
    }
    final response = await apiClient.invokeAPI(
      '/api/operationLogs/userId/$userId',
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
    return OperationLog.listFromJson(data);
  }

  // WebSocket Methods (Aligned with HTTP Endpoints)

  /// GET /api/operationLogs (WebSocket)
  /// 对应后端: @WsAction(service="OperationLogService", action="getAllOperationLogs")
  Future<List<Object>?> eventbusOperationLogsGet() async {
    final msg = {
      "service": "OperationLogService",
      "action": "getAllOperationLogs",
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

  /// DELETE /api/operationLogs/{logId} (WebSocket)
  /// 对应后端: @WsAction(service="OperationLogService", action="deleteOperationLog")
  Future<bool> eventbusOperationLogsLogIdDelete({required String logId}) async {
    if (logId.isEmpty) {
      throw ApiException(400, "Missing required param: logId");
    }
    final msg = {
      "service": "OperationLogService",
      "action": "deleteOperationLog",
      "args": [int.parse(logId)]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return true; // Success if no error
  }

  /// GET /api/operationLogs/{logId} (WebSocket)
  /// 对应后端: @WsAction(service="OperationLogService", action="getOperationLog")
  Future<Object?> eventbusOperationLogsLogIdGet({required String logId}) async {
    if (logId.isEmpty) {
      throw ApiException(400, "Missing required param: logId");
    }
    final msg = {
      "service": "OperationLogService",
      "action": "getOperationLog",
      "args": [int.parse(logId)]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// PUT /api/operationLogs/{logId} (WebSocket)
  /// 对应后端: @WsAction(service="OperationLogService", action="updateOperationLog")
  Future<Object?> eventbusOperationLogsLogIdPut({
    required String logId,
    required OperationLog operationLog,
  }) async {
    if (logId.isEmpty) {
      throw ApiException(400, "Missing required param: logId");
    }
    final msg = {
      "service": "OperationLogService",
      "action": "updateOperationLog",
      "args": [int.parse(logId), operationLog.toJson()]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// POST /api/operationLogs (WebSocket)
  /// 对应后端: @WsAction(service="OperationLogService", action="createOperationLog")
  Future<Object?> eventbusOperationLogsPost(
      {required OperationLog operationLog}) async {
    final msg = {
      "service": "OperationLogService",
      "action": "createOperationLog",
      "args": [operationLog.toJson()]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/operationLogs/result/{result} (WebSocket)
  /// 对应后端: @WsAction(service="OperationLogService", action="getOperationLogsByResult")
  Future<List<Object>?> eventbusOperationLogsResultResultGet(
      {required String result}) async {
    if (result.isEmpty) {
      throw ApiException(400, "Missing required param: result");
    }
    final msg = {
      "service": "OperationLogService",
      "action": "getOperationLogsByResult",
      "args": [result]
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

  /// GET /api/operationLogs/timeRange (WebSocket)
  /// 对应后端: @WsAction(service="OperationLogService", action="getOperationLogsByTimeRange")
  Future<List<Object>?> eventbusOperationLogsTimeRangeGet(
      {String? startTime, String? endTime}) async {
    final msg = {
      "service": "OperationLogService",
      "action": "getOperationLogsByTimeRange",
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

  /// GET /api/operationLogs/userId/{userId} (WebSocket)
  /// 对应后端: @WsAction(service="OperationLogService", action="getOperationLogsByUserId")
  Future<List<Object>?> eventbusOperationLogsUserIdUserIdGet(
      {required String userId}) async {
    if (userId.isEmpty) {
      throw ApiException(400, "Missing required param: userId");
    }
    final msg = {
      "service": "OperationLogService",
      "action": "getOperationLogsByUserId",
      "args": [int.parse(userId)]
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
