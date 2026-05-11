import 'dart:convert';
import 'package:final_assignment_front/features/model/operation_log.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

class OperationLogControllerApi with BaseApiClient {
  final ApiClient _apiClient;
  OperationLogControllerApi() : _apiClient = ApiClient();

  @override
  ApiClient get apiClient => _apiClient;

  Future<void> initializeWithJwt() async {
    final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null) {
      throw Exception('JWT token not found in SharedPreferences');
    }
    _apiClient.setJwtToken(jwtToken);
  }

  String _decode(http.Response r) => decodeBodyBytes(r);

  // GET /api/logs/operation
  Future<List<OperationLog>> listOperationLogs() async {
    final r = await _apiClient.invokeAPI(
      '/api/logs/operation',
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
    return data
        .map((e) => OperationLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/logs/operation/{logId}
  Future<OperationLog?> getOperationLog({required int logId}) async {
    final r = await _apiClient.invokeAPI(
      '/api/logs/operation/$logId',
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
    return OperationLog.fromJson(jsonDecode(_decode(r)));
  }

  // POST /api/logs/operation
  Future<OperationLog> createOperationLog({
    required OperationLog operationLog,
    required String idempotencyKey,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/logs/operation',
      'POST',
      idempotencyParams(idempotencyKey),
      operationLog.toJson(),
      {},
      {},
      'application/json',
      const ['bearerAuth'],
    );
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    return OperationLog.fromJson(jsonDecode(_decode(r)));
  }

  // PUT /api/logs/operation/{logId}
  Future<OperationLog> updateOperationLog({
    required int logId,
    required OperationLog operationLog,
    required String idempotencyKey,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/logs/operation/$logId',
      'PUT',
      idempotencyParams(idempotencyKey),
      operationLog.toJson(),
      {},
      {},
      'application/json',
      const ['bearerAuth'],
    );
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    return OperationLog.fromJson(jsonDecode(_decode(r)));
  }

  // DELETE /api/logs/operation/{logId}
  Future<void> deleteOperationLog({required int logId}) async {
    final r = await _apiClient.invokeAPI(
      '/api/logs/operation/$logId',
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

  // GET /api/logs/operation/search/module?module=&page=&size=
  Future<List<OperationLog>> searchOperationLogsByModule({
    required String module,
    int page = 1,
    int size = 20,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/logs/operation/search/module',
      'GET',
      [
        QueryParam('module', module),
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
        .map((e) => OperationLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/logs/operation/search/type?type=&page=&size=
  Future<List<OperationLog>> searchOperationLogsByType({
    required String type,
    int page = 1,
    int size = 20,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/logs/operation/search/type',
      'GET',
      [
        QueryParam('type', type),
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
        .map((e) => OperationLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/logs/operation/search/user/{userId}?page=&size=
  Future<List<OperationLog>> searchOperationLogsByUser({
    required int userId,
    int page = 1,
    int size = 20,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/logs/operation/search/user/$userId',
      'GET',
      [
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
        .map((e) => OperationLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/logs/operation/search/time-range?startTime=&endTime=&page=&size=
  Future<List<OperationLog>> searchOperationLogsByTimeRange({
    required String startTime,
    required String endTime,
    int page = 1,
    int size = 20,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/logs/operation/search/time-range',
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
        .map((e) => OperationLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/logs/operation/search/username?username=&page=&size=
  Future<List<OperationLog>> searchOperationLogsByUsername({
    required String username,
    int page = 1,
    int size = 20,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/logs/operation/search/username',
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
    return data
        .map((e) => OperationLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/logs/operation/search/request-url?requestUrl=&page=&size=
  Future<List<OperationLog>> searchOperationLogsByRequestUrl({
    required String requestUrl,
    int page = 1,
    int size = 20,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/logs/operation/search/request-url',
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
        .map((e) => OperationLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/logs/operation/search/request-method?requestMethod=&page=&size=
  Future<List<OperationLog>> searchOperationLogsByRequestMethod({
    required String requestMethod,
    int page = 1,
    int size = 20,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/logs/operation/search/request-method',
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
        .map((e) => OperationLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/logs/operation/search/result?operationResult=&page=&size=
  Future<List<OperationLog>> searchOperationLogsByResult({
    required String operationResult,
    int page = 1,
    int size = 20,
  }) async {
    final r = await _apiClient.invokeAPI(
      '/api/logs/operation/search/result',
      'GET',
      [
        QueryParam('operationResult', operationResult),
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
        .map((e) => OperationLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
