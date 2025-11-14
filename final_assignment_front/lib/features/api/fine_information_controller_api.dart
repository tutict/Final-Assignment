import 'dart:convert';
import 'package:final_assignment_front/features/model/fine_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final ApiClient defaultApiClient = ApiClient();

class FineInformationControllerApi {
  final ApiClient apiClient;

  FineInformationControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  /// 从 SharedPreferences 中读取 jwtToken 并设置到 ApiClient 中
  Future<void> initializeWithJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('未登录，请重新登录');
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint('Initialized FineInformationControllerApi with token: $jwtToken');
  }

  /// 解码响应体字节到字符串，使用 UTF-8 解码
  String _decodeBodyBytes(http.Response response) {
    return utf8.decode(response.bodyBytes); // Properly decode UTF-8
  }

  /// 获取带有 JWT 的请求头
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken') ?? '';
    return {
      'Content-Type': 'application/json; charset=utf-8',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// 添加 idempotencyKey 作为查询参数
  List<QueryParam> _addIdempotencyKey(String idempotencyKey) {
    return [QueryParam('idempotencyKey', idempotencyKey)];
  }

  // HTTP Methods

  /// POST /api/fines - 创建罚款 (仅管理员)
  Future<void> apiFinesPost({
    required FineInformation fineInformation,
    required String idempotencyKey,
  }) async {
    const path = '/api/fines';
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'POST',
      _addIdempotencyKey(idempotencyKey),
      fineInformation.toJson(),
      headerParams,
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// GET /api/fines/{fineId} - 获取罚款信息 (用户及管理员)
  Future<FineInformation?> apiFinesFineIdGet({
    required int fineId,
  }) async {
    final path = '/api/fines/$fineId';
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
      if (response.statusCode == 404) {
        return null; // Not found, return null
      }
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    final data = apiClient.deserialize(_decodeBodyBytes(response), 'Map<String, dynamic>');
    return FineInformation.fromJson(data);
  }

  /// GET /api/fines - 获取所有罚款 (用户及管理员)
  Future<List<FineInformation>> apiFinesGet() async {
    const path = '/api/fines';
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
    return jsonList.map((json) => FineInformation.fromJson(json)).toList();
  }

  /// PUT /api/fines/{fineId} - 更新罚款 (仅管理员)
  Future<FineInformation> apiFinesFineIdPut({
    required int fineId,
    required FineInformation fineInformation,
    required String idempotencyKey,
  }) async {
    final path = '/api/fines/$fineId';
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'PUT',
      _addIdempotencyKey(idempotencyKey),
      fineInformation.toJson(),
      headerParams,
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      if (response.statusCode == 404) {
        throw ApiException(404, "Fine not found with ID: $fineId");
      }
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final data = apiClient.deserialize(_decodeBodyBytes(response), 'Map<String, dynamic>');
    return FineInformation.fromJson(data);
  }

  /// DELETE /api/fines/{fineId} - 删除罚款 (仅管理员)
  Future<void> apiFinesFineIdDelete({
    required int fineId,
  }) async {
    final path = '/api/fines/$fineId';
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
      if (response.statusCode == 404) {
        throw ApiException(404, "Fine not found with ID: $fineId");
      } else if (response.statusCode == 403) {
        throw ApiException(403, "Unauthorized: Only ADMIN can delete fines");
      }
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// GET /api/fines/payee/{payee} - 根据缴款人获取罚款 (用户及管理员)
  Future<List<FineInformation>> apiFinesPayeePayeeGet({
    required String payee,
  }) async {
    if (payee.isEmpty) {
      throw ApiException(400, "Missing required param: payee");
    }
    final path = '/api/fines/payee/${Uri.encodeComponent(payee)}';
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
    return jsonList.map((json) => FineInformation.fromJson(json)).toList();
  }

  /// GET /api/fines/search/date-range - 根据时间范围获取罚款 (用户及管理员)
  Future<List<FineInformation>> apiFinesTimeRangeGet({
    String startDate = '1970-01-01', // Default matches backend
    String endDate = '2100-01-01',   // Default matches backend
  }) async {
    const path = '/api/fines/search/date-range';
    final queryParams = [
      QueryParam('startDate', startDate),
      QueryParam('endDate', endDate),
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
    return jsonList.map((json) => FineInformation.fromJson(json)).toList();
  }

  /// GET /api/fines/receiptNumber/{receiptNumber} - 根据收据编号获取罚款 (用户及管理员)
  Future<FineInformation?> apiFinesReceiptNumberReceiptNumberGet({
    required String receiptNumber,
  }) async {
    if (receiptNumber.isEmpty) {
      throw ApiException(400, "Missing required param: receiptNumber");
    }
    final path = '/api/fines/receiptNumber/${Uri.encodeComponent(receiptNumber)}';
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
      if (response.statusCode == 404) {
        return null; // Not found, return null
      }
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    final data = apiClient.deserialize(_decodeBodyBytes(response), 'Map<String, dynamic>');
    return FineInformation.fromJson(data);
  }

  /// GET /api/fines/offense/{offenseId} - 按违法记录分页查询罚款
  Future<List<FineInformation>> apiFinesOffenseOffenseIdGet({
    required int offenseId,
    int page = 1,
    int size = 20,
  }) async {
    final path = '/api/fines/offense/$offenseId';
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'GET',
      [QueryParam('page', '$page'), QueryParam('size', '$size')],
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
    return jsonList.map((json) => FineInformation.fromJson(json)).toList();
  }

  /// GET /api/fines/search/handler - 按处理人搜索罚款记录
  Future<List<FineInformation>> apiFinesSearchHandlerGet({
    required String handler,
    String mode = 'prefix', // or 'fuzzy'
    int page = 1,
    int size = 20,
  }) async {
    const path = '/api/fines/search/handler';
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'GET',
      [
        QueryParam('handler', handler),
        QueryParam('mode', mode),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
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
    return jsonList.map((json) => FineInformation.fromJson(json)).toList();
  }

  /// GET /api/fines/search/status - 按支付状态搜索罚款记录
  Future<List<FineInformation>> apiFinesSearchStatusGet({
    required String status,
    int page = 1,
    int size = 20,
  }) async {
    const path = '/api/fines/search/status';
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'GET',
      [
        QueryParam('status', status),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
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
    return jsonList.map((json) => FineInformation.fromJson(json)).toList();
  }

  /// GET /api/fines/by-time-range - 搜索罚款按时间范围 (用户及管理员)
  Future<List<FineInformation>> apiFinesByTimeRangeGet({
    required String startTime,
    required String endTime,
    int maxSuggestions = 10,
  }) async {
    if (startTime.isEmpty || endTime.isEmpty) {
      throw ApiException(400, "Missing required params: startTime or endTime");
    }
    const path = '/api/fines/by-time-range';
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
      if (response.statusCode == 204) {
        return []; // No content, return empty list
      }
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.map((json) => FineInformation.fromJson(json)).toList();
  }

  // WebSocket Methods (Aligned with HTTP Endpoints)

  /// POST /api/fines (WebSocket)
  Future<void> eventbusFinesPost({
    required FineInformation fineInformation,
    required String idempotencyKey,
  }) async {
    final msg = {
      "service": "FineInformationService",
      "action": "createFine",
      "args": [fineInformation.toJson(), idempotencyKey]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
  }

  /// GET /api/fines/{fineId} (WebSocket)
  Future<FineInformation?> eventbusFinesFineIdGet({
    required int fineId,
  }) async {
    final msg = {
      "service": "FineInformationService",
      "action": "getFineById",
      "args": [fineId]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      if (respMap["error"].toString().contains("not found")) {
        return null; // Not found, return null
      }
      throw ApiException(400, respMap["error"]);
    }
    if (respMap["result"] == null) return null;
    return FineInformation.fromJson(respMap["result"] as Map<String, dynamic>);
  }

  /// GET /api/fines (WebSocket)
  Future<List<FineInformation>> eventbusFinesGet() async {
    final msg = {
      "service": "FineInformationService",
      "action": "getAllFines",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    if (respMap["result"] is List) {
      return (respMap["result"] as List)
          .map((json) => FineInformation.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// PUT /api/fines/{fineId} (WebSocket)
  Future<FineInformation?> eventbusFinesFineIdPut({
    required int fineId,
    required FineInformation fineInformation,
    required String idempotencyKey,
  }) async {
    final msg = {
      "service": "FineInformationService",
      "action": "updateFine",
      "args": [fineId, fineInformation.toJson(), idempotencyKey]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      if (respMap["error"].toString().contains("not found")) {
        throw ApiException(404, "Fine not found with ID: $fineId");
      }
      throw ApiException(400, respMap["error"]);
    }
    if (respMap["result"] == null) return null;
    return FineInformation.fromJson(respMap["result"] as Map<String, dynamic>);
  }

  /// DELETE /api/fines/{fineId} (WebSocket)
  Future<void> eventbusFinesFineIdDelete({
    required int fineId,
  }) async {
    final msg = {
      "service": "FineInformationService",
      "action": "deleteFine",
      "args": [fineId]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      if (respMap["error"].toString().contains("not found")) {
        throw ApiException(404, "Fine not found with ID: $fineId");
      } else if (respMap["error"].toString().contains("Unauthorized")) {
        throw ApiException(403, "Unauthorized: Only ADMIN can delete fines");
      }
      throw ApiException(400, respMap["error"]);
    }
  }

  /// GET /api/fines/payee/{payee} (WebSocket)
  Future<List<FineInformation>> eventbusFinesPayeePayeeGet({
    required String payee,
  }) async {
    if (payee.isEmpty) {
      throw ApiException(400, "Missing required param: payee");
    }
    final msg = {
      "service": "FineInformationService",
      "action": "getFinesByPayee",
      "args": [payee]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    if (respMap["result"] is List) {
      return (respMap["result"] as List)
          .map((json) => FineInformation.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// GET /api/fines/receiptNumber/{receiptNumber} (WebSocket)
  Future<FineInformation?> eventbusFinesReceiptNumberReceiptNumberGet({
    required String receiptNumber,
  }) async {
    if (receiptNumber.isEmpty) {
      throw ApiException(400, "Missing required param: receiptNumber");
    }
    final msg = {
      "service": "FineInformationService",
      "action": "getFineByReceiptNumber",
      "args": [receiptNumber]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      if (respMap["error"].toString().contains("not found")) {
        return null; // Not found, return null
      }
      throw ApiException(400, respMap["error"]);
    }
    if (respMap["result"] == null) return null;
    return FineInformation.fromJson(respMap["result"] as Map<String, dynamic>);
  }

  /// GET /api/fines/timeRange (WebSocket)
  Future<List<FineInformation>> eventbusFinesTimeRangeGet({
    String startTime = '1970-01-01',
    String endTime = '2100-01-01',
  }) async {
    final msg = {
      "service": "FineInformationService",
      "action": "getFinesByTimeRange",
      "args": [startTime, endTime]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    if (respMap["result"] is List) {
      return (respMap["result"] as List)
          .map((json) => FineInformation.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
