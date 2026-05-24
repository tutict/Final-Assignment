import 'package:final_assignment_front/features/model/login_log.dart';
import 'package:final_assignment_front/features/model/operation_log.dart';
import 'package:final_assignment_front/features/model/sys_request_history.dart';
import 'package:final_assignment_front/features/model/system_logs.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';

class SystemLogsControllerApi with BaseApiClient {
  final ApiClient _apiClient;

  SystemLogsControllerApi() : _apiClient = ApiClient();

  @override
  ApiClient get apiClient => _apiClient;

  Future<void> initializeWithJwt() => initializeClientWithJwt();

  Future<Map<String, dynamic>> getSystemLogsOverview() {
    return requestMap('GET', '/api/system/logs/overview');
  }

  Future<List<LoginLog>> listRecentLoginLogs({int limit = 10}) {
    return requestList(
      'GET',
      '/api/system/logs/login/recent',
      LoginLog.fromJson,
      queryParams: [QueryParam('limit', '$limit')],
    );
  }

  Future<List<OperationLog>> listRecentOperationLogs({int limit = 10}) {
    return requestList(
      'GET',
      '/api/system/logs/operation/recent',
      OperationLog.fromJson,
      queryParams: [QueryParam('limit', '$limit')],
    );
  }

  Future<SysRequestHistoryModel?> getRequestHistory({
    required int historyId,
  }) {
    return requestNullableObject(
      'GET',
      '/api/system/logs/requests/$historyId',
      SysRequestHistoryModel.fromJson,
    );
  }

  Future<List<SysRequestHistoryModel>> searchRequestHistoryByIdempotency({
    required String key,
    int page = 1,
    int size = 20,
  }) {
    return _searchRequestHistory(
      '/api/system/logs/requests/search/idempotency',
      {'key': key},
      page,
      size,
    );
  }

  Future<List<SysRequestHistoryModel>> searchRequestHistoryByMethod({
    required String requestMethod,
    int page = 1,
    int size = 20,
  }) {
    return _searchRequestHistory(
      '/api/system/logs/requests/search/method',
      {'requestMethod': requestMethod},
      page,
      size,
    );
  }

  Future<List<SysRequestHistoryModel>> searchRequestHistoryByUrl({
    required String requestUrl,
    int page = 1,
    int size = 20,
  }) {
    return _searchRequestHistory(
      '/api/system/logs/requests/search/url',
      {'requestUrl': requestUrl},
      page,
      size,
    );
  }

  Future<List<SysRequestHistoryModel>> searchRequestHistoryByBusinessType({
    required String businessType,
    int page = 1,
    int size = 20,
  }) {
    return _searchRequestHistory(
      '/api/system/logs/requests/search/business-type',
      {'businessType': businessType},
      page,
      size,
    );
  }

  Future<List<SysRequestHistoryModel>> searchRequestHistoryByBusinessId({
    required int businessId,
    int page = 1,
    int size = 20,
  }) {
    return _searchRequestHistory(
      '/api/system/logs/requests/search/business-id',
      {'businessId': businessId},
      page,
      size,
    );
  }

  Future<List<SysRequestHistoryModel>> searchRequestHistoryByStatus({
    required String status,
    int page = 1,
    int size = 20,
  }) {
    return _searchRequestHistory(
      '/api/system/logs/requests/search/status',
      {'status': status},
      page,
      size,
    );
  }

  Future<List<SysRequestHistoryModel>> searchRequestHistoryByUser({
    required int userId,
    int page = 1,
    int size = 20,
  }) {
    return _searchRequestHistory(
      '/api/system/logs/requests/search/user',
      {'userId': userId},
      page,
      size,
    );
  }

  Future<List<SysRequestHistoryModel>> searchRequestHistoryByIp({
    required String requestIp,
    int page = 1,
    int size = 20,
  }) {
    return _searchRequestHistory(
      '/api/system/logs/requests/search/ip',
      {'requestIp': requestIp},
      page,
      size,
    );
  }

  Future<List<SysRequestHistoryModel>> searchRequestHistoryByTimeRange({
    required String startTime,
    required String endTime,
    int page = 1,
    int size = 20,
  }) {
    return _searchRequestHistory(
      '/api/system/logs/requests/search/time-range',
      {'startTime': startTime, 'endTime': endTime},
      page,
      size,
    );
  }

  Future<List<SystemLogs>> eventbusSystemLogsGet() {
    return sendWsList(
      service: 'SystemLogsService',
      action: 'getAllSystemLogs',
      fromJson: SystemLogs.fromJson,
    );
  }

  Future<List<SysRequestHistoryModel>> _searchRequestHistory(
    String path,
    Map<String, Object?> filters,
    int page,
    int size,
  ) {
    return requestList(
      'GET',
      path,
      SysRequestHistoryModel.fromJson,
      queryParams: queryParamsFromMap({
        ...filters,
        'page': page,
        'size': size,
      }),
    );
  }
}
