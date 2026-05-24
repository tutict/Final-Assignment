import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/features/model/role_management.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';

final ApiClient defaultApiClient = ApiClient();

class RoleManagementControllerApi with BaseApiClient {
  @override
  final ApiClient apiClient;

  RoleManagementControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  Future<void> initializeWithJwt() => initializeClientWithJwt();

  Future<RoleManagement?> createRole(
    RoleManagement role,
    String idempotencyKey,
  ) async {
    final response = await request(
      'POST',
      '/api/roles',
      body: role.toJson(),
      contentType: BaseApiClient.defaultContentType,
      idempotencyKey: idempotencyKey,
    );
    if (response.statusCode == 208) {
      return null;
    }
    return parseResponse(response, RoleManagement.fromJson);
  }

  Future<RoleManagement?> getRole(int roleId) {
    return requestNullableObject(
      'GET',
      '/api/roles/$roleId',
      RoleManagement.fromJson,
    );
  }

  Future<List<RoleManagement>> listRoles() {
    return requestList('GET', '/api/roles', RoleManagement.fromJson);
  }

  Future<List<RoleManagement>> searchRoles({String? name}) {
    if (name == null || name.isEmpty) {
      return listRoles();
    }
    return requestList(
      'GET',
      '/api/roles/search/name/fuzzy',
      RoleManagement.fromJson,
      queryParams: [QueryParam('roleName', name)],
    );
  }

