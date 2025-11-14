import 'dart:convert';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class DriverInformationControllerApi {
  final ApiClient apiClient;

  /// 构造函数，可传入 ApiClient，否则使用全局默认实例
  DriverInformationControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  /// 从 SharedPreferences 中读取 jwtToken 并设置到 ApiClient 中
  Future<void> initializeWithJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('未登录，请重新登录');
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint(
        'Initialized DriverInformationControllerApi with token: $jwtToken');
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

  /// POST /api/drivers - 创建司机信息
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

  /// GET /api/drivers/{driverId} - 根据ID获取司机信息
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

  /// GET /api/drivers - 获取所有司机信息
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

  /// PUT /api/drivers/{driverId}/name - 更新司机姓名
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

  /// PUT /api/drivers/{driverId}/contactNumber - 更新司机联系电话
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

  /// PUT /api/drivers/{driverId}/idCardNumber - 更新司机身份证号码
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

  /// PUT /api/drivers/{driverId} - 更新司机完整信息
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

  /// DELETE /api/drivers/{driverId} - 删除司机信息 (仅管理员)
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

  /// GET /api/drivers/by-id-card - 搜索司机信息按身份证号码
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

  /// GET /api/drivers/by-license-number - 搜索司机信息按驾驶证号
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

  /// GET /api/drivers/by-name - 搜索司机信息按姓名
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
