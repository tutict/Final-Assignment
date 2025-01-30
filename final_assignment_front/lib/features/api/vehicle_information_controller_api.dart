import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:http/http.dart'; // 用于 Response 和 MultipartRequest
import 'package:final_assignment_front/utils/services/api_client.dart'; // 替换为实际路径

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class VehicleInformationControllerApi {
  final ApiClient apiClient;

  /// 更新后的构造函数，apiClient 参数可为空
  VehicleInformationControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  // 解码响应体的辅助方法
  String _decodeBodyBytes(Response response) {
    return response.body;
  }

  /// 检查车牌号是否存在。 with HTTP info returned
  ///
  ///
  Future<Response> apiVehiclesExistsLicensePlateGetWithHttpInfo(
      {required String licensePlate}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/vehicles/exists/{licensePlate}"
        .replaceAll("{format}", "json")
        .replaceAll("{licensePlate}", licensePlate.toString());

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// 检查车牌号是否存在。
  ///
  ///
  Future<Object?> apiVehiclesExistsLicensePlateGet(
      {required String licensePlate}) async {
    Response response = await apiVehiclesExistsLicensePlateGetWithHttpInfo(
        licensePlate: licensePlate);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// 获取所有车辆信息。 with HTTP info returned
  ///
  ///
  Future<Response> apiVehiclesGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/vehicles".replaceAll("{format}", "json");

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// 获取所有车辆信息。
  ///
  ///
  Future<List<Object>?> apiVehiclesGet() async {
    Response response = await apiVehiclesGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }

  /// 根据车牌号删除车辆信息。 with HTTP info returned
  ///
  ///
  Future<Response> apiVehiclesLicensePlateLicensePlateDeleteWithHttpInfo(
      {required String licensePlate}) async {
    Object postBody = ''; // DELETE 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/vehicles/license-plate/{licensePlate}"
        .replaceAll("{format}", "json")
        .replaceAll("{licensePlate}", licensePlate.toString());

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'DELETE', queryParams,
        postBody, headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// 根据车牌号删除车辆信息。
  ///
  ///
  Future<bool> apiVehiclesLicensePlateLicensePlateDelete(
      {required String licensePlate}) async {
    Response response =
        await apiVehiclesLicensePlateLicensePlateDeleteWithHttpInfo(
            licensePlate: licensePlate);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else {
      // 假设 DELETE 请求成功时不返回内容，返回 true
      return true;
    }
  }

  /// 根据车牌号获取车辆信息。 with HTTP info returned
  ///
  ///
  Future<Response> apiVehiclesLicensePlateLicensePlateGetWithHttpInfo(
      {required String licensePlate}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/vehicles/license-plate/{licensePlate}"
        .replaceAll("{format}", "json")
        .replaceAll("{licensePlate}", licensePlate.toString());

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// 根据车牌号获取车辆信息。
  ///
  ///
  Future<Object?> apiVehiclesLicensePlateLicensePlateGet(
      {required String licensePlate}) async {
    Response response =
        await apiVehiclesLicensePlateLicensePlateGetWithHttpInfo(
            licensePlate: licensePlate);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// 根据车主名称获取车辆信息列表。 with HTTP info returned
  ///
  ///
  Future<Response> apiVehiclesOwnerOwnerNameGetWithHttpInfo(
      {required String ownerName}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/vehicles/owner/{ownerName}"
        .replaceAll("{format}", "json")
        .replaceAll("{ownerName}", ownerName.toString());

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// 根据车主名称获取车辆信息列表。
  ///
  ///
  Future<List<Object>?> apiVehiclesOwnerOwnerNameGet(
      {required String ownerName}) async {
    Response response =
        await apiVehiclesOwnerOwnerNameGetWithHttpInfo(ownerName: ownerName);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }

  /// 创建新的车辆信息。 with HTTP info returned
  ///
  ///
  Future<Response> apiVehiclesPostWithHttpInfo(
      {required VehicleInformation vehicleInformation}) async {
    Object postBody = vehicleInformation;

    // 创建路径和映射变量
    String path = "/api/vehicles".replaceAll("{format}", "json");

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = ["application/json"];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'POST', queryParams,
        postBody, headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// 创建新的车辆信息。
  ///
  ///
  Future<Object?> apiVehiclesPost(
      {required VehicleInformation vehicleInformation}) async {
    Response response = await apiVehiclesPostWithHttpInfo(
        vehicleInformation: vehicleInformation);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// 根据车辆状态获取车辆信息列表。 with HTTP info returned
  ///
  ///
  Future<Response> apiVehiclesStatusCurrentStatusGetWithHttpInfo(
      {required String currentStatus}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/vehicles/status/{currentStatus}"
        .replaceAll("{format}", "json")
        .replaceAll("{currentStatus}", currentStatus.toString());

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// 根据车辆状态获取车辆信息列表。
  ///
  ///
  Future<List<Object>?> apiVehiclesStatusCurrentStatusGet(
      {required String currentStatus}) async {
    Response response = await apiVehiclesStatusCurrentStatusGetWithHttpInfo(
        currentStatus: currentStatus);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }

  /// 根据车辆类型获取车辆信息列表。 with HTTP info returned
  ///
  ///
  Future<Response> apiVehiclesTypeVehicleTypeGetWithHttpInfo(
      {required String vehicleType}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/vehicles/type/{vehicleType}"
        .replaceAll("{format}", "json")
        .replaceAll("{vehicleType}", vehicleType.toString());

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// 根据车辆类型获取车辆信息列表。
  ///
  ///
  Future<List<Object>?> apiVehiclesTypeVehicleTypeGet(
      {required String vehicleType}) async {
    Response response = await apiVehiclesTypeVehicleTypeGetWithHttpInfo(
        vehicleType: vehicleType);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }

  /// 根据ID删除车辆信息。 with HTTP info returned
  ///
  ///
  Future<Response> apiVehiclesVehicleIdDeleteWithHttpInfo(
      {required String vehicleId}) async {
    Object postBody = ''; // DELETE 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/vehicles/{vehicleId}"
        .replaceAll("{format}", "json")
        .replaceAll("{vehicleId}", vehicleId.toString());

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'DELETE', queryParams,
        postBody, headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// 根据ID删除车辆信息。
  ///
  ///
  Future<bool> apiVehiclesVehicleIdDelete({required String vehicleId}) async {
    Response response =
        await apiVehiclesVehicleIdDeleteWithHttpInfo(vehicleId: vehicleId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else {
      // 假设 DELETE 请求成功时不返回内容，返回 true
      return true;
    }
  }

  /// 根据ID获取车辆信息。 with HTTP info returned
  ///
  ///
  Future<Response> apiVehiclesVehicleIdGetWithHttpInfo(
      {required String vehicleId}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/vehicles/{vehicleId}"
        .replaceAll("{format}", "json")
        .replaceAll("{vehicleId}", vehicleId.toString());

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// 根据ID获取车辆信息。
  ///
  ///
  Future<Object?> apiVehiclesVehicleIdGet({required String vehicleId}) async {
    Response response =
        await apiVehiclesVehicleIdGetWithHttpInfo(vehicleId: vehicleId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// 更新车辆信息。 with HTTP info returned
  ///
  ///
  Future<Response> apiVehiclesVehicleIdPutWithHttpInfo(
      {required String vehicleId,
      required VehicleInformation vehicleInformation}) async {
    Object postBody = vehicleInformation;

    // 创建路径和映射变量
    String path = "/api/vehicles/{vehicleId}"
        .replaceAll("{format}", "json")
        .replaceAll("{vehicleId}", vehicleId.toString());

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = ["application/json"];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'PUT', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// 更新车辆信息。
  ///
  ///
  Future<Object?> apiVehiclesVehicleIdPut(
      {required String vehicleId,
      required VehicleInformation vehicleInformation}) async {
    Response response = await apiVehiclesVehicleIdPutWithHttpInfo(
        vehicleId: vehicleId, vehicleInformation: vehicleInformation);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// 检查车牌号是否存在 (WebSocket)
  /// 假设后端 @WsAction(service="VehicleInformationService", action="checkLicensePlateExists")
  Future<Object?> eventbusVehiclesExistsLicensePlateGet({required String licensePlate}) async {
    final msg = {
      "service": "VehicleInformationService",
      "action": "checkLicensePlateExists",
      "args": [licensePlate]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if(respMap.containsKey("error")){
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// 获取所有车辆信息 (WebSocket)
  /// 假设后端 @WsAction(service="VehicleInformationService", action="getAllVehicles")
  Future<List<Object>?> eventbusVehiclesGet() async {
    final msg = {
      "service": "VehicleInformationService",
      "action": "getAllVehicles",
      "args": []
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if(respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    if(respMap["result"] is List){
      return (respMap["result"] as List).cast<Object>();
    }
    return null;
  }

  /// 根据车牌号删除车辆信息 (WebSocket)
  /// 假设后端 @WsAction(service="VehicleInformationService", action="deleteVehicleByLicensePlate")
  Future<bool> eventbusVehiclesLicensePlateLicensePlateDelete({required String licensePlate}) async {
    final msg = {
      "service":"VehicleInformationService",
      "action":"deleteVehicleByLicensePlate",
      "args":[ licensePlate ]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if(respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    // 假设删除成功后端不返回内容，就统一返回true
    return true;
  }

  /// 根据车牌号获取车辆信息 (WebSocket)
  /// 假设后端 @WsAction(service="VehicleInformationService", action="getVehicleByLicensePlate")
  Future<Object?> eventbusVehiclesLicensePlateLicensePlateGet({required String licensePlate}) async {
    final msg = {
      "service":"VehicleInformationService",
      "action":"getVehicleByLicensePlate",
      "args":[ licensePlate ]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if(respMap.containsKey("error")){
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// 根据车主名称获取车辆信息列表 (WebSocket)
  /// 假设后端 @WsAction(service="VehicleInformationService", action="getVehiclesByOwner")
  Future<List<Object>?> eventbusVehiclesOwnerOwnerNameGet({required String ownerName}) async {
    final msg = {
      "service":"VehicleInformationService",
      "action":"getVehiclesByOwner",
      "args":[ ownerName ]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if(respMap.containsKey("error")){
      throw ApiException(400, respMap["error"]);
    }
    if(respMap["result"] is List){
      return (respMap["result"] as List).cast<Object>();
    }
    return null;
  }

  /// 创建新的车辆信息 (WebSocket)
  /// 假设后端 @WsAction(service="VehicleInformationService", action="createVehicle")
  Future<Object?> eventbusVehiclesPost({required VehicleInformation vehicleInformation}) async {
    final vehicleMap = vehicleInformation.toJson();
    final msg = {
      "service":"VehicleInformationService",
      "action":"createVehicle",
      "args":[ vehicleMap ]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if(respMap.containsKey("error")){
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// 根据车辆状态获取车辆信息列表 (WebSocket)
  /// 假设后端 @WsAction(service="VehicleInformationService", action="getVehiclesByStatus")
  Future<List<Object>?> eventbusVehiclesStatusCurrentStatusGet({required String currentStatus}) async {
    final msg = {
      "service":"VehicleInformationService",
      "action":"getVehiclesByStatus",
      "args":[ currentStatus ]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if(respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    if(respMap["result"] is List){
      return (respMap["result"] as List).cast<Object>();
    }
    return null;
  }

  /// 根据车辆类型获取车辆信息列表 (WebSocket)
  /// 假设后端 @WsAction(service="VehicleInformationService", action="getVehiclesByType")
  Future<List<Object>?> eventbusVehiclesTypeVehicleTypeGet({required String vehicleType}) async {
    final msg = {
      "service":"VehicleInformationService",
      "action":"getVehiclesByType",
      "args":[ vehicleType ]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if(respMap.containsKey("error")){
      throw ApiException(400, respMap["error"]);
    }
    if(respMap["result"] is List){
      return (respMap["result"] as List).cast<Object>();
    }
    return null;
  }

  /// 根据ID删除车辆信息 (WebSocket)
  /// 假设后端 @WsAction(service="VehicleInformationService", action="deleteVehicleById")
  Future<bool> eventbusVehiclesVehicleIdDelete({required String vehicleId}) async {
    final msg = {
      "service":"VehicleInformationService",
      "action":"deleteVehicleById",
      "args":[ int.parse(vehicleId) ]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if(respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return true;
  }

  /// 根据ID获取车辆信息 (WebSocket)
  /// 假设后端 @WsAction(service="VehicleInformationService", action="getVehicleById")
  Future<Object?> eventbusVehiclesVehicleIdGet({required String vehicleId}) async {
    final msg = {
      "service":"VehicleInformationService",
      "action":"getVehicleById",
      "args":[ int.parse(vehicleId) ]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if(respMap.containsKey("error")){
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// 更新车辆信息 (WebSocket)
  /// 假设后端 @WsAction(service="VehicleInformationService", action="updateVehicle")
  /// 并签名: updateVehicle(int vehicleId, VehicleInformation vehicle)
  Future<Object?> eventbusVehiclesVehicleIdPut({
    required String vehicleId,
    required VehicleInformation vehicleInformation
  }) async {
    final vehicleMap = vehicleInformation.toJson();
    final msg = {
      "service":"VehicleInformationService",
      "action":"updateVehicle",
      "args":[
        int.parse(vehicleId),
        vehicleMap
      ]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if(respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }
}