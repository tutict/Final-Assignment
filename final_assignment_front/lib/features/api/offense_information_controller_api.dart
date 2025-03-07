import 'dart:convert';
import 'package:final_assignment_front/features/model/offense_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class OffenseInformationControllerApi {
  final ApiClient apiClient;

  OffenseInformationControllerApi([ApiClient? apiClient])
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

  /// 从 SharedPreferences 中读取 jwtToken 并设置到 ApiClient 中
  Future<void> initializeWithJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('未登录，请重新登录');
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint(
        'Initialized OffenseInformationControllerApi with token: $jwtToken');
  }

  // --- GET /api/offenses ---
  Future<http.Response> apiOffensesGetWithHttpInfo() async {
    const path = "/api/offenses";
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

  Future<List<OffenseInformation>> apiOffensesGet() async {
    final response = await apiOffensesGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
      return jsonList.map((json) => OffenseInformation.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  // --- GET /api/offenses/driverName/{driverName} ---
  Future<http.Response> apiOffensesDriverNameDriverNameGetWithHttpInfo(
      {required String driverName}) async {
    if (driverName.isEmpty) {
      throw ApiException(400, "Missing required param: driverName");
    }

    final path = "/api/offenses/driverName/${Uri.encodeComponent(driverName)}";
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

  Future<List<OffenseInformation>> apiOffensesDriverNameDriverNameGet(
      {required String driverName}) async {
    final response = await apiOffensesDriverNameDriverNameGetWithHttpInfo(
        driverName: driverName);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
      return jsonList.map((json) => OffenseInformation.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  // --- GET /api/offenses/licensePlate/{licensePlate} ---
  Future<http.Response> apiOffensesLicensePlateLicensePlateGetWithHttpInfo(
      {required String licensePlate}) async {
    if (licensePlate.isEmpty) {
      throw ApiException(400, "Missing required param: licensePlate");
    }

    final path =
        "/api/offenses/licensePlate/${Uri.encodeComponent(licensePlate)}";
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

  Future<List<OffenseInformation>> apiOffensesLicensePlateLicensePlateGet(
      {required String licensePlate}) async {
    final response = await apiOffensesLicensePlateLicensePlateGetWithHttpInfo(
        licensePlate: licensePlate);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
      return jsonList.map((json) => OffenseInformation.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  // --- DELETE /api/offenses/{offenseId} ---
  Future<http.Response> apiOffensesOffenseIdDeleteWithHttpInfo(
      {required String offenseId}) async {
    if (offenseId.isEmpty) {
      throw ApiException(400, "Missing required param: offenseId");
    }

    final path = "/api/offenses/$offenseId";
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

  Future<void> apiOffensesOffenseIdDelete({required String offenseId}) async {
    final response =
        await apiOffensesOffenseIdDeleteWithHttpInfo(offenseId: offenseId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  // --- GET /api/offenses/{offenseId} ---
  Future<http.Response> apiOffensesOffenseIdGetWithHttpInfo(
      {required String offenseId}) async {
    if (offenseId.isEmpty) {
      throw ApiException(400, "Missing required param: offenseId");
    }

    final path = "/api/offenses/$offenseId";
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

  Future<OffenseInformation?> apiOffensesOffenseIdGet(
      {required String offenseId}) async {
    final response =
        await apiOffensesOffenseIdGetWithHttpInfo(offenseId: offenseId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return OffenseInformation.fromJson(
          jsonDecode(_decodeBodyBytes(response)));
    }
    return null;
  }

  // --- PUT /api/offenses/{offenseId} ---
  Future<http.Response> apiOffensesOffenseIdPutWithHttpInfo({
    required String offenseId,
    required OffenseInformation offenseInformation,
    required String idempotencyKey,
  }) async {
    if (offenseId.isEmpty) {
      throw ApiException(400, "Missing required param: offenseId");
    }
    if (idempotencyKey.isEmpty) {
      throw ApiException(400, "Missing required param: idempotencyKey");
    }

    final path =
        "/api/offenses/$offenseId?idempotencyKey=${Uri.encodeComponent(idempotencyKey)}";
    final headerParams = await _getHeaders();

    return await apiClient.invokeAPI(
      path,
      'PUT',
      [],
      offenseInformation.toJson(),
      headerParams,
      {},
      'application/json',
      ['bearerAuth'],
    );
  }

  Future<OffenseInformation> apiOffensesOffenseIdPut({
    required String offenseId,
    required OffenseInformation offenseInformation,
    required String idempotencyKey,
  }) async {
    final response = await apiOffensesOffenseIdPutWithHttpInfo(
      offenseId: offenseId,
      offenseInformation: offenseInformation,
      idempotencyKey: idempotencyKey,
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    return OffenseInformation.fromJson(jsonDecode(_decodeBodyBytes(response)));
  }

  // --- POST /api/offenses ---
  Future<http.Response> apiOffensesPostWithHttpInfo({
    required OffenseInformation offenseInformation,
    required String idempotencyKey,
  }) async {
    if (idempotencyKey.isEmpty) {
      throw ApiException(400, "Missing required param: idempotencyKey");
    }

    final path =
        "/api/offenses?idempotencyKey=${Uri.encodeComponent(idempotencyKey)}";
    final headerParams = await _getHeaders();

    return await apiClient.invokeAPI(
      path,
      'POST',
      [],
      offenseInformation.toJson(),
      headerParams,
      {},
      'application/json',
      ['bearerAuth'],
    );
  }

  Future<OffenseInformation?> apiOffensesPost({
    required OffenseInformation offenseInformation,
    required String idempotencyKey,
  }) async {
    final response = await apiOffensesPostWithHttpInfo(
      offenseInformation: offenseInformation,
      idempotencyKey: idempotencyKey,
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return OffenseInformation.fromJson(
          jsonDecode(_decodeBodyBytes(response)));
    }
    return null;
  }

  // --- GET /api/offenses/processState/{processState} ---
  Future<http.Response> apiOffensesProcessStateProcessStateGetWithHttpInfo(
      {required String processState}) async {
    if (processState.isEmpty) {
      throw ApiException(400, "Missing required param: processState");
    }

    final path =
        "/api/offenses/processState/${Uri.encodeComponent(processState)}";
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

  Future<List<OffenseInformation>> apiOffensesProcessStateProcessStateGet(
      {required String processState}) async {
    final response = await apiOffensesProcessStateProcessStateGetWithHttpInfo(
        processState: processState);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
      return jsonList.map((json) => OffenseInformation.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  // --- GET /api/offenses/timeRange ---
  Future<http.Response> apiOffensesTimeRangeGetWithHttpInfo(
      {String? startTime, String? endTime}) async {
    const path = "/api/offenses/timeRange";
    final headerParams = await _getHeaders();
    final queryParams = <QueryParam>[];
    if (startTime != null) queryParams.add(QueryParam("startTime", startTime));
    if (endTime != null) queryParams.add(QueryParam("endTime", endTime));

    return await apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
  }

  Future<List<OffenseInformation>> apiOffensesTimeRangeGet(
      {String? startTime, String? endTime}) async {
    final response = await apiOffensesTimeRangeGetWithHttpInfo(
        startTime: startTime, endTime: endTime);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
      return jsonList.map((json) => OffenseInformation.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  // --- WebSocket Methods ---

  // getAllOffenses (WebSocket)
  Future<List<OffenseInformation>?> eventbusOffensesGet() async {
    final msg = {
      "service": "OffenseInformation",
      "action": "getAllOffenses",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
    if (respMap["result"] is List) {
      return (respMap["result"] as List)
          .map((json) => OffenseInformation.fromJson(json))
          .toList();
    }
    return null;
  }

  // getOffensesByDriverName (WebSocket)
  Future<List<OffenseInformation>?> eventbusOffensesDriverNameDriverNameGet(
      {required String driverName}) async {
    final msg = {
      "service": "OffenseInformation",
      "action": "getOffensesByDriverName",
      "args": [driverName]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
    if (respMap["result"] is List) {
      return (respMap["result"] as List)
          .map((json) => OffenseInformation.fromJson(json))
          .toList();
    }
    return null;
  }

  // getOffensesByLicensePlate (WebSocket)
  Future<List<OffenseInformation>?> eventbusOffensesLicensePlateLicensePlateGet(
      {required String licensePlate}) async {
    final msg = {
      "service": "OffenseInformation",
      "action": "getOffensesByLicensePlate",
      "args": [licensePlate]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
    if (respMap["result"] is List) {
      return (respMap["result"] as List)
          .map((json) => OffenseInformation.fromJson(json))
          .toList();
    }
    return null;
  }

  // deleteOffense (WebSocket)
  Future<void> eventbusOffensesOffenseIdDelete(
      {required String offenseId}) async {
    final msg = {
      "service": "OffenseInformation",
      "action": "deleteOffense",
      "args": [int.parse(offenseId)]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
  }

  // getOffenseById (WebSocket)
  Future<OffenseInformation?> eventbusOffensesOffenseIdGet(
      {required String offenseId}) async {
    final msg = {
      "service": "OffenseInformation",
      "action": "getOffenseById",
      "args": [int.parse(offenseId)]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
    if (respMap["result"] != null) {
      return OffenseInformation.fromJson(respMap["result"]);
    }
    return null;
  }

  // updateOffense (WebSocket)
  Future<OffenseInformation?> eventbusOffensesOffenseIdPut({
    required String offenseId,
    required OffenseInformation offenseInformation,
    required String idempotencyKey,
  }) async {
    if (idempotencyKey.isEmpty) {
      throw ApiException(400, "Missing required param: idempotencyKey");
    }
    final offenseMap = offenseInformation.toJson();
    final msg = {
      "service": "OffenseInformation",
      "action": "updateOffense",
      "args": [int.parse(offenseId), offenseMap, idempotencyKey]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
    if (respMap["result"] != null) {
      return OffenseInformation.fromJson(respMap["result"]);
    }
    return null;
  }

  // createOffense (WebSocket)
  Future<OffenseInformation?> eventbusOffensesPost({
    required OffenseInformation offenseInformation,
    required String idempotencyKey,
  }) async {
    if (idempotencyKey.isEmpty) {
      throw ApiException(400, "Missing required param: idempotencyKey");
    }
    final offenseMap = offenseInformation.toJson();
    final msg = {
      "service": "OffenseInformation",
      "action": "createOffense",
      "args": [offenseMap, idempotencyKey]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
    if (respMap["result"] != null) {
      return OffenseInformation.fromJson(respMap["result"]);
    }
    return null;
  }

  // getOffensesByProcessState (WebSocket)
  Future<List<OffenseInformation>?> eventbusOffensesProcessStateProcessStateGet(
      {required String processState}) async {
    final msg = {
      "service": "OffenseInformation",
      "action": "getOffensesByProcessState",
      "args": [processState]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
    if (respMap["result"] is List) {
      return (respMap["result"] as List)
          .map((json) => OffenseInformation.fromJson(json))
          .toList();
    }
    return null;
  }

  // getOffensesByTimeRange (WebSocket)
  Future<List<OffenseInformation>?> eventbusOffensesTimeRangeGet(
      {String? startTime, String? endTime}) async {
    final msg = {
      "service": "OffenseInformation",
      "action": "getOffensesByTimeRange",
      "args": [startTime ?? "", endTime ?? ""]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
    if (respMap["result"] is List) {
      return (respMap["result"] as List)
          .map((json) => OffenseInformation.fromJson(json))
          .toList();
    }
    return null;
  }
}
