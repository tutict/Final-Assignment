import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/features/model/permission_management.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';

final ApiClient defaultApiClient = ApiClient();

class PermissionManagementControllerApi with BaseApiClient {
  @override
  final ApiClient apiClient;

  PermissionManagementControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  Future<void> initializeWithJwt() => initializeClientWithJwt();

  Future<List<PermissionManagement>> listPermissions() {
    return requestList(
      'GET',
      '/api/permissions',
      PermissionManagement.fromJson,
    );
  }

  Future<void> deletePermissionByName({required String permissionName}) async {
    requireNotBlank(permissionName, 'permissionName');
    final permission =
        await getPermissionByName(permissionName: permissionName);
    final permissionId = permission?.permissionId;
    if (permissionId == null) {
      throw AppException.http(
        404,
        'Permission not found for name: $permissionName',
      );
    }
    await deletePermission(permissionId: permissionId.toString());
  }

  Future<PermissionManagement?> getPermissionByName({
    required String permissionName,
  }) async {
    requireNotBlank(permissionName, 'permissionName');
    final permissions =
        await searchPermissionsByNameFuzzy(permissionName: permissionName);
    for (final permission in permissions) {
      if (permission.permissionName == permissionName ||
          permission.permissionCode == permissionName) {
        return permission;
      }
    }
    return permissions.isEmpty ? null : permissions.first;
  }

  Future<void> deletePermission({required String permissionId}) {
    requireNotBlank(permissionId, 'permissionId');
    return requestVoid('DELETE', '/api/permissions/$permissionId');
  }

  Future<PermissionManagement?> getPermission({
    required String permissionId,
  }) {
    requireNotBlank(permissionId, 'permissionId');
    return requestNullableObject(
      'GET',
      '/api/permissions/$permissionId',
      PermissionManagement.fromJson,
    );
  }

  Future<PermissionManagement> updatePermission({
    required String permissionId,
    required PermissionManagement permissionManagement,
  }) {
    requireNotBlank(permissionId, 'permissionId');
    return requestObject(
      'PUT',
      '/api/permissions/$permissionId',
      PermissionManagement.fromJson,
      body: permissionManagement.toJson(),
      contentType: BaseApiClient.defaultContentType,
    );
  }

  Future<PermissionManagement> createPermission({
    required PermissionManagement permissionManagement,
  }) {
    return requestObject(
      'POST',
      '/api/permissions',
      PermissionManagement.fromJson,
      body: permissionManagement.toJson(),
      contentType: BaseApiClient.defaultContentType,
    );
  }

  Future<List<PermissionManagement>> searchPermissions({String? name}) {
    if (name == null || name.isEmpty) {
      return listPermissions();
    }
    return requestList(
      'GET',
      '/api/permissions/search/name/fuzzy',
      PermissionManagement.fromJson,
      queryParams: [QueryParam('permissionName', name)],
    );
  }

  Future<List<Object>?> eventbusPermissionsGet() {
    return sendWsObjectList(
      service: 'PermissionManagement',
      action: 'getAllPermissions',
    );
  }

  Future<bool> eventbusPermissionsNamePermissionNameDelete({
    required String permissionName,
  }) async {
    requireNotBlank(permissionName, 'permissionName');
    await sendWs(
      service: 'PermissionManagement',
      action: 'deletePermissionByName',
      args: [permissionName],
    );
    return true;
  }

  Future<Object?> eventbusPermissionsNamePermissionNameGet({
    required String permissionName,
  }) {
    requireNotBlank(permissionName, 'permissionName');
    return sendWs(
      service: 'PermissionManagement',
      action: 'getPermissionByName',
      args: [permissionName],
    );
  }

  Future<bool> eventbusPermissionsPermissionIdDelete({
    required String permissionId,
  }) async {
    requireNotBlank(permissionId, 'permissionId');
    await sendWs(
      service: 'PermissionManagement',
      action: 'deletePermission',
      args: [int.parse(permissionId)],
    );
    return true;
  }

  Future<Object?> eventbusPermissionsPermissionIdGet({
    required String permissionId,
  }) {
    requireNotBlank(permissionId, 'permissionId');
    return sendWs(
      service: 'PermissionManagement',
      action: 'getPermissionById',
      args: [int.parse(permissionId)],
    );
  }

