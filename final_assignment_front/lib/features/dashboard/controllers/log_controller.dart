import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:final_assignment_front/features/api/operation_log_controller_api.dart';
import 'package:final_assignment_front/features/api/system_logs_controller_api.dart';
import 'package:final_assignment_front/features/model/operation_log.dart';
import 'package:final_assignment_front/features/model/system_logs.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class LogController extends GetxController with WidgetsBindingObserver {
  final OperationLogControllerApi _operationLogApi =
      OperationLogControllerApi();
  final SystemLogsControllerApi _systemLogApi = SystemLogsControllerApi();
  String? _currentUsername;
  int? _currentUserId;
  String? _currentIpAddress;
  bool _isInitialized = false;
  bool _isRedirecting = false;

  Future<void> get initialization => _initialize();

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _initialize().then((_) {
      _logAppStartup();
    }).catchError((e) {
      developer.log('LogController initialization failed: $e',
          stackTrace: StackTrace.current);
      _logSystemError(
        error: 'Initialization failed: $e',
        stackTrace: StackTrace.current.toString(),
      );
    });
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_isInitialized) {
      _logAppLifecycleEvent(state);
    }
  }

  Future<void> _initialize() async {
    try {
// Prioritize JWT validation
      if (!await _validateJwtToken()) {
        developer.log('No valid JWT token, scheduling redirect to login');
        await _deferNavigationToLogin();
        return;
      }
// Fetch userId if missing
      if (_currentUserId == null) {
        await _fetchUserId();
      }
// Fetch IP address after username is set
      await _fetchIpAddress();
// Initialize APIs
      await _operationLogApi.initializeWithJwt();
      await _systemLogApi.initializeWithJwt();
      _isInitialized = true;
      developer.log(
          'LogController initialized with username: $_currentUsername, userId: $_currentUserId, IP: $_currentIpAddress');
    } catch (e) {
      _isInitialized = false;
      developer.log('Initialization error: $e', stackTrace: StackTrace.current);
      _currentUsername ??= 'Unknown';
      _currentIpAddress ??= 'Unknown';
      await _deferNavigationToLogin();
    }
  }

  Future<void> _fetchUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        developer.log('No JWT token for fetching userId');
        return;
      }
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/users/me'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _currentUserId = userData['userId'] != null
            ? int.tryParse(userData['userId'].toString())
            : null;
        developer.log('Fetched userId: $_currentUserId from /api/users/me');
      } else {
        developer.log('Failed to fetch userId: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching userId: $e',
          stackTrace: StackTrace.current);
    }
  }

  Future<void> _deferNavigationToLogin() async {
    if (_isRedirecting || Get.currentRoute == '/login') {
      developer
          .log('Already redirecting or on login route, skipping navigation');
      return;
    }
    _isRedirecting = true;
// Wait for context up to 5 seconds
    for (int i = 0; i < 50; i++) {
      if (Get.context != null && Get.currentRoute != '/login') {
        Get.offAllNamed('/login');
        developer.log('Navigated to login route');
        break;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (Get.context == null) {
      developer.log('Failed to navigate to login: context unavailable');
    }
    _isRedirecting = false;
  }

  Future<void> _logAppStartup() async {
    if (!_isInitialized) {
      developer.log('Cannot log app startup: LogController not initialized');
      return;
    }
    const maxRetries = 3;
    String idempotencyKey = _generateIdempotencyKey();

// Log to system_logs
    final systemLog = SystemLogs(
      logType: 'SYSTEM_EVENT',
      logContent: 'Application Started',
      operationUser: _currentUsername ?? 'Unknown',
      operationTime: DateTime.now(),
      operationIpAddress: _currentIpAddress,
      remarks: 'Traffic Violation Management System started',
      idempotencyKey: idempotencyKey,
    );
    try {
      await _systemLogApi.apiSystemLogsPost(
        systemLogs: systemLog,
        idempotencyKey: idempotencyKey,
      );
      developer.log('Logged application startup to system_logs');
    } catch (e) {
      developer.log('Failed to log app startup to system_logs: $e',
          stackTrace: StackTrace.current);
      if (e is ApiException && e.code == 403) {
        developer.log(
            'Permission denied for system log creation, attempting token refresh');
        await _handle403Error();
      }
    }

// Log to operation_logs with retry
    if (_currentUserId != null) {
      final operationLog = OperationLog(
        userId: _currentUserId,
        operationContent: 'Application Started',
        operationResult: 'Success',
        operationTime: DateTime.now(),
        operationIpAddress: _currentIpAddress,
        remarks: 'User launched the app',
        idempotencyKey: idempotencyKey,
      );
      for (int attempt = 0; attempt < maxRetries; attempt++) {
        try {
          await _operationLogApi.apiOperationLogsPost(
            operationLog: operationLog,
            idempotencyKey: idempotencyKey,
          );
          developer.log('Logged application startup to operation_logs');
          return;
        } catch (e) {
          if (e is ApiException &&
              e.code == 500 &&
              e.message.contains('Duplicate request detected')) {
            developer.log(
                'Duplicate request detected for operation log, retrying with new idempotencyKey (attempt ${attempt + 1}/$maxRetries)');
            idempotencyKey = _generateIdempotencyKey();
            operationLog.idempotencyKey = idempotencyKey;
            await Future.delayed(Duration(milliseconds: 100 * (attempt + 1)));
          } else {
            developer.log('Failed to log app startup to operation_logs: $e',
                stackTrace: StackTrace.current);
            if (e is ApiException && e.code == 403) {
              developer.log(
                  'Permission denied for operation log creation, attempting token refresh');
              await _handle403Error();
            }
            break;
          }
        }
      }
    } else {
      developer.log('Skipped operation log for app startup: userId is null');
    }
  }

  Future<void> _logAppLifecycleEvent(AppLifecycleState state) async {
    const maxRetries = 3;
    String idempotencyKey = _generateIdempotencyKey();
    final logContent = 'App Lifecycle: ${state.toString().split('.').last}';

// Log to system_logs
    final systemLog = SystemLogs(
      logType: 'APP_LIFECYCLE',
      logContent: logContent,
      operationUser: _currentUsername ?? 'Unknown',
      operationTime: DateTime.now(),
      operationIpAddress: _currentIpAddress,
      remarks: null,
      idempotencyKey: idempotencyKey,
    );
    try {
      await _systemLogApi.apiSystemLogsPost(
        systemLogs: systemLog,
        idempotencyKey: idempotencyKey,
      );
      developer.log('Logged app lifecycle event to system_logs: $logContent');
    } catch (e) {
      developer.log('Failed to log app lifecycle event to system_logs: $e',
          stackTrace: StackTrace.current);
      if (e is ApiException && e.code == 403) {
        developer.log(
            'Permission denied for system log creation, attempting token refresh');
        await _handle403Error();
      }
    }

// Log to operation_logs with retry
    if (_currentUserId != null) {
      final operationLog = OperationLog(
        userId: _currentUserId,
        operationContent: 'App Lifecycle Changed',
        operationResult: 'Success',
        operationTime: DateTime.now(),
        operationIpAddress: _currentIpAddress,
        remarks: logContent,
        idempotencyKey: idempotencyKey,
      );
      for (int attempt = 0; attempt < maxRetries; attempt++) {
        try {
          await _operationLogApi.apiOperationLogsPost(
            operationLog: operationLog,
            idempotencyKey: idempotencyKey,
          );
          developer
              .log('Logged app lifecycle event to operation_logs: $logContent');
          return;
        } catch (e) {
          if (e is ApiException &&
              e.code == 500 &&
              e.message.contains('Duplicate request detected')) {
            developer.log(
                'Duplicate request detected for operation log, retrying with new idempotencyKey (attempt ${attempt + 1}/$maxRetries)');
            idempotencyKey = _generateIdempotencyKey();
            operationLog.idempotencyKey = idempotencyKey;
            await Future.delayed(Duration(milliseconds: 100 * (attempt + 1)));
          } else {
            developer.log(
                'Failed to log app lifecycle event to operation_logs: $e',
                stackTrace: StackTrace.current);
            if (e is ApiException && e.code == 403) {
              developer.log(
                  'Permission denied for operation log creation, attempting token refresh');
              await _handle403Error();
            }
            break;
          }
        }
      }
    } else {
      developer
          .log('Skipped operation log for lifecycle event: userId is null');
    }
  }

  Future<void> _logSystemError({
    required String error,
    String? stackTrace,
    String? remarks,
  }) async {
    if (!_isInitialized) {
      developer.log('Cannot log system error: LogController not initialized');
      return;
    }
    const maxRetries = 3;
    String idempotencyKey = _generateIdempotencyKey();

// Log to system_logs
    final systemLog = SystemLogs(
      logType: 'SYSTEM_ERROR',
      logContent: error,
      operationUser: _currentUsername ?? 'Unknown',
      operationTime: DateTime.now(),
      operationIpAddress: _currentIpAddress,
      remarks: stackTrace ?? remarks,
      idempotencyKey: idempotencyKey,
    );
    try {
      await _systemLogApi.apiSystemLogsPost(
        systemLogs: systemLog,
        idempotencyKey: idempotencyKey,
      );
      developer.log('Logged system error to system_logs: $error');
    } catch (e) {
      developer.log('Failed to log system error to system_logs: $e',
          stackTrace: StackTrace.current);
      if (e is ApiException && e.code == 403) {
        developer.log(
            'Permission denied for system log creation, attempting token refresh');
        await _handle403Error();
      }
    }

// Log to operation_logs with retry
    if (_currentUserId != null) {
      final operationLog = OperationLog(
        userId: _currentUserId,
        operationContent: 'System Error Occurred',
        operationResult: 'Failed',
        operationTime: DateTime.now(),
        operationIpAddress: _currentIpAddress,
        remarks: error,
        idempotencyKey: idempotencyKey,
      );
      for (int attempt = 0; attempt < maxRetries; attempt++) {
        try {
          await _operationLogApi.apiOperationLogsPost(
            operationLog: operationLog,
            idempotencyKey: idempotencyKey,
          );
          developer.log('Logged system error to operation_logs: $error');
          return;
        } catch (e) {
          if (e is ApiException &&
              e.code == 500 &&
              e.message.contains('Duplicate request detected')) {
            developer.log(
                'Duplicate request detected for operation log, retrying with new idempotencyKey (attempt ${attempt + 1}/$maxRetries)');
            idempotencyKey = _generateIdempotencyKey();
            operationLog.idempotencyKey = idempotencyKey;
            await Future.delayed(Duration(milliseconds: 100 * (attempt + 1)));
          } else {
            developer.log('Failed to log system error to operation_logs: $e',
                stackTrace: StackTrace.current);
            if (e is ApiException && e.code == 403) {
              developer.log(
                  'Permission denied for operation log creation, attempting token refresh');
              await _handle403Error();
            }
            break;
          }
        }
      }
    } else {
      developer.log('Skipped operation log for system error: userId is null');
    }
  }

  Future<bool> _validateJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null || jwtToken.isEmpty) {
      developer.log('No JWT token found in SharedPreferences');
      _currentUsername = 'Unknown';
      return false;
    }
    try {
      var decodedToken = JwtDecoder.decode(jwtToken);
      final expiry =
          DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);
      final now = DateTime.now();
// Refresh if token is expired or will expire within 5 minutes
      if (JwtDecoder.isExpired(jwtToken) ||
          expiry.difference(now).inMinutes < 5) {
        developer.log('JWT token expired or near expiry, refreshing');
        jwtToken = await _refreshJwtToken();
        if (jwtToken == null) {
          developer.log('Failed to refresh JWT token');
          _currentUsername = 'Unknown';
          await _clearTokens(prefs);
          return false;
        }
        await prefs.setString('jwtToken', jwtToken);
        if (JwtDecoder.isExpired(jwtToken)) {
          developer.log('New JWT token is expired');
          _currentUsername = 'Unknown';
          await _clearTokens(prefs);
          return false;
        }
        decodedToken = JwtDecoder.decode(jwtToken);
      }
      _currentUsername = decodedToken['sub'] ?? 'Unknown';
      _currentUserId = decodedToken['userId'] != null
          ? int.tryParse(decodedToken['userId'].toString())
          : null;
      developer.log(
          'JWT validated, username: $_currentUsername, userId: $_currentUserId');
      return true;
    } catch (e) {
      developer.log('Invalid JWT token: $e', stackTrace: StackTrace.current);
      _currentUsername = 'Unknown';
      await _clearTokens(prefs);
      return false;
    }
  }

  Future<void> _clearTokens(SharedPreferences prefs) async {
    await prefs.remove('jwtToken');
    await prefs.remove('refreshToken');
    developer.log('Cleared invalid tokens');
  }

  Future<String?> _refreshJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');
    if (refreshToken == null) {
      developer.log('No refresh token found');
      return null;
    }
    try {
      final response = await http
          .post(
            Uri.parse('http://localhost:8081/api/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final newJwt = jsonDecode(response.body)['jwtToken'];
        await prefs.setString('jwtToken', newJwt);
        developer.log('JWT token refreshed successfully');
        return newJwt;
      }
      developer.log('Failed to refresh JWT token: ${response.statusCode}');
      return null;
    } catch (e) {
      developer.log('Error refreshing JWT token: $e',
          stackTrace: StackTrace.current);
      return null;
    }
  }

  Future<void> _fetchIpAddress() async {
    const maxRetries = 5;
    final services = [
      'https://api.ipify.org?format=json',
      'https://ifconfig.me/ip',
    ];
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      for (final service in services) {
        try {
          final client = HttpClient()
            ..badCertificateCallback =
                (X509Certificate cert, String host, int port) =>
                    true; // For testing only
          final request = await client.getUrl(Uri.parse(service));
          final response = await request.close().timeout(const Duration(seconds: 5));
          final responseBody = await response.transform(utf8.decoder).join();
          if (response.statusCode == 200) {
            if (service.contains('ipify')) {
              final data = jsonDecode(responseBody);
              _currentIpAddress = data['ip'];
            } else {
              _currentIpAddress = responseBody.trim();
            }
            developer
                .log('Fetched IP address: $_currentIpAddress from $service');
            return;
          } else {
            developer.log(
                'Failed to fetch IP from $service: ${response.statusCode}');
          }
        } catch (e) {
          developer.log('Error fetching IP from $service: $e',
              stackTrace: StackTrace.current);
        }
      }
      await Future.delayed(Duration(seconds: pow(2, attempt).toInt()));
    }
    _currentIpAddress = 'Unknown';
    developer.log('Set IP address to Unknown after retries');
  }

  Future<void> _handle403Error() async {
    if (_isRedirecting || Get.currentRoute == '/login') {
      developer
          .log('Already redirecting or on login route, skipping 403 handling');
      return;
    }
    developer.log('Handling 403 error, attempting JWT refresh');
    if (await _validateJwtToken()) {
// Retry initialization of APIs
      await _operationLogApi.initializeWithJwt();
      await _systemLogApi.initializeWithJwt();
      developer.log('Reinitialized APIs after token refresh');
    } else {
      developer.log('Failed to refresh token, scheduling redirect to login');
      await _deferNavigationToLogin();
    }
  }

  String _generateIdempotencyKey() {
    return const Uuid().v4();
  }

  Future<void> logNavigation(String pageName, {String? remarks}) async {
    if (!_isInitialized || _currentUserId == null) {
      developer.log('LogController not initialized or user ID missing');
      return;
    }
    const maxRetries = 3;
    String idempotencyKey = _generateIdempotencyKey();
    final operationLog = OperationLog(
      userId: _currentUserId,
      operationContent: 'Navigated to $pageName',
      operationResult: 'Success',
      operationTime: DateTime.now(),
      operationIpAddress: _currentIpAddress,
      remarks: remarks,
      idempotencyKey: idempotencyKey,
    );
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        await _operationLogApi.apiOperationLogsPost(
          operationLog: operationLog,
          idempotencyKey: idempotencyKey,
        );
        developer.log('Logged navigation to $pageName');
        return;
      } catch (e) {
        if (e is ApiException &&
            e.code == 500 &&
            e.message.contains('Duplicate request detected')) {
          developer.log(
              'Duplicate request detected for navigation log, retrying with new idempotencyKey (attempt ${attempt + 1}/$maxRetries)');
          idempotencyKey = _generateIdempotencyKey();
          operationLog.idempotencyKey = idempotencyKey;
          await Future.delayed(Duration(milliseconds: 100 * (attempt + 1)));
        } else {
          developer.log('Failed to log navigation: $e',
              stackTrace: StackTrace.current);
          if (e is ApiException && e.code == 403) {
            developer.log(
                'Permission denied for operation log creation, attempting token refresh');
            await _handle403Error();
          }
          break;
        }
      }
    }
  }

  Future<void> logUserAction(String action,
      {String? result, String? remarks}) async {
    if (!_isInitialized || _currentUserId == null) {
      developer.log('LogController not initialized or user ID missing');
      return;
    }
    const maxRetries = 3;
    String idempotencyKey = _generateIdempotencyKey();
    final operationLog = OperationLog(
      userId: _currentUserId,
      operationContent: action,
      operationResult: result ?? 'Success',
      operationTime: DateTime.now(),
      operationIpAddress: _currentIpAddress,
      remarks: remarks,
      idempotencyKey: idempotencyKey,
    );
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        await _operationLogApi.apiOperationLogsPost(
          operationLog: operationLog,
          idempotencyKey: idempotencyKey,
        );
        developer.log('Logged user action: $action');
        return;
      } catch (e) {
        if (e is ApiException &&
            e.code == 500 &&
            e.message.contains('Duplicate request detected')) {
          developer.log(
              'Duplicate request detected for user action log, retrying with new idempotencyKey (attempt ${attempt + 1}/$maxRetries)');
          idempotencyKey = _generateIdempotencyKey();
          operationLog.idempotencyKey = idempotencyKey;
          await Future.delayed(Duration(milliseconds: 100 * (attempt + 1)));
        } else {
          developer.log('Failed to log user action: $e',
              stackTrace: StackTrace.current);
          if (e is ApiException && e.code == 403) {
            developer.log(
                'Permission denied for operation log creation, attempting token refresh');
            await _handle403Error();
          }
          break;
        }
      }
    }
  }

  Future<void> logApiCall({
    required String endpoint,
    required String method,
    String? statusCode,
    String? result,
    String? error,
    String? remarks,
  }) async {
    if (!_isInitialized) {
      developer.log('LogController not initialized');
      return;
    }
    const maxRetries = 3;
    String idempotencyKey = _generateIdempotencyKey();
    final logContent =
        'API $method call to $endpoint${statusCode != null ? ' (Status: $statusCode)' : ''}${error != null ? ' (Error: $error)' : ''}';

// Log to system_logs
    final systemLog = SystemLogs(
      logType: error != null ? 'API_ERROR' : 'API_CALL',
      logContent: logContent,
      operationUser: _currentUsername ?? 'Unknown',
      operationTime: DateTime.now(),
      operationIpAddress: _currentIpAddress,
      remarks: remarks,
      idempotencyKey: idempotencyKey,
    );
    try {
      await _systemLogApi.apiSystemLogsPost(
        systemLogs: systemLog,
        idempotencyKey: idempotencyKey,
      );
      developer.log('Logged API call to system_logs: $logContent');
    } catch (e) {
      developer.log('Failed to log API call to system_logs: $e',
          stackTrace: StackTrace.current);
      if (e is ApiException && e.code == 403) {
        developer.log(
            'Permission denied for system log creation, attempting token refresh');
        await _handle403Error();
      }
    }

// Log to operation_logs with retry
    if (_currentUserId != null) {
      final operationLog = OperationLog(
        userId: _currentUserId,
        operationContent: 'API $method Call',
        operationResult: error != null ? 'Failed' : 'Success',
        operationTime: DateTime.now(),
        operationIpAddress: _currentIpAddress,
        remarks: '$logContent${remarks != null ? ' - $remarks' : ''}',
        idempotencyKey: idempotencyKey,
      );
      for (int attempt = 0; attempt < maxRetries; attempt++) {
        try {
          await _operationLogApi.apiOperationLogsPost(
            operationLog: operationLog,
            idempotencyKey: idempotencyKey,
          );
          developer.log('Logged API call to operation_logs: $logContent');
          return;
        } catch (e) {
          if (e is ApiException &&
              e.code == 500 &&
              e.message.contains('Duplicate request detected')) {
            developer.log(
                'Duplicate request detected for API call log, retrying with new idempotencyKey (attempt ${attempt + 1}/$maxRetries)');
            idempotencyKey = _generateIdempotencyKey();
            operationLog.idempotencyKey = idempotencyKey;
            await Future.delayed(Duration(milliseconds: 100 * (attempt + 1)));
          } else {
            developer.log('Failed to log API call to operation_logs: $e',
                stackTrace: StackTrace.current);
            if (e is ApiException && e.code == 403) {
              developer.log(
                  'Permission denied for operation log creation, attempting token refresh');
              await _handle403Error();
            }
            break;
          }
        }
      }
    } else {
      developer.log('Skipped operation log for API call: userId is null');
    }
  }

  Future<T> logApiCallWithResult<T>({
    required Future<T> Function() apiCall,
    required String endpoint,
    required String method,
    String? remarks,
  }) async {
    try {
      final result = await apiCall();
      await logApiCall(
        endpoint: endpoint,
        method: method,
        statusCode: '200',
        result: 'Success',
        remarks: remarks,
      );
      return result;
    } catch (e) {
      String errorMessage;
      String? statusCode;
      if (e is ApiException) {
        errorMessage = e.message;
        statusCode = e.code.toString();
      } else {
        errorMessage = e.toString();
        statusCode = null;
      }
      await logApiCall(
        endpoint: endpoint,
        method: method,
        statusCode: statusCode,
        error: errorMessage,
        remarks: remarks,
      );
      if (e is ApiException && e.code == 403) {
        developer.log('API call failed with 403, attempting token refresh');
        await _handle403Error();
      }
      rethrow;
    }
  }
}
