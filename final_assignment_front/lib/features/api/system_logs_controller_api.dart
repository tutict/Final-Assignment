import 'dart:convert';
import 'package:final_assignment_front/features/model/login_log.dart';
import 'package:final_assignment_front/features/model/operation_log.dart';
import 'package:final_assignment_front/features/model/sys_request_history.dart';
import 'package:final_assignment_front/features/model/system_logs.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SystemLogsControllerApi {
  final ApiClient _apiClient;

  SystemLogsControllerApi() : _apiClient = ApiClient();

  Future<void> initializeWithJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('JWT token not found in SharedPreferences');
    }
    _apiClient.setJwtToken(jwtToken);
    debugPrint('Initialized SystemLogsControllerApi with token: $jwtToken');
  }

  String _decode(http.Response r) => r.body;

  // GET /api/system/logs/overview
  Future<Map<String, dynamic>> apiSystemLogsOverviewGet() async {
    final r = await _apiClient.invokeAPI(
      '/api/system/logs/overview',
      'GET',
      const [],
      null,
      {},
      {},
      null,
      const ['bearerAuth'],
    );
    if (r.statusCode >= 400) {
      throw ApiException(r.statusCode, _decode(r));
    }
    if (r.body.isEmpty) return {};
    return jsonDecode(_decode(r)) as Map<String, dynamic>;
  }

  // GET /api/system/logs/login/recent?limit=10
  Future<List<LoginLog>> apiSystemLogsLoginRecentGet({int limit = 10}) async {
    final r = await _apiClient.invokeAPI(
      '/api/system/logs/login/recent',
      'GET',
      [QueryParam('limit', '$limit')],
      null,
      {},
      {},
      null,
      const ['bearerAuth'],
    );
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    if (r.body.isEmpty) return [];
    final List<dynamic> data = jsonDecode(_decode(r));
    return data.map((e) => LoginLog.fromJson(e as Map<String, dynamic>)).toList();
  }

  // GET /api/system/logs/operation/recent?limit=10
  Future<List<OperationLog>> apiSystemLogsOperationRecentGet({int limit = 10}) async {
    final r = await _apiClient.invokeAPI(
      '/api/system/logs/operation/recent',
      'GET',
      [QueryParam('limit', '$limit')],
      null,
      {},
      {},
      null,
      const ['bearerAuth'],
    );
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    if (r.body.isEmpty) return [];
    final List<dynamic> data = jsonDecode(_decode(r));
    return data
        .map((e) => OperationLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/system/logs/requests/{historyId}
  Future<SysRequestHistoryModel?> apiSystemLogsRequestsHistoryIdGet({
    required int historyId,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/system/logs/requests/$historyId',
      'GET',
      const [],
      null,
      {},
      {},
      null,
      const ['bearerAuth'],
    );
    if (r.statusCode == 404) return null;
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    if (r.body.isEmpty) return null;
    return SysRequestHistoryModel.fromJson(jsonDecode(_decode(r)));
  }

  // 以下 WebSocket 示例保留
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
}

