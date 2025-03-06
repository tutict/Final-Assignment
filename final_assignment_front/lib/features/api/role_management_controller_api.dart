import 'package:final_assignment_front/features/model/role_management.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class RoleManagementControllerApi {
  final ApiClient apiClient;

  /// 构造函数，可传入 ApiClient，否则使用全局默认实例
  RoleManagementControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  /// 从 SharedPreferences 中读取 jwtToken 并设置到 ApiClient 中
  Future<void> initializeWithJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('未登录，请重新登录');
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint('Initialized RoleManagementControllerApi with token: $jwtToken');
  }

  /// 解码响应体字节到字符串
  String _decodeBodyBytes(http.Response response) => response.body;

  /// 辅助方法：添加查询参数（如名称搜索）
  List<QueryParam> _addQueryParams({String? name, String? idempotencyKey}) {
    final queryParams = <QueryParam>[];
    if (name != null) queryParams.add(QueryParam('name', name));
    if (idempotencyKey != null) queryParams.add(QueryParam('idempotencyKey', idempotencyKey));
    return queryParams;
  }

  /// POST /api/roles - 创建新的角色记录 (仅 ADMIN)
  Future<RoleManagement> createRole(RoleManagement role, String idempotencyKey) async {
    final response = await apiClient.invokeAPI(
      '/api/roles',
      'POST',
      _addQueryParams(idempotencyKey: idempotencyKey),
      role.toJson(),
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final data = apiClient.deserialize(_decodeBodyBytes(response), 'Map<String, dynamic>');
    return RoleManagement.fromJson(data);
  }

  /// GET /api/roles/{roleId} - 根据角色ID获取角色信息 (USER 和 ADMIN)
  Future<RoleManagement?> apiRolesRoleIdGet(int roleId) async {
    final response = await apiClient.invokeAPI(
      '/api/roles/$roleId',
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
    final data = apiClient.deserialize(_decodeBodyBytes(response), 'Map<String, dynamic>');
    return RoleManagement.fromJson(data);
  }

  /// GET /api/roles - 获取所有角色信息 (USER 和 ADMIN)
  Future<List<RoleManagement>> apiRolesGet() async {
    final response = await apiClient.invokeAPI(
      '/api/roles',
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
    final List<dynamic> data = apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return RoleManagement.listFromJson(data);
  }

  /// GET /api/roles/name/{roleName} - 根据角色名称获取角色信息 (USER 和 ADMIN)
  Future<RoleManagement?> apiRolesNameRoleNameGet(String roleName) async {
    if (roleName.isEmpty) {
      throw ApiException(400, "Missing required param: roleName");
    }
    final response = await apiClient.invokeAPI(
      '/api/roles/name/$roleName',
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
    final data = apiClient.deserialize(_decodeBodyBytes(response), 'Map<String, dynamic>');
    return RoleManagement.fromJson(data);
  }

  /// GET /api/roles/search - 根据角色名称模糊匹配获取角色信息 (USER 和 ADMIN)
  Future<List<RoleManagement>> apiRolesSearchGet({String? name}) async {
    final response = await apiClient.invokeAPI(
      '/api/roles/search',
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
    final List<dynamic> data = apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return RoleManagement.listFromJson(data);
  }

  /// PUT /api/roles/{roleId} - 更新指定角色的信息 (仅 ADMIN)
  Future<RoleManagement> apiRolesRoleIdPut(int roleId, RoleManagement updatedRole, String idempotencyKey) async {
    final response = await apiClient.invokeAPI(
      '/api/roles/$roleId',
      'PUT',
      _addQueryParams(idempotencyKey: idempotencyKey),
      updatedRole.toJson(),
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final data = apiClient.deserialize(_decodeBodyBytes(response), 'Map<String, dynamic>');
    return RoleManagement.fromJson(data);
  }

  /// DELETE /api/roles/{roleId} - 删除指定角色记录 (仅 ADMIN)
  Future<void> apiRolesRoleIdDelete(int roleId) async {
    final response = await apiClient.invokeAPI(
      '/api/roles/$roleId',
      'DELETE',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode != 204) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// DELETE /api/roles/name/{roleName} - 根据角色名称删除角色记录 (仅 ADMIN)
  Future<void> apiRolesNameRoleNameDelete(String roleName) async {
    if (roleName.isEmpty) {
      throw ApiException(400, "Missing required param: roleName");
    }
    final response = await apiClient.invokeAPI(
      '/api/roles/name/$roleName',
      'DELETE',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode != 204) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// 获取当前用户角色 (USER 和 ADMIN)
  Future<String> getCurrentUserRole() async {
    final roles = await apiRolesGet();
    for (var role in roles) {
      if (role.roleName != null && role.roleName!.isNotEmpty) {
        return role.roleName!; // 返回第一个非空角色名，假设用户只有一个主要角色
      }
    }
    throw ApiException(403, '无法确定用户角色');
  }

  // WebSocket Methods (Aligned with HTTP Endpoints)

  /// GET /api/roles (WebSocket)
  /// 对应后端: @WsAction(service="RoleManagement", action="getAllRoles")
  Future<List<RoleManagement>> eventbusRolesGet() async {
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
      return (respMap["result"] as List)
          .map((json) => RoleManagement.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// DELETE /api/roles/name/{roleName} (WebSocket)
  /// 对应后端: @WsAction(service="RoleManagement", action="deleteRoleByName")
  Future<bool> eventbusRolesNameRoleNameDelete({required String roleName}) async {
    if (roleName.isEmpty) {
      throw ApiException(400, "Missing required param: roleName");
    }
    final msg = {
      "service": "RoleManagement",
      "action": "deleteRoleByName",
      "args": [roleName]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return true; // Success if no error
  }

  /// GET /api/roles/name/{roleName} (WebSocket)
  /// 对应后端: @WsAction(service="RoleManagement", action="getRoleByName")
  Future<RoleManagement?> eventbusRolesNameRoleNameGet({required String roleName}) async {
    if (roleName.isEmpty) {
      throw ApiException(400, "Missing required param: roleName");
    }
    final msg = {
      "service": "RoleManagement",
      "action": "getRoleByName",
      "args": [roleName]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    if (respMap["result"] != null) {
      return RoleManagement.fromJson(respMap["result"] as Map<String, dynamic>);
    }
    return null;
  }

  /// POST /api/roles (WebSocket)
  /// 对应后端: @WsAction(service="RoleManagement", action="createRole")
  Future<RoleManagement> eventbusRolesPost({required RoleManagement roleManagement, String? idempotencyKey}) async {
    final msg = {
      "service": "RoleManagement",
      "action": "createRole",
      "args": idempotencyKey != null ? [roleManagement.toJson(), idempotencyKey] : [roleManagement.toJson()]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return RoleManagement.fromJson(respMap["result"] as Map<String, dynamic>);
  }

  /// DELETE /api/roles/{roleId} (WebSocket)
  /// 对应后端: @WsAction(service="RoleManagement", action="deleteRole")
  Future<bool> eventbusRolesRoleIdDelete({required int roleId}) async {
    final msg = {
      "service": "RoleManagement",
      "action": "deleteRole",
      "args": [roleId]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return true; // Success if no error
  }

  /// GET /api/roles/{roleId} (WebSocket)
  /// 对应后端: @WsAction(service="RoleManagement", action="getRoleById")
  Future<RoleManagement?> eventbusRolesRoleIdGet({required int roleId}) async {
    final msg = {
      "service": "RoleManagement",
      "action": "getRoleById",
      "args": [roleId]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    if (respMap["result"] != null) {
      return RoleManagement.fromJson(respMap["result"] as Map<String, dynamic>);
    }
    return null;
  }

  /// PUT /api/roles/{roleId} (WebSocket)
  /// 对应后端: @WsAction(service="RoleManagement", action="updateRole")
  Future<RoleManagement> eventbusRolesRoleIdPut({
    required int roleId,
    required RoleManagement updatedRole,
    String? idempotencyKey,
  }) async {
    final msg = {
      "service": "RoleManagement",
      "action": "updateRole",
      "args": idempotencyKey != null ? [roleId, updatedRole.toJson(), idempotencyKey] : [roleId, updatedRole.toJson()]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return RoleManagement.fromJson(respMap["result"] as Map<String, dynamic>);
  }

  /// GET /api/roles/search (WebSocket)
  /// 对应后端: @WsAction(service="RoleManagement", action="getRolesByNameLike")
  Future<List<RoleManagement>> eventbusRolesSearchGet({String? name}) async {
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
      return (respMap["result"] as List)
          .map((json) => RoleManagement.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}