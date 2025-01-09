import 'dart:convert';

import 'package:final_assignment_front/features/model/appeal_management.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:http/http.dart'; // 用于 Response 和 MultipartRequest
import 'package:final_assignment_front/utils/services/api_client.dart';

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class AppealManagementControllerApi {
  final ApiClient apiClient;

  // 更新后的构造函数，apiClient 参数可为空
  AppealManagementControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  // 解码响应体的辅助方法
  String _decodeBodyBytes(Response response) {
    return response.body;
  }

  /// deleteAppeal with HTTP info returned
  ///
  ///
  Future<Response> apiAppealsAppealIdDeleteWithHttpInfo(
      {required String appealId}) async {
    Object postBody = ''; // DELETE 请求通常没有 body

    // 验证必需参数已设置
    if (appealId.isEmpty) {
      throw ApiException(400, "Missing required param: appealId");
    }

    // 创建路径和映射变量
    String path = "/api/appeals/{appealId}"
        .replaceAll("{format}", "json")
        .replaceAll("{appealId}", appealId);

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

  /// deleteAppeal
  ///
  ///
  Future<Object?> apiAppealsAppealIdDelete({required String appealId}) async {
    Response response =
        await apiAppealsAppealIdDeleteWithHttpInfo(appealId: appealId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getAppealById with HTTP info returned
  ///
  ///
  Future<Response> apiAppealsAppealIdGetWithHttpInfo(
      {required String appealId}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    if (appealId.isEmpty) {
      throw ApiException(400, "Missing required param: appealId");
    }

    // 创建路径和映射变量
    String path = "/api/appeals/{appealId}"
        .replaceAll("{format}", "json")
        .replaceAll("{appealId}", appealId);

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

  /// getAppealById
  ///
  ///
  Future<Object?> apiAppealsAppealIdGet({required String appealId}) async {
    Response response =
        await apiAppealsAppealIdGetWithHttpInfo(appealId: appealId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getOffenseByAppealId with HTTP info returned
  ///
  ///
  Future<Response> apiAppealsAppealIdOffenseGetWithHttpInfo(
      {required String appealId}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    if (appealId.isEmpty) {
      throw ApiException(400, "Missing required param: appealId");
    }

    // 创建路径和映射变量
    String path = "/api/appeals/{appealId}/offense"
        .replaceAll("{format}", "json")
        .replaceAll("{appealId}", appealId);

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

  /// getOffenseByAppealId
  ///
  ///
  Future<Object?> apiAppealsAppealIdOffenseGet(
      {required String appealId}) async {
    Response response =
        await apiAppealsAppealIdOffenseGetWithHttpInfo(appealId: appealId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// updateAppeal with HTTP info returned
  ///
  ///
  Future<Response> apiAppealsAppealIdPutWithHttpInfo(
      {required String appealId, int? integer}) async {
    Object postBody = integer ?? 0; // 根据实际需求设置默认值

    // 验证必需参数已设置
    if (appealId.isEmpty) {
      throw ApiException(400, "Missing required param: appealId");
    }

    // 创建路径和映射变量
    String path = "/api/appeals/{appealId}"
        .replaceAll("{format}", "json")
        .replaceAll("{appealId}", appealId);

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

  /// updateAppeal
  ///
  ///
  Future<Object?> apiAppealsAppealIdPut(
      {required String appealId, int? integer}) async {
    Response response = await apiAppealsAppealIdPutWithHttpInfo(
        appealId: appealId, integer: integer);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getAllAppeals with HTTP info returned
  ///
  ///
  Future<Response> apiAppealsGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/appeals".replaceAll("{format}", "json");

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

  /// getAllAppeals
  ///
  ///
  Future<List<AppealManagement>?> apiAppealsGet() async {
    Response response = await apiAppealsGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
      return AppealManagement.listFromJson(jsonList);
    } else {
      return null;
    }
  }

  /// getAppealsByAppealName with HTTP info returned
  ///
  ///
  Future<Response> apiAppealsNameAppealNameGetWithHttpInfo(
      {required String appealName}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    if (appealName.isEmpty) {
      throw ApiException(400, "Missing required param: appealName");
    }

    // 创建路径和映射变量
    String path = "/api/appeals/name/{appealName}"
        .replaceAll("{format}", "json")
        .replaceAll("{appealName}", appealName);

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

  /// getAppealsByAppealName
  ///
  ///
  Future<Object?> apiAppealsNameAppealNameGet(
      {required String appealName}) async {
    Response response =
        await apiAppealsNameAppealNameGetWithHttpInfo(appealName: appealName);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// createAppeal with HTTP info returned
  ///
  ///
  Future<Response> apiAppealsPostWithHttpInfo(
      {required AppealManagement appealManagement}) async {
    Object postBody = appealManagement;

    // 创建路径和映射变量
    String path = "/api/appeals".replaceAll("{format}", "json");

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

  /// createAppeal
  ///
  ///
  Future<Object?> apiAppealsPost(
      {required AppealManagement appealManagement}) async {
    Response response =
        await apiAppealsPostWithHttpInfo(appealManagement: appealManagement);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getAppealsByProcessStatus with HTTP info returned
  ///
  ///
  Future<Response> apiAppealsStatusProcessStatusGetWithHttpInfo(
      {required String processStatus}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    if (processStatus.isEmpty) {
      throw ApiException(400, "Missing required param: processStatus");
    }

    // 创建路径和映射变量
    String path = "/api/appeals/status/{processStatus}"
        .replaceAll("{format}", "json")
        .replaceAll("{processStatus}", processStatus);

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

  /// getAppealsByProcessStatus
  ///
  ///
  Future<List<Object>?> apiAppealsStatusProcessStatusGet(
      {required String processStatus}) async {
    Response response = await apiAppealsStatusProcessStatusGetWithHttpInfo(
        processStatus: processStatus);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }

  /// deleteAppeal with HTTP info returned (eventbus)
  ///
  ///
  Future<Response> eventbusAppealsAppealIdDeleteWithHttpInfo(
      {required String appealId}) async {
    Object postBody = ''; // DELETE 请求通常没有 body

    // 验证必需参数已设置
    if (appealId.isEmpty) {
      throw ApiException(400, "Missing required param: appealId");
    }

    // 创建路径和映射变量
    String path = "/eventbus/appeals/{appealId}"
        .replaceAll("{format}", "json")
        .replaceAll("{appealId}", appealId);

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

  /// deleteAppeal
  ///
  ///
  Future<Object?> eventbusAppealsAppealIdDelete(
      {required String appealId}) async {
    Response response =
        await eventbusAppealsAppealIdDeleteWithHttpInfo(appealId: appealId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getAppealById with HTTP info returned (eventbus)
  ///
  ///
  Future<Response> eventbusAppealsAppealIdGetWithHttpInfo(
      {required String appealId}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    if (appealId.isEmpty) {
      throw ApiException(400, "Missing required param: appealId");
    }

    // 创建路径和映射变量
    String path = "/eventbus/appeals/{appealId}"
        .replaceAll("{format}", "json")
        .replaceAll("{appealId}", appealId);

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

  /// getAppealById (eventbus)
  ///
  ///
  Future<Object?> eventbusAppealsAppealIdGet({required String appealId}) async {
    Response response =
        await eventbusAppealsAppealIdGetWithHttpInfo(appealId: appealId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getOffenseByAppealId with HTTP info returned (eventbus)
  ///
  ///
  Future<Response> eventbusAppealsAppealIdOffenseGetWithHttpInfo(
      {required String appealId}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    if (appealId.isEmpty) {
      throw ApiException(400, "Missing required param: appealId");
    }

    // 创建路径和映射变量
    String path = "/eventbus/appeals/{appealId}/offense"
        .replaceAll("{format}", "json")
        .replaceAll("{appealId}", appealId);

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

  /// getOffenseByAppealId (eventbus)
  ///
  ///
  Future<Object?> eventbusAppealsAppealIdOffenseGet(
      {required String appealId}) async {
    Response response =
        await eventbusAppealsAppealIdOffenseGetWithHttpInfo(appealId: appealId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// updateAppeal with HTTP info returned (eventbus)
  ///
  ///
  Future<Response> eventbusAppealsAppealIdPutWithHttpInfo(
      {required String appealId, int? integer}) async {
    Object postBody = integer ?? 0; // 根据实际需求设置默认值

    // 验证必需参数已设置
    if (appealId.isEmpty) {
      throw ApiException(400, "Missing required param: appealId");
    }

    // 创建路径和映射变量
    String path = "/eventbus/appeals/{appealId}"
        .replaceAll("{format}", "json")
        .replaceAll("{appealId}", appealId);

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

  /// updateAppeal (eventbus)
  ///
  ///
  Future<Object?> eventbusAppealsAppealIdPut(
      {required String appealId, int? integer}) async {
    Response response = await eventbusAppealsAppealIdPutWithHttpInfo(
        appealId: appealId, integer: integer);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getAllAppeals with HTTP info returned (eventbus)
  ///
  ///
  Future<Response> eventbusAppealsGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/eventbus/appeals".replaceAll("{format}", "json");

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

  /// getAllAppeals (eventbus)
  ///
  ///
  Future<List<Object>?> eventbusAppealsGet() async {
    Response response = await eventbusAppealsGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }
}
