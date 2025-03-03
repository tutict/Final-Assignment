// role_management_controller_api.dart
import 'package:final_assignment_front/features/model/role_management.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class RoleManagementControllerApi {
  final ApiClient apiClient;

  // 更新后的构造函数，apiClient 参数可为空
  RoleManagementControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  // 解码响应体的辅助方法
  String _decodeBodyBytes(http.Response response) {
    return response.body;
  }

  // 辅助方法：转换查询参数
  List<QueryParam> _convertParametersForCollectionFormat(
      String collectionFormat, String name, dynamic value) {
    return [QueryParam(name, value.toString())];
  }

  /// 创建新的角色记录 (仅 ADMIN)
  Future<RoleManagement> createRole(RoleManagement role, String idempotencyKey) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw ApiException(401, 'No JWT token found');
    }

    final response = await http.post(
      Uri.parse('http://localhost:8081/api/roles?idempotencyKey=$idempotencyKey'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
      body: jsonEncode(role.toJson()),
    );

    if (response.statusCode == 201) {
      return RoleManagement.fromJson(jsonDecode(_decodeBodyBytes(response)));
    }
    throw ApiException(response.statusCode, _decodeBodyBytes(response));
  }

  /// 根据角色ID获取角色信息 (USER 和 ADMIN)
  Future<RoleManagement> getRoleById(int roleId) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw ApiException(401, 'No JWT token found');
    }

    final response = await http.get(
      Uri.parse('http://localhost:8081/api/roles/$roleId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
    );

    if (response.statusCode == 200) {
      return RoleManagement.fromJson(jsonDecode(_decodeBodyBytes(response)));
    }
    throw ApiException(response.statusCode, _decodeBodyBytes(response));
  }

  /// 获取所有角色信息 (USER 和 ADMIN)
  Future<List<RoleManagement>> getAllRoles() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw ApiException(401, 'No JWT token found');
    }

    final response = await http.get(
      Uri.parse('http://localhost:8081/api/roles'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(_decodeBodyBytes(response));
      return data.map((json) => RoleManagement.fromJson(json)).toList();
    }
    throw ApiException(response.statusCode, _decodeBodyBytes(response));
  }

  /// 根据角色名称获取角色信息 (USER 和 ADMIN)
  Future<RoleManagement> getRoleByName(String roleName) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw ApiException(401, 'No JWT token found');
    }

    final response = await http.get(
      Uri.parse('http://localhost:8081/api/roles/name/$roleName'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
    );

    if (response.statusCode == 200) {
      return RoleManagement.fromJson(jsonDecode(_decodeBodyBytes(response)));
    }
    throw ApiException(response.statusCode, _decodeBodyBytes(response));
  }

  /// 根据角色名称模糊匹配获取角色信息 (USER 和 ADMIN)
  Future<List<RoleManagement>> getRolesByNameLike(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw ApiException(401, 'No JWT token found');
    }

    final response = await http.get(
      Uri.parse('http://localhost:8081/api/roles/search?name=$name'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(_decodeBodyBytes(response));
      return data.map((json) => RoleManagement.fromJson(json)).toList();
    }
    throw ApiException(response.statusCode, _decodeBodyBytes(response));
  }

  /// 更新指定角色的信息 (仅 ADMIN)
  Future<RoleManagement> updateRole(int roleId, RoleManagement updatedRole, String idempotencyKey) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw ApiException(401, 'No JWT token found');
    }

    final response = await http.put(
      Uri.parse('http://localhost:8081/api/roles/$roleId?idempotencyKey=$idempotencyKey'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
      body: jsonEncode(updatedRole.toJson()),
    );

    if (response.statusCode == 200) {
      return RoleManagement.fromJson(jsonDecode(_decodeBodyBytes(response)));
    }
    throw ApiException(response.statusCode, _decodeBodyBytes(response));
  }

  /// 删除指定角色记录 (仅 ADMIN)
  Future<void> deleteRole(int roleId) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw ApiException(401, 'No JWT token found');
    }

    final response = await http.delete(
      Uri.parse('http://localhost:8081/api/roles/$roleId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
    );

    if (response.statusCode != 204) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// 根据角色名称删除角色记录 (仅 ADMIN)
  Future<void> deleteRoleByName(String roleName) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw ApiException(401, 'No JWT token found');
    }

    final response = await http.delete(
      Uri.parse('http://localhost:8081/api/roles/name/$roleName'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
    );

    if (response.statusCode != 204) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// 获取当前用户角色 (USER 和 ADMIN)
  Future<String> getCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw ApiException(401, 'No JWT token found');
    }

    // 调用后端获取所有角色，并从中找到当前用户的角色
    final roles = await getAllRoles();
    for (var role in roles) {
      if (role.roleName != null && role.roleName!.isNotEmpty) {
        return role.roleName!; // 返回第一个非空角色名，假设用户只有一个主要角色
      }
    }
    throw ApiException(403, '无法确定用户角色');
  }

  /// WebSocket 方法保持不变（仅展示关键部分）

  /// getAllRoles (WebSocket)
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

  /// deleteRoleByName (WebSocket)
  Future<void> eventbusRolesNameRoleNameDelete({required String roleName}) async {
    final msg = {
      "service": "RoleManagement",
      "action": "deleteRoleByName",
      "args": [roleName]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
  }

  /// getRoleByName (WebSocket)
  Future<RoleManagement> eventbusRolesNameRoleNameGet(
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
    return RoleManagement.fromJson(respMap["result"] as Map<String, dynamic>);
  }

  /// createRole (WebSocket)
  Future<RoleManagement> eventbusRolesPost(
      {required RoleManagement roleManagement}) async {
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
    return RoleManagement.fromJson(respMap["result"] as Map<String, dynamic>);
  }

  /// deleteRole (WebSocket)
  Future<void> eventbusRolesRoleIdDelete({required int roleId}) async {
    final msg = {
      "service": "RoleManagement",
      "action": "deleteRole",
      "args": [roleId]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
  }

  /// getRoleById (WebSocket)
  Future<RoleManagement> eventbusRolesRoleIdGet({required int roleId}) async {
    final msg = {
      "service": "RoleManagement",
      "action": "getRoleById",
      "args": [roleId]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return RoleManagement.fromJson(respMap["result"] as Map<String, dynamic>);
  }

  /// updateRole (WebSocket)
  Future<RoleManagement> eventbusRolesRoleIdPut(
      {required int roleId, required RoleManagement updatedRole}) async {
    final roleMap = updatedRole.toJson();

    final msg = {
      "service": "RoleManagement",
      "action": "updateRole",
      "args": [roleId, roleMap]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return RoleManagement.fromJson(respMap["result"] as Map<String, dynamic>);
  }

  /// getRolesByNameLike (WebSocket)
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