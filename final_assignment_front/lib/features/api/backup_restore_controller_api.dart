import 'package:final_assignment_front/features/model/backup_restore.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';

final ApiClient defaultApiClient = ApiClient();

class BackupRestoreControllerApi with BaseApiClient {
  @override
  final ApiClient apiClient;

  BackupRestoreControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  Future<void> initializeWithJwt() => initializeClientWithJwt();

  Future<BackupRestore> createBackup({
    required BackupRestore backupRestore,
    String? idempotencyKey,
  }) {
    return requestObject(
      'POST',
      '/api/system/backup',
      BackupRestore.fromJson,
      body: backupRestore.toJson(),
      contentType: 'application/json',
      idempotencyKey: idempotencyKey,
    );
  }

  Future<BackupRestore> updateBackup({
    required int backupId,
    required BackupRestore backupRestore,
    String? idempotencyKey,
  }) {
    return requestObject(
      'PUT',
      '/api/system/backup/$backupId',
      BackupRestore.fromJson,
      body: backupRestore.toJson(),
      contentType: 'application/json',
      idempotencyKey: idempotencyKey,
    );
  }

  Future<void> deleteBackup({required int backupId}) {
    return requestVoid('DELETE', '/api/system/backup/$backupId');
  }

  Future<BackupRestore?> getBackup({required int backupId}) {
    return requestNullableObject(
      'GET',
      '/api/system/backup/$backupId',
      BackupRestore.fromJson,
    );
  }

  Future<List<BackupRestore>> listBackups({String? status}) {
    final trimmedStatus = status?.trim();
    return requestList(
      'GET',
      '/api/system/backup',
      BackupRestore.fromJson,
      queryParams: queryParamsFromMap({
        'status': trimmedStatus?.isEmpty == true ? null : trimmedStatus,
      }),
      emptyStatusCodes: const {204, 404},
      passThroughStatusCodes: const {404},
    );
  }

  Future<List<BackupRestore>> searchBackupsByType({
    required String backupType,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(backupType, 'backupType');
    return _search('/api/system/backup/search/type', {
      'backupType': backupType,
      'page': page,
      'size': size,
    });
  }

  Future<List<BackupRestore>> searchBackupsByFileName({
    required String backupFileName,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(backupFileName, 'backupFileName');
    return _search('/api/system/backup/search/file-name', {
      'backupFileName': backupFileName,
      'page': page,
      'size': size,
    });
  }

  Future<List<BackupRestore>> searchBackupsByHandler({
    required String backupHandler,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(backupHandler, 'backupHandler');
    return _search('/api/system/backup/search/handler', {
      'backupHandler': backupHandler,
      'page': page,
      'size': size,
    });
  }

  Future<List<BackupRestore>> searchBackupsByRestoreStatus({
    required String restoreStatus,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(restoreStatus, 'restoreStatus');
    return _search('/api/system/backup/search/restore-status', {
      'restoreStatus': restoreStatus,
      'page': page,
      'size': size,
    });
  }

  Future<List<BackupRestore>> searchBackupsByStatus({
    required String status,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(status, 'status');
    return _search('/api/system/backup/search/status', {
      'status': status,
      'page': page,
      'size': size,
    });
  }

  Future<List<BackupRestore>> searchBackupsByBackupTimeRange({
    required String startTime,
    required String endTime,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(startTime, 'startTime');
    requireNotBlank(endTime, 'endTime');
    return _search('/api/system/backup/search/backup-time-range', {
      'startTime': startTime,
      'endTime': endTime,
      'page': page,
      'size': size,
    });
  }

  Future<List<BackupRestore>> searchBackupsByRestoreTimeRange({
    required String startTime,
    required String endTime,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(startTime, 'startTime');
    requireNotBlank(endTime, 'endTime');
    return _search('/api/system/backup/search/restore-time-range', {
      'startTime': startTime,
      'endTime': endTime,
      'page': page,
      'size': size,
    });
  }

  Future<List<BackupRestore>> _search(
    String path,
    Map<String, Object?> params,
  ) {
    return requestList(
      'GET',
      path,
      BackupRestore.fromJson,
      queryParams: queryParamsFromMap(params),
    );
  }
}
