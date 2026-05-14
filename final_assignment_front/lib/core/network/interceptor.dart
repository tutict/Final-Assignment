import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:final_assignment_front/core/auth/auth_service.dart';
import 'package:final_assignment_front/core/config/app_config.dart';
import 'package:final_assignment_front/features/model/operation_log.dart';
import 'package:final_assignment_front/features/model/system_logs.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'client_factory.dart' as client_factory;

class DeviceInfoService {
  DeviceInfoService({
    http.Client? client,
    this.cacheTtl = const Duration(minutes: 10),
  }) : _client = client ?? client_factory.createHttpClient();

  final http.Client _client;
  final Duration cacheTtl;
  String? _cachedPublicIp;
  DateTime? _cachedAt;

  Future<String> getPublicIp({bool forceRefresh = false}) async {
    final cachedIp = _cachedPublicIp;
    final cachedAt = _cachedAt;
    if (!forceRefresh &&
        cachedIp != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < cacheTtl) {
      return cachedIp;
    }

    const services = [
      'https://api.ipify.org?format=json',
      'https://ifconfig.me/ip',
    ];

    for (final service in services) {
      try {
        final response = await _client
            .get(Uri.parse(service))
            .timeout(const Duration(seconds: 5));
        if (response.statusCode != 200) {
          continue;
        }

        final ipAddress = service.contains('ipify')
            ? (jsonDecode(response.body) as Map<String, dynamic>)['ip']
                ?.toString()
            : response.body.trim();
        if (ipAddress != null && ipAddress.isNotEmpty) {
          _cachedPublicIp = ipAddress;
          _cachedAt = DateTime.now();
          return ipAddress;
        }
      } catch (error, stackTrace) {
        developer.log(
          'Failed to fetch public IP from $service',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    return 'Unknown';
  }

  void close() {
    _client.close();
  }
}

class LogEventWriter {
  LogEventWriter({
    required AuthService authService,
    required DeviceInfoService deviceInfoService,
    http.Client? client,
  })  : _authService = authService,
        _deviceInfoService = deviceInfoService,
        _client = client ?? client_factory.createHttpClient();

  final AuthService _authService;
  final DeviceInfoService _deviceInfoService;
  final http.Client _client;
  final Uuid _uuid = const Uuid();

  Future<void> writeSystemEvent({
    required String logType,
    required String content,
    String? remarks,
    String? operationUser,
    String? ipAddress,
  }) async {
    try {
      final token = await _authService.getValidJwtToken();
      if (token == null || token.isEmpty) return;

      final user = await _authService.currentUser(refreshIfNeeded: false);
      final idempotencyKey = _uuid.v4();
      final logEntry = SystemLogs(
        logType: logType,
        logContent: content,
        operationUser: operationUser ?? user?.username ?? 'Unknown',
        operationIpAddress: ipAddress ?? await _deviceInfoService.getPublicIp(),
        operationTime: DateTime.now(),
        remarks: remarks,
        idempotencyKey: idempotencyKey,
      );
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/system/logs')
          .replace(queryParameters: {'idempotencyKey': idempotencyKey});

      final response = await _client
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(logEntry.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 401) {
        await _authService.handleUnauthorized(source: uri.path);
      } else if (response.statusCode >= 400) {
        developer.log(
          'Failed to write system log: ${response.statusCode} ${response.body}',
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        'Failed to write system event',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> writeOperationEvent({
    required String content,
    String result = 'Success',
    String? type,
    String? module,
    String? function,
    String? requestMethod,
    String? requestUrl,
    String? requestParams,
    String? responseData,
    String? errorMessage,
    int? executionTime,
    String? remarks,
    String? ipAddress,
  }) async {
    try {
      final token = await _authService.getValidJwtToken();
      if (token == null || token.isEmpty) return;

      final user = await _authService.currentUser(refreshIfNeeded: false);
      if (user?.userId == null) {
        return;
      }

      final operationLog = OperationLog(
        operationType: type,
        operationModule: module,
        operationFunction: function,
        operationContent: content,
        operationTime: DateTime.now(),
        userId: user!.userId,
        username: user.username,
        requestMethod: requestMethod,
        requestUrl: requestUrl,
        requestParams: requestParams,
        requestIp: ipAddress ?? await _deviceInfoService.getPublicIp(),
        operationResult: result,
        responseData: responseData,
        errorMessage: errorMessage,
        executionTime: executionTime,
        remarks: remarks,
      );
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/logs/operation')
          .replace(queryParameters: {'idempotencyKey': _uuid.v4()});

      final response = await _client
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(operationLog.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 401) {
        await _authService.handleUnauthorized(source: uri.path);
      } else if (response.statusCode >= 400) {
        developer.log(
          'Failed to write operation log: ${response.statusCode} ${response.body}',
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        'Failed to write operation event',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> writeApiRequest({
    required Uri uri,
    required String method,
    required int elapsedMilliseconds,
    int? statusCode,
    Object? error,
  }) async {
    final failed = error != null || (statusCode != null && statusCode >= 400);
    final statusText = statusCode == null ? 'unknown' : statusCode.toString();
    final content = 'API $method ${uri.path} completed with $statusText';
    final errorMessage = error?.toString();
    final ipAddress = await _deviceInfoService.getPublicIp();

    await Future.wait([
      writeSystemEvent(
        logType: failed ? 'API_ERROR' : 'API_CALL',
        content: content,
        remarks: errorMessage,
        ipAddress: ipAddress,
      ),
      writeOperationEvent(
        type: 'API',
        module: 'Network',
        function: method,
        content: content,
        result: failed ? 'Failed' : 'Success',
        requestMethod: method,
        requestUrl: uri.toString(),
        requestParams: uri.query.isEmpty ? null : uri.query,
        errorMessage: errorMessage,
        executionTime: elapsedMilliseconds,
        ipAddress: ipAddress,
      ),
    ]);
  }

  void close() {
    _client.close();
  }
}

class ApiRequestLoggingInterceptor extends GetxService {
  ApiRequestLoggingInterceptor({
    required this.authService,
    DeviceInfoService? deviceInfoService,
    LogEventWriter? logWriter,
  }) {
    this.deviceInfoService = deviceInfoService ?? DeviceInfoService();
    this.logWriter = logWriter ??
        LogEventWriter(
          authService: authService,
          deviceInfoService: this.deviceInfoService,
        );
  }

  final AuthService authService;
  late final DeviceInfoService deviceInfoService;
  late final LogEventWriter logWriter;

  http.Client wrap(http.Client inner) {
    return _InterceptedHttpClient(inner, this);
  }

  Future<void> recordResponse({
    required Uri uri,
    required String method,
    required int statusCode,
    required int elapsedMilliseconds,
  }) async {
    if (!_shouldLog(uri)) return;
    await logWriter.writeApiRequest(
      uri: uri,
      method: method,
      statusCode: statusCode,
      elapsedMilliseconds: elapsedMilliseconds,
    );
  }

  Future<void> recordError({
    required Uri uri,
    required String method,
    required Object error,
    required int elapsedMilliseconds,
  }) async {
    if (!_shouldLog(uri)) return;
    await logWriter.writeApiRequest(
      uri: uri,
      method: method,
      error: error,
      elapsedMilliseconds: elapsedMilliseconds,
    );
  }

  bool _shouldLog(Uri uri) {
    if (!_isApiBaseUri(uri)) return false;
    if (_isAuthRefresh(uri)) return false;
    if (uri.path.startsWith('/api/logs') ||
        uri.path.startsWith('/api/system/logs')) {
      return false;
    }
    return true;
  }

  bool _isApiBaseUri(Uri uri) {
    final apiBaseUri = Uri.parse(AppConfig.apiBaseUrl);
    return uri.scheme == apiBaseUri.scheme &&
        uri.host == apiBaseUri.host &&
        uri.port == apiBaseUri.port;
  }

  bool _isAuthRefresh(Uri uri) {
    return uri.path == '/api/auth/refresh';
  }

  @override
  void onClose() {
    logWriter.close();
    deviceInfoService.close();
    super.onClose();
  }
}

class _InterceptedHttpClient extends http.BaseClient {
  _InterceptedHttpClient(this._inner, this._interceptor);

  final http.Client _inner;
  final ApiRequestLoggingInterceptor _interceptor;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _inner.send(request);
      stopwatch.stop();
      unawaited(
        _interceptor.recordResponse(
          uri: request.url,
          method: request.method,
          statusCode: response.statusCode,
          elapsedMilliseconds: stopwatch.elapsedMilliseconds,
        ),
      );
      return response;
    } catch (error) {
      stopwatch.stop();
      unawaited(
        _interceptor.recordError(
          uri: request.url,
          method: request.method,
          error: error,
          elapsedMilliseconds: stopwatch.elapsedMilliseconds,
        ),
      );
      rethrow;
    }
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
