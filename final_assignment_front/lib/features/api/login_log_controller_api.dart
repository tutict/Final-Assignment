import 'dart:convert';
import 'package:final_assignment_front/features/model/login_log.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginLogControllerApi {
  final ApiClient _apiClient;
  LoginLogControllerApi() : _apiClient = ApiClient();

  Future<void> initializeWithJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('JWT token not found in SharedPreferences');
    }
    _apiClient.setJwtToken(jwtToken);
  }

  String _decode(http.Response r) => r.body;

  // GET /api/logs/login
  Future<List<LoginLog>> apiLogsLoginGet() async {
    final r = await _apiClient.invokeAPI(
      '/api/logs/login',
      'GET',
      const [],
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

  // GET /api/logs/login/{logId}
  Future<LoginLog?> apiLogsLoginLogIdGet({required int logId}) async {
    final r = await _apiClient.invokeAPI(
      '/api/logs/login/$logId',
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
    return LoginLog.fromJson(jsonDecode(_decode(r)));
  }

  // POST /api/logs/login
  Future<LoginLog> apiLogsLoginPost({
    required LoginLog loginLog,
    required String idempotencyKey,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/logs/login',
      'POST',
      [QueryParam('idempotencyKey', idempotencyKey)],
      loginLog.toJson(),
      {},
      {},
      'application/json',
      const ['bearerAuth'],
    );
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    return LoginLog.fromJson(jsonDecode(_decode(r)));
  }

  // PUT /api/logs/login/{logId}
  Future<LoginLog> apiLogsLoginLogIdPut({
    required int logId,
    required LoginLog loginLog,
    required String idempotencyKey,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/logs/login/$logId',
      'PUT',
      [QueryParam('idempotencyKey', idempotencyKey)],
      loginLog.toJson(),
      {},
      {},
      'application/json',
      const ['bearerAuth'],
    );
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    return LoginLog.fromJson(jsonDecode(_decode(r)));
  }

  // DELETE /api/logs/login/{logId}
  Future<void> apiLogsLoginLogIdDelete({required int logId}) async {
    final r = await _apiClient.invokeAPI(
      '/api/logs/login/$logId',
      'DELETE',
      const [],
      null,
      {},
      {},
      null,
      const ['bearerAuth'],
    );
    if (r.statusCode != 204) throw ApiException(r.statusCode, _decode(r));
  }

  // GET /api/logs/login/search/username?username=&page=&size=
  Future<List<LoginLog>> apiLogsLoginSearchUsernameGet({
    required String username,
    int page = 1,
    int size = 20,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/logs/login/search/username',
      'GET',
      [
        QueryParam('username', username),
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
    return data.map((e) => LoginLog.fromJson(e as Map<String, dynamic>)).toList();
  }

  // GET /api/logs/login/search/result?result=&page=&size=
  Future<List<LoginLog>> apiLogsLoginSearchResultGet({
    required String result,
    int page = 1,
    int size = 20,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/logs/login/search/result',
      'GET',
      [
        QueryParam('result', result),
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
    return data.map((e) => LoginLog.fromJson(e as Map<String, dynamic>)).toList();
  }

  // GET /api/logs/login/search/time-range?startTime=&endTime=&page=&size=
  Future<List<LoginLog>> apiLogsLoginSearchTimeRangeGet({
    required String startTime,
    required String endTime,
    int page = 1,
    int size = 20,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/logs/login/search/time-range',
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
    return data.map((e) => LoginLog.fromJson(e as Map<String, dynamic>)).toList();
  }

  // GET /api/logs/login/search/ip?ip=&page=&size=
  Future<List<LoginLog>> apiLogsLoginSearchIpGet({
    required String ip,
    int page = 1,
    int size = 20,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/logs/login/search/ip',
      'GET',
      [
        QueryParam('ip', ip),
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
    return data.map((e) => LoginLog.fromJson(e as Map<String, dynamic>)).toList();
  }

  // GET /api/logs/login/search/location?loginLocation=&page=&size=
  Future<List<LoginLog>> apiLogsLoginSearchLocationGet({
    required String loginLocation,
    int page = 1,
    int size = 20,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/logs/login/search/location',
      'GET',
      [
        QueryParam('loginLocation', loginLocation),
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
    return data.map((e) => LoginLog.fromJson(e as Map<String, dynamic>)).toList();
  }

  // GET /api/logs/login/search/device-type?deviceType=&page=&size=
  Future<List<LoginLog>> apiLogsLoginSearchDeviceTypeGet({
    required String deviceType,
    int page = 1,
    int size = 20,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/logs/login/search/device-type',
      'GET',
      [
        QueryParam('deviceType', deviceType),
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
    return data.map((e) => LoginLog.fromJson(e as Map<String, dynamic>)).toList();
  }

  // GET /api/logs/login/search/browser-type?browserType=&page=&size=
  Future<List<LoginLog>> apiLogsLoginSearchBrowserTypeGet({
    required String browserType,
    int page = 1,
    int size = 20,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/logs/login/search/browser-type',
      'GET',
      [
        QueryParam('browserType', browserType),
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
    return data.map((e) => LoginLog.fromJson(e as Map<String, dynamic>)).toList();
  }

  // GET /api/logs/login/search/logout-time-range?startTime=&endTime=&page=&size=
  Future<List<LoginLog>> apiLogsLoginSearchLogoutTimeRangeGet({
    required String startTime,
    required String endTime,
    int page = 1,
    int size = 20,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/logs/login/search/logout-time-range',
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
    return data.map((e) => LoginLog.fromJson(e as Map<String, dynamic>)).toList();
  }
}
