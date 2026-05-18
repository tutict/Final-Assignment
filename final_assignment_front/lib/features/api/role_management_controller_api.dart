import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'package:final_assignment_front/features/model/role_management.dart';
import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

/// å®ä¹ä¸ä¸ªå
// ¨å±ç?defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class RoleManagementControllerApi with BaseApiClient {
  @override
  final ApiClient apiClient;

  /// æé å½æ°ï¼å¯ä¼ å
// ?ApiClientï¼å¦åä½¿ç¨å
// ¨å±é»è®¤å®ä¾
  RoleManagementControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  /// ä»?SharedPreferences ä¸­è¯»å?jwtToken å¹¶è®¾ç½®å° ApiClient ä¸?
  Future<void> initializeWithJwt() async {
    final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null) {
      throw Exception('Not authenticated. Please log in again.');
    }
    apiClient.setJwtToken(jwtToken);
    AppLogger.debug(
        'Initialized RoleManagementControllerApi with token: $jwtToken');
  }

  /// è§£ç ååºä½å­èå°å­ç¬¦ä¸?
  String _decodeBodyBytes(http.Response response) => decodeBodyBytes(response);

  /// è¾
// å©æ¹æ³ï¼æ·»å æ¥è¯¢åæ°ï¼å¦åç§°æç´¢ï¼
  List<QueryParam> _addQueryParams({String? name}) {
    final queryParams = <QueryParam>[];
    if (name != null) queryParams.add(QueryParam('name', name));
    return queryParams;
  }

  /// POST /api/roles - åå»ºæ°çè§è²è®°å½ (ä»?ADMIN)
  Future<RoleManagement?> createRole(
      RoleManagement role, String idempotencyKey) async {
    final response = await apiClient.invokeAPI(
      '/api/roles',
      'POST',
      _addQueryParams(),
      role.toJson(),
      await getHeaders(idempotencyKey: idempotencyKey),
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode == 208) {
      return null;
    }
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw AppException.http(response.statusCode, _decodeBodyBytes(response));
    }
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return RoleManagement.fromJson(data);
  }

  /// GET /api/roles/{roleId} - æ ¹æ®è§è²IDè·åè§è²ä¿¡æ¯ (USER å?ADMIN)
  Future<RoleManagement?> getRole(int roleId) async {
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
    if (response.body.isEmpty) return null;
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return RoleManagement.fromJson(data);
  }

  /// GET /api/roles - è·åææè§è²ä¿¡æ?(USER å?ADMIN)
  Future<List<RoleManagement>> listRoles() async {
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
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return RoleManagement.listFromJson(data);
  }

  /// GET /api/roles/name/{roleName} - æ ¹æ®è§è²åç§°è·åè§è²ä¿¡æ¯ (USER å?ADMIN)
  /// GET /api/roles/search - æ ¹æ®è§è²åç§°æ¨¡ç³å¹é
