import 'dart:convert';
import 'package:final_assignment_front/features/model/fine_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

final ApiClient defaultApiClient = ApiClient();

class FineInformationControllerApi {
  final ApiClient apiClient;

  FineInformationControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  /// ä»?SharedPreferences ä¸­è¯»å?jwtToken å¹¶è®¾ç½®å° ApiClient ä¸?
  Future<void> initializeWithJwt() async {
      final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null) {
      throw Exception('æªç»å½ï¼è¯·éæ°ç»å½?);
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint('Initialized FineInformationControllerApi with token: $jwtToken');
  }

  /// è§£ç ååºä½å­èå°å­ç¬¦ä¸²ï¼ä½¿ç¨ UTF-8 è§£ç 
  String _decodeBodyBytes(http.Response response) {
    return utf8.decode(response.bodyBytes); // Properly decode UTF-8
  }

  /// è·åå¸¦æ JWT çè¯·æ±å¤´
  Future<Map<String, String>> _getHeaders() async {
      final token = (await AuthTokenStore.instance.getJwtToken()) ?? '';
    return {
      'Content-Type': 'application/json; charset=utf-8',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// æ·»å  idempotencyKey ä½ä¸ºæ¥è¯¢åæ°
  List<QueryParam> _addIdempotencyKey(String idempotencyKey) {
    return [QueryParam('idempotencyKey', idempotencyKey)];
  }

  // HTTP Methods

  /// POST /api/fines - åå»ºç½æ¬¾ (ä»ç®¡çå)
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

  /// GET /api/fines/{fineId} - è·åç½æ¬¾ä¿¡æ¯ (ç¨æ·åç®¡çå)
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

  /// GET /api/fines - è·åææç½æ¬?(ç¨æ·åç®¡çå)
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

  /// PUT /api/fines/{fineId} - æ´æ°ç½æ¬¾ (ä»ç®¡çå)
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

  /// DELETE /api/fines/{fineId} - å é¤ç½æ¬¾ (ä»ç®¡çå)
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

  /// GET /api/fines/payee/{payee} - æ ¹æ®ç¼´æ¬¾äººè·åç½æ¬?(ç¨æ·åç®¡çå)
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

  /// GET /api/fines/search/date-range - æ ¹æ®æ¶é´èå´è·åç½æ¬¾ (ç¨æ·åç®¡çå)
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

  /// GET /api/fines/receiptNumber/{receiptNumber} - æ ¹æ®æ¶æ®ç¼å·è·åç½æ¬¾ (ç¨æ·åç®¡çå)
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

  /// GET /api/fines/offense/{offenseId} - æè¿æ³è®°å½åé¡µæ¥è¯¢ç½æ¬?  Future<List<FineInformation>> apiFinesOffenseOffenseIdGet({
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

  /// GET /api/fines/search/handler - æå¤çäººæç´¢ç½æ¬¾è®°å½
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

  /// GET /api/fines/search/status - ææ¯ä»ç¶ææç´¢ç½æ¬¾è®°å½?  Future<List<FineInformation>> apiFinesSearchStatusGet({
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

  /// GET /api/fines/by-time-range - æç´¢ç½æ¬¾ææ¶é´èå?(ç¨æ·åç®¡çå)
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
