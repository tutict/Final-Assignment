import 'dart:convert';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

/// å®ä¹ä¸ä¸ªå¨å±ç?defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class DriverInformationControllerApi {
  final ApiClient apiClient;

  /// æé å½æ°ï¼å¯ä¼ å?ApiClientï¼å¦åä½¿ç¨å¨å±é»è®¤å®ä¾
  DriverInformationControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  /// ä»?SharedPreferences ä¸­è¯»å?jwtToken å¹¶è®¾ç½®å° ApiClient ä¸?
  Future<void> initializeWithJwt() async {
      final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null) {
      throw Exception('æªç»å½ï¼è¯·éæ°ç»å½?);
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint(
        'Initialized DriverInformationControllerApi with token: $jwtToken');
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

  /// POST /api/drivers - åå»ºå¸æºä¿¡æ¯
  Future<void> apiDriversPost({
    required DriverInformation driverInformation,
    required String idempotencyKey,
  }) async {
    const path = '/api/drivers';
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'POST',
      _addIdempotencyKey(idempotencyKey),
      driverInformation.toJson(),
      headerParams,
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      if (response.statusCode == 409) {
        throw ApiException(409,
            "Duplicate request detected with idempotencyKey: $idempotencyKey");
      }
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// GET /api/drivers/{driverId} - æ ¹æ®IDè·åå¸æºä¿¡æ¯
  Future<DriverInformation?> apiDriversDriverIdGet({
    required int driverId,
  }) async {
    final path = '/api/drivers/$driverId';
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
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return DriverInformation.fromJson(data);
  }

  /// GET /api/drivers - è·åææå¸æºä¿¡æ?
  Future<List<DriverInformation>> apiDriversGet() async {
    const path = '/api/drivers';
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
    return jsonList.map((json) => DriverInformation.fromJson(json)).toList();
  }

  /// PUT /api/drivers/{driverId}/name - æ´æ°å¸æºå§å
  Future<void> apiDriversDriverIdNamePut({
    required int driverId,
    required String name,
    required String idempotencyKey,
  }) async {
    final path = '/api/drivers/$driverId/name';
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'PUT',
      _addIdempotencyKey(idempotencyKey),
      jsonEncode(name),
      // String directly encoded as JSON
      headerParams,
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      if (response.statusCode == 404) {
        throw ApiException(404, "Driver not found with ID: $driverId");
      } else if (response.statusCode == 409) {
        throw ApiException(409,
            "Duplicate request detected with idempotencyKey: $idempotencyKey");
      }
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// PUT /api/drivers/{driverId}/contactNumber - æ´æ°å¸æºèç³»çµè¯
  Future<void> apiDriversDriverIdContactNumberPut({
    required int driverId,
    required String contactNumber,
    required String idempotencyKey,
  }) async {
    final path = '/api/drivers/$driverId/contactNumber';
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'PUT',
      _addIdempotencyKey(idempotencyKey),
      jsonEncode(contactNumber),
      // String directly encoded as JSON
      headerParams,
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      if (response.statusCode == 404) {
        throw ApiException(404, "Driver not found with ID: $driverId");
      } else if (response.statusCode == 409) {
        throw ApiException(409,
            "Duplicate request detected with idempotencyKey: $idempotencyKey");
      }
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// PUT /api/drivers/{driverId}/idCardNumber - æ´æ°å¸æºèº«ä»½è¯å·ç ?
  Future<void> apiDriversDriverIdIdCardNumberPut({
    required int driverId,
    required String idCardNumber,
    required String idempotencyKey,
  }) async {
    final path = '/api/drivers/$driverId/idCardNumber';
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'PUT',
      _addIdempotencyKey(idempotencyKey),
      jsonEncode(idCardNumber),
      // String directly encoded as JSON
      headerParams,
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      if (response.statusCode == 404) {
        throw ApiException(404, "Driver not found with ID: $driverId");
      } else if (response.statusCode == 409) {
        throw ApiException(409,
            "Duplicate request detected with idempotencyKey: $idempotencyKey");
      }
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// PUT /api/drivers/{driverId} - æ´æ°å¸æºå®æ´ä¿¡æ¯
  Future<void> apiDriversDriverIdPut({
    required int driverId,
    required DriverInformation driverInformation,
    required String idempotencyKey,
  }) async {
    final path = '/api/drivers/$driverId';
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'PUT',
      _addIdempotencyKey(idempotencyKey),
      driverInformation.toJson(),
      headerParams,
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      if (response.statusCode == 404) {
        throw ApiException(404, "Driver not found with ID: $driverId");
      } else if (response.statusCode == 409) {
        throw ApiException(409,
            "Duplicate request detected with idempotencyKey: $idempotencyKey");
      }
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// DELETE /api/drivers/{driverId} - å é¤å¸æºä¿¡æ¯ (ä»ç®¡çå)
  Future<void> apiDriversDriverIdDelete({
    required int driverId,
  }) async {
    final path = '/api/drivers/$driverId';
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
        throw ApiException(404, "Driver not found with ID: $driverId");
      } else if (response.statusCode == 403) {
        throw ApiException(403, "Unauthorized: Only ADMIN can delete drivers");
      }
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// GET /api/drivers/by-id-card - æç´¢å¸æºä¿¡æ¯æèº«ä»½è¯å·ç 
  Future<List<DriverInformation>> apiDriversByIdCardGet({
    required String query,
    int page = 1,
    int size = 10,
  }) async {
    if (query.isEmpty) {
      throw ApiException(400, "Missing required param: query");
    }
    const path = '/api/drivers/search/id-card';
    final queryParams = [
      QueryParam('keywords', query),
      QueryParam('page', page.toString()),
      QueryParam('size', size.toString()),
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
    return jsonList.map((json) => DriverInformation.fromJson(json)).toList();
  }

  /// GET /api/drivers/by-license-number - æç´¢å¸æºä¿¡æ¯æé©¾é©¶è¯å?
  Future<List<DriverInformation>> apiDriversByLicenseNumberGet({
    required String query,
    int page = 1,
    int size = 10,
  }) async {
    if (query.isEmpty) {
      throw ApiException(400, "Missing required param: query");
    }
    const path = '/api/drivers/search/license';
    final queryParams = [
      QueryParam('keywords', query),
      QueryParam('page', page.toString()),
      QueryParam('size', size.toString()),
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
    return jsonList.map((json) => DriverInformation.fromJson(json)).toList();
  }

  /// GET /api/drivers/by-name - æç´¢å¸æºä¿¡æ¯æå§å?
  Future<List<DriverInformation>> apiDriversByNameGet({
    required String query,
    int page = 1,
    int size = 10,
  }) async {
    if (query.isEmpty) {
      throw ApiException(400, "Missing required param: query");
    }
    const path = '/api/drivers/search/name';
    final queryParams = [
      QueryParam('keywords', query),
      QueryParam('page', page.toString()),
      QueryParam('size', size.toString()),
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
    return jsonList.map((json) => DriverInformation.fromJson(json)).toList();
  }

  // WebSocket Methods (Aligned with HTTP Endpoints)

  /// POST /api/drivers (WebSocket)
  Future<void> eventbusDriversPost({
    required DriverInformation driverInformation,
    required String idempotencyKey,
  }) async {
    final msg = {
      "service": "DriverInformationService",
      "action": "createDriver",
      "args": [driverInformation.toJson(), idempotencyKey]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      if (respMap["error"].toString().contains("Duplicate request")) {
        throw ApiException(409,
            "Duplicate request detected with idempotencyKey: $idempotencyKey");
      }
      throw ApiException(400, respMap["error"]);
    }
  }

  /// GET /api/drivers/{driverId} (WebSocket)
  Future<DriverInformation?> eventbusDriversDriverIdGet({
    required int driverId,
  }) async {
    final msg = {
      "service": "DriverInformationService",
      "action": "getDriverById",
      "args": [driverId]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      if (respMap["error"].toString().contains("not found")) {
        return null; // Not found, return null
      }
      throw ApiException(400, respMap["error"]);
    }
    if (respMap["result"] == null) return null;
    return DriverInformation.fromJson(
        respMap["result"] as Map<String, dynamic>);
  }

  /// GET /api/drivers (WebSocket)
  Future<List<DriverInformation>> eventbusDriversGet() async {
    final msg = {
      "service": "DriverInformationService",
      "action": "getAllDrivers",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    if (respMap["result"] is List) {
      return (respMap["result"] as List)
          .map((json) =>
              DriverInformation.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// PUT /api/drivers/{driverId} (WebSocket)
  Future<void> eventbusDriversDriverIdPut({
    required int driverId,
    required DriverInformation driverInformation,
    required String idempotencyKey,
  }) async {
    final msg = {
      "service": "DriverInformationService",
      "action": "updateDriver",
      "args": [driverId, driverInformation.toJson(), idempotencyKey]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      if (respMap["error"].toString().contains("not found")) {
        throw ApiException(404, "Driver not found with ID: $driverId");
      } else if (respMap["error"].toString().contains("Duplicate request")) {
        throw ApiException(409,
            "Duplicate request detected with idempotencyKey: $idempotencyKey");
      }
      throw ApiException(400, respMap["error"]);
    }
  }

  /// DELETE /api/drivers/{driverId} (WebSocket)
  Future<void> eventbusDriversDriverIdDelete({
    required int driverId,
  }) async {
    final msg = {
      "service": "DriverInformationService",
      "action": "deleteDriver",
      "args": [driverId]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      if (respMap["error"].toString().contains("not found")) {
        throw ApiException(404, "Driver not found with ID: $driverId");
      } else if (respMap["error"].toString().contains("Unauthorized")) {
        throw ApiException(403, "Unauthorized: Only ADMIN can delete drivers");
      }
      throw ApiException(400, respMap["error"]);
    }
  }
}
