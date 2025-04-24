import 'dart:convert';
import 'package:final_assignment_front/features/model/system_logs.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SystemLogsControllerApi {
  final ApiClient _apiClient;
  String? _username;

  SystemLogsControllerApi()
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

  Future<List<SystemLogs>> apiSystemLogsGet({
    int page = 1,
    int size = 10,
  }) async {
    final queryParams = [
      QueryParam('page', page.toString()),
      QueryParam('size', size.toString()),
    ];
    final response = await _apiClient.invokeAPI(
      '/api/systemLogs',
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
      return SystemLogs.listFromJson(data);
    } else if (response.statusCode == 404) {
      return [];
    }
    throw ApiException(response.statusCode,
        'Failed to fetch all system logs: ${response.body}');
  }

  Future<void> apiSystemLogsLogIdDelete({required String logId}) async {
    if (logId.isEmpty) {
      throw ApiException(400, 'Missing required param: logId');
    }
    final response = await _apiClient.invokeAPI(
      '/api/systemLogs/$logId',
      'DELETE',
      [],
      null,
      {'Content-Type': 'application/json; charset=UTF-8'},
      {'Accept': 'application/json; charset=UTF-8'},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode != 204) {
      throw ApiException(
          response.statusCode, 'Failed to delete system log: ${response.body}');
    }
  }

  Future<SystemLogs?> apiSystemLogsLogIdGet({required String logId}) async {
    if (logId.isEmpty) {
      throw ApiException(400, 'Missing required param: logId');
    }
    final response = await _apiClient.invokeAPI(
      '/api/systemLogs/$logId',
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
      return SystemLogs.fromJson(jsonDecode(decodedBody));
    } else if (response.statusCode == 404) {
      return null;
    }
    throw ApiException(response.statusCode,
        'Failed to fetch system log by ID: ${response.body}');
  }

  Future<SystemLogs> apiSystemLogsLogIdPut({
    required String logId,
    required SystemLogs systemLogs,
    required String idempotencyKey,
  }) async {
    if (logId.isEmpty) {
      throw ApiException(400, 'Missing required param: logId');
    }
    final queryParams = [QueryParam('idempotencyKey', idempotencyKey)];
    final response = await _apiClient.invokeAPI(
      '/api/systemLogs/$logId',
      'PUT',
      queryParams,
      systemLogs.toJson(),
      {'Content-Type': 'application/json; charset=UTF-8'},
      {'Accept': 'application/json; charset=UTF-8'},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint('Raw response body (update): $decodedBody');
      return SystemLogs.fromJson(jsonDecode(decodedBody));
    }
    throw ApiException(
        response.statusCode, 'Failed to update system log: ${response.body}');
  }

  Future<List<SystemLogs>> apiSystemLogsOperationUserGet({
    required String operationUser,
    int page = 1,
    int size = 10,
  }) async {
    if (operationUser.isEmpty) {
      throw ApiException(400, 'Missing required param: operationUser');
    }
    final queryParams = [
      QueryParam('page', page.toString()),
      QueryParam('size', size.toString()),
    ];
    final response = await _apiClient.invokeAPI(
      '/api/systemLogs/operationUser/$operationUser',
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
      debugPrint('Raw response body (get by operation user): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      return SystemLogs.listFromJson(data);
    } else if (response.statusCode == 404) {
      return [];
    }
    throw ApiException(response.statusCode,
        'Failed to fetch system logs by operation user: ${response.body}');
  }

  Future<SystemLogs> apiSystemLogsPost({
    required SystemLogs systemLogs,
    required String idempotencyKey,
  }) async {
    final queryParams = [QueryParam('idempotencyKey', idempotencyKey)];
    final response = await _apiClient.invokeAPI(
      '/api/systemLogs',
      'POST',
      queryParams,
      systemLogs.toJson(),
      {'Content-Type': 'application/json; charset=UTF-8'},
      {'Accept': 'application/json; charset=UTF-8'},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode == 201) {
      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint('Raw response body (create): $decodedBody');
      return SystemLogs.fromJson(jsonDecode(decodedBody));
    }
    throw ApiException(
        response.statusCode, 'Failed to create system log: ${response.body}');
  }

  Future<List<SystemLogs>> apiSystemLogsTimeRangeGet({
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
      '/api/systemLogs/timeRange',
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
      return SystemLogs.listFromJson(data);
    } else if (response.statusCode == 404) {
      return [];
    }
    throw ApiException(response.statusCode,
        'Failed to fetch system logs by time range: ${response.body}');
  }

  Future<List<SystemLogs>> apiSystemLogsTypeLogTypeGet({
    required String logType,
    int page = 1,
    int size = 10,
  }) async {
    if (logType.isEmpty) {
      throw ApiException(400, 'Missing required param: logType');
    }
    final queryParams = [
      QueryParam('page', page.toString()),
      QueryParam('size', size.toString()),
    ];
    final response = await _apiClient.invokeAPI(
      '/api/systemLogs/type/$logType',
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
      debugPrint('Raw response body (get by log type): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      return SystemLogs.listFromJson(data);
    } else if (response.statusCode == 404) {
      return [];
    }
    throw ApiException(response.statusCode,
        'Failed to fetch system logs by log type: ${response.body}');
  }

  Future<List<SystemLogs>> eventbusSystemLogsGet() async {
    final msg = {
      'service': 'SystemLogsService',
      'action': 'getAllSystemLogs',
      'args': [],
    };
    final respMap = await _apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      throw ApiException(400, respMap['error']);
    }
    final result = respMap['result'] as List<dynamic>?;
    if (result == null) return [];
    return SystemLogs.listFromJson(result);
  }

  Future<bool> eventbusSystemLogsLogIdDelete({required String logId}) async {
    if (logId.isEmpty) {
      throw ApiException(400, 'Missing required param: logId');
    }
    final msg = {
      'service': 'SystemLogsService',
      'action': 'deleteSystemLog',
      'args': [int.parse(logId)],
    };
    final respMap = await _apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      throw ApiException(400, respMap['error']);
    }
    return true;
  }

  Future<SystemLogs?> eventbusSystemLogsLogIdGet(
      {required String logId}) async {
    if (logId.isEmpty) {
      throw ApiException(400, 'Missing required param: logId');
    }
    final msg = {
      'service': 'SystemLogsService',
      'action': 'getSystemLogById',
      'args': [int.parse(logId)],
    };
    final respMap = await _apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      throw ApiException(400, respMap['error']);
    }
    final result = respMap['result'];
    if (result == null) return null;
    return SystemLogs.fromJson(result);
  }

  Future<SystemLogs> eventbusSystemLogsLogIdPut({
    required String logId,
    required SystemLogs systemLogs,
  }) async {
    if (logId.isEmpty) {
      throw ApiException(400, 'Missing required param: logId');
    }
    final msg = {
      'service': 'SystemLogsService',
      'action': 'updateSystemLog',
      'args': [int.parse(logId), systemLogs.toJson()],
    };
    final respMap = await _apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      throw ApiException(400, respMap['error']);
    }
    final result = respMap['result'];
    if (result == null) {
      throw ApiException(400, 'No result returned from WebSocket');
    }
    return SystemLogs.fromJson(result);
  }

  Future<List<SystemLogs>> eventbusSystemLogsOperationUserOperationUserGet({
    required String operationUser,
  }) async {
    if (operationUser.isEmpty) {
      throw ApiException(400, 'Missing required param: operationUser');
    }
    final msg = {
      'service': 'SystemLogsService',
      'action': 'getSystemLogsByOperationUser',
      'args': [operationUser],
    };
    final respMap = await _apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      throw ApiException(400, respMap['error']);
    }
    final result = respMap['result'] as List<dynamic>?;
    if (result == null) return [];
    return SystemLogs.listFromJson(result);
  }

  Future<SystemLogs> eventbusSystemLogsPost({
    required SystemLogs systemLogs,
  }) async {
    final msg = {
      'service': 'SystemLogsService',
      'action': 'createSystemLog',
      'args': [systemLogs.toJson()],
    };
    final respMap = await _apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      throw ApiException(400, respMap['error']);
    }
    final result = respMap['result'];
    if (result == null) {
      throw ApiException(400, 'No result returned from WebSocket');
    }
    return SystemLogs.fromJson(result);
  }

  Future<List<SystemLogs>> eventbusSystemLogsTimeRangeGet({
    String? startTime,
    String? endTime,
  }) async {
    final msg = {
      'service': 'SystemLogsService',
      'action': 'getSystemLogsByTimeRange',
      'args': [startTime ?? '', endTime ?? ''],
    };
    final respMap = await _apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      throw ApiException(400, respMap['error']);
    }
    final result = respMap['result'] as List<dynamic>?;
    if (result == null) return [];
    return SystemLogs.listFromJson(result);
  }

  Future<List<SystemLogs>> eventbusSystemLogsTypeLogTypeGet({
    required String logType,
  }) async {
    if (logType.isEmpty) {
      throw ApiException(400, 'Missing required param: logType');
    }
    final msg = {
      'service': 'SystemLogsService',
      'action': 'getSystemLogsByType',
      'args': [logType],
    };
    final respMap = await _apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      throw ApiException(400, respMap['error']);
    }
    final result = respMap['result'] as List<dynamic>?;
    if (result == null) return [];
    return SystemLogs.listFromJson(result);
  }
}
