import 'package:final_assignment_front/features/model/login_log.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';

class LoginLogControllerApi with BaseApiClient {
  LoginLogControllerApi([ApiClient? apiClient])
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  ApiClient get apiClient => _apiClient;

  Future<void> initializeWithJwt() => initializeClientWithJwt();

  Future<List<LoginLog>> listLoginLogs() {
    return requestList('GET', '/api/logs/login', LoginLog.fromJson);
  }

  Future<LoginLog?> getLoginLog({required int logId}) {
    return requestNullableObject(
      'GET',
      '/api/logs/login/$logId',
      LoginLog.fromJson,
    );
  }

  Future<LoginLog> createLoginLog({
    required LoginLog loginLog,
    required String idempotencyKey,
  }) {
    requireNotBlank(idempotencyKey, 'idempotencyKey');
    return requestObject(
      'POST',
      '/api/logs/login',
      LoginLog.fromJson,
      body: loginLog.toJson(),
      contentType: 'application/json',
      idempotencyKey: idempotencyKey,
    );
  }

  Future<LoginLog> updateLoginLog({
    required int logId,
    required LoginLog loginLog,
    required String idempotencyKey,
  }) {
    requireNotBlank(idempotencyKey, 'idempotencyKey');
    return requestObject(
      'PUT',
      '/api/logs/login/$logId',
      LoginLog.fromJson,
      body: loginLog.toJson(),
      contentType: 'application/json',
      idempotencyKey: idempotencyKey,
    );
  }

  Future<void> deleteLoginLog({required int logId}) {
    return requestVoid('DELETE', '/api/logs/login/$logId');
  }

  Future<List<LoginLog>> searchLoginLogsByUsername({
    required String username,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(username, 'username');
    return _search('/api/logs/login/search/username', {
      'username': username,
      'page': page,
      'size': size,
    });
  }

  Future<List<LoginLog>> searchLoginLogsByResult({
    required String result,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(result, 'result');
    return _search('/api/logs/login/search/result', {
      'result': result,
      'page': page,
      'size': size,
    });
  }

  Future<List<LoginLog>> searchLoginLogsByTimeRange({
    required String startTime,
    required String endTime,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(startTime, 'startTime');
    requireNotBlank(endTime, 'endTime');
    return _search('/api/logs/login/search/time-range', {
      'startTime': startTime,
      'endTime': endTime,
      'page': page,
      'size': size,
    });
  }

  Future<List<LoginLog>> searchLoginLogsByIp({
    required String ip,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(ip, 'ip');
    return _search('/api/logs/login/search/ip', {
      'ip': ip,
      'page': page,
      'size': size,
    });
  }

  Future<List<LoginLog>> searchLoginLogsByLocation({
    required String loginLocation,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(loginLocation, 'loginLocation');
    return _search('/api/logs/login/search/location', {
      'loginLocation': loginLocation,
      'page': page,
      'size': size,
    });
  }

  Future<List<LoginLog>> searchLoginLogsByDeviceType({
    required String deviceType,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(deviceType, 'deviceType');
    return _search('/api/logs/login/search/device-type', {
      'deviceType': deviceType,
      'page': page,
      'size': size,
    });
  }

  Future<List<LoginLog>> searchLoginLogsByBrowserType({
    required String browserType,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(browserType, 'browserType');
    return _search('/api/logs/login/search/browser-type', {
      'browserType': browserType,
      'page': page,
      'size': size,
    });
  }

  Future<List<LoginLog>> searchLoginLogsByLogoutTimeRange({
    required String startTime,
    required String endTime,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(startTime, 'startTime');
    requireNotBlank(endTime, 'endTime');
    return _search('/api/logs/login/search/logout-time-range', {
      'startTime': startTime,
      'endTime': endTime,
      'page': page,
      'size': size,
    });
  }

  Future<List<LoginLog>> _search(
    String path,
    Map<String, Object?> params,
  ) {
    return requestList(
      'GET',
      path,
      LoginLog.fromJson,
      queryParams: queryParamsFromMap(params),
    );
  }
}
