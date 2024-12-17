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

  /// 检查车牌号是否存在。 with HTTP info returned
  ///
  ///
  Future<Response> eventbusVehiclesExistsLicensePlateGetWithHttpInfo(
      {required String licensePlate}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/eventbus/vehicles/exists/{licensePlate}"
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
  Future<Object?> eventbusVehiclesExistsLicensePlateGet(
      {required String licensePlate}) async {
    Response response = await eventbusVehiclesExistsLicensePlateGetWithHttpInfo(
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
  Future<Response> eventbusVehiclesGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/eventbus/vehicles".replaceAll("{format}", "json");

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
  Future<List<Object>?> eventbusVehiclesGet() async {
    Response response = await eventbusVehiclesGetWithHttpInfo();
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
  Future<Response> eventbusVehiclesLicensePlateLicensePlateDeleteWithHttpInfo(
      {required String licensePlate}) async {
    Object postBody = ''; // DELETE 请求通常没有 body

    // 创建路径和映射变量
    String path = "/eventbus/vehicles/license-plate/{licensePlate}"
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
  Future<bool> eventbusVehiclesLicensePlateLicensePlateDelete(
      {required String licensePlate}) async {
    Response response =
        await eventbusVehiclesLicensePlateLicensePlateDeleteWithHttpInfo(
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
  Future<Response> eventbusVehiclesLicensePlateLicensePlateGetWithHttpInfo(
      {required String licensePlate}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/eventbus/vehicles/license-plate/{licensePlate}"
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
  Future<Object?> eventbusVehiclesLicensePlateLicensePlateGet(
      {required String licensePlate}) async {
    Response response =
        await eventbusVehiclesLicensePlateLicensePlateGetWithHttpInfo(
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
  Future<Response> eventbusVehiclesOwnerOwnerNameGetWithHttpInfo(
      {required String ownerName}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/eventbus/vehicles/owner/{ownerName}"
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
  Future<List<Object>?> eventbusVehiclesOwnerOwnerNameGet(
      {required String ownerName}) async {
    Response response = await eventbusVehiclesOwnerOwnerNameGetWithHttpInfo(
        ownerName: ownerName);
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
  Future<Response> eventbusVehiclesPostWithHttpInfo(
      {required VehicleInformation vehicleInformation}) async {
    Object postBody = vehicleInformation;

    // 创建路径和映射变量
    String path = "/eventbus/vehicles".replaceAll("{format}", "json");

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
  Future<Object?> eventbusVehiclesPost(
      {required VehicleInformation vehicleInformation}) async {
    Response response = await eventbusVehiclesPostWithHttpInfo(
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
  Future<Response> eventbusVehiclesStatusCurrentStatusGetWithHttpInfo(
      {required String currentStatus}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/eventbus/vehicles/status/{currentStatus}"
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
  Future<List<Object>?> eventbusVehiclesStatusCurrentStatusGet(
      {required String currentStatus}) async {
    Response response =
        await eventbusVehiclesStatusCurrentStatusGetWithHttpInfo(
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
  Future<Response> eventbusVehiclesTypeVehicleTypeGetWithHttpInfo(
      {required String vehicleType}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/eventbus/vehicles/type/{vehicleType}"
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
  Future<List<Object>?> eventbusVehiclesTypeVehicleTypeGet(
      {required String vehicleType}) async {
    Response response = await eventbusVehiclesTypeVehicleTypeGetWithHttpInfo(
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
  Future<Response> eventbusVehiclesVehicleIdDeleteWithHttpInfo(
      {required String vehicleId}) async {
    Object postBody = ''; // DELETE 请求通常没有 body

    // 创建路径和映射变量
    String path = "/eventbus/vehicles/{vehicleId}"
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
  Future<bool> eventbusVehiclesVehicleIdDelete(
      {required String vehicleId}) async {
    Response response =
        await eventbusVehiclesVehicleIdDeleteWithHttpInfo(vehicleId: vehicleId);
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
  Future<Response> eventbusVehiclesVehicleIdGetWithHttpInfo(
      {required String vehicleId}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/eventbus/vehicles/{vehicleId}"
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
  Future<Object?> eventbusVehiclesVehicleIdGet(
      {required String vehicleId}) async {
    Response response =
        await eventbusVehiclesVehicleIdGetWithHttpInfo(vehicleId: vehicleId);
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
  Future<Response> eventbusVehiclesVehicleIdPutWithHttpInfo(
      {required String vehicleId,
      required VehicleInformation vehicleInformation}) async {
    Object postBody = vehicleInformation;

    // 创建路径和映射变量
    String path = "/eventbus/vehicles/{vehicleId}"
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
  Future<Object?> eventbusVehiclesVehicleIdPut(
      {required String vehicleId,
      required VehicleInformation vehicleInformation}) async {
    Response response = await eventbusVehiclesVehicleIdPutWithHttpInfo(
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
}
