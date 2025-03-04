import 'dart:convert';
import 'package:final_assignment_front/features/model/appeal_management.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:http/http.dart'; // 用于 Response 和 MultipartRequest
import 'package:final_assignment_front/utils/services/api_client.dart';

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class AppealManagementControllerApi {
  final ApiClient apiClient;

  /// 构造函数允许传入自定义 ApiClient，否则使用全局 defaultApiClient
  AppealManagementControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  // 解码响应体的辅助方法
  String _decodeBodyBytes(Response response) {
    return response.body;
  }

  /// DELETE 申诉（HTTP DELETE）
  Future<Response> apiAppealsAppealIdDeleteWithHttpInfo(
      {required String appealId}) async {
    Object postBody = ''; // DELETE 请求通常没有 body

    if (appealId.isEmpty) {
      throw ApiException(400, "Missing required param: appealId");
    }

    String path = "/api/appeals/{appealId}"
        .replaceAll("{format}", "json")
        .replaceAll("{appealId}", appealId);

    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};
    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'DELETE', queryParams,
        postBody, headerParams, formParams, nullableContentType, authNames);
    return response;
  }

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

  /// GET 通过 ID 获取申诉详情（HTTP GET）
  Future<Response> apiAppealsAppealIdGetWithHttpInfo(
      {required String appealId}) async {
    Object postBody = ''; // GET 请求通常没有 body

    if (appealId.isEmpty) {
      throw ApiException(400, "Missing required param: appealId");
    }

    String path = "/api/appeals/{appealId}"
        .replaceAll("{format}", "json")
        .replaceAll("{appealId}", appealId);

    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};
    List<String> contentTypes = [];
    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

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

  /// GET 获取指定申诉的关联违法信息（HTTP GET）
  Future<Response> apiAppealsAppealIdOffenseGetWithHttpInfo(
      {required String appealId}) async {
    Object postBody = '';

    if (appealId.isEmpty) {
      throw ApiException(400, "Missing required param: appealId");
    }

    String path = "/api/appeals/{appealId}/offense"
        .replaceAll("{format}", "json")
        .replaceAll("{appealId}", appealId);

    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};
    List<String> contentTypes = [];
    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

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

  /// PUT 更新申诉，传递完整的 AppealManagement 对象（HTTP PUT）
  Future<Response> apiAppealsAppealIdPutWithHttpInfo({
    required String appealId,
    required AppealManagement appealManagement,
  }) async {
    Object postBody = appealManagement; // 传递完整对象

    if (appealId.isEmpty) {
      throw ApiException(400, "Missing required param: appealId");
    }

    String path = "/api/appeals/{appealId}"
        .replaceAll("{format}", "json")
        .replaceAll("{appealId}", appealId);

    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};
    List<String> contentTypes = ["application/json"];
    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'PUT', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  Future<Object?> apiAppealsAppealIdPut({
    required String appealId,
    required AppealManagement appealManagement,
  }) async {
    Response response = await apiAppealsAppealIdPutWithHttpInfo(
        appealId: appealId, appealManagement: appealManagement);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// GET 获取所有申诉记录（HTTP GET）
  Future<Response> apiAppealsGetWithHttpInfo() async {
    Object postBody = '';

    String path = "/api/appeals".replaceAll("{format}", "json");

    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};
    List<String> contentTypes = [];
    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

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

  /// GET 根据上诉人姓名查询申诉记录（HTTP GET）
  Future<Response> apiAppealsNameAppealNameGetWithHttpInfo(
      {required String appealName}) async {
    Object postBody = '';

    if (appealName.isEmpty) {
      throw ApiException(400, "Missing required param: appealName");
    }

    String path = "/api/appeals/name/{appealName}"
        .replaceAll("{format}", "json")
        .replaceAll("{appealName}", appealName);

    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};
    List<String> contentTypes = [];
    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

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

  /// POST 创建申诉（HTTP POST）
  Future<Response> apiAppealsPostWithHttpInfo(
      {required AppealManagement appealManagement}) async {
    Object postBody = appealManagement;

    String path = "/api/appeals".replaceAll("{format}", "json");

    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};
    List<String> contentTypes = ["application/json"];
    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'POST', queryParams,
        postBody, headerParams, formParams, nullableContentType, authNames);
    return response;
  }

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

  /// GET 根据处理状态查询申诉记录（HTTP GET）
  Future<Response> apiAppealsStatusProcessStatusGetWithHttpInfo(
      {required String processStatus}) async {
    Object postBody = '';

    if (processStatus.isEmpty) {
      throw ApiException(400, "Missing required param: processStatus");
    }

    String path = "/api/appeals/status/{processStatus}"
        .replaceAll("{format}", "json")
        .replaceAll("{processStatus}", processStatus);

    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};
    List<String> contentTypes = [];
    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

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

  /// 以下为 WebSocket 方式调用

  /// 通过 WebSocket 删除申诉
  Future<Object?> eventbusAppealsAppealIdDelete(
      {required String appealId}) async {
    final msg = {
      "service": "AppealManagementService",
      "action": "deleteAppeal",
      "args": [int.parse(appealId)],
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("result")) {
      return respMap["result"];
    } else if (respMap.containsKey("status")) {
      return respMap["status"];
    }
    return respMap;
  }

  /// 通过 WebSocket 获取申诉详情
  Future<Object?> eventbusAppealsAppealIdGet({required String appealId}) async {
    final msg = {
      "service": "AppealManagementService",
      "action": "getAppealById",
      "args": [int.parse(appealId)],
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("result")) {
      return respMap["result"];
    }
    return respMap;
  }

  /// 通过 WebSocket 获取申诉关联的违法信息
  Future<Object?> eventbusAppealsAppealIdOffenseGet(
      {required String appealId}) async {
    final msg = {
      "service": "AppealManagementService",
      "action": "getOffenseByAppealId",
      "args": [int.parse(appealId)],
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("result")) {
      return respMap["result"];
    }
    return respMap;
  }

  /// 通过 WebSocket 更新申诉（简化调用，仅作为示例，实际推荐使用 HTTP PUT）
  Future<Object?> eventbusAppealsAppealIdPut(
      {required String appealId, int? integer}) async {
    final msg = {
      "service": "AppealManagementService",
      "action": "updateAppeal",
      "args": [int.parse(appealId), integer ?? 0],
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("result")) {
      return respMap["result"];
    }
    return respMap;
  }

  /// 通过 WebSocket 获取所有申诉记录
  Future<List<Object>?> eventbusAppealsGet() async {
    final msg = {
      "service": "AppealManagementService",
      "action": "getAllAppeals",
      "args": []
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("result") && respMap["result"] is List) {
      return respMap["result"] as List<Object>;
    }
    return null;
  }
}