  Future<Object?> eventbusPermissionsPermissionIdPut({
    required String permissionId,
    required PermissionManagement permissionManagement,
  }) {
    requireNotBlank(permissionId, 'permissionId');
    return sendWs(
      service: 'PermissionManagement',
      action: 'updatePermission',
      args: [int.parse(permissionId), permissionManagement.toJson()],
    );
  }

  Future<Object?> eventbusPermissionsPost({
    required PermissionManagement permissionManagement,
  }) {
    return sendWs(
      service: 'PermissionManagement',
      action: 'createPermission',
      args: [permissionManagement.toJson()],
    );
  }

  Future<List<Object>?> eventbusPermissionsSearchGet({String? name}) {
    return sendWsObjectList(
      service: 'PermissionManagement',
      action: 'getPermissionsByNameLike',
      args: [name ?? ''],
    );
  }

  Future<List<PermissionManagement>> listPermissionsByParent({
    required int parentId,
    int page = 1,
    int size = 50,
  }) {
    return requestList(
      'GET',
      '/api/permissions/parent/$parentId',
      PermissionManagement.fromJson,
      queryParams: pageParams(page, size),
    );
  }

  Future<List<PermissionManagement>> searchPermissionsByCodePrefix({
    required String permissionCode,
    int page = 1,
    int size = 50,
  }) {
    return _searchPermissions(
      '/api/permissions/search/code/prefix',
      {'permissionCode': permissionCode},
      page,
      size,
    );
  }

  Future<List<PermissionManagement>> searchPermissionsByCodeFuzzy({
    required String permissionCode,
    int page = 1,
    int size = 50,
  }) {
    return _searchPermissions(
      '/api/permissions/search/code/fuzzy',
      {'permissionCode': permissionCode},
      page,
      size,
    );
  }

  Future<List<PermissionManagement>> searchPermissionsByNamePrefix({
    required String permissionName,
    int page = 1,
    int size = 50,
  }) {
    return _searchPermissions(
      '/api/permissions/search/name/prefix',
      {'permissionName': permissionName},
      page,
      size,
    );
  }

  Future<List<PermissionManagement>> searchPermissionsByNameFuzzy({
    required String permissionName,
    int page = 1,
    int size = 50,
  }) {
    return _searchPermissions(
      '/api/permissions/search/name/fuzzy',
      {'permissionName': permissionName},
      page,
      size,
    );
  }

  Future<List<PermissionManagement>> searchPermissionsByType({
    required String permissionType,
    int page = 1,
    int size = 50,
  }) {
    return _searchPermissions(
      '/api/permissions/search/type',
      {'permissionType': permissionType},
      page,
      size,
    );
  }

  Future<List<PermissionManagement>> searchPermissionsByApiPath({
    required String apiPath,
    int page = 1,
    int size = 50,
  }) {
    return _searchPermissions(
      '/api/permissions/search/api-path',
      {'apiPath': apiPath},
      page,
      size,
    );
  }

  Future<List<PermissionManagement>> searchPermissionsByMenuPath({
    required String menuPath,
    int page = 1,
    int size = 50,
  }) {
    return _searchPermissions(
      '/api/permissions/search/menu-path',
      {'menuPath': menuPath},
      page,
      size,
    );
  }

  Future<List<PermissionManagement>> searchPermissionsByVisible({
    required bool isVisible,
    int page = 1,
    int size = 50,
  }) {
    return _searchPermissions(
      '/api/permissions/search/visible',
      {'isVisible': isVisible},
      page,
      size,
    );
  }

  Future<List<PermissionManagement>> searchPermissionsByExternal({
    required bool isExternal,
    int page = 1,
    int size = 50,
  }) {
    return _searchPermissions(
      '/api/permissions/search/external',
      {'isExternal': isExternal},
      page,
      size,
    );
  }

  Future<List<PermissionManagement>> searchPermissionsByStatus({
    required String status,
    int page = 1,
    int size = 50,
  }) {
    return _searchPermissions(
      '/api/permissions/search/status',
      {'status': status},
      page,
      size,
    );
  }

  Future<List<PermissionManagement>> _searchPermissions(
    String path,
    Map<String, Object?> filters,
    int page,
    int size,
  ) {
    return requestList(
      'GET',
      path,
      PermissionManagement.fromJson,
      queryParams: queryParamsFromMap({
        ...filters,
        'page': page,
        'size': size,
      }),
    );
  }
}
