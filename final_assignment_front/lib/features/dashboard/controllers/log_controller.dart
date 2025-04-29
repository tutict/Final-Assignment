import 'dart:convert';
import 'dart:developer' as developer;
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

class LogController extends GetxController with WidgetsBindingObserver {
  final OperationLogControllerApi _operationLogApi =
      OperationLogControllerApi();
  final SystemLogsControllerApi _systemLogApi = SystemLogsControllerApi();
  String? _currentUsername;
  int? _currentUserId;
  String? _currentIpAddress;
  bool _isInitialized = false;

  Future<void> get initialization => _initialize();

  @override
  void onInit() {
    super.onInit();
    // Register as WidgetsBindingObserver to listen for app lifecycle events
    WidgetsBinding.instance.addObserver(this);
    // Start initialization and log app startup
    _initialize().then((_) {
      _logAppStartup();
    }).catchError((e) {
      developer.log('LogController initialization failed: $e',
          stackTrace: StackTrace.current);
      _logSystemError(
          error: 'Initialization failed: $e',
          stackTrace: StackTrace.current.toString()); // Fixed typo here
    });
  }

  @override
  void onClose() {
    // Remove observer when controller is disposed
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Log app lifecycle events (e.g., resumed, paused)
    if (_isInitialized) {
      _logAppLifecycleEvent(state);
    }
  }

  /// Initializes the controller by validating JWT and fetching IP address.
  Future<void> _initialize() async {
    try {
      await _validateJwtToken();
      await _fetchIpAddress();
      await _operationLogApi.initializeWithJwt();
      await _systemLogApi.initializeWithJwt();
      _isInitialized = true;
      developer
          .log('LogController initialized with username: $_currentUsername');
    } catch (e) {
      _isInitialized = false;
      rethrow; // Rethrow to handle in onInit
    }
  }

  /// Logs the application startup event.
  Future<void> _logAppStartup() async {
    if (!_isInitialized) {
      developer.log('Cannot log app startup: LogController not initialized');
      return;
    }
    final idempotencyKey = _generateIdempotencyKey();
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
      developer.log('Logged application startup');
    } catch (e) {
      developer.log('Failed to log app startup: $e',
          stackTrace: StackTrace.current);
    }
  }

  /// Logs app lifecycle events (e.g., resumed, paused).
  Future<void> _logAppLifecycleEvent(AppLifecycleState state) async {
    final idempotencyKey = _generateIdempotencyKey();
    final logContent = 'App Lifecycle: ${state.toString().split('.').last}';
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
      developer.log('Logged app lifecycle event: $logContent');
    } catch (e) {
      developer.log('Failed to log app lifecycle event: $e',
          stackTrace: StackTrace.current);
    }
  }

  /// Validates JWT token and refreshes if expired.
  Future<bool> _validateJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null || jwtToken.isEmpty) {
      developer.log('No JWT token found');
      return false;
    }
    try {
      final decodedToken = JwtDecoder.decode(jwtToken);
      if (JwtDecoder.isExpired(jwtToken)) {
        jwtToken = await _refreshJwtToken();
        if (jwtToken == null) {
          developer.log('Failed to refresh JWT token');
          return false;
        }
        await prefs.setString('jwtToken', jwtToken);
        if (JwtDecoder.isExpired(jwtToken)) {
          developer.log('New JWT token is expired');
          return false;
        }
      }
      _currentUsername = decodedToken['sub'] ?? 'Unknown';
      _currentUserId = decodedToken['userId'] != null
          ? int.tryParse(decodedToken['userId'].toString())
          : null;
      return true;
    } catch (e) {
      developer.log('Invalid JWT token: $e', stackTrace: StackTrace.current);
      return false;
    }
  }

  /// Refreshes JWT token using refresh token.
  Future<String?> _refreshJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');
    if (refreshToken == null) {
      developer.log('No refresh token found');
      return null;
    }
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8081/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
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

  /// Fetches the client's IP address using an external API.
  Future<void> _fetchIpAddress() async {
    try {
      final response =
          await http.get(Uri.parse('https://api.ipify.org?format=json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentIpAddress = data['ip'];
        developer.log('Fetched IP address: $_currentIpAddress');
      } else {
        developer.log('Failed to fetch IP address: ${response.statusCode}');
        _currentIpAddress = 'Unknown';
      }
    } catch (e) {
      developer.log('Error fetching IP address: $e',
          stackTrace: StackTrace.current);
      _currentIpAddress = 'Unknown';
    }
  }

  /// Generates a unique idempotency key.
  String _generateIdempotencyKey() {
    return const Uuid().v4();
  }

  /// Logs a navigation event as an OperationLog.
  Future<void> logNavigation(String pageName, {String? remarks}) async {
    if (!_isInitialized || _currentUserId == null) {
      developer.log('LogController not initialized or user ID missing');
      return;
    }
    final idempotencyKey = _generateIdempotencyKey();
    final operationLog = OperationLog(
      userId: _currentUserId,
      operationContent: 'Navigated to $pageName',
      operationResult: 'Success',
      operationTime: DateTime.now(),
      operationIpAddress: _currentIpAddress,
      remarks: remarks,
      idempotencyKey: idempotencyKey,
    );
    try {
      await _operationLogApi.apiOperationLogsPost(
        operationLog: operationLog,
        idempotencyKey: idempotencyKey,
      );
      developer.log('Logged navigation to $pageName');
    } catch (e) {
      developer.log('Failed to log navigation: $e',
          stackTrace: StackTrace.current);
    }
  }

  /// Logs a user action (e.g., button click) as an OperationLog.
  Future<void> logUserAction(String action,
      {String? result, String? remarks}) async {
    if (!_isInitialized || _currentUserId == null) {
      developer.log('LogController not initialized or user ID missing');
      return;
    }
    final idempotencyKey = _generateIdempotencyKey();
    final operationLog = OperationLog(
      userId: _currentUserId,
      operationContent: action,
      operationResult: result ?? 'Success',
      operationTime: DateTime.now(),
      operationIpAddress: _currentIpAddress,
      remarks: remarks,
      idempotencyKey: idempotencyKey,
    );
    try {
      await _operationLogApi.apiOperationLogsPost(
        operationLog: operationLog,
        idempotencyKey: idempotencyKey,
      );
      developer.log('Logged user action: $action');
    } catch (e) {
      developer.log('Failed to log user action: $e',
          stackTrace: StackTrace.current);
    }
  }

  /// Logs an API call as a SystemLog.
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
    final idempotencyKey = _generateIdempotencyKey();
    final logContent =
        'API $method call to $endpoint${statusCode != null ? ' (Status: $statusCode)' : ''}${error != null ? ' (Error: $error)' : ''}';
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
      developer.log('Logged API call: $logContent');
    } catch (e) {
      developer.log('Failed to log API call: $e',
          stackTrace: StackTrace.current);
    }
  }

  /// Logs a system error as a SystemLog.
  Future<void> _logSystemError({
    required String error,
    String? stackTrace,
    String? remarks,
  }) async {
    if (!_isInitialized) {
      developer.log('LogController not initialized');
      return;
    }
    final idempotencyKey = _generateIdempotencyKey();
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
      developer.log('Logged system error: $error');
    } catch (e) {
      developer.log('Failed to log system error: $e',
          stackTrace: StackTrace.current);
    }
  }

  /// Wraps an API call to automatically log success or failure.
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
      rethrow;
    }
  }
}
