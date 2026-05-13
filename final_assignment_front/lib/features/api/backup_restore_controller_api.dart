import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'dart:convert';

import 'package:final_assignment_front/features/model/backup_restore.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

final ApiClient defaultApiClient = ApiClient();

class BackupRestoreControllerApi with BaseApiClient {
  @override
  final ApiClient apiClient;

  BackupRestoreControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  Future<void> initializeWithJwt() async {
    final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null || jwtToken.isEmpty) {
      throw Exception('Not authenticated. Please log in again.');
    }
    apiClient.setJwtToken(jwtToken);
    AppLogger.debug(
        'Initialized BackupRestoreControllerApi with token: $jwtToken');
  }

  String _decodeBodyBytes(http.Response response) {
    return decodeBodyBytes(response);
  }

  Future<Map<String, String>> _getHeaders({String? idempotencyKey}) async {
    return getHeaders(idempotencyKey: idempotencyKey);
  }

  void _ensureSuccess(http.Response response) {
    ensureSuccess(response);
  }

  List<BackupRestore> _parseList(String body) {
    if (body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(body) as List<dynamic>;
    return jsonList
        .map((item) => BackupRestore.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/system/backup
  Future<BackupRestore> createBackup({
    required BackupRestore backupRestore,
    String? idempotencyKey,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/backup',
      'POST',
      const [],
      backupRestore.toJson(),
      await _getHeaders(idempotencyKey: idempotencyKey),
      const {},
      'application/json',
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return BackupRestore.fromJson(
        jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>);
  }

  /// PUT /api/system/backup/{backupId}
  Future<BackupRestore> updateBackup({
    required int backupId,
    required BackupRestore backupRestore,
    String? idempotencyKey,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/backup/$backupId',
      'PUT',
      const [],
      backupRestore.toJson(),
      await _getHeaders(idempotencyKey: idempotencyKey),
      const {},
      'application/json',
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return BackupRestore.fromJson(
        jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>);
  }

  /// DELETE /api/system/backup/{backupId}
  Future<void> deleteBackup({required int backupId}) async {
    final response = await apiClient.invokeAPI(
      '/api/system/backup/$backupId',
      'DELETE',
      const [],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      _ensureSuccess(response);
    }
  }

  /// GET /api/system/backup/{backupId}
  Future<BackupRestore?> getBackup({required int backupId}) async {
    final response = await apiClient.invokeAPI(
      '/api/system/backup/$backupId',
      'GET',
      const [],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
      passThroughStatusCodes: const {404},
    );
    if (response.statusCode == 404) {
      return null;
    }
    _ensureSuccess(response);
    if (response.body.isEmpty) {
      return null;
    }
    return BackupRestore.fromJson(
        jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>);
  }

  /// GET /api/system/backup?status=...
  Future<List<BackupRestore>> listBackups({String? status}) async {
    final queryParams = <QueryParam>[];
    if (status != null && status.trim().isNotEmpty) {
      queryParams.add(QueryParam('status', status.trim()));
    }
    final response = await apiClient.invokeAPI(
      '/api/system/backup',
      'GET',
      queryParams,
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
      passThroughStatusCodes: const {404},
    );
    if (response.statusCode == 404) {
      return [];
    }
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }

  /// GET /api/system/backup/search/type
  Future<List<BackupRestore>> searchBackupsByType({
    required String backupType,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/backup/search/type',
      'GET',
      [
        QueryParam('backupType', backupType),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }

  /// GET /api/system/backup/search/file-name
  Future<List<BackupRestore>> searchBackupsByFileName({
    required String backupFileName,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/backup/search/file-name',
      'GET',
      [
        QueryParam('backupFileName', backupFileName),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }

  /// GET /api/system/backup/search/handler
  Future<List<BackupRestore>> searchBackupsByHandler({
    required String backupHandler,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/backup/search/handler',
      'GET',
      [
        QueryParam('backupHandler', backupHandler),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }

  /// GET /api/system/backup/search/restore-status
  Future<List<BackupRestore>> searchBackupsByRestoreStatus({
    required String restoreStatus,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/backup/search/restore-status',
      'GET',
      [
        QueryParam('restoreStatus', restoreStatus),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }

  /// GET /api/system/backup/search/status
  Future<List<BackupRestore>> searchBackupsByStatus({
    required String status,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/backup/search/status',
      'GET',
      [
        QueryParam('status', status),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }

  /// GET /api/system/backup/search/backup-time-range
  Future<List<BackupRestore>> searchBackupsByBackupTimeRange({
    required String startTime,
    required String endTime,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/backup/search/backup-time-range',
      'GET',
      [
        QueryParam('startTime', startTime),
        QueryParam('endTime', endTime),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }

  /// GET /api/system/backup/search/restore-time-range
  Future<List<BackupRestore>> searchBackupsByRestoreTimeRange({
    required String startTime,
    required String endTime,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/system/backup/search/restore-time-range',
      'GET',
      [
        QueryParam('startTime', startTime),
        QueryParam('endTime', endTime),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }
}
