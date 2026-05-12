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

class SystemLogsControllerApi with BaseApiClient {
  final ApiClient _apiClient;

  SystemLogsControllerApi() : _apiClient = ApiClient();

  @override
  ApiClient get apiClient => _apiClient;

  /// 使用当前登录态初始化系统日志 API 客户端的 JWT。
  ///
  /// 调用日志查询接口前应先完成初始化，确保后续请求携带 bearer token。
  ///
  /// 抛出 [Exception]：当本地登录态无有效 JWT 时。
  Future<void> initializeWithJwt() async {
    final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null) {
      throw Exception('JWT token not found in SharedPreferences');
    }
    _apiClient.setJwtToken(jwtToken);
    debugPrint('Initialized SystemLogsControllerApi with token: $jwtToken');
  }

  String _decode(http.Response r) => decodeBodyBytes(r);

  // GET /api/system/logs/overview
  /// 获取系统日志概览数据。
  ///
  /// 返回概览统计 Map；后端返回空响应时返回空 Map。
  ///
  /// 抛出 [ApiException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/system/logs/overview
  Future<Map<String, dynamic>> getSystemLogsOverview() async {
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
  /// 获取最近登录日志列表。
  ///
  /// [limit] 返回的最近登录日志条数，默认 10。
  ///
  /// 返回 [LoginLog] 列表；无数据时返回空列表。
  ///
  /// 抛出 [ApiException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/system/logs/login/recent
  Future<List<LoginLog>> listRecentLoginLogs({int limit = 10}) async {
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
    return data
        .map((e) => LoginLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/system/logs/operation/recent?limit=10
  /// 获取最近操作日志列表。
  ///
  /// [limit] 返回的最近操作日志条数，默认 10。
  ///
  /// 返回 [OperationLog] 列表；无数据时返回空列表。
  ///
  /// 抛出 [ApiException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/system/logs/operation/recent
  Future<List<OperationLog>> listRecentOperationLogs({int limit = 10}) async {
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
  /// 根据请求历史 ID 获取单条请求审计记录。
  ///
  /// [historyId] 请求历史主键。
  ///
  /// 返回 [SysRequestHistoryModel]；后端返回 404 或空响应时返回 `null`。
  ///
  /// 抛出 [ApiException]：当 HTTP 响应非 2xx 且不是 404 时。
  ///
  /// 对应接口：GET /api/system/logs/requests/{historyId}
  Future<SysRequestHistoryModel?> getRequestHistory({
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
  /// 按幂等键搜索请求历史。
  ///
  /// [key] 幂等键查询值。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [SysRequestHistoryModel] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [ApiException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/system/logs/requests/search/idempotency
  Future<List<SysRequestHistoryModel>> searchRequestHistoryByIdempotency({
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
  /// 按 HTTP 方法搜索请求历史。
  ///
  /// [requestMethod] HTTP 方法，例如 GET、POST、PUT、DELETE。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [SysRequestHistoryModel] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [ApiException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/system/logs/requests/search/method
  Future<List<SysRequestHistoryModel>> searchRequestHistoryByMethod({
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
  /// 按请求 URL 搜索请求历史。
  ///
  /// [requestUrl] 请求 URL 或 URL 片段，匹配规则由后端定义。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [SysRequestHistoryModel] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [ApiException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/system/logs/requests/search/url
  Future<List<SysRequestHistoryModel>> searchRequestHistoryByUrl({
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
  /// 按业务类型搜索请求历史。
  ///
  /// [businessType] 业务类型标识。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [SysRequestHistoryModel] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [ApiException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/system/logs/requests/search/business-type
  Future<List<SysRequestHistoryModel>> searchRequestHistoryByBusinessType({
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
  /// 按业务记录 ID 搜索请求历史。
  ///
  /// [businessId] 业务记录主键。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [SysRequestHistoryModel] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [ApiException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/system/logs/requests/search/business-id
  Future<List<SysRequestHistoryModel>> searchRequestHistoryByBusinessId({
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
  /// 按业务处理状态搜索请求历史。
  ///
  /// [status] 业务层状态，区别于 HTTP 状态码。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [SysRequestHistoryModel] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [ApiException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/system/logs/requests/search/status
  Future<List<SysRequestHistoryModel>> searchRequestHistoryByStatus({
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
  /// 按用户 ID 搜索请求历史。
  ///
  /// [userId] 发起请求的用户主键。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [SysRequestHistoryModel] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [ApiException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/system/logs/requests/search/user
  Future<List<SysRequestHistoryModel>> searchRequestHistoryByUser({
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
  /// 按请求 IP 搜索请求历史。
  ///
  /// [requestIp] 发起请求的客户端 IP。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [SysRequestHistoryModel] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [ApiException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/system/logs/requests/search/ip
  Future<List<SysRequestHistoryModel>> searchRequestHistoryByIp({
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
  /// 按请求时间范围搜索请求历史。
  ///
  /// [startTime] 查询开始时间。
  /// [endTime] 查询结束时间。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [SysRequestHistoryModel] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [ApiException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/system/logs/requests/search/time-range
  Future<List<SysRequestHistoryModel>> searchRequestHistoryByTimeRange({
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
  /// @realtimeApi
  /// 通过 WebSocket eventbus 获取系统日志列表。
  ///
  /// 返回 [SystemLogs] 列表；eventbus result 为空时返回空列表。
  ///
  /// 抛出 [ApiException]：当 WebSocket 响应包含 `error` 字段时。
  ///
  /// 对应实时动作：SystemLogsService.getAllSystemLogs
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
