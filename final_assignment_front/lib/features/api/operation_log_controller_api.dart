import 'dart:convert';
import 'package:final_assignment_front/features/model/operation_log.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OperationLogControllerApi {
  final ApiClient _apiClient;
  String? _username;

  OperationLogControllerApi()
      : _apiClient = ApiClient(basePath: 'http://localhost:8081');

  Future<void> initializeWithJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken != null) {
      _apiClient.setJwtToken(jwtToken);
      final decodedToken = JwtDecoder.decode(jwtToken);
      _username = decodedToken['sub'] ?? 'Unknown';
      debugPrint('Initialized with username: $_username');
    } else {
      throw Exception('JWT token not found in SharedPreferences');
    }
  }

  List<QueryParam> _addQueryParams({String? startTime, String? endTime}) {
    final queryParams = <QueryParam>[];
    if (startTime != null) queryParams.add(QueryParam('startTime', startTime));
    if (endTime != null) queryParams.add(QueryParam('endTime', endTime));
    return queryParams;
  }

  Future<List<OperationLog>> apiOperationLogsGet({
    int page = 1,
    int size = 10,
  }) async {
    final queryParams = [
      QueryParam('page', page.toString()),
      QueryParam('size', size.toString()),
    ];
    final response = await _apiClient.invokeAPI(
      '/api/operationLogs',
      'GET',
      queryParams,
      null,
      {'Content-Type': 'application/json; charset=UTF-8'},
      {'Accept': 'application/json; charset=UTF-8'},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint('Raw response body (get all): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      return OperationLog.listFromJson(data);
    } else if (response.statusCode == 404) {
      return [];
    }
    throw ApiException(response.statusCode,
        'Failed to fetch all operation logs: ${response.body}');
  }

  Future<void> apiOperationLogsLogIdDelete({required String logId}) async {
    if (logId.isEmpty) {
      throw ApiException(400, 'Missing required param: logId');
    }
    final response = await _apiClient.invokeAPI(
      '/api/operationLogs/$logId',
      'DELETE',
      [],
      null,
      {'Content-Type': 'application/json; charset=UTF-8'},
      {'Accept': 'application/json; charset=UTF-8'},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode != 204) {
      throw ApiException(response.statusCode,
          'Failed to delete operation log: ${response.body}');
    }
  }

  Future<OperationLog?> apiOperationLogsLogIdGet(
      {required String logId}) async {
    if (logId.isEmpty) {
      throw ApiException(400, 'Missing required param: logId');
    }
    final response = await _apiClient.invokeAPI(
      '/api/operationLogs/$logId',
      'GET',
      [],
      null,
      {'Content-Type': 'application/json; charset=UTF-8'},
      {'Accept': 'application/json; charset=UTF-8'},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint('Raw response body (get by ID): $decodedBody');
      return OperationLog.fromJson(jsonDecode(decodedBody));
    } else if (response.statusCode == 404) {
      return null;
    }
    throw ApiException(response.statusCode,
        'Failed to fetch operation log by ID: ${response.body}');
  }

  Future<OperationLog> apiOperationLogsLogIdPut({
    required String logId,
    required OperationLog operationLog,
    required String idempotencyKey,
  }) async {
    if (logId.isEmpty) {
      throw ApiException(400, 'Missing required param: logId');
    }
    final queryParams = [QueryParam('idempotencyKey', idempotencyKey)];
    final response = await _apiClient.invokeAPI(
      '/api/operationLogs/$logId',
      'PUT',
      queryParams,
      operationLog.toJson(),
      {'Content-Type': 'application/json; charset=UTF-8'},
      {'Accept': 'application/json; charset=UTF-8'},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint('Raw response body (update): $decodedBody');
      return OperationLog.fromJson(jsonDecode(decodedBody));
    }
    throw ApiException(response.statusCode,
        'Failed to update operation log: ${response.body}');
  }

  Future<OperationLog> apiOperationLogsPost({
    required OperationLog operationLog,
    required String idempotencyKey,
  }) async {
    final queryParams = [QueryParam('idempotencyKey', idempotencyKey)];
    final response = await _apiClient.invokeAPI(
      '/api/operationLogs',
      'POST',
      queryParams,
      operationLog.toJson(),
      {'Content-Type': 'application/json; charset=UTF-8'},
      {'Accept': 'application/json; charset=UTF-8'},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode == 201) {
      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint('Raw response body (create): $decodedBody');
      return OperationLog.fromJson(jsonDecode(decodedBody));
    }
    throw ApiException(response.statusCode,
        'Failed to create operation log: ${response.body}');
  }

  Future<List<OperationLog>> apiOperationLogsResultResultGet({
    required String result,
    int page = 1,
    int size = 10,
  }) async {
    if (result.isEmpty) {
      throw ApiException(400, 'Missing required param: result');
    }
    final queryParams = [
      QueryParam('page', page.toString()),
      QueryParam('size', size.toString()),
    ];
    final response = await _apiClient.invokeAPI(
      '/api/operationLogs/result/$result',
      'GET',
      queryParams,
      null,
      {'Content-Type': 'application/json; charset=UTF-8'},
      {'Accept': 'application/json; charset=UTF-8'},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint('Raw response body (get by result): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      return OperationLog.listFromJson(data);
    } else if (response.statusCode == 404) {
      return [];
    }
    throw ApiException(response.statusCode,
        'Failed to fetch operation logs by result: ${response.body}');
  }

  Future<List<OperationLog>> apiOperationLogsTimeRangeGet({
    String? startTime,
    String? endTime,
    int page = 1,
    int size = 10,
  }) async {
    final queryParams = _addQueryParams(startTime: startTime, endTime: endTime)
      ..addAll([
        QueryParam('page', page.toString()),
        QueryParam('size', size.toString()),
      ]);
    final response = await _apiClient.invokeAPI(
      '/api/operationLogs/timeRange',
      'GET',
      queryParams,
      null,
      {'Content-Type': 'application/json; charset=UTF-8'},
      {'Accept': 'application/json; charset=UTF-8'},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint('Raw response body (get by time range): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      return OperationLog.listFromJson(data);
    } else if (response.statusCode == 404) {
      return [];
    }
    throw ApiException(response.statusCode,
        'Failed to fetch operation logs by time range: ${response.body}');
  }

  Future<List<OperationLog>> apiOperationLogsUserIdUserIdGet({
    required String userId,
    int page = 1,
    int size = 10,
  }) async {
    if (userId.isEmpty) {
      throw ApiException(400, 'Missing required param: userId');
    }
    final queryParams = [
      QueryParam('page', page.toString()),
      QueryParam('size', size.toString()),
    ];
    final response = await _apiClient.invokeAPI(
      '/api/operationLogs/userId/$userId',
      'GET',
      queryParams,
      null,
      {'Content-Type': 'application/json; charset=UTF-8'},
      {'Accept': 'application/json; charset=UTF-8'},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint('Raw response body (get by user ID): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      return OperationLog.listFromJson(data);
    } else if (response.statusCode == 404) {
      return [];
    }
    throw ApiException(response.statusCode,
        'Failed to fetch operation logs by user ID: ${response.body}');
  }

  Future<List<OperationLog>> eventbusOperationLogsGet() async {
    final msg = {
      'service': 'OperationLogService',
      'action': 'getAllOperationLogs',
      'args': [],
    };
    final respMap = await _apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      throw ApiException(400, respMap['error']);
    }
    final result = respMap['result'] as List<dynamic>?;
    if (result == null) return [];
    return OperationLog.listFromJson(result);
  }

  Future<bool> eventbusOperationLogsLogIdDelete({required String logId}) async {
    if (logId.isEmpty) {
      throw ApiException(400, 'Missing required param: logId');
    }
    final msg = {
      'service': 'OperationLogService',
      'action': 'deleteOperationLog',
      'args': [int.parse(logId)],
    };
    final respMap = await _apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      throw ApiException(400, respMap['error']);
    }
    return true;
  }

  Future<OperationLog?> eventbusOperationLogsLogIdGet({
    required String logId,
  }) async {
    if (logId.isEmpty) {
      throw ApiException(400, 'Missing required param: logId');
    }
    final msg = {
      'service': 'OperationLogService',
      'action': 'getOperationLog',
      'args': [int.parse(logId)],
    };
    final respMap = await _apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      throw ApiException(400, respMap['error']);
    }
    final result = respMap['result'];
    if (result == null) return null;
    return OperationLog.fromJson(result);
  }

  Future<OperationLog> eventbusOperationLogsLogIdPut({
    required String logId,
    required OperationLog operationLog,
  }) async {
    if (logId.isEmpty) {
      throw ApiException(400, 'Missing required param: logId');
    }
    final msg = {
      'service': 'OperationLogService',
      'action': 'updateOperationLog',
      'args': [int.parse(logId), operationLog.toJson()],
    };
    final respMap = await _apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      throw ApiException(400, respMap['error']);
    }
    final result = respMap['result'];
    if (result == null) {
      throw ApiException(400, 'No result returned from WebSocket');
    }
    return OperationLog.fromJson(result);
  }

  Future<OperationLog> eventbusOperationLogsPost({
    required OperationLog operationLog,
  }) async {
    final msg = {
      'service': 'OperationLogService',
      'action': 'createOperationLog',
      'args': [operationLog.toJson()],
    };
    final respMap = await _apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      throw ApiException(400, respMap['error']);
    }
    final result = respMap['result'];
    if (result == null) {
      throw ApiException(400, 'No result returned from WebSocket');
    }
    return OperationLog.fromJson(result);
  }

  Future<List<OperationLog>> eventbusOperationLogsResultResultGet({
    required String result,
  }) async {
    if (result.isEmpty) {
      throw ApiException(400, 'Missing required param: result');
    }
    final msg = {
      'service': 'OperationLogService',
      'action': 'getOperationLogsByResult',
      'args': [result],
    };
    final respMap = await _apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      throw ApiException(400, respMap['error']);
    }
    final resultList = respMap['result'] as List<dynamic>?;
    if (resultList == null) return [];
    return OperationLog.listFromJson(resultList);
  }

  Future<List<OperationLog>> eventbusOperationLogsTimeRangeGet({
    String? startTime,
    String? endTime,
  }) async {
    final msg = {
      'service': 'OperationLogService',
      'action': 'getOperationLogsByTimeRange',
      'args': [startTime ?? '', endTime ?? ''],
    };
    final respMap = await _apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      throw ApiException(400, respMap['error']);
    }
    final result = respMap['result'] as List<dynamic>?;
    if (result == null) return [];
    return OperationLog.listFromJson(result);
  }

  Future<List<OperationLog>> eventbusOperationLogsUserIdUserIdGet({
    required String userId,
  }) async {
    if (userId.isEmpty) {
      throw ApiException(400, 'Missing required param: userId');
    }
    final msg = {
      'service': 'OperationLogService',
      'action': 'getOperationLogsByUserId',
      'args': [int.parse(userId)],
    };
    final respMap = await _apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      throw ApiException(400, respMap['error']);
    }
    final result = respMap['result'] as List<dynamic>?;
    if (result == null) return [];
    return OperationLog.listFromJson(result);
  }
}
