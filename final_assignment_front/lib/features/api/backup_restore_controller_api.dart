import 'dart:convert';

import 'package:final_assignment_front/features/model/backup_restore.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final ApiClient defaultApiClient = ApiClient();

class BackupRestoreControllerApi {
  final ApiClient apiClient;

  BackupRestoreControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  Future<void> initializeWithJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null || jwtToken.isEmpty) {
      throw Exception('未登录，请重新登录');
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint('Initialized BackupRestoreControllerApi with token: $jwtToken');
  }

  String _decodeBodyBytes(http.Response response) {
    return utf8.decode(response.bodyBytes);
  }

  Future<Map<String, String>> _getHeaders({String? idempotencyKey}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken') ?? '';
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
    };
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (idempotencyKey != null && idempotencyKey.trim().isNotEmpty) {
      headers['Idempotency-Key'] = idempotencyKey.trim();
    }
    return headers;
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 400) {
      final message = response.body.isNotEmpty
          ? _decodeBodyBytes(response)
          : 'Request failed with status ${response.statusCode}';
      throw ApiException(response.statusCode, message);
    }
  }

  List<BackupRestore> _parseList(String body) {
    if (body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(body) as List<dynamic>;
    return jsonList
        .map((item) => BackupRestore.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/system/backup
  Future<BackupRestore> apiSystemBackupPost({
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
  Future<BackupRestore> apiSystemBackupBackupIdPut({
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
  Future<void> apiSystemBackupBackupIdDelete({required int backupId}) async {
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
  Future<BackupRestore?> apiSystemBackupBackupIdGet(
      {required int backupId}) async {
    final response = await apiClient.invokeAPI(
      '/api/system/backup/$backupId',
      'GET',
      const [],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
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
  Future<List<BackupRestore>> apiSystemBackupGet({String? status}) async {
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
    );
    if (response.statusCode == 404) {
      return [];
    }
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }
}