  Future<RoleManagement> updateRole(
    int roleId,
    RoleManagement updatedRole,
    String idempotencyKey,
  ) {
    return requestObject(
      'PUT',
      '/api/roles/$roleId',
      RoleManagement.fromJson,
      body: updatedRole.toJson(),
      contentType: BaseApiClient.defaultContentType,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<void> deleteRole(int roleId) {
    return requestVoid('DELETE', '/api/roles/$roleId');
  }

  Future<String> getCurrentUserRole() async {
    final roles = await listRoles();
    for (final role in roles) {
      final roleName = role.roleName;
      if (roleName != null && roleName.isNotEmpty) {
        return roleName;
      }
    }
    throw AppException.http(403, 'No role available for current user');
  }

  Future<List<RoleManagement>> eventbusRolesGet() {
    return sendWsList(
      service: 'RoleManagement',
      action: 'getAllRoles',
      fromJson: RoleManagement.fromJson,
    );
  }

  Future<bool> eventbusRolesNameRoleNameDelete({
    required String roleName,
  }) async {
    requireNotBlank(roleName, 'roleName');
    await sendWs(
      service: 'RoleManagement',
      action: 'deleteRoleByName',
      args: [roleName],
    );
    return true;
  }

  Future<RoleManagement?> eventbusRolesNameRoleNameGet({
    required String roleName,
  }) {
    requireNotBlank(roleName, 'roleName');
    return sendWsObject(
      service: 'RoleManagement',
      action: 'getRoleByName',
      fromJson: RoleManagement.fromJson,
      args: [roleName],
    );
  }

  Future<RoleManagement> eventbusRolesPost({
    required RoleManagement roleManagement,
    String? idempotencyKey,
  }) async {
    final role = await sendWsObject(
      service: 'RoleManagement',
      action: 'createRole',
      fromJson: RoleManagement.fromJson,
      args: idempotencyKey != null
          ? [roleManagement.toJson(), idempotencyKey]
          : [roleManagement.toJson()],
    );
    return role ?? _missingRoleResult();
  }

  Future<bool> eventbusRolesRoleIdDelete({required int roleId}) async {
    await sendWs(
      service: 'RoleManagement',
      action: 'deleteRole',
      args: [roleId],
    );
    return true;
  }

  Future<RoleManagement?> eventbusRolesRoleIdGet({required int roleId}) {
    return sendWsObject(
      service: 'RoleManagement',
      action: 'getRoleById',
      fromJson: RoleManagement.fromJson,
      args: [roleId],
    );
  }

  Future<RoleManagement> eventbusRolesRoleIdPut({
    required int roleId,
    required RoleManagement updatedRole,
    String? idempotencyKey,
  }) async {
    final role = await sendWsObject(
      service: 'RoleManagement',
      action: 'updateRole',
      fromJson: RoleManagement.fromJson,
      args: idempotencyKey != null
          ? [roleId, updatedRole.toJson(), idempotencyKey]
          : [roleId, updatedRole.toJson()],
    );
    return role ?? _missingRoleResult();
  }

  Future<List<RoleManagement>> eventbusRolesSearchGet({String? name}) {
    return sendWsList(
      service: 'RoleManagement',
      action: 'getRolesByNameLike',
      fromJson: RoleManagement.fromJson,
      args: [name ?? ''],
    );
  }

  Future<RoleManagement?> getRoleByCode(String roleCode) {
    requireNotBlank(roleCode, 'roleCode');
    return requestNullableObject(
      'GET',
      '/api/roles/by-code/$roleCode',
      RoleManagement.fromJson,
    );
  }

  Future<List<RoleManagement>> searchRolesByCodePrefix({
    required String roleCode,
    int page = 1,
    int size = 20,
  }) {
    return _searchRoles(
      '/api/roles/search/code/prefix',
      {'roleCode': roleCode},
      page,
      size,
    );
  }

  Future<List<RoleManagement>> searchRolesByCodeFuzzy({
    required String roleCode,
    int page = 1,
    int size = 20,
  }) {
    return _searchRoles(
      '/api/roles/search/code/fuzzy',
      {'roleCode': roleCode},
      page,
      size,
    );
  }

  Future<List<RoleManagement>> searchRolesByNamePrefix({
    required String roleName,
    int page = 1,
    int size = 20,
  }) {
    return _searchRoles(
      '/api/roles/search/name/prefix',
      {'roleName': roleName},
      page,
      size,
    );
  }

  Future<List<RoleManagement>> searchRolesByNameFuzzy({
    required String roleName,
    int page = 1,
    int size = 20,
  }) {
    return _searchRoles(
      '/api/roles/search/name/fuzzy',
      {'roleName': roleName},
      page,
      size,
    );
  }

  Future<List<RoleManagement>> searchRolesByType({
    required String roleType,
    int page = 1,
    int size = 20,
  }) {
    return _searchRoles(
      '/api/roles/search/type',
      {'roleType': roleType},
      page,
      size,
    );
  }

  Future<List<RoleManagement>> searchRolesByDataScope({
    required String dataScope,
    int page = 1,
    int size = 20,
  }) {
    return _searchRoles(
      '/api/roles/search/data-scope',
      {'dataScope': dataScope},
      page,
      size,
    );
  }

  Future<List<RoleManagement>> searchRolesByStatus({
    required String status,
    int page = 1,
    int size = 20,
  }) {
    return _searchRoles(
      '/api/roles/search/status',
      {'status': status},
      page,
      size,
    );
  }

  Future<List<dynamic>> listRolePermissions({
    required int roleId,
    int page = 1,
    int size = 50,
  }) {
    return requestValueList<dynamic>(
      'GET',
      '/api/roles/$roleId/permissions',
      (value) => value,
      queryParams: pageParams(page, size),
    );
  }

  Future<List<dynamic>> searchRolePermissions({
    required int roleId,
    required int permissionId,
    int page = 1,
    int size = 50,
  }) {
    return requestValueList<dynamic>(
      'GET',
      '/api/roles/permissions/search',
      (value) => value,
      queryParams: queryParamsFromMap({
        'roleId': roleId,
        'permissionId': permissionId,
        'page': page,
        'size': size,
      }),
    );
  }

  Future<List<RoleManagement>> _searchRoles(
    String path,
    Map<String, Object?> filters,
    int page,
    int size,
  ) {
    return requestList(
      'GET',
      path,
      RoleManagement.fromJson,
      queryParams: queryParamsFromMap({
        ...filters,
        'page': page,
        'size': size,
      }),
    );
  }

  Never _missingRoleResult() {
    throw AppException.http(400, 'Missing role result from WebSocket response');
  }
}
