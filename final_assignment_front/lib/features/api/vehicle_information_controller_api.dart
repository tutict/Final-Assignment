import 'package:http/http.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 全局默认 ApiClient 实例
final ApiClient defaultApiClient = ApiClient();

class VehicleInformationControllerApi {
  final ApiClient apiClient;

  /// 构造函数，可传入 ApiClient，否则使用全局默认实例
  VehicleInformationControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  /// 从 SharedPreferences 中读取 jwtToken 并设置到 ApiClient 中
  Future<void> initializeWithJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('未登录，请重新登录');
    }
    apiClient.setJwtToken(jwtToken);
  }

  /// 解码响应体字节到字符串
  String _decodeBodyBytes(Response response) => response.body;

  /// 辅助方法：添加幂等性键到查询参数
  List<QueryParam> _addIdempotencyKey(String idempotencyKey) {
    return [QueryParam('idempotencyKey', idempotencyKey)];
  }

  /// 检查车牌是否存在
  /// GET /api/vehicles/exists/{licensePlate}
  Future<bool> apiVehiclesExistsLicensePlateGet(
      {required String licensePlate}) async {
    final response = await apiClient.invokeAPI(
      '/api/vehicles/exists/$licensePlate',
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
    return apiClient.deserialize(_decodeBodyBytes(response), 'bool') as bool;
  }

  /// 获取所有车辆
  /// GET /api/vehicles
  Future<List<VehicleInformation>> apiVehiclesGet() async {
    final response = await apiClient.invokeAPI(
      '/api/vehicles',
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
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return VehicleInformation.listFromJson(data);
  }

  /// 通过车牌删除车辆 (仅管理员)
  /// DELETE /api/vehicles/license-plate/{licensePlate}
  Future<void> apiVehiclesLicensePlateLicensePlateDelete(
      {required String licensePlate}) async {
    final response = await apiClient.invokeAPI(
      '/api/vehicles/license-plate/$licensePlate',
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

  /// 通过车牌获取车辆
  /// GET /api/vehicles/license-plate/{licensePlate}
  Future<VehicleInformation?> apiVehiclesLicensePlateLicensePlateGet(
      {required String licensePlate}) async {
    final response = await apiClient.invokeAPI(
      '/api/vehicles/license-plate/$licensePlate',
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
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return VehicleInformation.fromJson(data);
  }

  /// 根据车主名称获取车辆
  /// GET /api/vehicles/owner/{ownerName}
  Future<List<VehicleInformation>> apiVehiclesOwnerOwnerNameGet(
      {required String ownerName}) async {
    final response = await apiClient.invokeAPI(
      '/api/vehicles/owner/$ownerName',
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
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return VehicleInformation.listFromJson(data);
  }

  /// 创建车辆 (仅管理员)
  /// POST /api/vehicles
  Future<VehicleInformation> apiVehiclesPost({
    required VehicleInformation vehicleInformation,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/vehicles',
      'POST',
      _addIdempotencyKey(idempotencyKey),
      vehicleInformation.toJson(),
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return VehicleInformation.fromJson(data);
  }

  /// 根据状态获取车辆
  /// GET /api/vehicles/status/{currentStatus}
  Future<List<VehicleInformation>> apiVehiclesStatusCurrentStatusGet(
      {required String currentStatus}) async {
    final response = await apiClient.invokeAPI(
      '/api/vehicles/status/$currentStatus',
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
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return VehicleInformation.listFromJson(data);
  }

  /// 根据类型获取车辆
  /// GET /api/vehicles/type/{vehicleType}
  Future<List<VehicleInformation>> apiVehiclesTypeVehicleTypeGet(
      {required String vehicleType}) async {
    final response = await apiClient.invokeAPI(
      '/api/vehicles/type/$vehicleType',
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
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return VehicleInformation.listFromJson(data);
  }

  /// 根据车辆 ID 删除车辆 (仅管理员)
  /// DELETE /api/vehicles/{vehicleId}
  Future<void> apiVehiclesVehicleIdDelete({required int vehicleId}) async {
    final response = await apiClient.invokeAPI(
      '/api/vehicles/$vehicleId',
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

  /// 根据车辆 ID 获取车辆
  /// GET /api/vehicles/{vehicleId}
  Future<VehicleInformation?> apiVehiclesVehicleIdGet(
      {required int vehicleId}) async {
    final response = await apiClient.invokeAPI(
      '/api/vehicles/$vehicleId',
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
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return VehicleInformation.fromJson(data);
  }

  /// 更新车辆 (仅管理员)
  /// PUT /api/vehicles/{vehicleId}
  Future<VehicleInformation> apiVehiclesVehicleIdPut({
    required int vehicleId,
    required VehicleInformation vehicleInformation,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/vehicles/$vehicleId',
      'PUT',
      _addIdempotencyKey(idempotencyKey),
      vehicleInformation.toJson(),
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return VehicleInformation.fromJson(data);
  }

  // WebSocket 方法（此处保持不变）
  Future<Object?> eventbusVehiclesExistsLicensePlateGet(
      {required String licensePlate}) async {
    final msg = {
      "service": "VehicleInformationService",
      "action": "checkLicensePlateExists",
      "args": [licensePlate]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  Future<List<Object>?> eventbusVehiclesGet() async {
    final msg = {
      "service": "VehicleInformationService",
      "action": "getAllVehicles",
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

  /// Delete vehicle by license plate (WebSocket)
  /// Assumes backend @WsAction(service="VehicleInformationService", action="deleteVehicleByLicensePlate")
  Future<bool> eventbusVehiclesLicensePlateLicensePlateDelete(
      {required String licensePlate}) async {
    final msg = {
      "service": "VehicleInformationService",
      "action": "deleteVehicleByLicensePlate",
      "args": [licensePlate]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return true; // Assumes success if no error
  }

  /// Get vehicle by license plate (WebSocket)
  /// Assumes backend @WsAction(service="VehicleInformationService", action="getVehicleByLicensePlate")
  Future<Object?> eventbusVehiclesLicensePlateLicensePlateGet(
      {required String licensePlate}) async {
    final msg = {
      "service": "VehicleInformationService",
      "action": "getVehicleByLicensePlate",
      "args": [licensePlate]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// Get vehicles by owner name (WebSocket)
  /// Assumes backend @WsAction(service="VehicleInformationService", action="getVehiclesByOwner")
  Future<List<Object>?> eventbusVehiclesOwnerOwnerNameGet(
      {required String ownerName}) async {
    final msg = {
      "service": "VehicleInformationService",
      "action": "getVehiclesByOwner",
      "args": [ownerName]
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

  /// Create a new vehicle (WebSocket)
  /// Assumes backend @WsAction(service="VehicleInformationService", action="createVehicle")
  Future<Object?> eventbusVehiclesPost(
      {required VehicleInformation vehicleInformation}) async {
    final vehicleMap = vehicleInformation.toJson();
    final msg = {
      "service": "VehicleInformationService",
      "action": "createVehicle",
      "args": [vehicleMap]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// Get vehicles by status (WebSocket)
  /// Assumes backend @WsAction(service="VehicleInformationService", action="getVehiclesByStatus")
  Future<List<Object>?> eventbusVehiclesStatusCurrentStatusGet(
      {required String currentStatus}) async {
    final msg = {
      "service": "VehicleInformationService",
      "action": "getVehiclesByStatus",
      "args": [currentStatus]
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

  /// Get vehicles by type (WebSocket)
  /// Assumes backend @WsAction(service="VehicleInformationService", action="getVehicles W由ype")
  Future<List<Object>?> eventbusVehiclesTypeVehicleTypeGet(
      {required String vehicleType}) async {
    final msg = {
      "service": "VehicleInformationService",
      "action": "getVehiclesByType",
      "args": [vehicleType]
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

  /// Delete vehicle by ID (WebSocket)
  /// Assumes backend @WsAction(service="VehicleInformationService", action="deleteVehicleById")
  Future<bool> eventbusVehiclesVehicleIdDelete(
      {required String vehicleId}) async {
    final msg = {
      "service": "VehicleInformationService",
      "action": "deleteVehicleById",
      "args": [int.parse(vehicleId)]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return true;
  }

  /// Get vehicle by ID (WebSocket)
  /// Assumes backend @WsAction(service="VehicleInformationService", action="getVehicleById")
  Future<Object?> eventbusVehiclesVehicleIdGet(
      {required String vehicleId}) async {
    final msg = {
      "service": "VehicleInformationService",
      "action": "getVehicleById",
      "args": [int.parse(vehicleId)]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// Update vehicle (WebSocket)
  /// Assumes backend @WsAction(service="VehicleInformationService", action="updateVehicle")
  Future<Object?> eventbusVehiclesVehicleIdPut({
    required String vehicleId,
    required VehicleInformation vehicleInformation,
  }) async {
    final vehicleMap = vehicleInformation.toJson();
    final msg = {
      "service": "VehicleInformationService",
      "action": "updateVehicle",
      "args": [int.parse(vehicleId), vehicleMap]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }
}
