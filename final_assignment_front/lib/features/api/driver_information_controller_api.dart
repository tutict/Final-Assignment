import 'dart:convert';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
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
  String _decodeBodyBytes(Response response) {
    return utf8.decode(response.bodyBytes); // Properly decode UTF-8
  }

  /// 添加 idempotencyKey 作为查询参数
  List<QueryParam> _addIdempotencyKey(String idempotencyKey) {
    return [QueryParam('idempotencyKey', idempotencyKey)];
  }

  /// DELETE /api/drivers/{driverId} - 删除司机信息
  Future<void> apiDriversDriverIdDelete({required String driverId}) async {
    if (driverId.isEmpty) {
      throw ApiException(400, "Missing required param: driverId");
    }
    final response = await apiClient.invokeAPI(
      '/api/drivers/$driverId',
      'DELETE',
      [],
      '',
      {},
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

  /// GET /api/drivers/{driverId} - 根据ID获取司机信息
  Future<DriverInformation?> apiDriversDriverIdGet(
      {required String driverId}) async {
    if (driverId.isEmpty) {
      throw ApiException(400, "Missing required param: driverId");
    }
    final response = await apiClient.invokeAPI(
      '/api/drivers/$driverId',
      'GET',
      [],
      '',
      {},
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
    final decodedBody = _decodeBodyBytes(response);
    debugPrint(
        'Response: ${response.statusCode} - $decodedBody'); // Debug raw response
    final data = apiClient.deserialize(decodedBody, 'Map<String, dynamic>');
    debugPrint(
        'Deserializing JSON: $data to Map<String,dynamic>'); // Debug JSON
    return DriverInformation.fromJson(data);
  }

  /// PUT /api/drivers/{driverId} - 更新司机信息
  Future<void> apiDriversDriverIdPut({
    required String driverId,
    required DriverInformation driverInformation,
    required String idempotencyKey,
  }) async {
    if (driverId.isEmpty) {
      throw ApiException(400, "Missing required param: driverId");
    }
    final response = await apiClient.invokeAPI(
      '/api/drivers/$driverId',
      'PUT',
      _addIdempotencyKey(idempotencyKey),
      driverInformation.toJson(),
      {},
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

  /// GET /api/drivers/driverLicenseNumber/{driverLicenseNumber} - 根据驾照号码获取司机信息
  Future<DriverInformation?>
      apiDriversDriverLicenseNumberDriverLicenseNumberGet({
    required String driverLicenseNumber,
  }) async {
    if (driverLicenseNumber.isEmpty) {
      throw ApiException(400, "Missing required param: driverLicenseNumber");
    }
    final response = await apiClient.invokeAPI(
      '/api/drivers/driverLicenseNumber/$driverLicenseNumber',
      'GET',
      [],
      '',
      {},
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
    final decodedBody = _decodeBodyBytes(response);
    debugPrint('Response: ${response.statusCode} - $decodedBody');
    final data = apiClient.deserialize(decodedBody, 'Map<String, dynamic>');
    debugPrint('Deserializing JSON: $data to Map<String,dynamic>');
    return DriverInformation.fromJson(data);
  }

  /// GET /api/drivers - 获取所有司机信息
  Future<List<DriverInformation>> apiDriversGet() async {
    final response = await apiClient.invokeAPI(
      '/api/drivers',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final decodedBody = _decodeBodyBytes(response);
    debugPrint('Response: ${response.statusCode} - $decodedBody');
    final List<dynamic> data =
        apiClient.deserialize(decodedBody, 'List<dynamic>');
    debugPrint('Deserializing JSON: $data to List<dynamic>');
    return DriverInformation.listFromJson(data);
  }

  /// GET /api/drivers/idCardNumber/{idCardNumber} - 根据身份证号码获取司机信息
  Future<List<DriverInformation>> apiDriversIdCardNumberIdCardNumberGet({
    required String idCardNumber,
  }) async {
    if (idCardNumber.isEmpty) {
      throw ApiException(400, "Missing required param: idCardNumber");
    }
    final response = await apiClient.invokeAPI(
      '/api/drivers/idCardNumber/$idCardNumber',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      if (response.statusCode == 404) {
        return []; // Not found, return empty list
      }
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final decodedBody = _decodeBodyBytes(response);
    debugPrint('Response: ${response.statusCode} - $decodedBody');
    final List<dynamic> data =
        apiClient.deserialize(decodedBody, 'List<dynamic>');
    debugPrint('Deserializing JSON: $data to List<dynamic>');
    return DriverInformation.listFromJson(data);
  }

  /// GET /api/drivers/name/{name} - 根据姓名获取司机信息
  Future<List<DriverInformation>> apiDriversNameNameGet(
      {required String name}) async {
    if (name.isEmpty) {
      throw ApiException(400, "Missing required param: name");
    }
    final response = await apiClient.invokeAPI(
      '/api/drivers/name/$name',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      if (response.statusCode == 404) {
        return []; // Not found, return empty list
      }
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final decodedBody = _decodeBodyBytes(response);
    debugPrint('Response: ${response.statusCode} - $decodedBody');
    final List<dynamic> data =
        apiClient.deserialize(decodedBody, 'List<dynamic>');
    debugPrint('Deserializing JSON: $data to List<dynamic>');
    return DriverInformation.listFromJson(data);
  }

  /// POST /api/drivers - 创建司机信息
  Future<void> apiDriversPost({
    required DriverInformation driverInformation,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/drivers',
      'POST',
      _addIdempotencyKey(idempotencyKey),
      driverInformation.toJson(),
      {},
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

  // WebSocket Methods (Aligned with HTTP Endpoints)

  /// DELETE /api/drivers/{driverId} (WebSocket)
  /// 对应后端: @WsAction(service="DriverInformationService", action="deleteDriver")
  Future<void> eventbusDriversDriverIdDelete({required String driverId}) async {
    if (driverId.isEmpty) {
      throw ApiException(400, "Missing required param: driverId");
    }
    final msg = {
      "service": "DriverInformationService",
      "action": "deleteDriver",
      "args": [int.parse(driverId)]
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

  /// GET /api/drivers/{driverId} (WebSocket)
  /// 对应后端: @WsAction(service="DriverInformationService", action="getDriverById")
  Future<DriverInformation?> eventbusDriversDriverIdGet(
      {required String driverId}) async {
    if (driverId.isEmpty) {
      throw ApiException(400, "Missing required param: driverId");
    }
    final msg = {
      "service": "DriverInformationService",
      "action": "getDriverById",
      "args": [int.parse(driverId)]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      if (respMap["error"].toString().contains("not found")) {
        return null; // Not found, return null
      }
      throw ApiException(400, respMap["error"]);
    }
    if (respMap["result"] == null) return null;
    debugPrint('WebSocket Response: $respMap'); // Debug WebSocket response
    return DriverInformation.fromJson(
        respMap["result"] as Map<String, dynamic>);
  }

  /// PUT /api/drivers/{driverId} (WebSocket)
  /// 对应后端: @WsAction(service="DriverInformationService", action="updateDriver")
  Future<void> eventbusDriversDriverIdPut({
    required String driverId,
    required DriverInformation driverInformation,
    required String idempotencyKey,
  }) async {
    if (driverId.isEmpty) {
      throw ApiException(400, "Missing required param: driverId");
    }
    final msg = {
      "service": "DriverInformationService",
      "action": "updateDriver",
      "args": [int.parse(driverId), driverInformation.toJson(), idempotencyKey]
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

  /// GET /api/drivers/driverLicenseNumber/{driverLicenseNumber} (WebSocket)
  /// 对应后端: @WsAction(service="DriverInformationService", action="getDriverByDriverLicenseNumber")
  Future<DriverInformation?>
      eventbusDriversDriverLicenseNumberDriverLicenseNumberGet({
    required String driverLicenseNumber,
  }) async {
    if (driverLicenseNumber.isEmpty) {
      throw ApiException(400, "Missing required param: driverLicenseNumber");
    }
    final msg = {
      "service": "DriverInformationService",
      "action": "getDriverByDriverLicenseNumber",
      "args": [driverLicenseNumber]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      if (respMap["error"].toString().contains("not found")) {
        return null; // Not found, return null
      }
      throw ApiException(400, respMap["error"]);
    }
    if (respMap["result"] == null) return null;
    debugPrint('WebSocket Response: $respMap');
    return DriverInformation.fromJson(
        respMap["result"] as Map<String, dynamic>);
  }

  /// GET /api/drivers (WebSocket)
  /// 对应后端: @WsAction(service="DriverInformationService", action="getAllDrivers")
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
      debugPrint('WebSocket Response: $respMap');
      return DriverInformation.listFromJson(respMap["result"] as List<dynamic>);
    }
    return [];
  }

  /// GET /api/drivers/idCardNumber/{idCardNumber} (WebSocket)
  /// 对应后端: @WsAction(service="DriverInformationService", action="getDriversByIdCardNumber")
  Future<List<DriverInformation>> eventbusDriversIdCardNumberIdCardNumberGet({
    required String idCardNumber,
  }) async {
    if (idCardNumber.isEmpty) {
      throw ApiException(400, "Missing required param: idCardNumber");
    }
    final msg = {
      "service": "DriverInformationService",
      "action": "getDriversByIdCardNumber",
      "args": [idCardNumber]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      if (respMap["error"].toString().contains("not found")) {
        return []; // Not found, return empty list
      }
      throw ApiException(400, respMap["error"]);
    }
    if (respMap["result"] is List) {
      debugPrint('WebSocket Response: $respMap');
      return DriverInformation.listFromJson(respMap["result"] as List<dynamic>);
    }
    return [];
  }

  /// GET /api/drivers/name/{name} (WebSocket)
  /// 对应后端: @WsAction(service="DriverInformationService", action="getDriversByName")
  Future<List<DriverInformation>> eventbusDriversNameNameGet(
      {required String name}) async {
    if (name.isEmpty) {
      throw ApiException(400, "Missing required param: name");
    }
    final msg = {
      "service": "DriverInformationService",
      "action": "getDriversByName",
      "args": [name]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      if (respMap["error"].toString().contains("not found")) {
        return []; // Not found, return empty list
      }
      throw ApiException(400, respMap["error"]);
    }
    if (respMap["result"] is List) {
      debugPrint('WebSocket Response: $respMap');
      return DriverInformation.listFromJson(respMap["result"] as List<dynamic>);
    }
    return [];
  }

  /// POST /api/drivers (WebSocket)
  /// 对应后端: @WsAction(service="DriverInformationService", action="createDriver")
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
}