// è·åè§è²ä¿¡æ¯ (USER å?ADMIN)
  Future<List<RoleManagement>> searchRoles({String? name}) async {
    if (name == null || name.isEmpty) {
      return listRoles();
    }
    final response = await apiClient.invokeAPI(
      '/api/roles/search/name/fuzzy',
      'GET',
      [QueryParam('roleName', name)],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return RoleManagement.listFromJson(data);
  }

  /// PUT /api/roles/{roleId} - æ´æ°æå®è§è²çä¿¡æ?(ä»?ADMIN)
  Future<RoleManagement> updateRole(
      int roleId, RoleManagement updatedRole, String idempotencyKey) async {
    final response = await apiClient.invokeAPI(
      '/api/roles/$roleId',
      'PUT',
      _addQueryParams(),
      updatedRole.toJson(),
      await getHeaders(idempotencyKey: idempotencyKey),
      {},
      'application/json',
      ['bearerAuth'],
    );
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return RoleManagement.fromJson(data);
  }

  /// DELETE /api/roles/{roleId} - å é¤æå®è§è²è®°å½ (ä»?ADMIN)
  Future<void> deleteRole(int roleId) async {
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
      throw AppException.http(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// DELETE /api/roles/name/{roleName} - æ ¹æ®è§è²åç§°å é¤è§è²è®°å½ (ä»?ADMIN)
  /// è·åå½åç¨æ·è§è² (USER å?ADMIN)
  Future<String> getCurrentUserRole() async {
    final roles = await listRoles();
    for (var role in roles) {
      if (role.roleName != null && role.roleName!.isNotEmpty) {
        return role
            .roleName!; // è¿åç¬¬ä¸ä¸ªéç©ºè§è²åï¼åè®¾ç¨æ·åªæä¸ä¸ªä¸»è¦è§è?
      }
    }
    throw AppException.http(403, 'æ æ³ç¡®å®ç¨æ·è§è²');
  }

  // WebSocket Methods (Aligned with HTTP Endpoints)

  /// GET /api/roles (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="RoleManagement", action="getAllRoles")
  Future<List<RoleManagement>> eventbusRolesGet() async {
    final msg = {
      "service": "RoleManagement",
      "action": "getAllRoles",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw AppException.http(400, respMap["error"]);
    }
    if (respMap["result"] is List) {
      return (respMap["result"] as List)
          .map((json) => RoleManagement.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// DELETE /api/roles/name/{roleName} (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="RoleManagement", action="deleteRoleByName")
  Future<bool> eventbusRolesNameRoleNameDelete(
      {required String roleName}) async {
    if (roleName.isEmpty) {
      throw AppException.http(400, "Missing required param: roleName");
    }
    final msg = {
      "service": "RoleManagement",
      "action": "deleteRoleByName",
      "args": [roleName]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw AppException.http(400, respMap["error"]);
    }
    return true; // Success if no error
  }

  /// GET /api/roles/name/{roleName} (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="RoleManagement", action="getRoleByName")
  Future<RoleManagement?> eventbusRolesNameRoleNameGet(
      {required String roleName}) async {
    if (roleName.isEmpty) {
      throw AppException.http(400, "Missing required param: roleName");
    }
    final msg = {
      "service": "RoleManagement",
      "action": "getRoleByName",
      "args": [roleName]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw AppException.http(400, respMap["error"]);
    }
    if (respMap["result"] != null) {
      return RoleManagement.fromJson(respMap["result"] as Map<String, dynamic>);
    }
    return null;
  }

  /// POST /api/roles (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="RoleManagement", action="createRole")
  Future<RoleManagement> eventbusRolesPost(
      {required RoleManagement roleManagement, String? idempotencyKey}) async {
    final msg = {
      "service": "RoleManagement",
      "action": "createRole",
      "args": idempotencyKey != null
          ? [roleManagement.toJson(), idempotencyKey]
          : [roleManagement.toJson()]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw AppException.http(400, respMap["error"]);
    }
    return RoleManagement.fromJson(respMap["result"] as Map<String, dynamic>);
  }

  /// DELETE /api/roles/{roleId} (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="RoleManagement", action="deleteRole")
  Future<bool> eventbusRolesRoleIdDelete({required int roleId}) async {
    final msg = {
      "service": "RoleManagement",
      "action": "deleteRole",
      "args": [roleId]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw AppException.http(400, respMap["error"]);
    }
    return true; // Success if no error
  }

  /// GET /api/roles/{roleId} (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="RoleManagement", action="getRoleById")
  Future<RoleManagement?> eventbusRolesRoleIdGet({required int roleId}) async {
    final msg = {
      "service": "RoleManagement",
      "action": "getRoleById",
      "args": [roleId]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw AppException.http(400, respMap["error"]);
    }
    if (respMap["result"] != null) {
      return RoleManagement.fromJson(respMap["result"] as Map<String, dynamic>);
    }
    return null;
  }

  /// PUT /api/roles/{roleId} (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="RoleManagement", action="updateRole")
  Future<RoleManagement> eventbusRolesRoleIdPut({
    required int roleId,
    required RoleManagement updatedRole,
    String? idempotencyKey,
  }) async {
    final msg = {
      "service": "RoleManagement",
      "action": "updateRole",
      "args": idempotencyKey != null
          ? [roleId, updatedRole.toJson(), idempotencyKey]
          : [roleId, updatedRole.toJson()]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw AppException.http(400, respMap["error"]);
    }
    return RoleManagement.fromJson(respMap["result"] as Map<String, dynamic>);
  }

  /// GET /api/roles/search (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="RoleManagement", action="getRolesByNameLike")
  Future<List<RoleManagement>> eventbusRolesSearchGet({String? name}) async {
    final msg = {
      "service": "RoleManagement",
      "action": "getRolesByNameLike",
      "args": [name ?? ""]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw AppException.http(400, respMap["error"]);
    }
    if (respMap["result"] is List) {
      return (respMap["result"] as List)
          .map((json) => RoleManagement.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // HTTP: GET /api/roles/by-code/{roleCode} - æ ¹æ®è§è²ç¼ç è·å
  Future<RoleManagement?> getRoleByCode(String roleCode) async {
    if (roleCode.isEmpty) {
      throw AppException.http(400, "Missing required param: roleCode");
    }
    final response = await apiClient.invokeAPI(
      '/api/roles/by-code/$roleCode',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.body.isEmpty) return null;
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return RoleManagement.fromJson(data);
  }

  // HTTP: GET /api/roles/search/code/prefix?roleCode=&page=&size=
  Future<List<RoleManagement>> searchRolesByCodePrefix({
    required String roleCode,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/roles/search/code/prefix',
      'GET',
      [
        QueryParam('roleCode', roleCode),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return RoleManagement.listFromJson(data);
  }

  // HTTP: GET /api/roles/search/code/fuzzy?roleCode=&page=&size=
  Future<List<RoleManagement>> searchRolesByCodeFuzzy({
    required String roleCode,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/roles/search/code/fuzzy',
      'GET',
      [
        QueryParam('roleCode', roleCode),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return RoleManagement.listFromJson(data);
  }

  // HTTP: GET /api/roles/search/name/prefix?roleName=&page=&size=
  Future<List<RoleManagement>> searchRolesByNamePrefix({
    required String roleName,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/roles/search/name/prefix',
      'GET',
      [
        QueryParam('roleName', roleName),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return RoleManagement.listFromJson(data);
  }

  // HTTP: GET /api/roles/search/name/fuzzy?roleName=&page=&size=
  Future<List<RoleManagement>> searchRolesByNameFuzzy({
    required String roleName,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/roles/search/name/fuzzy',
      'GET',
      [
        QueryParam('roleName', roleName),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return RoleManagement.listFromJson(data);
  }

  // HTTP: GET /api/roles/search/type?roleType=&page=&size=
  Future<List<RoleManagement>> searchRolesByType({
    required String roleType,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/roles/search/type',
      'GET',
      [
        QueryParam('roleType', roleType),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return RoleManagement.listFromJson(data);
  }

  // HTTP: GET /api/roles/search/data-scope?dataScope=&page=&size=
  Future<List<RoleManagement>> searchRolesByDataScope({
    required String dataScope,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/roles/search/data-scope',
      'GET',
      [
        QueryParam('dataScope', dataScope),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return RoleManagement.listFromJson(data);
  }

  // HTTP: GET /api/roles/search/status?status=&page=&size=
  Future<List<RoleManagement>> searchRolesByStatus({
    required String status,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/roles/search/status',
      'GET',
      [
        QueryParam('status', status),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return RoleManagement.listFromJson(data);
  }

  // HTTP: GET /api/roles/{roleId}/permissions - æ¥è¯¢è§è²æ¥æçæé?
  Future<List<dynamic>> listRolePermissions({
    required int roleId,
    int page = 1,
    int size = 50,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/roles/$roleId/permissions',
      'GET',
      [
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    return apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
  }

  // HTTP: GET /api/roles/permissions/search?roleId=&permissionId=&page=&size=
  Future<List<dynamic>> searchRolePermissions({
    required int roleId,
    required int permissionId,
    int page = 1,
    int size = 50,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/roles/permissions/search',
      'GET',
      [
        QueryParam('roleId', '$roleId'),
        QueryParam('permissionId', '$permissionId'),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    return apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
  }
}
