import 'package:final_assignment_front/features/model/role_management.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:http/http.dart'; // 用于 Response 和 MultipartRequest
import 'package:final_assignment_front/utils/services/api_client.dart'; // 替换为实际路径

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class RoleManagementControllerApi {
  final ApiClient apiClient;

  // 更新后的构造函数，apiClient 参数可为空
  RoleManagementControllerApi([ApiClient? apiClient])
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

  /// getAllRoles with HTTP info returned
  ///
  ///
  Future<Response> apiRolesGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/roles".replaceAll("{format}", "json");

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

  /// getAllRoles
  ///
  ///
  Future<List<Object>?> apiRolesGet() async {
    Response response = await apiRolesGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }

  /// deleteRoleByName with HTTP info returned
  ///
  ///
  Future<Response> apiRolesNameRoleNameDeleteWithHttpInfo(
      {required String roleName}) async {
    Object postBody = ''; // DELETE 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/roles/name/{roleName}"
        .replaceAll("{format}", "json")
        .replaceAll("{roleName}", roleName);

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

  /// deleteRoleByName
  ///
  ///
  Future<Object?> apiRolesNameRoleNameDelete({required String roleName}) async {
    Response response =
        await apiRolesNameRoleNameDeleteWithHttpInfo(roleName: roleName);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getRoleByName with HTTP info returned
  ///
  ///
  Future<Response> apiRolesNameRoleNameGetWithHttpInfo(
      {required String roleName}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/roles/name/{roleName}"
        .replaceAll("{format}", "json")
        .replaceAll("{roleName}", roleName);

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

  /// getRoleByName
  ///
  ///
  Future<Object?> apiRolesNameRoleNameGet({required String roleName}) async {
    Response response =
        await apiRolesNameRoleNameGetWithHttpInfo(roleName: roleName);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// createRole with HTTP info returned
  ///
  ///
  Future<Response> apiRolesPostWithHttpInfo(
      {required RoleManagement roleManagement}) async {
    Object postBody = roleManagement;

    // 创建路径和映射变量
    String path = "/api/roles".replaceAll("{format}", "json");

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

  /// createRole
  ///
  ///
  Future<Object?> apiRolesPost({required RoleManagement roleManagement}) async {
    Response response =
        await apiRolesPostWithHttpInfo(roleManagement: roleManagement);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// deleteRole with HTTP info returned
  ///
  ///
  Future<Response> apiRolesRoleIdDeleteWithHttpInfo(
      {required String roleId}) async {
    Object postBody = ''; // DELETE 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/roles/{roleId}"
        .replaceAll("{format}", "json")
        .replaceAll("{roleId}", roleId);

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

  /// deleteRole
  ///
  ///
  Future<Object?> apiRolesRoleIdDelete({required String roleId}) async {
    Response response = await apiRolesRoleIdDeleteWithHttpInfo(roleId: roleId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getRoleById with HTTP info returned
  ///
  ///
  Future<Response> apiRolesRoleIdGetWithHttpInfo(
      {required String roleId}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/roles/{roleId}"
        .replaceAll("{format}", "json")
        .replaceAll("{roleId}", roleId);

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

  /// getRoleById
  ///
  ///
  Future<Object?> apiRolesRoleIdGet({required String roleId}) async {
    Response response = await apiRolesRoleIdGetWithHttpInfo(roleId: roleId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// updateRole with HTTP info returned
  ///
  ///
  Future<Response> apiRolesRoleIdPutWithHttpInfo(
      {required String roleId, int? updateValue}) async {
    Object postBody = updateValue ?? 0; // 根据实际需求设置默认值

    // 创建路径和映射变量
    String path = "/api/roles/{roleId}"
        .replaceAll("{format}", "json")
        .replaceAll("{roleId}", roleId);

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

  /// updateRole
  ///
  ///
  Future<Object?> apiRolesRoleIdPut(
      {required String roleId, int? updateValue}) async {
    Response response = await apiRolesRoleIdPutWithHttpInfo(
        roleId: roleId, updateValue: updateValue);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getRolesByNameLike with HTTP info returned
  ///
  ///
  Future<Response> apiRolesSearchGetWithHttpInfo({String? name}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/roles/search".replaceAll("{format}", "json");

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

  /// getRolesByNameLike
  ///
  ///
  Future<List<Object>?> apiRolesSearchGet({String? name}) async {
    Response response = await apiRolesSearchGetWithHttpInfo(name: name);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }

  /// getAllRoles (WebSocket)
  /// 对应后端: @WsAction(service="RoleManagement", action="getAllRoles")
  Future<List<Object>?> eventbusRolesGet() async {
    final msg = {
      "service": "RoleManagement",
      "action": "getAllRoles",
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

  /// deleteRoleByName (WebSocket)
  /// 对应后端: @WsAction(service="RoleManagement", action="deleteRoleByName")
  Future<Object?> eventbusRolesNameRoleNameDelete(
      {required String roleName}) async {
    final msg = {
      "service": "RoleManagement",
      "action": "deleteRoleByName",
      "args": [roleName]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// getRoleByName (WebSocket)
  /// 对应后端: @WsAction(service="RoleManagement", action="getRoleByName")
  Future<Object?> eventbusRolesNameRoleNameGet(
      {required String roleName}) async {
    final msg = {
      "service": "RoleManagement",
      "action": "getRoleByName",
      "args": [roleName]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// createRole (WebSocket)
  /// 对应后端: @WsAction(service="RoleManagement", action="createRole")
  Future<Object?> eventbusRolesPost(
      {required RoleManagement roleManagement}) async {
    // 将 roleManagement 序列化
    final roleMap = roleManagement.toJson();

    final msg = {
      "service": "RoleManagement",
      "action": "createRole",
      "args": [roleMap]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// deleteRole (WebSocket)
  /// 对应后端: @WsAction(service="RoleManagement", action="deleteRole")
  Future<Object?> eventbusRolesRoleIdDelete({required String roleId}) async {
    final msg = {
      "service": "RoleManagement",
      "action": "deleteRole",
      "args": [int.parse(roleId)] // 如果后端是 int roleId
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// getRoleById (WebSocket)
  /// 对应后端: @WsAction(service="RoleManagement", action="getRoleById")
  Future<Object?> eventbusRolesRoleIdGet({required String roleId}) async {
    final msg = {
      "service": "RoleManagement",
      "action": "getRoleById",
      "args": [int.parse(roleId)]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// updateRole (WebSocket)
  /// 对应后端: @WsAction(service="RoleManagement", action="updateRole")
  Future<Object?> eventbusRolesRoleIdPut(
      {required String roleId, int? updateValue}) async {
    final msg = {
      "service": "RoleManagement",
      "action": "updateRole",
      "args": [int.parse(roleId), updateValue ?? 0]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// getRolesByNameLike (WebSocket)
  /// 对应后端: @WsAction(service="RoleManagement", action="getRolesByNameLike")
  Future<List<Object>?> eventbusRolesSearchGet({String? name}) async {
    final msg = {
      "service": "RoleManagement",
      "action": "getRolesByNameLike",
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
