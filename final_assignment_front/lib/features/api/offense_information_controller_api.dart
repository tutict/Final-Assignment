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

  Future<Map<String, String>> _getHeaders(
      {Map<String, String>? extraHeaders}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken') ?? '';
    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    if (extraHeaders != null) headers.addAll(extraHeaders);
    return headers;
  }

  /// 从 SharedPreferences 中读取 jwtToken 并设置到 ApiClient 中
  Future<void> initializeWithJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null || jwtToken.isEmpty) {
      throw Exception('未登录，请重新登录');
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint('Initialized OffenseInformationControllerApi with token: $jwtToken');
  }

  // --- GET /api/offenses ---
  Future<http.Response> apiOffensesGetWithHttpInfo({int page = 0, int size = 10}) async {
    final path = '/api/offenses?page=$page&size=$size';
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

  Future<List<OffenseInformation>> apiOffensesGet({int page = 0, int size = 10}) async {
    final response = await apiOffensesGetWithHttpInfo(page: page, size: size);
    if (response.statusCode == 200) {
      if (response.body.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
        return jsonList.map((json) => OffenseInformation.fromJson(json)).toList();
      }
      return [];
    }
    throw ApiException(response.statusCode, _decodeBodyBytes(response));
  }

  // --- GET /api/offenses/{offenseId} ---
  Future<http.Response> apiOffensesOffenseIdGetWithHttpInfo({required int offenseId}) async {
    final path = '/api/offenses/$offenseId';
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

  Future<OffenseInformation?> apiOffensesOffenseIdGet({required int offenseId}) async {
    final response = await apiOffensesOffenseIdGetWithHttpInfo(offenseId: offenseId);
    if (response.statusCode == 200) {
      if (response.body.isNotEmpty) {
        return OffenseInformation.fromJson(jsonDecode(_decodeBodyBytes(response)));
      }
      return null;
    } else if (response.statusCode == 404) {
      return null;
    }
    throw ApiException(response.statusCode, _decodeBodyBytes(response));
  }

  // --- POST /api/offenses ---
  Future<http.Response> apiOffensesPostWithHttpInfo({
    required OffenseInformation offenseInformation,
    required String idempotencyKey,
  }) async {
    final path = '/api/offenses?idempotencyKey=${Uri.encodeQueryComponent(idempotencyKey)}';
    final headerParams = await _getHeaders();
    final body = jsonEncode(offenseInformation.toJson());

    return await apiClient.invokeAPI(
      path,
      'POST',
      [],
      body,
      headerParams,
      {},
      'application/json',
      ['bearerAuth'],
    );
  }

  Future<void> apiOffensesPost({
    required OffenseInformation offenseInformation,
    required String idempotencyKey,
  }) async {
    final response = await apiOffensesPostWithHttpInfo(
      offenseInformation: offenseInformation,
      idempotencyKey: idempotencyKey,
    );
    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  // --- PUT /api/offenses/{offenseId} ---
  Future<http.Response> apiOffensesOffenseIdPutWithHttpInfo({
    required int offenseId,
    required OffenseInformation offenseInformation,
    required String idempotencyKey,
  }) async {
    final path = '/api/offenses/$offenseId?idempotencyKey=${Uri.encodeQueryComponent(idempotencyKey)}';
    final headerParams = await _getHeaders();
    final body = jsonEncode(offenseInformation.toJson());

    return await apiClient.invokeAPI(
      path,
      'PUT',
      [],
      body,
      headerParams,
      {},
      'application/json',
      ['bearerAuth'],
    );
  }

  Future<OffenseInformation> apiOffensesOffenseIdPut({
    required int offenseId,
    required OffenseInformation offenseInformation,
    required String idempotencyKey,
  }) async {
    final response = await apiOffensesOffenseIdPutWithHttpInfo(
      offenseId: offenseId,
      offenseInformation: offenseInformation,
      idempotencyKey: idempotencyKey,
    );
    if (response.statusCode == 200) {
      return OffenseInformation.fromJson(jsonDecode(_decodeBodyBytes(response)));
    }
    throw ApiException(response.statusCode, _decodeBodyBytes(response));
  }

  // --- DELETE /api/offenses/{offenseId} ---
  Future<http.Response> apiOffensesOffenseIdDeleteWithHttpInfo({required int offenseId}) async {
    final path = '/api/offenses/$offenseId';
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

  Future<void> apiOffensesOffenseIdDelete({required int offenseId}) async {
    final response = await apiOffensesOffenseIdDeleteWithHttpInfo(offenseId: offenseId);
    if (response.statusCode != 204) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  // --- GET /api/offenses/timeRange ---
  Future<http.Response> apiOffensesTimeRangeGetWithHttpInfo({
    required DateTime startTime,
    required DateTime endTime,
    int page = 0,
    int size = 10,
  }) async {
    final path = '/api/offenses/timeRange?startTime=${startTime.toIso8601String()}&endTime=${endTime.toIso8601String()}&page=$page&size=$size';
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

  Future<List<OffenseInformation>> apiOffensesTimeRangeGet({
    required DateTime startTime,
    required DateTime endTime,
    int page = 0,
    int size = 10,
  }) async {
    final response = await apiOffensesTimeRangeGetWithHttpInfo(
      startTime: startTime,
      endTime: endTime,
      page: page,
      size: size,
    );
    if (response.statusCode == 200) {
      if (response.body.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
        return jsonList.map((json) => OffenseInformation.fromJson(json)).toList();
      }
      return [];
    }
    throw ApiException(response.statusCode, _decodeBodyBytes(response));
  }

  // --- GET /api/offenses/processState/{processState} ---
  Future<http.Response> apiOffensesProcessStateGetWithHttpInfo({
    required String processState,
    int page = 0,
    int size = 10,
  }) async {
    final path = '/api/offenses/processState/${Uri.encodeComponent(processState)}?page=$page&size=$size';
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

  Future<List<OffenseInformation>> apiOffensesProcessStateGet({
    required String processState,
    int page = 0,
    int size = 10,
  }) async {
    final response = await apiOffensesProcessStateGetWithHttpInfo(
      processState: processState,
      page: page,
      size: size,
    );
    if (response.statusCode == 200) {
      if (response.body.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
        return jsonList.map((json) => OffenseInformation.fromJson(json)).toList();
      }
      return [];
    }
    throw ApiException(response.statusCode, _decodeBodyBytes(response));
  }

  // --- GET /api/offenses/driverName/{driverName} ---
  Future<http.Response> apiOffensesDriverNameGetWithHttpInfo({
    required String driverName,
    int page = 0,
    int size = 10,
  }) async {
    final path = '/api/offenses/driverName/${Uri.encodeComponent(driverName)}?page=$page&size=$size';
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

  Future<List<OffenseInformation>> apiOffensesDriverNameGet({
    required String driverName,
    int page = 0,
    int size = 10,
  }) async {
    final response = await apiOffensesDriverNameGetWithHttpInfo(
      driverName: driverName,
      page: page,
      size: size,
    );
    if (response.statusCode == 200) {
      if (response.body.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
        return jsonList.map((json) => OffenseInformation.fromJson(json)).toList();
      }
      return [];
    }
    throw ApiException(response.statusCode, _decodeBodyBytes(response));
  }

  // --- GET /api/offenses/licensePlate/{licensePlate} ---
  Future<http.Response> apiOffensesLicensePlateGetWithHttpInfo({
    required String licensePlate,
    int page = 0,
    int size = 10,
  }) async {
    final path = '/api/offenses/licensePlate/${Uri.encodeComponent(licensePlate)}?page=$page&size=$size';
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

  Future<List<OffenseInformation>> apiOffensesLicensePlateGet({
    required String licensePlate,
    int page = 0,
    int size = 10,
  }) async {
    final response = await apiOffensesLicensePlateGetWithHttpInfo(
      licensePlate: licensePlate,
      page: page,
      size: size,
    );
    if (response.statusCode == 200) {
      if (response.body.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
        return jsonList.map((json) => OffenseInformation.fromJson(json)).toList();
      }
      return [];
    }
    throw ApiException(response.statusCode, _decodeBodyBytes(response));
  }

  // --- WebSocket Methods ---

  // getAllOffenses (WebSocket)
  Future<List<OffenseInformation>?> eventbusOffensesGet({int page = 0, int size = 10}) async {
    final msg = {
      'service': 'OffenseInformationService',
      'action': 'getOffensesInformation',
      'args': [page, size],
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) throw ApiException(400, respMap['error']);
    if (respMap['result'] is List) {
      return (respMap['result'] as List).map((json) => OffenseInformation.fromJson(json)).toList();
    }
    return [];
  }

  // getOffenseById (WebSocket)
  Future<OffenseInformation?> eventbusOffensesOffenseIdGet({required int offenseId}) async {
    final msg = {
      'service': 'OffenseInformationService',
      'action': 'getOffenseByOffenseId',
      'args': [offenseId],
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) throw ApiException(400, respMap['error']);
    if (respMap['result'] != null) {
      return OffenseInformation.fromJson(respMap['result']);
    }
    return null;
  }

  // createOffense (WebSocket)
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
    if (respMap.containsKey('error')) throw ApiException(400, respMap['error']);
  }

  // updateOffense (WebSocket)
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
    if (respMap.containsKey('error')) throw ApiException(400, respMap['error']);
    if (respMap['result'] != null) {
      return OffenseInformation.fromJson(respMap['result']);
    }
    return null;
  }

  // deleteOffense (WebSocket)
  Future<void> eventbusOffensesOffenseIdDelete({required int offenseId}) async {
    final msg = {
      'service': 'OffenseInformationService',
      'action': 'deleteOffense',
      'args': [offenseId],
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) throw ApiException(400, respMap['error']);
  }

  // getOffensesByTimeRange (WebSocket)
  Future<List<OffenseInformation>?> eventbusOffensesTimeRangeGet({
    required DateTime startTime,
    required DateTime endTime,
    int page = 0,
    int size = 10,
  }) async {
    final msg = {
      'service': 'OffenseInformationService',
      'action': 'getOffensesByTimeRange',
      'args': [startTime.toIso8601String(), endTime.toIso8601String(), page, size],
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) throw ApiException(400, respMap['error']);
    if (respMap['result'] is List) {
      return (respMap['result'] as List).map((json) => OffenseInformation.fromJson(json)).toList();
    }
    return [];
  }

  // getOffensesByProcessState (WebSocket)
  Future<List<OffenseInformation>?> eventbusOffensesProcessStateGet({
    required String processState,
    int page = 0,
    int size = 10,
  }) async {
    final msg = {
      'service': 'OffenseInformationService',
      'action': 'getOffensesByProcessState',
      'args': [processState, page, size],
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) throw ApiException(400, respMap['error']);
    if (respMap['result'] is List) {
      return (respMap['result'] as List).map((json) => OffenseInformation.fromJson(json)).toList();
    }
    return [];
  }

  // getOffensesByDriverName (WebSocket)
  Future<List<OffenseInformation>?> eventbusOffensesDriverNameGet({
    required String driverName,
    int page = 0,
    int size = 10,
  }) async {
    final msg = {
      'service': 'OffenseInformationService',
      'action': 'getOffensesByDriverName',
      'args': [driverName, page, size],
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) throw ApiException(400, respMap['error']);
    if (respMap['result'] is List) {
      return (respMap['result'] as List).map((json) => OffenseInformation.fromJson(json)).toList();
    }
    return [];
  }

  // getOffensesByLicensePlate (WebSocket)
  Future<List<OffenseInformation>?> eventbusOffensesLicensePlateGet({
    required String licensePlate,
    int page = 0,
    int size = 10,
  }) async {
    final msg = {
      'service': 'OffenseInformationService',
      'action': 'getOffensesByLicensePlate',
      'args': [licensePlate, page, size],
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) throw ApiException(400, respMap['error']);
    if (respMap['result'] is List) {
      return (respMap['result'] as List).map((json) => OffenseInformation.fromJson(json)).toList();
    }
    return [];
  }
}