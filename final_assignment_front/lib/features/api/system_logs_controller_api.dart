import 'dart:convert';
import 'package:final_assignment_front/features/model/system_logs.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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

  Future<List<SystemLogs>> apiSystemLogsGet() async {
    final uri = Uri.parse('http://localhost:8081/api/systemLogs');
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('JWT token not found in SharedPreferences');
    }
    debugPrint('Request URL: $uri');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json; charset=UTF-8',
      },
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
    final uri = Uri.parse('http://localhost:8081/api/systemLogs/$logId');
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('JWT token not found in SharedPreferences');
    }
    debugPrint('Request URL: $uri');
    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json; charset=UTF-8',
      },
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
    final uri = Uri.parse('http://localhost:8081/api/systemLogs/$logId');
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('JWT token not found in SharedPreferences');
    }
    debugPrint('Request URL: $uri');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json; charset=UTF-8',
      },
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
    final uri = Uri.parse(
        'http://localhost:8081/api/systemLogs/$logId?idempotencyKey=$idempotencyKey');
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('JWT token not found in SharedPreferences');
    }
    debugPrint('Request URL: $uri');
    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(systemLogs.toJson()),
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
  }) async {
    if (operationUser.isEmpty) {
      throw ApiException(400, 'Missing required param: operationUser');
    }
    final uri = Uri.parse(
        'http://localhost:8081/api/systemLogs/operationUser/$operationUser');
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('JWT token not found in SharedPreferences');
    }
    debugPrint('Request URL: $uri');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json; charset=UTF-8',
      },
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

  Future<void> apiSystemLogsPost({
    required SystemLogs systemLogs,
    required String idempotencyKey,
  }) async {
    final uri = Uri.parse(
        'http://localhost:8081/api/systemLogs?idempotencyKey=$idempotencyKey');
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('JWT token not found in SharedPreferences');
    }
    debugPrint('Request URL: $uri');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(systemLogs.toJson()),
    );

    if (response.statusCode != 201) {
      throw ApiException(
          response.statusCode, 'Failed to create system log: ${response.body}');
    }
  }

  Future<List<SystemLogs>> apiSystemLogsTimeRangeGet({
    String? startTime,
    String? endTime,
  }) async {
    final queryParameters = <String, String>{
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
    };
    final uri = Uri.parse('http://localhost:8081/api/systemLogs/timeRange')
        .replace(queryParameters: queryParameters);
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('JWT token not found in SharedPreferences');
    }
    debugPrint('Request URL: $uri');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json; charset=UTF-8',
      },
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
  }) async {
    if (logType.isEmpty) {
      throw ApiException(400, 'Missing required param: logType');
    }
    final uri = Uri.parse('http://localhost:8081/api/systemLogs/type/$logType');
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('JWT token not found in SharedPreferences');
    }
    debugPrint('Request URL: $uri');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json; charset=UTF-8',
      },
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

  Future<List<String>> apiSystemLogsAutocompleteLogTypesGet({
    required String prefix,
  }) async {
    if (prefix.isEmpty) {
      throw ApiException(400, 'Missing required param: prefix');
    }
    final uri = Uri.parse(
        'http://localhost:8081/api/system-logs/autocomplete/log-types/me?prefix=$prefix');
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('JWT token not found in SharedPreferences');
    }
    debugPrint('Request URL: $uri');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint('Raw response body (autocomplete log types): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      return data.cast<String>();
    } else if (response.statusCode == 404) {
      return [];
    }
    throw ApiException(response.statusCode,
        'Failed to fetch log type autocomplete suggestions: ${response.body}');
  }

  Future<List<String>> apiSystemLogsAutocompleteOperationUsersGet({
    required String prefix,
  }) async {
    if (prefix.isEmpty) {
      throw ApiException(400, 'Missing required param: prefix');
    }
    final uri = Uri.parse(
        'http://localhost:8081/api/system-logs/autocomplete/operation-users/me?prefix=$prefix');
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('JWT token not found in SharedPreferences');
    }
    debugPrint('Request URL: $uri');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint(
          'Raw response body (autocomplete operation users): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      return data.cast<String>();
    } else if (response.statusCode == 404) {
      return [];
    }
    throw ApiException(response.statusCode,
        'Failed to fetch operation user autocomplete suggestions: ${response.body}');
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

  Future<List<String>> eventbusSystemLogsAutocompleteLogTypesGet({
    required String prefix,
  }) async {
    if (prefix.isEmpty) {
      throw ApiException(400, 'Missing required param: prefix');
    }
    final msg = {
      'service': 'SystemLogsService',
      'action': 'getLogTypeAutocompleteSuggestionsGlobally',
      'args': [prefix],
    };
    final respMap = await _apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      throw ApiException(400, respMap['error']);
    }
    final result = respMap['result'] as List<dynamic>?;
    if (result == null) return [];
    return result.cast<String>();
  }

  Future<List<String>> eventbusSystemLogsAutocompleteOperationUsersGet({
    required String prefix,
  }) async {
    if (prefix.isEmpty) {
      throw ApiException(400, 'Missing required param: prefix');
    }
    final msg = {
      'service': 'SystemLogsService',
      'action': 'getOperationUserAutocompleteSuggestionsGlobally',
      'args': [prefix],
    };
    final respMap = await _apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      throw ApiException(400, respMap['error']);
    }
    final result = respMap['result'] as List<dynamic>?;
    if (result == null) return [];
    return result.cast<String>();
  }
}
