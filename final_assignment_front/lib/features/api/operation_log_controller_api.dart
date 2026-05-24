import 'package:final_assignment_front/features/model/operation_log.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';

class OperationLogControllerApi with BaseApiClient {
  OperationLogControllerApi([ApiClient? apiClient])
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  ApiClient get apiClient => _apiClient;

  Future<void> initializeWithJwt() => initializeClientWithJwt();

  Future<List<OperationLog>> listOperationLogs() {
    return requestList('GET', '/api/logs/operation', OperationLog.fromJson);
  }

  Future<OperationLog?> getOperationLog({required int logId}) {
    return requestNullableObject(
      'GET',
      '/api/logs/operation/$logId',
      OperationLog.fromJson,
    );
  }

  Future<OperationLog> createOperationLog({
    required OperationLog operationLog,
    required String idempotencyKey,
  }) {
    requireNotBlank(idempotencyKey, 'idempotencyKey');
    return requestObject(
      'POST',
      '/api/logs/operation',
      OperationLog.fromJson,
      body: operationLog.toJson(),
      contentType: 'application/json',
      idempotencyKey: idempotencyKey,
    );
  }

  Future<OperationLog> updateOperationLog({
    required int logId,
    required OperationLog operationLog,
    required String idempotencyKey,
  }) {
    requireNotBlank(idempotencyKey, 'idempotencyKey');
    return requestObject(
      'PUT',
      '/api/logs/operation/$logId',
      OperationLog.fromJson,
      body: operationLog.toJson(),
      contentType: 'application/json',
      idempotencyKey: idempotencyKey,
    );
  }

  Future<void> deleteOperationLog({required int logId}) {
    return requestVoid('DELETE', '/api/logs/operation/$logId');
  }

  Future<List<OperationLog>> searchOperationLogsByModule({
    required String module,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(module, 'module');
    return _search('/api/logs/operation/search/module', {
      'module': module,
      'page': page,
      'size': size,
    });
  }

  Future<List<OperationLog>> searchOperationLogsByType({
    required String type,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(type, 'type');
    return _search('/api/logs/operation/search/type', {
      'type': type,
      'page': page,
      'size': size,
    });
  }

  Future<List<OperationLog>> searchOperationLogsByUser({
    required int userId,
    int page = 1,
    int size = 20,
  }) {
    return requestList(
      'GET',
      '/api/logs/operation/search/user/$userId',
      OperationLog.fromJson,
      queryParams: pageParams(page, size),
    );
  }

  Future<List<OperationLog>> searchOperationLogsByTimeRange({
    required String startTime,
    required String endTime,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(startTime, 'startTime');
    requireNotBlank(endTime, 'endTime');
    return _search('/api/logs/operation/search/time-range', {
      'startTime': startTime,
      'endTime': endTime,
      'page': page,
      'size': size,
    });
  }

  Future<List<OperationLog>> searchOperationLogsByUsername({
    required String username,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(username, 'username');
    return _search('/api/logs/operation/search/username', {
      'username': username,
      'page': page,
      'size': size,
    });
  }

  Future<List<OperationLog>> searchOperationLogsByRequestUrl({
    required String requestUrl,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(requestUrl, 'requestUrl');
    return _search('/api/logs/operation/search/request-url', {
      'requestUrl': requestUrl,
      'page': page,
      'size': size,
    });
  }

  Future<List<OperationLog>> searchOperationLogsByRequestMethod({
    required String requestMethod,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(requestMethod, 'requestMethod');
    return _search('/api/logs/operation/search/request-method', {
      'requestMethod': requestMethod,
      'page': page,
      'size': size,
    });
  }

  Future<List<OperationLog>> searchOperationLogsByResult({
    required String operationResult,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(operationResult, 'operationResult');
    return _search('/api/logs/operation/search/result', {
      'operationResult': operationResult,
      'page': page,
      'size': size,
    });
  }

  Future<List<OperationLog>> _search(
    String path,
    Map<String, Object?> params,
  ) {
    return requestList(
      'GET',
      path,
      OperationLog.fromJson,
      queryParams: queryParamsFromMap(params),
    );
  }
}
