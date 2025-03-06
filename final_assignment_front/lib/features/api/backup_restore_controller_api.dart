import 'package:final_assignment_front/features/model/backup_restore.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class BackupRestoreControllerApi {
  final ApiClient apiClient;

  /// 构造函数，可传入 ApiClient，否则使用全局默认实例
  BackupRestoreControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  /// 从 SharedPreferences 中读取 jwtToken 并设置到 ApiClient 中
  Future<void> initializeWithJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('未登录，请重新登录');
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint('Initialized BackupRestoreControllerApi with token: $jwtToken');
  }

  /// 解码响应体字节到字符串
  String _decodeBodyBytes(Response response) => response.body;

  /// DELETE /api/backups/{backupId} - 删除备份 (仅管理员)
  Future<void> apiBackupsBackupIdDelete(String backupId) async {
    if (backupId.isEmpty) {
      throw ApiException(400, "Missing required param: backupId");
    }
    final response = await apiClient.invokeAPI(
      '/api/backups/$backupId',
      'DELETE',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// GET /api/backups/{backupId} - 根据ID获取备份
  Future<BackupRestore?> apiBackupsBackupIdGet(String backupId) async {
    if (backupId.isEmpty) {
      throw ApiException(400, "Missing required param: backupId");
    }
    final response = await apiClient.invokeAPI(
      '/api/backups/$backupId',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return BackupRestore.fromJson(data);
  }

  /// PUT /api/backups/{backupId} - 更新备份 (仅管理员)
  Future<BackupRestore> apiBackupsBackupIdPut({
    required String backupId,
    required BackupRestore backupRestore,
  }) async {
    if (backupId.isEmpty) {
      throw ApiException(400, "Missing required param: backupId");
    }
    final response = await apiClient.invokeAPI(
      '/api/backups/$backupId',
      'PUT',
      [],
      backupRestore.toJson(),
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return BackupRestore.fromJson(data);
  }

  /// GET /api/backups/filename/{backupFileName} - 根据文件名获取备份
  Future<BackupRestore?> apiBackupsFilenameBackupFileNameGet(
      String backupFileName) async {
    if (backupFileName.isEmpty) {
      throw ApiException(400, "Missing required param: backupFileName");
    }
    final response = await apiClient.invokeAPI(
      '/api/backups/filename/$backupFileName',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return BackupRestore.fromJson(data);
  }

  /// GET /api/backups - 获取所有备份
  Future<List<BackupRestore>> apiBackupsGet() async {
    final response = await apiClient.invokeAPI(
      '/api/backups',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return BackupRestore.listFromJson(data);
  }

  /// POST /api/backups - 创建备份 (仅管理员)
  Future<BackupRestore> apiBackupsPost(
      {required BackupRestore backupRestore}) async {
    final response = await apiClient.invokeAPI(
      '/api/backups',
      'POST',
      [],
      backupRestore.toJson(),
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return BackupRestore.fromJson(data);
  }

  /// GET /api/backups/time/{backupTime} - 根据时间获取备份
  Future<List<BackupRestore>> apiBackupsTimeBackupTimeGet(
      String backupTime) async {
    if (backupTime.isEmpty) {
      throw ApiException(400, "Missing required param: backupTime");
    }
    final response = await apiClient.invokeAPI(
      '/api/backups/time/$backupTime',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return BackupRestore.listFromJson(data);
  }

  // WebSocket Methods (Aligned with HTTP Endpoints)

  /// DELETE /api/backups/{backupId} (WebSocket)
  /// 对应后端: @WsAction(service="BackupRestore", action="deleteBackup")
  Future<bool> eventbusBackupsBackupIdDelete(String backupId) async {
    if (backupId.isEmpty) {
      throw ApiException(400, "Missing required param: backupId");
    }
    final msg = {
      "service": "BackupRestore",
      "action": "deleteBackup",
      "args": [int.parse(backupId)]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return true; // Success if no error
  }

  /// GET /api/backups/{backupId} (WebSocket)
  /// 对应后端: @WsAction(service="BackupRestore", action="getBackupById")
  Future<Object?> eventbusBackupsBackupIdGet(String backupId) async {
    if (backupId.isEmpty) {
      throw ApiException(400, "Missing required param: backupId");
    }
    final msg = {
      "service": "BackupRestore",
      "action": "getBackupById",
      "args": [int.parse(backupId)]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// PUT /api/backups/{backupId} (WebSocket)
  /// 对应后端: @WsAction(service="BackupRestore", action="updateBackup")
  Future<Object?> eventbusBackupsBackupIdPut({
    required String backupId,
    required BackupRestore backupRestore,
  }) async {
    if (backupId.isEmpty) {
      throw ApiException(400, "Missing required param: backupId");
    }
    final msg = {
      "service": "BackupRestore",
      "action": "updateBackup",
      "args": [int.parse(backupId), backupRestore.toJson()]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/backups/filename/{backupFileName} (WebSocket)
  /// 对应后端: @WsAction(service="BackupRestore", action="getBackupByFileName")
  Future<Object?> eventbusBackupsFilenameBackupFileNameGet(
      String backupFileName) async {
    if (backupFileName.isEmpty) {
      throw ApiException(400, "Missing required param: backupFileName");
    }
    final msg = {
      "service": "BackupRestore",
      "action": "getBackupByFileName",
      "args": [backupFileName]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/backups (WebSocket)
  /// 对应后端: @WsAction(service="BackupRestore", action="getAllBackups")
  Future<List<Object>?> eventbusBackupsGet() async {
    final msg = {
      "service": "BackupRestore",
      "action": "getAllBackups",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    if (respMap["result"] is List) {
      return (respMap["result"] as List).cast<Object>();
    }
    return null;
  }

  /// POST /api/backups (WebSocket)
  /// 对应后端: @WsAction(service="BackupRestore", action="createBackup")
  Future<Object?> eventbusBackupsPost(
      {required BackupRestore backupRestore}) async {
    final msg = {
      "service": "BackupRestore",
      "action": "createBackup",
      "args": [backupRestore.toJson()]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/backups/time/{backupTime} (WebSocket)
  /// 对应后端: @WsAction(service="BackupRestore", action="getBackupsByTime")
  Future<List<Object>?> eventbusBackupsTimeBackupTimeGet(
      String backupTime) async {
    if (backupTime.isEmpty) {
      throw ApiException(400, "Missing required param: backupTime");
    }
    final msg = {
      "service": "BackupRestore",
      "action": "getBackupsByTime",
      "args": [backupTime]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    if (respMap["result"] is List) {
      return (respMap["result"] as List).cast<Object>();
    }
    return null;
  }
}
