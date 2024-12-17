import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:http/http.dart'; // 用于 Response 和 MultipartRequest
import 'package:final_assignment_front/utils/services/api_client.dart';

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class DriverInformationControllerApi {
  final ApiClient apiClient;

  // 更新后的构造函数，apiClient 参数可为空
  DriverInformationControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  // 解码响应体的辅助方法
  String _decodeBodyBytes(Response response) {
    return response.body;
  }

  /// deleteDriver with HTTP info returned
  ///
  ///
  Future<Response> apiDriversDriverIdDeleteWithHttpInfo(
      {required String driverId}) async {
    Object postBody = ''; // DELETE 请求通常没有 body

    // 验证必需参数已设置
    if (driverId.isEmpty) {
      throw ApiException(400, "Missing required param: driverId");
    }

    // 创建路径和映射变量
    String path = "/api/drivers/{driverId}"
        .replaceAll("{format}", "json")
        .replaceAll("{driverId}", driverId);

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

  /// deleteDriver
  ///
  ///
  Future<Object?> apiDriversDriverIdDelete({required String driverId}) async {
    Response response =
        await apiDriversDriverIdDeleteWithHttpInfo(driverId: driverId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getDriverById with HTTP info returned
  ///
  ///
  Future<Response> apiDriversDriverIdGetWithHttpInfo(
      {required String driverId}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    if (driverId.isEmpty) {
      throw ApiException(400, "Missing required param: driverId");
    }

    // 创建路径和映射变量
    String path = "/api/drivers/{driverId}"
        .replaceAll("{format}", "json")
        .replaceAll("{driverId}", driverId);

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

  /// getDriverById
  ///
  ///
  Future<Object?> apiDriversDriverIdGet({required String driverId}) async {
    Response response =
        await apiDriversDriverIdGetWithHttpInfo(driverId: driverId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// updateDriver with HTTP info returned
  ///
  ///
  Future<Response> apiDriversDriverIdPutWithHttpInfo(
      {required String driverId, int? updateValue}) async {
    Object postBody = updateValue ?? 0; // 根据实际需求设置默认值

    // 验证必需参数已设置
    if (driverId.isEmpty) {
      throw ApiException(400, "Missing required param: driverId");
    }

    // 创建路径和映射变量
    String path = "/api/drivers/{driverId}"
        .replaceAll("{format}", "json")
        .replaceAll("{driverId}", driverId);

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

  /// updateDriver
  ///
  ///
  Future<Object?> apiDriversDriverIdPut(
      {required String driverId, int? updateValue}) async {
    Response response = await apiDriversDriverIdPutWithHttpInfo(
        driverId: driverId, updateValue: updateValue);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getDriverByDriverLicenseNumber with HTTP info returned
  ///
  ///
  Future<Response>
      apiDriversDriverLicenseNumberDriverLicenseNumberGetWithHttpInfo(
          {required String driverLicenseNumber}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    if (driverLicenseNumber.isEmpty) {
      throw ApiException(400, "Missing required param: driverLicenseNumber");
    }

    // 创建路径和映射变量
    String path = "/api/drivers/driverLicenseNumber/{driverLicenseNumber}"
        .replaceAll("{format}", "json")
        .replaceAll("{driverLicenseNumber}", driverLicenseNumber);

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

  /// getDriverByDriverLicenseNumber
  ///
  ///
  Future<Object?> apiDriversDriverLicenseNumberDriverLicenseNumberGet(
      {required String driverLicenseNumber}) async {
    Response response =
        await apiDriversDriverLicenseNumberDriverLicenseNumberGetWithHttpInfo(
            driverLicenseNumber: driverLicenseNumber);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getAllDrivers with HTTP info returned
  ///
  ///
  Future<Response> apiDriversGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/drivers".replaceAll("{format}", "json");

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

  /// getAllDrivers
  ///
  ///
  Future<List<Object>?> apiDriversGet() async {
    Response response = await apiDriversGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }

  /// getDriversByIdCardNumber with HTTP info returned
  ///
  ///
  Future<Response> apiDriversIdCardNumberIdCardNumberGetWithHttpInfo(
      {required String idCardNumber}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    if (idCardNumber.isEmpty) {
      throw ApiException(400, "Missing required param: idCardNumber");
    }

    // 创建路径和映射变量
    String path = "/api/drivers/idCardNumber/{idCardNumber}"
        .replaceAll("{format}", "json")
        .replaceAll("{idCardNumber}", idCardNumber);

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

  /// getDriversByIdCardNumber
  ///
  ///
  Future<Object?> apiDriversIdCardNumberIdCardNumberGet(
      {required String idCardNumber}) async {
    Response response = await apiDriversIdCardNumberIdCardNumberGetWithHttpInfo(
        idCardNumber: idCardNumber);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getDriversByName with HTTP info returned
  ///
  ///
  Future<Response> apiDriversNameNameGetWithHttpInfo(
      {required String name}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    if (name.isEmpty) {
      throw ApiException(400, "Missing required param: name");
    }

    // 创建路径和映射变量
    String path = "/api/drivers/name/{name}"
        .replaceAll("{format}", "json")
        .replaceAll("{name}", name);

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

  /// getDriversByName
  ///
  ///
  Future<Object?> apiDriversNameNameGet({required String name}) async {
    Response response = await apiDriversNameNameGetWithHttpInfo(name: name);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// createDriver with HTTP info returned
  ///
  ///
  Future<Response> apiDriversPostWithHttpInfo(
      {required DriverInformation driverInformation}) async {
    Object postBody = driverInformation;

    // 创建路径和映射变量
    String path = "/api/drivers".replaceAll("{format}", "json");

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

  /// createDriver
  ///
  ///
  Future<Object?> apiDriversPost(
      {required DriverInformation driverInformation}) async {
    Response response =
        await apiDriversPostWithHttpInfo(driverInformation: driverInformation);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// deleteDriver with HTTP info returned (eventbus)
  ///
  ///
  Future<Response> eventbusDriversDriverIdDeleteWithHttpInfo(
      {required String driverId}) async {
    Object postBody = ''; // DELETE 请求通常没有 body

    // 验证必需参数已设置
    if (driverId.isEmpty) {
      throw ApiException(400, "Missing required param: driverId");
    }

    // 创建路径和映射变量
    String path = "/eventbus/drivers/{driverId}"
        .replaceAll("{format}", "json")
        .replaceAll("{driverId}", driverId);

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

  /// deleteDriver
  ///
  ///
  Future<Object?> eventbusDriversDriverIdDelete(
      {required String driverId}) async {
    Response response =
        await eventbusDriversDriverIdDeleteWithHttpInfo(driverId: driverId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getDriverById with HTTP info returned (eventbus)
  ///
  ///
  Future<Response> eventbusDriversDriverIdGetWithHttpInfo(
      {required String driverId}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    if (driverId.isEmpty) {
      throw ApiException(400, "Missing required param: driverId");
    }

    // 创建路径和映射变量
    String path = "/eventbus/drivers/{driverId}"
        .replaceAll("{format}", "json")
        .replaceAll("{driverId}", driverId);

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

  /// getDriverById
  ///
  ///
  Future<Object?> eventbusDriversDriverIdGet({required String driverId}) async {
    Response response =
        await eventbusDriversDriverIdGetWithHttpInfo(driverId: driverId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// updateDriver with HTTP info returned (eventbus)
  ///
  ///
  Future<Response> eventbusDriversDriverIdPutWithHttpInfo(
      {required String driverId, int? updateValue}) async {
    Object postBody = updateValue ?? 0; // 根据实际需求设置默认值

    // 验证必需参数已设置
    if (driverId.isEmpty) {
      throw ApiException(400, "Missing required param: driverId");
    }

    // 创建路径和映射变量
    String path = "/eventbus/drivers/{driverId}"
        .replaceAll("{format}", "json")
        .replaceAll("{driverId}", driverId);

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

  /// updateDriver (eventbus)
  ///
  ///
  Future<Object?> eventbusDriversDriverIdPut(
      {required String driverId, int? updateValue}) async {
    Response response = await eventbusDriversDriverIdPutWithHttpInfo(
        driverId: driverId, updateValue: updateValue);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getDriverByDriverLicenseNumber with HTTP info returned (eventbus)
  ///
  ///
  Future<Response>
      eventbusDriversDriverLicenseNumberDriverLicenseNumberGetWithHttpInfo(
          {required String driverLicenseNumber}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    if (driverLicenseNumber.isEmpty) {
      throw ApiException(400, "Missing required param: driverLicenseNumber");
    }

    // 创建路径和映射变量
    String path = "/eventbus/drivers/driverLicenseNumber/{driverLicenseNumber}"
        .replaceAll("{format}", "json")
        .replaceAll("{driverLicenseNumber}", driverLicenseNumber);

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

  /// getDriverByDriverLicenseNumber (eventbus)
  ///
  ///
  Future<Object?> eventbusDriversDriverLicenseNumberDriverLicenseNumberGet(
      {required String driverLicenseNumber}) async {
    Response response =
        await eventbusDriversDriverLicenseNumberDriverLicenseNumberGetWithHttpInfo(
            driverLicenseNumber: driverLicenseNumber);
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
