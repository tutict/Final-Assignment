import 'package:final_assignment_front/features/model/permission_management.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class PermissionManagementControllerApi {
  final ApiClient apiClient;

  /// 构造函数，可传入 ApiClient，否则使用全局默认实例
  PermissionManagementControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  /// 从 SharedPreferences 中读取 jwtToken 并设置到 ApiClient 中
  Future<void> initializeWithJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('未登录，请重新登录');
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint(
        'Initialized PermissionManagementControllerApi with token: $jwtToken');
  }

  /// 解码响应体字节到字符串
  String _decodeBodyBytes(Response response) => response.body;

  /// 辅助方法：添加查询参数（如名称搜索）
  List<QueryParam> _addQueryParams({String? name}) {
    final queryParams = <QueryParam>[];
    if (name != null) queryParams.add(QueryParam('name', name));
    return queryParams;
  }

  /// GET /api/permissions - 获取所有权限
  Future<List<PermissionManagement>> apiPermissionsGet() async {
    final response = await apiClient.invokeAPI(
      '/api/permissions',
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
    return PermissionManagement.listFromJson(data);
  }

  /// DELETE /api/permissions/name/{permissionName} - 根据名称删除权限 (仅管理员)
  Future<void> apiPermissionsNamePermissionNameDelete(
      {required String permissionName}) async {
    if (permissionName.isEmpty) {
      throw ApiException(400, "Missing required param: permissionName");
    }
    final response = await apiClient.invokeAPI(
      '/api/permissions/name/$permissionName',
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

  /// GET /api/permissions/name/{permissionName} - 根据名称获取权限
  Future<PermissionManagement?> apiPermissionsNamePermissionNameGet(
      {required String permissionName}) async {
    if (permissionName.isEmpty) {
      throw ApiException(400, "Missing required param: permissionName");
    }
    final response = await apiClient.invokeAPI(
      '/api/permissions/name/$permissionName',
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
    return PermissionManagement.fromJson(data);
  }

  /// DELETE /api/permissions/{permissionId} - 根据ID删除权限 (仅管理员)
  Future<void> apiPermissionsPermissionIdDelete(
      {required String permissionId}) async {
    if (permissionId.isEmpty) {
      throw ApiException(400, "Missing required param: permissionId");
    }
    final response = await apiClient.invokeAPI(
      '/api/permissions/$permissionId',
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

  /// GET /api/permissions/{permissionId} - 根据ID获取权限
  Future<PermissionManagement?> apiPermissionsPermissionIdGet(
      {required String permissionId}) async {
    if (permissionId.isEmpty) {
      throw ApiException(400, "Missing required param: permissionId");
    }
    final response = await apiClient.invokeAPI(
      '/api/permissions/$permissionId',
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
    return PermissionManagement.fromJson(data);
  }

  /// PUT /api/permissions/{permissionId} - 更新权限 (仅管理员)
  Future<PermissionManagement> apiPermissionsPermissionIdPut({
    required String permissionId,
    required PermissionManagement permissionManagement,
  }) async {
    if (permissionId.isEmpty) {
      throw ApiException(400, "Missing required param: permissionId");
    }
    final response = await apiClient.invokeAPI(
      '/api/permissions/$permissionId',
      'PUT',
      [],
      permissionManagement.toJson(),
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
    return PermissionManagement.fromJson(data);
  }

  /// POST /api/permissions - 创建权限 (仅管理员)
  Future<PermissionManagement> apiPermissionsPost(
      {required PermissionManagement permissionManagement}) async {
    final response = await apiClient.invokeAPI(
      '/api/permissions',
      'POST',
      [],
      permissionManagement.toJson(),
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
    return PermissionManagement.fromJson(data);
  }

  /// GET /api/permissions/search - 根据名称模糊搜索权限
  Future<List<PermissionManagement>> apiPermissionsSearchGet(
      {String? name}) async {
    final response = await apiClient.invokeAPI(
      '/api/permissions/search',
      'GET',
      _addQueryParams(name: name),
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
    return PermissionManagement.listFromJson(data);
  }

  // WebSocket Methods (Aligned with HTTP Endpoints)

  /// GET /api/permissions (WebSocket)
  /// 对应后端: @WsAction(service="PermissionManagement", action="getAllPermissions")
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

  /// DELETE /api/permissions/name/{permissionName} (WebSocket)
  /// 对应后端: @WsAction(service="PermissionManagement", action="deletePermissionByName")
  Future<bool> eventbusPermissionsNamePermissionNameDelete(
      {required String permissionName}) async {
    if (permissionName.isEmpty) {
      throw ApiException(400, "Missing required param: permissionName");
    }
    final msg = {
      "service": "PermissionManagement",
      "action": "deletePermissionByName",
      "args": [permissionName]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return true; // Success if no error
  }

  /// GET /api/permissions/name/{permissionName} (WebSocket)
  /// 对应后端: @WsAction(service="PermissionManagement", action="getPermissionByName")
  Future<Object?> eventbusPermissionsNamePermissionNameGet(
      {required String permissionName}) async {
    if (permissionName.isEmpty) {
      throw ApiException(400, "Missing required param: permissionName");
    }
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

  /// DELETE /api/permissions/{permissionId} (WebSocket)
  /// 对应后端: @WsAction(service="PermissionManagement", action="deletePermission")
  Future<bool> eventbusPermissionsPermissionIdDelete(
      {required String permissionId}) async {
    if (permissionId.isEmpty) {
      throw ApiException(400, "Missing required param: permissionId");
    }
    final msg = {
      "service": "PermissionManagement",
      "action": "deletePermission",
      "args": [int.parse(permissionId)]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return true; // Success if no error
  }

  /// GET /api/permissions/{permissionId} (WebSocket)
  /// 对应后端: @WsAction(service="PermissionManagement", action="getPermissionById")
  Future<Object?> eventbusPermissionsPermissionIdGet(
      {required String permissionId}) async {
    if (permissionId.isEmpty) {
      throw ApiException(400, "Missing required param: permissionId");
    }
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

  /// PUT /api/permissions/{permissionId} (WebSocket)
  /// 对应后端: @WsAction(service="PermissionManagement", action="updatePermission")
  Future<Object?> eventbusPermissionsPermissionIdPut({
    required String permissionId,
    required PermissionManagement permissionManagement,
  }) async {
    if (permissionId.isEmpty) {
      throw ApiException(400, "Missing required param: permissionId");
    }
    final msg = {
      "service": "PermissionManagement",
      "action": "updatePermission",
      "args": [int.parse(permissionId), permissionManagement.toJson()]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// POST /api/permissions (WebSocket)
  /// 对应后端: @WsAction(service="PermissionManagement", action="createPermission")
  Future<Object?> eventbusPermissionsPost(
      {required PermissionManagement permissionManagement}) async {
    final msg = {
      "service": "PermissionManagement",
      "action": "createPermission",
      "args": [permissionManagement.toJson()]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/permissions/search (WebSocket)
  /// 对应后端: @WsAction(service="PermissionManagement", action="getPermissionsByNameLike")
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
