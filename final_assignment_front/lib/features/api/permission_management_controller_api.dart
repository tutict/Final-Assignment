import 'package:final_assignment_front/features/model/permission_management.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:http/http.dart'; // 用于 Response 和 MultipartRequest
import 'package:final_assignment_front/utils/services/api_client.dart'; // 替换为实际路径

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class PermissionManagementControllerApi {
  final ApiClient apiClient;

  // 更新后的构造函数，apiClient 参数可为空
  PermissionManagementControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  // 解码响应体的辅助方法
  String _decodeBodyBytes(Response response) {
    return response.body;
  }

  // 辅助方法：转换查询参数
  List<QueryParam> _convertParametersForCollectionFormat(
      String collectionFormat, String name, dynamic value) {
    // 根据 collectionFormat 实现参数转换逻辑
    // 这里提供一个简单的实现示例
    return [QueryParam(name, value.toString())];
  }

  /// getAllPermissions with HTTP info returned
  ///
  ///
  Future<Response> apiPermissionsGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/permissions".replaceAll("{format}", "json");

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

  /// getAllPermissions
  ///
  ///
  Future<List<Object>?> apiPermissionsGet() async {
    Response response = await apiPermissionsGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }

  /// deletePermissionByName with HTTP info returned
  ///
  ///
  Future<Response> apiPermissionsNamePermissionNameDeleteWithHttpInfo(
      {required String permissionName}) async {
    Object postBody = ''; // DELETE 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/permissions/name/{permissionName}"
        .replaceAll("{format}", "json")
        .replaceAll("{permissionName}", permissionName);

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

  /// deletePermissionByName
  ///
  ///
  Future<Object?> apiPermissionsNamePermissionNameDelete(
      {required String permissionName}) async {
    Response response =
        await apiPermissionsNamePermissionNameDeleteWithHttpInfo(
            permissionName: permissionName);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getPermissionByName with HTTP info returned
  ///
  ///
  Future<Response> apiPermissionsNamePermissionNameGetWithHttpInfo(
      {required String permissionName}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/permissions/name/{permissionName}"
        .replaceAll("{format}", "json")
        .replaceAll("{permissionName}", permissionName);

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

  /// getPermissionByName
  ///
  ///
  Future<Object?> apiPermissionsNamePermissionNameGet(
      {required String permissionName}) async {
    Response response = await apiPermissionsNamePermissionNameGetWithHttpInfo(
        permissionName: permissionName);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// deletePermission with HTTP info returned
  ///
  ///
  Future<Response> apiPermissionsPermissionIdDeleteWithHttpInfo(
      {required String permissionId}) async {
    Object postBody = ''; // DELETE 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/permissions/{permissionId}"
        .replaceAll("{format}", "json")
        .replaceAll("{permissionId}", permissionId);

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

  /// deletePermission
  ///
  ///
  Future<Object?> apiPermissionsPermissionIdDelete(
      {required String permissionId}) async {
    Response response = await apiPermissionsPermissionIdDeleteWithHttpInfo(
        permissionId: permissionId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getPermissionById with HTTP info returned
  ///
  ///
  Future<Response> apiPermissionsPermissionIdGetWithHttpInfo(
      {required String permissionId}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/permissions/{permissionId}"
        .replaceAll("{format}", "json")
        .replaceAll("{permissionId}", permissionId);

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

  /// getPermissionById
  ///
  ///
  Future<Object?> apiPermissionsPermissionIdGet(
      {required String permissionId}) async {
    Response response = await apiPermissionsPermissionIdGetWithHttpInfo(
        permissionId: permissionId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// updatePermission with HTTP info returned
  ///
  ///
  Future<Response> apiPermissionsPermissionIdPutWithHttpInfo(
      {required String permissionId, int? updateValue}) async {
    Object postBody = updateValue ?? 0; // 根据实际需求设置默认值

    // 创建路径和映射变量
    String path = "/api/permissions/{permissionId}"
        .replaceAll("{format}", "json")
        .replaceAll("{permissionId}", permissionId);

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

  /// updatePermission
  ///
  ///
  Future<Object?> apiPermissionsPermissionIdPut(
      {required String permissionId, int? updateValue}) async {
    Response response = await apiPermissionsPermissionIdPutWithHttpInfo(
        permissionId: permissionId, updateValue: updateValue);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// createPermission with HTTP info returned
  ///
  ///
  Future<Response> apiPermissionsPostWithHttpInfo(
      {required PermissionManagement permissionManagement}) async {
    Object postBody = permissionManagement;

    // 创建路径和映射变量
    String path = "/api/permissions".replaceAll("{format}", "json");

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

  /// createPermission
  ///
  ///
  Future<Object?> apiPermissionsPost(
      {required PermissionManagement permissionManagement}) async {
    Response response = await apiPermissionsPostWithHttpInfo(
        permissionManagement: permissionManagement);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getPermissionsByNameLike with HTTP info returned
  ///
  ///
  Future<Response> apiPermissionsSearchGetWithHttpInfo({String? name}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/permissions/search".replaceAll("{format}", "json");

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};
    if (name != null) {
      queryParams
          .addAll(_convertParametersForCollectionFormat("", "name", name));
    }

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// getPermissionsByNameLike
  ///
  ///
  Future<List<Object>?> apiPermissionsSearchGet({String? name}) async {
    Response response = await apiPermissionsSearchGetWithHttpInfo(name: name);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }

  /// getAllPermissions (WebSocket)
  /// 对应后端 @WsAction(service="PermissionManagement", action="getAllPermissions")
  Future<List<Object>?> eventbusPermissionsGet() async {
    final msg = {
      "service": "PermissionManagement",
      "action": "getAllPermissions",
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

  /// deletePermissionByName (WebSocket)
  /// 对应后端: @WsAction(service="PermissionManagement", action="deletePermissionByName")
  Future<Object?> eventbusPermissionsNamePermissionNameDelete(
      {required String permissionName}) async {
    final msg = {
      "service": "PermissionManagement",
      "action": "deletePermissionByName",
      "args": [permissionName]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// getPermissionByName (WebSocket)
  /// 对应后端: @WsAction(service="PermissionManagement", action="getPermissionByName")
  Future<Object?> eventbusPermissionsNamePermissionNameGet(
      {required String permissionName}) async {
    final msg = {
      "service": "PermissionManagement",
      "action": "getPermissionByName",
      "args": [permissionName]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// deletePermission (WebSocket)
  /// 对应后端: @WsAction(service="PermissionManagement", action="deletePermission")
  Future<Object?> eventbusPermissionsPermissionIdDelete(
      {required String permissionId}) async {
    final msg = {
      "service": "PermissionManagement",
      "action": "deletePermission",
      "args": [int.parse(permissionId)] // 如果后端是 int
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// getPermissionById (WebSocket)
  /// 对应后端: @WsAction(service="PermissionManagement", action="getPermissionById")
  Future<Object?> eventbusPermissionsPermissionIdGet(
      {required String permissionId}) async {
    final msg = {
      "service": "PermissionManagement",
      "action": "getPermissionById",
      "args": [int.parse(permissionId)]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// updatePermission (WebSocket)
  /// 对应后端: @WsAction(service="PermissionManagement", action="updatePermission")
  /// 可能需要2个参数, e.g. (Integer permissionId, int valueToUpdate)
  Future<Object?> eventbusPermissionsPermissionIdPut(
      {required String permissionId, int? updateValue}) async {
    final msg = {
      "service": "PermissionManagement",
      "action": "updatePermission",
      "args": [int.parse(permissionId), updateValue ?? 0]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// createPermission (WebSocket)
  /// 对应后端: @WsAction(service="PermissionManagement", action="createPermission")
  Future<Object?> eventbusPermissionsPost(
      {required PermissionManagement permissionManagement}) async {
    // 序列化
    final pmMap = permissionManagement.toJson();
    final msg = {
      "service": "PermissionManagement",
      "action": "createPermission",
      "args": [pmMap]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// getPermissionsByNameLike (WebSocket)
  /// 对应后端: @WsAction(service="PermissionManagement", action="getPermissionsByNameLike")
  /// 传1个参数: name
  Future<List<Object>?> eventbusPermissionsSearchGet({String? name}) async {
    final msg = {
      "service": "PermissionManagement",
      "action": "getPermissionsByNameLike",
      "args": [name ?? ""]
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
}
