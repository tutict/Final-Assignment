import 'dart:convert';
import 'package:final_assignment_front/features/model/appeal_management.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ApiClient defaultApiClient = ApiClient();

class AppealManagementControllerApi {
  final ApiClient apiClient;

  AppealManagementControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  String _decodeBodyBytes(http.Response response) => response.body;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken') ?? '';
    return {
      'Content-Type': 'application/json; charset=utf-8',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // --- GET /api/appeals ---
  Future<http.Response> apiAppealsGetWithHttpInfo() async {
    const path = "/api/appeals";
    final headerParams = await _getHeaders();

    return await apiClient.invokeAPI(
      path,
      'GET',
      [],
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
  }

  Future<List<AppealManagement>> apiAppealsGet() async {
    final response = await apiAppealsGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
      return jsonList.map((json) => AppealManagement.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  // --- GET /api/appeals/name/{appealName} ---
  Future<http.Response> apiAppealsNameAppealNameGetWithHttpInfo({
    required String appealName,
  }) async {
    if (appealName.isEmpty) {
      throw ApiException(400, "Missing required param: appealName");
    }

    final path = "/api/appeals/name/${Uri.encodeComponent(appealName)}";
    final headerParams = await _getHeaders();

    return await apiClient.invokeAPI(
      path,
      'GET',
      [],
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
  }

  Future<List<AppealManagement>> apiAppealsNameAppealNameGet({
    required String appealName,
  }) async {
    final response =
        await apiAppealsNameAppealNameGetWithHttpInfo(appealName: appealName);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
      return jsonList.map((json) => AppealManagement.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  // --- POST /api/appeals ---
  Future<http.Response> apiAppealsPostWithHttpInfo({
    required AppealManagement appealManagement,
    required String idempotencyKey,
  }) async {
    if (idempotencyKey.isEmpty) {
      throw ApiException(400, "Missing required param: idempotencyKey");
    }

    final path = "/api/appeals?idempotencyKey=$idempotencyKey";
    final headerParams = await _getHeaders();

    return await apiClient.invokeAPI(
      path,
      'POST',
      [],
      appealManagement.toJson(),
      headerParams,
      {},
      'application/json',
      ['bearerAuth'],
    );
  }

  Future<void> apiAppealsPost({
    required AppealManagement appealManagement,
    required String idempotencyKey,
  }) async {
    final response = await apiAppealsPostWithHttpInfo(
      appealManagement: appealManagement,
      idempotencyKey: idempotencyKey,
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  // --- PUT /api/appeals/{appealId} ---
  Future<http.Response> apiAppealsAppealIdPutWithHttpInfo({
    required String appealId,
    required AppealManagement appealManagement,
    required String idempotencyKey,
  }) async {
    if (appealId.isEmpty) {
      throw ApiException(400, "Missing required param: appealId");
    }
    if (idempotencyKey.isEmpty) {
      throw ApiException(400, "Missing required param: idempotencyKey");
    }

    final path = "/api/appeals/$appealId?idempotencyKey=$idempotencyKey";
    final headerParams = await _getHeaders();

    return await apiClient.invokeAPI(
      path,
      'PUT',
      [],
      appealManagement.toJson(),
      headerParams,
      {},
      'application/json',
      ['bearerAuth'],
    );
  }

  Future<void> apiAppealsAppealIdPut({
    required String appealId,
    required AppealManagement appealManagement,
    required String idempotencyKey,
  }) async {
    final response = await apiAppealsAppealIdPutWithHttpInfo(
      appealId: appealId,
      appealManagement: appealManagement,
      idempotencyKey: idempotencyKey,
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  // --- DELETE /api/appeals/{appealId} ---
  Future<http.Response> apiAppealsAppealIdDeleteWithHttpInfo({
    required String appealId,
  }) async {
    if (appealId.isEmpty) {
      throw ApiException(400, "Missing required param: appealId");
    }

    final path = "/api/appeals/$appealId";
    final headerParams = await _getHeaders();

    return await apiClient.invokeAPI(
      path,
      'DELETE',
      [],
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
  }

  Future<void> apiAppealsAppealIdDelete({
    required String appealId,
  }) async {
    final response =
        await apiAppealsAppealIdDeleteWithHttpInfo(appealId: appealId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// 以下为 WebSocket 方式调用

  /// 通过 WebSocket 删除申诉
  Future<Object?> eventbusAppealsAppealIdDelete(
      {required String appealId}) async {
    final msg = {
      "service": "AppealManagementService",
      "action": "deleteAppeal",
      "args": [int.parse(appealId)],
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("result")) {
      return respMap["result"];
    } else if (respMap.containsKey("status")) {
      return respMap["status"];
    }
    return respMap;
  }

  /// 通过 WebSocket 获取申诉详情
  Future<Object?> eventbusAppealsAppealIdGet({required String appealId}) async {
    final msg = {
      "service": "AppealManagementService",
      "action": "getAppealById",
      "args": [int.parse(appealId)],
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("result")) {
      return respMap["result"];
    }
    return respMap;
  }

  /// 通过 WebSocket 获取申诉关联的违法信息
  Future<Object?> eventbusAppealsAppealIdOffenseGet(
      {required String appealId}) async {
    final msg = {
      "service": "AppealManagementService",
      "action": "getOffenseByAppealId",
      "args": [int.parse(appealId)],
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("result")) {
      return respMap["result"];
    }
    return respMap;
  }

  /// 通过 WebSocket 更新申诉（简化调用，仅作为示例，实际推荐使用 HTTP PUT）
  Future<Object?> eventbusAppealsAppealIdPut(
      {required String appealId, int? integer}) async {
    final msg = {
      "service": "AppealManagementService",
      "action": "updateAppeal",
      "args": [int.parse(appealId), integer ?? 0],
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("result")) {
      return respMap["result"];
    }
    return respMap;
  }

  /// 通过 WebSocket 获取所有申诉记录
  Future<List<Object>?> eventbusAppealsGet() async {
    final msg = {
      "service": "AppealManagementService",
      "action": "getAllAppeals",
      "args": []
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("result") && respMap["result"] is List) {
      return respMap["result"] as List<Object>;
    }
    return null;
  }
}
