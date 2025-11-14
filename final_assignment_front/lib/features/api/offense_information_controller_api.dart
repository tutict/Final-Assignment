import 'dart:convert';
import 'package:final_assignment_front/features/model/offense_information.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
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

  /// 从 SharedPreferences 中读取 jwtToken 并设置到 ApiClient 中
  Future<void> initializeWithJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null || jwtToken.isEmpty) {
      throw Exception('未登录，请重新登录');
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint(
        'Initialized OffenseInformationControllerApi with token: $jwtToken');
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

  /// POST /api/offenses - 创建违法行为 (仅管理员)
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

  /// GET /api/offenses/{offenseId} - 根据ID获取违法行为信息 (用户及管理员)
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

  /// GET /api/offenses - 获取所有违法行为信息 (用户及管理员)
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

  /// PUT /api/offenses/{offenseId} - 更新违法行为信息 (仅管理员)
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

  /// DELETE /api/offenses/{offenseId} - 删除违法行为信息 (仅管理员)
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

  /// GET /api/offenses/timeRange - 根据时间范围获取违法行为信息 (用户及管理员)
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

  /// GET /api/offenses/by-offense-type - 搜索违法行为按类型 (用户及管理员)
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

  /// GET /api/offenses/by-driver-name - 搜索违法行为按司机姓名 (用户及管理员)
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

  /// GET /api/offenses/driver/{driverId} - 按驾驶员ID查询
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

  /// GET /api/offenses/vehicle/{vehicleId} - 按车辆ID查询
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

  /// GET /api/offenses/search/status?processStatus=... - 按处理状态查询
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

  /// GET /api/offenses/search/number?offenseNumber=... - 按违法编号查询
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
  /// GET /api/offenses/by-license-plate - 搜索违法行为按车牌号 (用户及管理员)
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
