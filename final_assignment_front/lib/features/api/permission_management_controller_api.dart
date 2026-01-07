import 'package:final_assignment_front/features/model/permission_management.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

/// å®ä¹ä¸ä¸ªå¨å±ç?defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class PermissionManagementControllerApi {
  final ApiClient apiClient;

  /// æé å½æ°ï¼å¯ä¼ å?ApiClientï¼å¦åä½¿ç¨å¨å±é»è®¤å®ä¾
  PermissionManagementControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  /// ä»?SharedPreferences ä¸­è¯»å?jwtToken å¹¶è®¾ç½®å° ApiClient ä¸?
  Future<void> initializeWithJwt() async {
      final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null) {
      throw Exception('æªç»å½ï¼è¯·éæ°ç»å½?);
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint(
        'Initialized PermissionManagementControllerApi with token: $jwtToken');
  }

  /// è§£ç ååºä½å­èå°å­ç¬¦ä¸?
  String _decodeBodyBytes(Response response) => response.body;

  /// è¾å©æ¹æ³ï¼æ·»å æ¥è¯¢åæ°ï¼å¦åç§°æç´¢ï¼
  List<QueryParam> _addQueryParams({String? name}) {
    final queryParams = <QueryParam>[];
    if (name != null) queryParams.add(QueryParam('name', name));
    return queryParams;
  }

  /// GET /api/permissions - è·åæææé?
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

  /// DELETE /api/permissions/name/{permissionName} - æ ¹æ®åç§°å é¤æé (ä»ç®¡çå)
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

  /// GET /api/permissions/name/{permissionName} - æ ¹æ®åç§°è·åæé
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

  /// DELETE /api/permissions/{permissionId} - æ ¹æ®IDå é¤æé (ä»ç®¡çå)
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

  /// GET /api/permissions/{permissionId} - æ ¹æ®IDè·åæé
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

  /// PUT /api/permissions/{permissionId} - æ´æ°æé (ä»ç®¡çå)
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

  /// POST /api/permissions - åå»ºæé (ä»ç®¡çå)
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

  /// GET /api/permissions/search - æ ¹æ®åç§°æ¨¡ç³æç´¢æé
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
  /// å¯¹åºåç«¯: @WsAction(service="PermissionManagement", action="getAllPermissions")
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
  /// å¯¹åºåç«¯: @WsAction(service="PermissionManagement", action="deletePermissionByName")
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
  /// å¯¹åºåç«¯: @WsAction(service="PermissionManagement", action="getPermissionByName")
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
  /// å¯¹åºåç«¯: @WsAction(service="PermissionManagement", action="deletePermission")
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
  /// å¯¹åºåç«¯: @WsAction(service="PermissionManagement", action="getPermissionById")
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
  /// å¯¹åºåç«¯: @WsAction(service="PermissionManagement", action="updatePermission")
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
  /// å¯¹åºåç«¯: @WsAction(service="PermissionManagement", action="createPermission")
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
  /// å¯¹åºåç«¯: @WsAction(service="PermissionManagement", action="getPermissionsByNameLike")
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

  // HTTP: GET /api/permissions/parent/{parentId} - æç¶èç¹æ¥è¯¢æé
  Future<List<PermissionManagement>> apiPermissionsParentParentIdGet({
    required int parentId,
    int page = 1,
    int size = 50,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/permissions/parent/$parentId',
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
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return PermissionManagement.listFromJson(data);
  }

  // HTTP: GET /api/permissions/search/code/prefix
  Future<List<PermissionManagement>> apiPermissionsSearchCodePrefixGet({
    required String permissionCode,
    int page = 1,
    int size = 50,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/permissions/search/code/prefix',
      'GET',
      [
        QueryParam('permissionCode', permissionCode),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
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

  // HTTP: GET /api/permissions/search/code/fuzzy
  Future<List<PermissionManagement>> apiPermissionsSearchCodeFuzzyGet({
    required String permissionCode,
    int page = 1,
    int size = 50,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/permissions/search/code/fuzzy',
      'GET',
      [
        QueryParam('permissionCode', permissionCode),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
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

  // HTTP: GET /api/permissions/search/name/prefix
  Future<List<PermissionManagement>> apiPermissionsSearchNamePrefixGet({
    required String permissionName,
    int page = 1,
    int size = 50,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/permissions/search/name/prefix',
      'GET',
      [
        QueryParam('permissionName', permissionName),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
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

  // HTTP: GET /api/permissions/search/name/fuzzy
  Future<List<PermissionManagement>> apiPermissionsSearchNameFuzzyGet({
    required String permissionName,
    int page = 1,
    int size = 50,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/permissions/search/name/fuzzy',
      'GET',
      [
        QueryParam('permissionName', permissionName),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
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

  // HTTP: GET /api/permissions/search/type
  Future<List<PermissionManagement>> apiPermissionsSearchTypeGet({
    required String permissionType,
    int page = 1,
    int size = 50,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/permissions/search/type',
      'GET',
      [
        QueryParam('permissionType', permissionType),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
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

  // HTTP: GET /api/permissions/search/api-path
  Future<List<PermissionManagement>> apiPermissionsSearchApiPathGet({
    required String apiPath,
    int page = 1,
    int size = 50,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/permissions/search/api-path',
      'GET',
      [
        QueryParam('apiPath', apiPath),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
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

  // HTTP: GET /api/permissions/search/menu-path
  Future<List<PermissionManagement>> apiPermissionsSearchMenuPathGet({
    required String menuPath,
    int page = 1,
    int size = 50,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/permissions/search/menu-path',
      'GET',
      [
        QueryParam('menuPath', menuPath),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
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

  // HTTP: GET /api/permissions/search/visible
  Future<List<PermissionManagement>> apiPermissionsSearchVisibleGet({
    required bool isVisible,
    int page = 1,
    int size = 50,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/permissions/search/visible',
      'GET',
      [
        QueryParam('isVisible', isVisible.toString()),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
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

  // HTTP: GET /api/permissions/search/external
  Future<List<PermissionManagement>> apiPermissionsSearchExternalGet({
    required bool isExternal,
    int page = 1,
    int size = 50,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/permissions/search/external',
      'GET',
      [
        QueryParam('isExternal', isExternal.toString()),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
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

  // HTTP: GET /api/permissions/search/status
  Future<List<PermissionManagement>> apiPermissionsSearchStatusGet({
    required String status,
    int page = 1,
    int size = 50,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/permissions/search/status',
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
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return PermissionManagement.listFromJson(data);
  }
}
