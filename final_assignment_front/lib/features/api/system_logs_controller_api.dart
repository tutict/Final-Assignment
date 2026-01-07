import 'dart:convert';
import 'package:final_assignment_front/features/model/login_log.dart';
import 'package:final_assignment_front/features/model/operation_log.dart';
import 'package:final_assignment_front/features/model/sys_request_history.dart';
import 'package:final_assignment_front/features/model/system_logs.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';
import 'package:http/http.dart' as http;

class SystemLogsControllerApi {
  final ApiClient _apiClient;

  SystemLogsControllerApi() : _apiClient = ApiClient();

  Future<void> initializeWithJwt() async {
      final jwtToken = (await AuthTokenStore.instance.getJwtToken());
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

  // GET /api/system/logs/requests/search/idempotency
  Future<List<SysRequestHistoryModel>> apiSystemLogsRequestsSearchIdempotencyGet({
    required String key,
    int page = 1,
    int size = 20,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/system/logs/requests/search/idempotency',
      'GET',
      [
        QueryParam('key', key),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
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
        .map((e) => SysRequestHistoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/system/logs/requests/search/method
  Future<List<SysRequestHistoryModel>> apiSystemLogsRequestsSearchMethodGet({
    required String requestMethod,
    int page = 1,
    int size = 20,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/system/logs/requests/search/method',
      'GET',
      [
        QueryParam('requestMethod', requestMethod),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
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
        .map((e) => SysRequestHistoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/system/logs/requests/search/url
  Future<List<SysRequestHistoryModel>> apiSystemLogsRequestsSearchUrlGet({
    required String requestUrl,
    int page = 1,
    int size = 20,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/system/logs/requests/search/url',
      'GET',
      [
        QueryParam('requestUrl', requestUrl),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
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
        .map((e) => SysRequestHistoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/system/logs/requests/search/business-type
  Future<List<SysRequestHistoryModel>> apiSystemLogsRequestsSearchBusinessTypeGet({
    required String businessType,
    int page = 1,
    int size = 20,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/system/logs/requests/search/business-type',
      'GET',
      [
        QueryParam('businessType', businessType),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
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
        .map((e) => SysRequestHistoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/system/logs/requests/search/business-id
  Future<List<SysRequestHistoryModel>> apiSystemLogsRequestsSearchBusinessIdGet({
    required int businessId,
    int page = 1,
    int size = 20,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/system/logs/requests/search/business-id',
      'GET',
      [
        QueryParam('businessId', '$businessId'),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
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
        .map((e) => SysRequestHistoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/system/logs/requests/search/status
  Future<List<SysRequestHistoryModel>> apiSystemLogsRequestsSearchStatusGet({
    required String status,
    int page = 1,
    int size = 20,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/system/logs/requests/search/status',
      'GET',
      [
        QueryParam('status', status),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
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
        .map((e) => SysRequestHistoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/system/logs/requests/search/user
  Future<List<SysRequestHistoryModel>> apiSystemLogsRequestsSearchUserGet({
    required int userId,
    int page = 1,
    int size = 20,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/system/logs/requests/search/user',
      'GET',
      [
        QueryParam('userId', '$userId'),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
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
        .map((e) => SysRequestHistoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/system/logs/requests/search/ip
  Future<List<SysRequestHistoryModel>> apiSystemLogsRequestsSearchIpGet({
    required String requestIp,
    int page = 1,
    int size = 20,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/system/logs/requests/search/ip',
      'GET',
      [
        QueryParam('requestIp', requestIp),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
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
        .map((e) => SysRequestHistoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/system/logs/requests/search/time-range
  Future<List<SysRequestHistoryModel>> apiSystemLogsRequestsSearchTimeRangeGet({
    required String startTime,
    required String endTime,
    int page = 1,
    int size = 20,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/system/logs/requests/search/time-range',
      'GET',
      [
        QueryParam('startTime', startTime),
        QueryParam('endTime', endTime),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
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
        .map((e) => SysRequestHistoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
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
