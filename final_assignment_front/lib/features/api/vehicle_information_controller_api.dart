import 'package:http/http.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ApiClient defaultApiClient = ApiClient();

class VehicleInformationControllerApi {
  final ApiClient apiClient;

  VehicleInformationControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  Future<void> initializeWithJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('未登录，请重新登录');
    }
    apiClient.setJwtToken(jwtToken);
  }

  String _decodeBodyBytes(Response response) => response.body;

  List<QueryParam> _addIdempotencyKey(String idempotencyKey) {
    return [QueryParam('idempotencyKey', idempotencyKey)];
  }

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
    final List<dynamic> data = apiClient.deserialize(
        _decodeBodyBytes(response), 'List<VehicleInformation>');
    return data.map((item) => item as VehicleInformation).toList();
  }

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
    if (response.statusCode == 404) {
      return null; // No vehicle found
    }
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return VehicleInformation.fromJson(data);
  }

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
    final List<dynamic> data = apiClient.deserialize(
        _decodeBodyBytes(response), 'List<VehicleInformation>');
    return data.map((item) => item as VehicleInformation).toList();
  }

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
    final List<dynamic> data = apiClient.deserialize(
        _decodeBodyBytes(response), 'List<VehicleInformation>');
    return data.map((item) => item as VehicleInformation).toList();
  }

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
    final List<dynamic> data = apiClient.deserialize(
        _decodeBodyBytes(response), 'List<VehicleInformation>');
    return data.map((item) => item as VehicleInformation).toList();
  }

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
    if (response.statusCode == 404) {
      return null; // No vehicle found
    }
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return VehicleInformation.fromJson(data);
  }

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

  // WebSocket methods (unchanged)
  Future<Object?> eventbusVehiclesExistsLicensePlateGet(
      {required String licensePlate}) async {
    final msg = {
      "service": "VehicleInformationService",
      "action": "checkLicensePlateExists",
      "args": [licensePlate]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
    return respMap["result"];
  }

  Future<List<Object>?> eventbusVehiclesGet() async {
    final msg = {
      "service": "VehicleInformationService",
      "action": "getAllVehicles",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
    if (respMap["result"] is List) {
      return (respMap["result"] as List).cast<Object>();
    }
    return null;
  }

  Future<bool> eventbusVehiclesLicensePlateLicensePlateDelete(
      {required String licensePlate}) async {
    final msg = {
      "service": "VehicleInformationService",
      "action": "deleteVehicleByLicensePlate",
      "args": [licensePlate]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
    return true;
  }

  Future<Object?> eventbusVehiclesLicensePlateLicensePlateGet(
      {required String licensePlate}) async {
    final msg = {
      "service": "VehicleInformationService",
      "action": "getVehicleByLicensePlate",
      "args": [licensePlate]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
    return respMap["result"];
  }

  Future<List<Object>?> eventbusVehiclesOwnerOwnerNameGet(
      {required String ownerName}) async {
    final msg = {
      "service": "VehicleInformationService",
      "action": "getVehiclesByOwner",
      "args": [ownerName]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
    if (respMap["result"] is List) {
      return (respMap["result"] as List).cast<Object>();
    }
    return null;
  }

  Future<Object?> eventbusVehiclesPost(
      {required VehicleInformation vehicleInformation}) async {
    final vehicleMap = vehicleInformation.toJson();
    final msg = {
      "service": "VehicleInformationService",
      "action": "createVehicle",
      "args": [vehicleMap]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
    return respMap["result"];
  }

  Future<List<Object>?> eventbusVehiclesStatusCurrentStatusGet(
      {required String currentStatus}) async {
    final msg = {
      "service": "VehicleInformationService",
      "action": "getVehiclesByStatus",
      "args": [currentStatus]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
    if (respMap["result"] is List) {
      return (respMap["result"] as List).cast<Object>();
    }
    return null;
  }

  Future<List<Object>?> eventbusVehiclesTypeVehicleTypeGet(
      {required String vehicleType}) async {
    final msg = {
      "service": "VehicleInformationService",
      "action": "getVehiclesByType",
      "args": [vehicleType]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
    if (respMap["result"] is List) {
      return (respMap["result"] as List).cast<Object>();
    }
    return null;
  }

  Future<bool> eventbusVehiclesVehicleIdDelete(
      {required String vehicleId}) async {
    final msg = {
      "service": "VehicleInformationService",
      "action": "deleteVehicleById",
      "args": [int.parse(vehicleId)]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
    return true;
  }

  Future<Object?> eventbusVehiclesVehicleIdGet(
      {required String vehicleId}) async {
    final msg = {
      "service": "VehicleInformationService",
      "action": "getVehicleById",
      "args": [int.parse(vehicleId)]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
    return respMap["result"];
  }

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
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
    return respMap["result"];
  }
}
