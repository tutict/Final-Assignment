import 'dart:convert';
import 'package:final_assignment_front/features/model/login_log.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginLogControllerApi {
  final ApiClient _apiClient;
  String? _username;

  LoginLogControllerApi()
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

  Future<List<LoginLog>> apiLoginLogsGet({
    int page = 1,
    int size = 10,
  }) async {
    final queryParams = [
      QueryParam('page', page.toString()),
      QueryParam('size', size.toString()),
    ];
    final response = await _apiClient.invokeAPI(
      '/api/loginLogs',
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
      return LoginLog.listFromJson(data);
    } else if (response.statusCode == 404) {
      return [];
    }
    throw ApiException(response.statusCode,
        'Failed to fetch all login logs: ${response.body}');
  }

  Future<void> apiLoginLogsLogIdDelete({required String logId}) async {
    if (logId.isEmpty) {
      throw ApiException(400, 'Missing required param: logId');
    }
    final response = await _apiClient.invokeAPI(
      '/api/loginLogs/$logId',
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
          response.statusCode, 'Failed to delete login log: ${response.body}');
    }
  }

  Future<LoginLog?> apiLoginLogsLogIdGet({required String logId}) async {
    if (logId.isEmpty) {
      throw ApiException(400, 'Missing required param: logId');
    }
    final response = await _apiClient.invokeAPI(
      '/api/loginLogs/$logId',
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
      return LoginLog.fromJson(jsonDecode(decodedBody));
    } else if (response.statusCode == 404) {
      return null;
    }
    throw ApiException(response.statusCode,
        'Failed to fetch login log by ID: ${response.body}');
  }

  Future<LoginLog> apiLoginLogsLogIdPut({
    required String logId,
    required LoginLog loginLog,
    required String idempotencyKey,
  }) async {
    if (logId.isEmpty) {
      throw ApiException(400, 'Missing required param: logId');
    }
    final queryParams = [QueryParam('idempotencyKey', idempotencyKey)];
    final response = await _apiClient.invokeAPI(
      '/api/loginLogs/$logId',
      'PUT',
      queryParams,
      loginLog.toJson(),
      {'Content-Type': 'application/json; charset=UTF-8'},
      {'Accept': 'application/json; charset=UTF-8'},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint('Raw response body (update): $decodedBody');
      return LoginLog.fromJson(jsonDecode(decodedBody));
    }
    throw ApiException(
        response.statusCode, 'Failed to update login log: ${response.body}');
  }

  Future<List<LoginLog>> apiLoginLogsLoginResultLoginResultGet({
    required String loginResult,
    int page = 1,
    int size = 10,
  }) async {
    if (loginResult.isEmpty) {
      throw ApiException(400, 'Missing required param: loginResult');
    }
    final queryParams = [
      QueryParam('page', page.toString()),
      QueryParam('size', size.toString()),
    ];
    final response = await _apiClient.invokeAPI(
      '/api/loginLogs/loginResult/$loginResult',
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
      debugPrint('Raw response body (get by login result): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      return LoginLog.listFromJson(data);
    } else if (response.statusCode == 404) {
      return [];
    }
    throw ApiException(response.statusCode,
        'Failed to fetch login logs by login result: ${response.body}');
  }

  Future<LoginLog> apiLoginLogsPost({
    required LoginLog loginLog,
    required String idempotencyKey,
  }) async {
    final queryParams = [QueryParam('idempotencyKey', idempotencyKey)];
    final response = await _apiClient.invokeAPI(
      '/api/loginLogs',
      'POST',
      queryParams,
      loginLog.toJson(),
      {'Content-Type': 'application/json; charset=UTF-8'},
      {'Accept': 'application/json; charset=UTF-8'},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode == 201) {
      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint('Raw response body (create): $decodedBody');
      return LoginLog.fromJson(jsonDecode(decodedBody));
    }
    throw ApiException(
        response.statusCode, 'Failed to create login log: ${response.body}');
  }

  Future<List<LoginLog>> apiLoginLogsTimeRangeGet({
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
      '/api/loginLogs/timeRange',
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
      return LoginLog.listFromJson(data);
    } else if (response.statusCode == 404) {
      return [];
    }
    throw ApiException(response.statusCode,
        'Failed to fetch login logs by time range: ${response.body}');
  }

  Future<List<LoginLog>> apiLoginLogsUsernameUsernameGet({
    required String username,
    int page = 1,
    int size = 10,
  }) async {
    if (username.isEmpty) {
      throw ApiException(400, 'Missing required param: username');
    }
    final queryParams = [
      QueryParam('page', page.toString()),
      QueryParam('size', size.toString()),
    ];
    final response = await _apiClient.invokeAPI(
      '/api/loginLogs/username/$username',
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
      debugPrint('Raw response body (get by username): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      return LoginLog.listFromJson(data);
    } else if (response.statusCode == 404) {
      return [];
    }
    throw ApiException(response.statusCode,
        'Failed to fetch login logs by username: ${response.body}');
  }

  Future<bool> eventbusLoginLogsLogIdDelete({required String logId}) async {
    if (logId.isEmpty) {
      throw ApiException(400, 'Missing required param: logId');
    }
    final msg = {
      'service': 'LoginLogService',
      'action': 'deleteLoginLog',
      'args': [int.parse(logId)],
    };
    final respMap = await _apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      throw ApiException(400, respMap['error']);
    }
    return true;
  }

  Future<LoginLog?> eventbusLoginLogsLogIdGet({required String logId}) async {
    if (logId.isEmpty) {
      throw ApiException(400, 'Missing required param: logId');
    }
    final msg = {
      'service': 'LoginLogService',
      'action': 'getLoginLog',
      'args': [int.parse(logId)],
    };
    final respMap = await _apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      throw ApiException(400, respMap['error']);
    }
    final result = respMap['result'];
    if (result == null) return null;
    return LoginLog.fromJson(result);
  }

  Future<LoginLog> eventbusLoginLogsLogIdPut({
    required String logId,
    required LoginLog loginLog,
  }) async {
    if (logId.isEmpty) {
      throw ApiException(400, 'Missing required param: logId');
    }
    final msg = {
      'service': 'LoginLogService',
      'action': 'updateLoginLog',
      'args': [int.parse(logId), loginLog.toJson()],
    };
    final respMap = await _apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      throw ApiException(400, respMap['error']);
    }
    final result = respMap['result'];
    if (result == null) {
      throw ApiException(400, 'No result returned from WebSocket');
    }
    return LoginLog.fromJson(result);
  }

  Future<List<LoginLog>> eventbusLoginLogsLoginResultLoginResultGet({
    required String loginResult,
  }) async {
    if (loginResult.isEmpty) {
      throw ApiException(400, 'Missing required param: loginResult');
    }
    final msg = {
      'service': 'LoginLogService',
      'action': 'getLoginLogsByLoginResult',
      'args': [loginResult],
    };
    final respMap = await _apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      throw ApiException(400, respMap['error']);
    }
    final result = respMap['result'] as List<dynamic>?;
    if (result == null) return [];
    return LoginLog.listFromJson(result);
  }

  Future<LoginLog> eventbusLoginLogsPost({required LoginLog loginLog}) async {
    final msg = {
      'service': 'LoginLogService',
      'action': 'createLoginLog',
      'args': [loginLog.toJson()],
    };
    final respMap = await _apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      throw ApiException(400, respMap['error']);
    }
    final result = respMap['result'];
    if (result == null) {
      throw ApiException(400, 'No result returned from WebSocket');
    }
    return LoginLog.fromJson(result);
  }

  Future<List<LoginLog>> eventbusLoginLogsTimeRangeGet({
    String? startTime,
    String? endTime,
  }) async {
    final msg = {
      'service': 'LoginLogService',
      'action': 'getLoginLogsByTimeRange',
      'args': [startTime ?? '', endTime ?? ''],
    };
    final respMap = await _apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      throw ApiException(400, respMap['error']);
    }
    final result = respMap['result'] as List<dynamic>?;
    if (result == null) return [];
    return LoginLog.listFromJson(result);
  }

  Future<List<LoginLog>> eventbusLoginLogsUsernameUsernameGet({
    required String username,
  }) async {
    if (username.isEmpty) {
      throw ApiException(400, 'Missing required param: username');
    }
    final msg = {
      'service': 'LoginLogService',
      'action': 'getLoginLogsByUsername',
      'args': [username],
    };
    final respMap = await _apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      throw ApiException(400, respMap['error']);
    }
    final result = respMap['result'] as List<dynamic>?;
    if (result == null) return [];
    return LoginLog.listFromJson(result);
  }
}
