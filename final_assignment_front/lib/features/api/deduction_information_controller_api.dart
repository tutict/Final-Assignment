import 'dart:convert';
import 'package:final_assignment_front/features/model/deduction_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class DeductionInformationControllerApi {
  final ApiClient apiClient;

  /// 构造函数，可传入 ApiClient，否则使用全局默认实例
  DeductionInformationControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  /// 从 SharedPreferences 中读取 jwtToken 并设置到 ApiClient 中
  Future<void> initializeWithJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('未登录，请重新登录');
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint('Initialized DeductionInformationControllerApi with token: $jwtToken');
  }

  /// 解码响应体字节到字符串
  String _decodeBodyBytes(http.Response response) => response.body;

  /// 获取带有 JWT 的请求头
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken') ?? '';
    return {
      'Content-Type': 'application/json; charset=utf-8',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// 辅助方法：将幂等性键添加为查询参数
  List<QueryParam> _addIdempotencyKey(String idempotencyKey) {
    return [QueryParam('idempotencyKey', idempotencyKey)];
  }

  // HTTP Methods

  /// POST /api/deductions - 创建扣分信息 (仅管理员)
  Future<void> apiDeductionsPost({
    required DeductionInformation deductionInformation,
    required String idempotencyKey,
  }) async {
    if (idempotencyKey.isEmpty) {
      throw ApiException(400, "Missing required param: idempotencyKey");
    }
    const path = '/api/deductions';
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'POST',
      _addIdempotencyKey(idempotencyKey),
      deductionInformation.toJson(),
      headerParams,
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// GET /api/deductions/{deductionId} - 根据ID获取扣分信息
  Future<DeductionInformation?> apiDeductionsDeductionIdGet({
    required int deductionId,
  }) async {
    final path = '/api/deductions/$deductionId';
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'GET',
      [],
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    final data = apiClient.deserialize(_decodeBodyBytes(response), 'Map<String, dynamic>');
    return DeductionInformation.fromJson(data);
  }

  /// GET /api/deductions - 获取所有扣分信息
  Future<List<DeductionInformation>> apiDeductionsGet() async {
    const path = '/api/deductions';
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'GET',
      [],
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.map((json) => DeductionInformation.fromJson(json)).toList();
  }

  /// PUT /api/deductions/{deductionId} - 更新扣分信息 (仅管理员)
  Future<void> apiDeductionsDeductionIdPut({
    required int deductionId,
    required DeductionInformation deductionInformation,
    required String idempotencyKey,
  }) async {
    if (idempotencyKey.isEmpty) {
      throw ApiException(400, "Missing required param: idempotencyKey");
    }
    final path = '/api/deductions/$deductionId';
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'PUT',
      _addIdempotencyKey(idempotencyKey),
      deductionInformation.toJson(),
      headerParams,
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// DELETE /api/deductions/{deductionId} - 删除扣分信息 (仅管理员)
  Future<void> apiDeductionsDeductionIdDelete({
    required int deductionId,
  }) async {
    final path = '/api/deductions/$deductionId';
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'DELETE',
      [],
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// GET /api/deductions/handler/{handler} - 根据处理人获取扣分信息
  Future<List<DeductionInformation>> apiDeductionsHandlerHandlerGet({
    required String handler,
  }) async {
    if (handler.isEmpty) {
      throw ApiException(400, "Missing required param: handler");
    }
    final path = '/api/deductions/handler/${Uri.encodeComponent(handler)}';
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'GET',
      [],
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.map((json) => DeductionInformation.fromJson(json)).toList();
  }

  /// GET /api/deductions/timeRange - 根据时间范围获取扣分信息
  Future<List<DeductionInformation>> apiDeductionsTimeRangeGet({
    required String startTime,
    required String endTime,
  }) async {
    if (startTime.isEmpty || endTime.isEmpty) {
      throw ApiException(400, "Missing required params: startTime or endTime");
    }
    const path = '/api/deductions/timeRange';
    final queryParams = [
      QueryParam('startTime', startTime),
      QueryParam('endTime', endTime),
    ];
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.map((json) => DeductionInformation.fromJson(json)).toList();
  }

  /// GET /api/deductions/by-handler - 搜索扣分信息按处理人
  Future<List<DeductionInformation>> apiDeductionsByHandlerGet({
    required String handler,
    int maxSuggestions = 10,
  }) async {
    if (handler.isEmpty) {
      throw ApiException(400, "Missing required param: handler");
    }
    const path = '/api/deductions/by-handler';
    final queryParams = [
      QueryParam('handler', handler),
      QueryParam('maxSuggestions', maxSuggestions.toString()),
    ];
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.map((json) => DeductionInformation.fromJson(json)).toList();
  }

  /// GET /api/deductions/by-time-range - 搜索扣分信息按时间范围
  Future<List<DeductionInformation>> apiDeductionsByTimeRangeGet({
    required String startTime,
    required String endTime,
    int maxSuggestions = 10,
  }) async {
    if (startTime.isEmpty || endTime.isEmpty) {
      throw ApiException(400, "Missing required params: startTime or endTime");
    }
    const path = '/api/deductions/by-time-range';
    final queryParams = [
      QueryParam('startTime', startTime),
      QueryParam('endTime', endTime),
      QueryParam('maxSuggestions', maxSuggestions.toString()),
    ];
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.map((json) => DeductionInformation.fromJson(json)).toList();
  }

  // WebSocket Methods (Aligned with HTTP Endpoints)

  /// POST /api/deductions (WebSocket)
  Future<Object?> eventbusDeductionsPost({
    required DeductionInformation deductionInformation,
    required String idempotencyKey,
  }) async {
    if (idempotencyKey.isEmpty) {
      throw ApiException(400, "Missing required param: idempotencyKey");
    }
    final msg = {
      "service": "DeductionInformationService",
      "action": "createDeduction",
      "args": [deductionInformation.toJson(), idempotencyKey]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/deductions/{deductionId} (WebSocket)
  Future<Object?> eventbusDeductionsDeductionIdGet({
    required int deductionId,
  }) async {
    final msg = {
      "service": "DeductionInformationService",
      "action": "getDeductionById",
      "args": [deductionId]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/deductions (WebSocket)
  Future<List<Object>?> eventbusDeductionsGet() async {
    final msg = {
      "service": "DeductionInformationService",
      "action": "getAllDeductions",
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

  /// PUT /api/deductions/{deductionId} (WebSocket)
  Future<Object?> eventbusDeductionsDeductionIdPut({
    required int deductionId,
    required DeductionInformation deductionInformation,
    required String idempotencyKey,
  }) async {
    if (idempotencyKey.isEmpty) {
      throw ApiException(400, "Missing required param: idempotencyKey");
    }
    final msg = {
      "service": "DeductionInformationService",
      "action": "updateDeduction",
      "args": [deductionId, deductionInformation.toJson(), idempotencyKey]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// DELETE /api/deductions/{deductionId} (WebSocket)
  Future<bool> eventbusDeductionsDeductionIdDelete({
    required int deductionId,
  }) async {
    final msg = {
      "service": "DeductionInformationService",
      "action": "deleteDeduction",
      "args": [deductionId]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return true;
  }

  /// GET /api/deductions/handler/{handler} (WebSocket)
  Future<List<Object>?> eventbusDeductionsHandlerHandlerGet({
    required String handler,
  }) async {
    if (handler.isEmpty) {
      throw ApiException(400, "Missing required param: handler");
    }
    final msg = {
      "service": "DeductionInformationService",
      "action": "getDeductionsByHandler",
      "args": [handler]
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

  /// GET /api/deductions/timeRange (WebSocket)
  Future<List<Object>?> eventbusDeductionsTimeRangeGet({
    required String startTime,
    required String endTime,
  }) async {
    if (startTime.isEmpty || endTime.isEmpty) {
      throw ApiException(400, "Missing required param: startTime or endTime");
    }
    final msg = {
      "service": "DeductionInformationService",
      "action": "getDeductionsByTimeRange",
      "args": [startTime, endTime]
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