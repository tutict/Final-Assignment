import 'dart:convert';
import 'package:final_assignment_front/features/model/offense_information.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

/// å®ä¹ä¸ä¸ªå
// ¨å±ç?defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class OffenseInformationControllerApi {
  final ApiClient apiClient;

  OffenseInformationControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  /// ä»?SharedPreferences ä¸­è¯»å?jwtToken å¹¶è®¾ç½®å° ApiClient ä¸?
  Future<void> initializeWithJwt() async {
      final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null || jwtToken.isEmpty) {
      throw Exception('Not authenticated. Please log in again.');
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint(
        'Initialized OffenseInformationControllerApi with token: $jwtToken');
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

  /// POST /api/offenses - åå»ºè¿æ³è¡ä¸º (ä»
// ç®¡çå)
  Future<void> apiOffensesPost({
    required OffenseInformation offenseInformation,
    required String idempotencyKey,
  }) async {
    const path = '/api/offenses';
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'POST',
      _addIdempotencyKey(idempotencyKey),
      offenseInformation.toJson(),
      headerParams,
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      if (response.statusCode == 400) {
        throw ApiException(400, "Invalid request data");
      } else if (response.statusCode == 409) {
        throw ApiException(409,
            "Duplicate request detected with idempotencyKey: $idempotencyKey");
      }
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// GET /api/offenses/{offenseId} - æ ¹æ®IDè·åè¿æ³è¡ä¸ºä¿¡æ¯ (ç¨æ·åç®¡çå)
  Future<OffenseInformation?> apiOffensesOffenseIdGet({
    required int offenseId,
  }) async {
    final path = '/api/offenses/$offenseId';
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
    return OffenseInformation.fromJson(data);
  }

  /// GET /api/offenses - è·åææè¿æ³è¡ä¸ºä¿¡æ?(ç¨æ·åç®¡çå)
  Future<List<OffenseInformation>> apiOffensesGet() async {
    const path = '/api/offenses';
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
    return jsonList.map((json) => OffenseInformation.fromJson(json)).toList();
  }

  /// PUT /api/offenses/{offenseId} - æ´æ°è¿æ³è¡ä¸ºä¿¡æ¯ (ä»
// ç®¡çå)
  Future<OffenseInformation> apiOffensesOffenseIdPut({
    required int offenseId,
    required OffenseInformation offenseInformation,
    required String idempotencyKey,
  }) async {
    final path = '/api/offenses/$offenseId';
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'PUT',
      _addIdempotencyKey(idempotencyKey),
      offenseInformation.toJson(),
      headerParams,
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      if (response.statusCode == 404) {
        throw ApiException(404, "Offense not found with ID: $offenseId");
      } else if (response.statusCode == 409) {
        throw ApiException(409,
            "Duplicate request detected with idempotencyKey: $idempotencyKey");
      }
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return OffenseInformation.fromJson(data);
  }

  /// DELETE /api/offenses/{offenseId} - å é¤è¿æ³è¡ä¸ºä¿¡æ¯ (ä»
// ç®¡çå)
  Future<void> apiOffensesOffenseIdDelete({
    required int offenseId,
  }) async {
    final path = '/api/offenses/$offenseId';
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
        throw ApiException(404, "Offense not found with ID: $offenseId");
      } else if (response.statusCode == 403) {
        throw ApiException(403, "Unauthorized: Only ADMIN can delete offenses");
      }
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// GET /api/offenses/timeRange - æ ¹æ®æ¶é´èå´è·åè¿æ³è¡ä¸ºä¿¡æ¯ (ç¨æ·åç®¡çå)
  Future<List<OffenseInformation>> apiOffensesTimeRangeGet({
    String startTime = '1970-01-01', // Default matches backend
    String endTime = '2100-01-01', // Default matches backend
  }) async {
    const path = '/api/offenses/search/time-range';
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
    return jsonList.map((json) => OffenseInformation.fromJson(json)).toList();
  }

  /// GET /api/offenses/by-offense-type - æç´¢è¿æ³è¡ä¸ºæç±»å?(ç¨æ·åç®¡çå)
  Future<List<OffenseInformation>> apiOffensesByOffenseTypeGet({
    required String query,
    int page = 1,
    int size = 10,
  }) async {
    if (query.isEmpty) {
      throw ApiException(400, "Missing required param: query");
    }
const path = '/api/offenses/search/code';
    final queryParams = [
      QueryParam('offenseCode', query),
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
    return jsonList.map((json) => OffenseInformation.fromJson(json)).toList();
  }

  /// GET /api/offenses/by-driver-name - æç´¢è¿æ³è¡ä¸ºæå¸æºå§å?(ç¨æ·åç®¡çå)
  Future<List<OffenseInformation>> apiOffensesByDriverNameGet({
    required String query,
    int page = 1,
    int size = 10,
  }) async {
    if (query.isEmpty) {
      throw ApiException(400, "Missing required param: query");
    }
    // Composite: drivers by name -> offenses by driverId
    const driverPath = '/api/drivers/search/name';
    final headerParams = await _getHeaders();
    final driverResp = await apiClient.invokeAPI(
      driverPath,
      'GET',
      [
        QueryParam('keywords', query),
        QueryParam('page', '1'),
        QueryParam('size', '20'),
      ],
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
    if (driverResp.statusCode >= 400) {
      throw ApiException(driverResp.statusCode, _decodeBodyBytes(driverResp));
    }
    if (driverResp.body.isEmpty) return [];
    final List<dynamic> driversJson = jsonDecode(_decodeBodyBytes(driverResp));
    final drivers =
        driversJson.map((e) => DriverInformation.fromJson(e)).toList();
    if (drivers.isEmpty) return [];

    final Map<int, OffenseInformation> merged = {};
    for (final d in drivers) {
      final did = d.driverId;
      if (did == null) continue;
      final offensesResp = await apiClient.invokeAPI(
        '/api/offenses/driver/$did',
        'GET',
        [QueryParam('page', '$page'), QueryParam('size', '$size')],
        null,
        headerParams,
        {},
        null,
        ['bearerAuth'],
      );
      if (offensesResp.statusCode >= 400 || offensesResp.body.isEmpty) {
        continue;
      }
      final List<dynamic> oJson = jsonDecode(_decodeBodyBytes(offensesResp));
      for (final oj in oJson) {
        final oi = OffenseInformation.fromJson(oj);
        if (oi.offenseId != null) {
          merged[oi.offenseId!] = oi;
        }
      }
    }
    return merged.values.toList();
  }

  /// GET /api/offenses/driver/{driverId} - æé©¾é©¶åIDæ¥è¯¢
  Future<List<OffenseInformation>> apiOffensesDriverDriverIdGet({
    required int driverId,
    int page = 1,
    int size = 20,
  }) async {
    final path = '/api/offenses/driver/$driverId';
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
      if (response.statusCode == 204) return [];
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.map((json) => OffenseInformation.fromJson(json)).toList();
  }

  /// GET /api/offenses/vehicle/{vehicleId} - æè½¦è¾IDæ¥è¯¢
  Future<List<OffenseInformation>> apiOffensesVehicleVehicleIdGet({
    required int vehicleId,
    int page = 1,
    int size = 20,
  }) async {
    final path = '/api/offenses/vehicle/$vehicleId';
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
      if (response.statusCode == 204) return [];
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.map((json) => OffenseInformation.fromJson(json)).toList();
  }

  /// GET /api/offenses/search/status?processStatus=... - æå¤çç¶ææ¥è¯?
  Future<List<OffenseInformation>> apiOffensesSearchStatusGet({
    required String processStatus,
    int page = 1,
    int size = 20,
  }) async {
    const path = '/api/offenses/search/status';
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'GET',
      [
        QueryParam('processStatus', processStatus),
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
      if (response.statusCode == 204) return [];
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.map((json) => OffenseInformation.fromJson(json)).toList();
  }

  /// GET /api/offenses/search/number?offenseNumber=... - æè¿æ³ç¼å·æ¥è¯?
  Future<List<OffenseInformation>> apiOffensesSearchNumberGet({
    required String offenseNumber,
    int page = 1,
    int size = 20,
  }) async {
    const path = '/api/offenses/search/number';
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'GET',
      [
        QueryParam('offenseNumber', offenseNumber),
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
      if (response.statusCode == 204) return [];
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.map((json) => OffenseInformation.fromJson(json)).toList();
  }

  /// GET /api/offenses/search/location?offenseLocation=...
  Future<List<OffenseInformation>> apiOffensesSearchLocationGet({
    required String offenseLocation,
    int page = 1,
    int size = 20,
  }) async {
    const path = '/api/offenses/search/location';
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'GET',
      [
        QueryParam('offenseLocation', offenseLocation),
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
      if (response.statusCode == 204) return [];
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.map((json) => OffenseInformation.fromJson(json)).toList();
  }

  /// GET /api/offenses/search/province?offenseProvince=...
  Future<List<OffenseInformation>> apiOffensesSearchProvinceGet({
    required String offenseProvince,
    int page = 1,
    int size = 20,
  }) async {
    const path = '/api/offenses/search/province';
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'GET',
      [
        QueryParam('offenseProvince', offenseProvince),
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
      if (response.statusCode == 204) return [];
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.map((json) => OffenseInformation.fromJson(json)).toList();
  }

  /// GET /api/offenses/search/city?offenseCity=...
  Future<List<OffenseInformation>> apiOffensesSearchCityGet({
    required String offenseCity,
    int page = 1,
    int size = 20,
  }) async {
    const path = '/api/offenses/search/city';
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'GET',
      [
        QueryParam('offenseCity', offenseCity),
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
      if (response.statusCode == 204) return [];
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.map((json) => OffenseInformation.fromJson(json)).toList();
  }

  /// GET /api/offenses/search/notification?notificationStatus=...
  Future<List<OffenseInformation>> apiOffensesSearchNotificationGet({
    required String notificationStatus,
    int page = 1,
    int size = 20,
  }) async {
    const path = '/api/offenses/search/notification';
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'GET',
      [
        QueryParam('notificationStatus', notificationStatus),
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
      if (response.statusCode == 204) return [];
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.map((json) => OffenseInformation.fromJson(json)).toList();
  }

  /// GET /api/offenses/search/agency?enforcementAgency=...
  Future<List<OffenseInformation>> apiOffensesSearchAgencyGet({
    required String enforcementAgency,
    int page = 1,
    int size = 20,
  }) async {
    const path = '/api/offenses/search/agency';
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'GET',
      [
        QueryParam('enforcementAgency', enforcementAgency),
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
      if (response.statusCode == 204) return [];
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.map((json) => OffenseInformation.fromJson(json)).toList();
  }

  /// GET /api/offenses/search/fine-range?minAmount=&maxAmount=&page=&size=
  Future<List<OffenseInformation>> apiOffensesSearchFineRangeGet({
    required double minAmount,
    required double maxAmount,
    int page = 1,
    int size = 20,
  }) async {
    const path = '/api/offenses/search/fine-range';
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'GET',
      [
        QueryParam('minAmount', '$minAmount'),
        QueryParam('maxAmount', '$maxAmount'),
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
      if (response.statusCode == 204) return [];
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.map((json) => OffenseInformation.fromJson(json)).toList();
  }
  /// GET /api/offenses/by-license-plate - æç´¢è¿æ³è¡ä¸ºæè½¦çå· (ç¨æ·åç®¡çå)
  Future<List<OffenseInformation>> apiOffensesByLicensePlateGet({
    required String query,
    int page = 1,
    int size = 10,
  }) async {
    if (query.isEmpty) {
      throw ApiException(400, "Missing required param: query");
    }
    final headerParams = await _getHeaders();
    // Step1: exact search vehicle by license plate
    final vResp = await apiClient.invokeAPI(
      '/api/vehicles/search/license',
      'GET',
      [QueryParam('licensePlate', query)],
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
    if (vResp.statusCode == 404 || vResp.body.isEmpty) {
      return [];
    }
    if (vResp.statusCode >= 400) {
      throw ApiException(vResp.statusCode, _decodeBodyBytes(vResp));
    }
    final vehicle = VehicleInformation.fromJson(
        jsonDecode(_decodeBodyBytes(vResp)) as Map<String, dynamic>);
    if (vehicle.vehicleId == null) return [];

    // Step2: offenses by vehicle id
    final oResp = await apiClient.invokeAPI(
      '/api/offenses/vehicle/${vehicle.vehicleId}',
      'GET',
      [QueryParam('page', '$page'), QueryParam('size', '$size')],
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
    if (oResp.statusCode >= 400) {
      throw ApiException(oResp.statusCode, _decodeBodyBytes(oResp));
    }
    if (oResp.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(oResp));
    return jsonList.map((json) => OffenseInformation.fromJson(json)).toList();
  }

  // WebSocket Methods (Aligned with HTTP Endpoints)

  /// POST /api/offenses (WebSocket)
  Future<void> eventbusOffensesPost({
    required OffenseInformation offenseInformation,
    required String idempotencyKey,
  }) async {
    final msg = {
      'service': 'OffenseInformationService',
      'action': 'checkAndInsertIdempotency',
      'args': [idempotencyKey, offenseInformation.toJson(), 'create'],
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      if (respMap['error'].toString().contains("Duplicate")) {
        throw ApiException(409,
            "Duplicate request detected with idempotencyKey: $idempotencyKey");
      }
      throw ApiException(400, respMap['error']);
    }
  }

  /// GET /api/offenses/{offenseId} (WebSocket)
  Future<OffenseInformation?> eventbusOffensesOffenseIdGet({
    required int offenseId,
  }) async {
    final msg = {
      'service': 'OffenseInformationService',
      'action': 'getOffenseByOffenseId',
      'args': [offenseId],
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      if (respMap['error'].toString().contains("not found")) {
        return null; // Not found, return null
      }
      throw ApiException(400, respMap['error']);
    }
    if (respMap['result'] == null) return null;
    return OffenseInformation.fromJson(
        respMap['result'] as Map<String, dynamic>);
  }

  /// GET /api/offenses (WebSocket)
  Future<List<OffenseInformation>> eventbusOffensesGet() async {
    final msg = {
      'service': 'OffenseInformationService',
      'action': 'getOffensesInformation',
      'args': [],
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      throw ApiException(400, respMap['error']);
    }
    if (respMap['result'] is List) {
      return (respMap['result'] as List)
          .map((json) =>
              OffenseInformation.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// PUT /api/offenses/{offenseId} (WebSocket)
  Future<OffenseInformation?> eventbusOffensesOffenseIdPut({
    required int offenseId,
    required OffenseInformation offenseInformation,
    required String idempotencyKey,
  }) async {
    final msg = {
      'service': 'OffenseInformationService',
      'action': 'checkAndInsertIdempotency',
      'args': [idempotencyKey, offenseInformation.toJson(), 'update'],
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      if (respMap['error'].toString().contains("not found")) {
        throw ApiException(404, "Offense not found with ID: $offenseId");
      } else if (respMap['error'].toString().contains("Duplicate")) {
        throw ApiException(409,
            "Duplicate request detected with idempotencyKey: $idempotencyKey");
      }
      throw ApiException(400, respMap['error']);
    }
    if (respMap['result'] == null) return null;
    return OffenseInformation.fromJson(
        respMap['result'] as Map<String, dynamic>);
  }

  /// DELETE /api/offenses/{offenseId} (WebSocket)
  Future<void> eventbusOffensesOffenseIdDelete({
    required int offenseId,
  }) async {
    final msg = {
      'service': 'OffenseInformationService',
      'action': 'deleteOffense',
      'args': [offenseId],
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      if (respMap['error'].toString().contains("not found")) {
        throw ApiException(404, "Offense not found with ID: $offenseId");
      } else if (respMap['error'].toString().contains("Unauthorized")) {
        throw ApiException(403, "Unauthorized: Only ADMIN can delete offenses");
      }
      throw ApiException(400, respMap['error']);
    }
  }

  /// GET /api/offenses/timeRange (WebSocket)
  Future<List<OffenseInformation>> eventbusOffensesTimeRangeGet({
    String startTime = '1970-01-01',
    String endTime = '2100-01-01',
  }) async {
    final msg = {
      'service': 'OffenseInformationService',
      'action': 'getOffensesByTimeRange',
      'args': [startTime, endTime],
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      throw ApiException(400, respMap['error']);
    }
    if (respMap['result'] is List) {
      return (respMap['result'] as List)
          .map((json) =>
              OffenseInformation.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
