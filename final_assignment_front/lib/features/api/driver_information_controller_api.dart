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
    debugPrint('Initialized DriverInformationControllerApi with token: $jwtToken');
  }

  /// 解码响应体字节到字符串
  String _decodeBodyBytes(Response response) => response.body;

  /// DELETE /api/drivers/{driverId} - 删除司机信息 (仅管理员)
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
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// GET /api/drivers/{driverId} - 根据ID获取司机信息
  Future<DriverInformation?> apiDriversDriverIdGet({required String driverId}) async {
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
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    final data = apiClient.deserialize(_decodeBodyBytes(response), 'Map<String, dynamic>');
    return DriverInformation.fromJson(data);
  }

  /// PUT /api/drivers/{driverId} - 更新司机信息 (仅管理员)
  Future<DriverInformation> apiDriversDriverIdPut({
    required String driverId,
    required DriverInformation driverInformation,
  }) async {
    if (driverId.isEmpty) {
      throw ApiException(400, "Missing required param: driverId");
    }
    final response = await apiClient.invokeAPI(
      '/api/drivers/$driverId',
      'PUT',
      [],
      driverInformation.toJson(),
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final data = apiClient.deserialize(_decodeBodyBytes(response), 'Map<String, dynamic>');
    return DriverInformation.fromJson(data);
  }

  /// GET /api/drivers/driverLicenseNumber/{driverLicenseNumber} - 根据驾照号码获取司机信息
  Future<DriverInformation?> apiDriversDriverLicenseNumberDriverLicenseNumberGet({
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
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    final data = apiClient.deserialize(_decodeBodyBytes(response), 'Map<String, dynamic>');
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
    final List<dynamic> data = apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return DriverInformation.listFromJson(data);
  }

  /// GET /api/drivers/idCardNumber/{idCardNumber} - 根据身份证号码获取司机信息
  Future<DriverInformation?> apiDriversIdCardNumberIdCardNumberGet({required String idCardNumber}) async {
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
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    final data = apiClient.deserialize(_decodeBodyBytes(response), 'Map<String, dynamic>');
    return DriverInformation.fromJson(data);
  }

  /// GET /api/drivers/name/{name} - 根据姓名获取司机信息
  Future<List<DriverInformation>> apiDriversNameNameGet({required String name}) async {
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
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data = apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return DriverInformation.listFromJson(data);
  }

  /// POST /api/drivers - 创建司机信息 (仅管理员)
  Future<DriverInformation> apiDriversPost({required DriverInformation driverInformation}) async {
    final response = await apiClient.invokeAPI(
      '/api/drivers',
      'POST',
      [],
      driverInformation.toJson(),
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final data = apiClient.deserialize(_decodeBodyBytes(response), 'Map<String, dynamic>');
    return DriverInformation.fromJson(data);
  }

  // WebSocket Methods (Aligned with HTTP Endpoints)

  /// DELETE /api/drivers/{driverId} (WebSocket)
  /// 对应后端: @WsAction(service="DriverInformation", action="deleteDriver")
  Future<bool> eventbusDriversDriverIdDelete({required String driverId}) async {
    if (driverId.isEmpty) {
      throw ApiException(400, "Missing required param: driverId");
    }
    final msg = {
      "service": "DriverInformation",
      "action": "deleteDriver",
      "args": [int.parse(driverId)]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return true; // Success if no error
  }

  /// GET /api/drivers/{driverId} (WebSocket)
  /// 对应后端: @WsAction(service="DriverInformation", action="getDriverById")
  Future<Object?> eventbusDriversDriverIdGet({required String driverId}) async {
    if (driverId.isEmpty) {
      throw ApiException(400, "Missing required param: driverId");
    }
    final msg = {
      "service": "DriverInformation",
      "action": "getDriverById",
      "args": [int.parse(driverId)]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// PUT /api/drivers/{driverId} (WebSocket)
  /// 对应后端: @WsAction(service="DriverInformation", action="updateDriver")
  Future<Object?> eventbusDriversDriverIdPut({
    required String driverId,
    required DriverInformation driverInformation,
  }) async {
    if (driverId.isEmpty) {
      throw ApiException(400, "Missing required param: driverId");
    }
    final msg = {
      "service": "DriverInformation",
      "action": "updateDriver",
      "args": [int.parse(driverId), driverInformation.toJson()]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/drivers/driverLicenseNumber/{driverLicenseNumber} (WebSocket)
  /// 对应后端: @WsAction(service="DriverInformation", action="getDriverByDriverLicenseNumber")
  Future<Object?> eventbusDriversDriverLicenseNumberDriverLicenseNumberGet({
    required String driverLicenseNumber,
  }) async {
    if (driverLicenseNumber.isEmpty) {
      throw ApiException(400, "Missing required param: driverLicenseNumber");
    }
    final msg = {
      "service": "DriverInformation",
      "action": "getDriverByDriverLicenseNumber",
      "args": [driverLicenseNumber]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/drivers (WebSocket)
  /// 对应后端: @WsAction(service="DriverInformation", action="getAllDrivers")
  Future<List<Object>?> eventbusDriversGet() async {
    final msg = {
      "service": "DriverInformation",
      "action": "getAllDrivers",
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

  /// GET /api/drivers/idCardNumber/{idCardNumber} (WebSocket)
  /// 对应后端: @WsAction(service="DriverInformation", action="getDriversByIdCardNumber")
  Future<Object?> eventbusDriversIdCardNumberIdCardNumberGet({required String idCardNumber}) async {
    if (idCardNumber.isEmpty) {
      throw ApiException(400, "Missing required param: idCardNumber");
    }
    final msg = {
      "service": "DriverInformation",
      "action": "getDriversByIdCardNumber",
      "args": [idCardNumber]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/drivers/name/{name} (WebSocket)
  /// 对应后端: @WsAction(service="DriverInformation", action="getDriversByName")
  Future<List<Object>?> eventbusDriversNameNameGet({required String name}) async {
    if (name.isEmpty) {
      throw ApiException(400, "Missing required param: name");
    }
    final msg = {
      "service": "DriverInformation",
      "action": "getDriversByName",
      "args": [name]
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

  /// POST /api/drivers (WebSocket)
  /// 对应后端: @WsAction(service="DriverInformation", action="createDriver")
  Future<Object?> eventbusDriversPost({required DriverInformation driverInformation}) async {
    final msg = {
      "service": "DriverInformation",
      "action": "createDriver",
      "args": [driverInformation.toJson()]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }
}