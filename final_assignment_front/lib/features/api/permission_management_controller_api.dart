import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'package:final_assignment_front/features/model/permission_management.dart';
import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:http/http.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

/// å®ä¹ä¸ä¸ªå
// ¨å±ç?defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class PermissionManagementControllerApi with BaseApiClient {
  @override
  final ApiClient apiClient;

  /// æé å½æ°ï¼å¯ä¼ å
// ?ApiClientï¼å¦åä½¿ç¨å
// ¨å±é»è®¤å®ä¾
  PermissionManagementControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  /// ä»?SharedPreferences ä¸­è¯»å?jwtToken å¹¶è®¾ç½®å° ApiClient ä¸?
  /// 使用当前登录态初始化权限管理 API 客户端的 JWT。
  ///
  /// 调用权限管理接口前应先完成初始化；权限校验由后端根据当前 JWT 和角色执行。
  ///
  /// 抛出 [Exception]：当本地登录态无有效 JWT 时。
  Future<void> initializeWithJwt() async {
    final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null) {
      throw Exception('Not authenticated. Please log in again.');
    }
    apiClient.setJwtToken(jwtToken);
    AppLogger.debug(
        'Initialized PermissionManagementControllerApi with token: $jwtToken');
  }

  /// è§£ç ååºä½å­èå°å­ç¬¦ä¸?
  String _decodeBodyBytes(Response response) => decodeBodyBytes(response);

  /// è¾
// å©æ¹æ³ï¼æ·»å æ¥è¯¢åæ°ï¼å¦åç§°æç´¢ï¼
  /// GET /api/permissions - è·åæææé?
  /// 获取权限配置列表。
  ///
  /// 返回 [PermissionManagement] 列表；调用方需要具备后端要求的权限管理角色。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 或后端角色校验失败时。
  ///
  /// 对应接口：GET /api/permissions
  Future<List<PermissionManagement>> listPermissions() async {
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
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return PermissionManagement.listFromJson(data);
  }

  /// DELETE /api/permissions/name/{permissionName} - æ ¹æ®åç§°å é¤æé (ä»
// ç®¡çå)
  /// 按权限名称删除权限配置。
  ///
  /// [permissionName] 权限名称，不能为空。
  ///
  /// 删除成功时无返回值；调用方需要具备后端要求的权限管理角色。
  ///
  /// 抛出 [AppException]：当 [permissionName] 为空、HTTP 响应非 2xx 或后端角色校验失败时。
  ///
  /// 对应接口：DELETE /api/permissions/name/{permissionName}
  Future<void> deletePermissionByName({required String permissionName}) async {
    if (permissionName.isEmpty) {
      throw AppException.http(400, "Missing required param: permissionName");
    }
    final permission =
        await getPermissionByName(permissionName: permissionName);
    final permissionId = permission?.permissionId;
    if (permissionId == null) {
      throw AppException.http(
          404, 'Permission not found for name: $permissionName');
    }
    await deletePermission(permissionId: permissionId.toString());
  }

  /// GET /api/permissions/name/{permissionName} - æ ¹æ®åç§°è·åæé
  /// 按权限名称获取权限配置。
  ///
  /// [permissionName] 权限名称，不能为空。
  ///
  /// 返回 [PermissionManagement]；后端返回空响应时返回 `null`。
  ///
  /// 抛出 [AppException]：当 [permissionName] 为空、HTTP 响应非 2xx 或后端角色校验失败时。
  ///
  /// 对应接口：GET /api/permissions/name/{permissionName}
  Future<PermissionManagement?> getPermissionByName(
      {required String permissionName}) async {
    if (permissionName.isEmpty) {
      throw AppException.http(400, "Missing required param: permissionName");
    }
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

  /// DELETE /api/permissions/{permissionId} - æ ¹æ®IDå é¤æé (ä»
// ç®¡çå)
  /// 按权限 ID 删除权限配置。
  ///
  /// [permissionId] 权限主键，不能为空。
  ///
  /// 删除成功时无返回值；调用方需要具备后端要求的权限管理角色。
  ///
  /// 抛出 [AppException]：当 [permissionId] 为空、HTTP 响应非 2xx 或后端角色校验失败时。
  ///
  /// 对应接口：DELETE /api/permissions/{permissionId}
  Future<void> deletePermission({required String permissionId}) async {
    if (permissionId.isEmpty) {
      throw AppException.http(400, "Missing required param: permissionId");
    }
    await apiClient.invokeAPI(
      '/api/permissions/$permissionId',
      'DELETE',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
  }

  /// GET /api/permissions/{permissionId} - æ ¹æ®IDè·åæé
  /// 按权限 ID 获取权限配置。
  ///
  /// [permissionId] 权限主键，不能为空。
  ///
  /// 返回 [PermissionManagement]；后端返回空响应时返回 `null`。
  ///
  /// 抛出 [AppException]：当 [permissionId] 为空、HTTP 响应非 2xx 或后端角色校验失败时。
  ///
  /// 对应接口：GET /api/permissions/{permissionId}
  Future<PermissionManagement?> getPermission(
      {required String permissionId}) async {
    if (permissionId.isEmpty) {
      throw AppException.http(400, "Missing required param: permissionId");
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
    if (response.body.isEmpty) return null;
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return PermissionManagement.fromJson(data);
  }

  /// PUT /api/permissions/{permissionId} - æ´æ°æé (ä»
// ç®¡çå)
  /// 更新权限配置。
  ///
  /// [permissionId] 待更新的权限主键，不能为空。
  /// [permissionManagement] 更新后的权限配置。
  ///
  /// 返回后端更新后的 [PermissionManagement]；调用方需要具备后端要求的权限管理角色。
  ///
  /// 抛出 [AppException]：当 [permissionId] 为空、HTTP 响应非 2xx 或后端角色校验失败时。
  ///
  /// 对应接口：PUT /api/permissions/{permissionId}
  Future<PermissionManagement> updatePermission({
    required String permissionId,
    required PermissionManagement permissionManagement,
  }) async {
    if (permissionId.isEmpty) {
      throw AppException.http(400, "Missing required param: permissionId");
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
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return PermissionManagement.fromJson(data);
  }

  /// POST /api/permissions - åå»ºæé (ä»
// ç®¡çå)
  /// 创建权限配置。
  ///
  /// [permissionManagement] 待创建的权限配置。
  ///
  /// 返回后端创建后的 [PermissionManagement]；调用方需要具备后端要求的权限管理角色。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 或后端角色校验失败时。
  ///
  /// 对应接口：POST /api/permissions
  Future<PermissionManagement> createPermission(
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
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return PermissionManagement.fromJson(data);
  }

  /// GET /api/permissions/search - æ ¹æ®åç§°æ¨¡ç³æç´¢æé
  /// 按权限名称搜索权限配置。
  ///
  /// [name] 权限名称关键字；为空时由后端决定是否返回全部或空结果。
  ///
  /// 返回 [PermissionManagement] 列表；调用方需要具备后端要求的权限管理角色。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 或后端角色校验失败时。
  ///
  /// 对应接口：GET /api/permissions/search
  Future<List<PermissionManagement>> searchPermissions({String? name}) async {
    if (name == null || name.isEmpty) {
      return listPermissions();
    }
    final response = await apiClient.invokeAPI(
      '/api/permissions/search/name/fuzzy',
      'GET',
      [QueryParam('permissionName', name)],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return PermissionManagement.listFromJson(data);
  }

  // WebSocket Methods (Aligned with HTTP Endpoints)

  /// GET /api/permissions (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="PermissionManagement", action="getAllPermissions")
  /// @realtimeApi
  /// 通过 WebSocket eventbus 获取权限配置列表。
  ///
  /// 返回 eventbus 原始权限对象列表；result 不是列表时返回 `null`。
  ///
  /// 抛出 [AppException]：当 WebSocket 响应包含 `error` 字段时。
  ///
  /// 对应实时动作：PermissionManagement.getAllPermissions
  Future<List<Object>?> eventbusPermissionsGet() async {
    final msg = {
      "service": "PermissionManagement",
      "action": "getAllPermissions",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw AppException.http(400, respMap["error"]);
    }
    if (respMap["result"] is List) {
      return (respMap["result"] as List).cast<Object>();
    }
    return null;
  }

  /// DELETE /api/permissions/name/{permissionName} (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="PermissionManagement", action="deletePermissionByName")
  /// @realtimeApi
  /// 通过 WebSocket eventbus 按权限名称删除权限配置。
  ///
  /// [permissionName] 权限名称，不能为空。
  ///
  /// 返回 `true` 表示 eventbus 未返回错误；调用方需要具备后端要求的权限管理角色。
  ///
  /// 抛出 [AppException]：当 [permissionName] 为空或 WebSocket 响应包含 `error` 字段时。
  ///
  /// 对应实时动作：PermissionManagement.deletePermissionByName
  Future<bool> eventbusPermissionsNamePermissionNameDelete(
      {required String permissionName}) async {
    if (permissionName.isEmpty) {
      throw AppException.http(400, "Missing required param: permissionName");
    }
    final msg = {
      "service": "PermissionManagement",
      "action": "deletePermissionByName",
      "args": [permissionName]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw AppException.http(400, respMap["error"]);
    }
    return true; // Success if no error
  }

  /// GET /api/permissions/name/{permissionName} (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="PermissionManagement", action="getPermissionByName")
  /// @realtimeApi
  /// 通过 WebSocket eventbus 按权限名称获取权限配置。
  ///
  /// [permissionName] 权限名称，不能为空。
  ///
  /// 返回 eventbus 原始 result；未找到时可能返回 `null`。
  ///
  /// 抛出 [AppException]：当 [permissionName] 为空或 WebSocket 响应包含 `error` 字段时。
  ///
  /// 对应实时动作：PermissionManagement.getPermissionByName
  Future<Object?> eventbusPermissionsNamePermissionNameGet(
      {required String permissionName}) async {
    if (permissionName.isEmpty) {
      throw AppException.http(400, "Missing required param: permissionName");
    }
    final msg = {
      "service": "PermissionManagement",
      "action": "getPermissionByName",
      "args": [permissionName]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw AppException.http(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// DELETE /api/permissions/{permissionId} (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="PermissionManagement", action="deletePermission")
  /// @realtimeApi
  /// 通过 WebSocket eventbus 按权限 ID 删除权限配置。
  ///
  /// [permissionId] 权限主键字符串，不能为空，内部会转换为整数传给后端。
  ///
  /// 返回 `true` 表示 eventbus 未返回错误；调用方需要具备后端要求的权限管理角色。
  ///
  /// 抛出 [AppException]：当 [permissionId] 为空或 WebSocket 响应包含 `error` 字段时。
  ///
  /// 对应实时动作：PermissionManagement.deletePermission
  Future<bool> eventbusPermissionsPermissionIdDelete(
      {required String permissionId}) async {
    if (permissionId.isEmpty) {
      throw AppException.http(400, "Missing required param: permissionId");
    }
    final msg = {
      "service": "PermissionManagement",
      "action": "deletePermission",
      "args": [int.parse(permissionId)]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw AppException.http(400, respMap["error"]);
    }
    return true; // Success if no error
  }

  /// GET /api/permissions/{permissionId} (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="PermissionManagement", action="getPermissionById")
  /// @realtimeApi
  /// 通过 WebSocket eventbus 按权限 ID 获取权限配置。
  ///
  /// [permissionId] 权限主键字符串，不能为空，内部会转换为整数传给后端。
  ///
  /// 返回 eventbus 原始 result；未找到时可能返回 `null`。
  ///
  /// 抛出 [AppException]：当 [permissionId] 为空或 WebSocket 响应包含 `error` 字段时。
  ///
  /// 对应实时动作：PermissionManagement.getPermissionById
  Future<Object?> eventbusPermissionsPermissionIdGet(
      {required String permissionId}) async {
    if (permissionId.isEmpty) {
      throw AppException.http(400, "Missing required param: permissionId");
    }
    final msg = {
      "service": "PermissionManagement",
      "action": "getPermissionById",
      "args": [int.parse(permissionId)]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw AppException.http(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// PUT /api/permissions/{permissionId} (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="PermissionManagement", action="updatePermission")
  /// @realtimeApi
  /// 通过 WebSocket eventbus 更新权限配置。
  ///
  /// [permissionId] 权限主键字符串，不能为空，内部会转换为整数传给后端。
  /// [permissionManagement] 更新后的权限配置。
  ///
  /// 返回 eventbus 原始 result；调用方需要具备后端要求的权限管理角色。
  ///
  /// 抛出 [AppException]：当 [permissionId] 为空或 WebSocket 响应包含 `error` 字段时。
  ///
  /// 对应实时动作：PermissionManagement.updatePermission
  Future<Object?> eventbusPermissionsPermissionIdPut({
    required String permissionId,
    required PermissionManagement permissionManagement,
  }) async {
    if (permissionId.isEmpty) {
      throw AppException.http(400, "Missing required param: permissionId");
    }
    final msg = {
      "service": "PermissionManagement",
      "action": "updatePermission",
      "args": [int.parse(permissionId), permissionManagement.toJson()]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw AppException.http(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// POST /api/permissions (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="PermissionManagement", action="createPermission")
  /// @realtimeApi
  /// 通过 WebSocket eventbus 创建权限配置。
  ///
  /// [permissionManagement] 待创建的权限配置。
  ///
  /// 返回 eventbus 原始 result；调用方需要具备后端要求的权限管理角色。
  ///
  /// 抛出 [AppException]：当 WebSocket 响应包含 `error` 字段时。
  ///
  /// 对应实时动作：PermissionManagement.createPermission
  Future<Object?> eventbusPermissionsPost(
      {required PermissionManagement permissionManagement}) async {
    final msg = {
      "service": "PermissionManagement",
      "action": "createPermission",
      "args": [permissionManagement.toJson()]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw AppException.http(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/permissions/search (WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="PermissionManagement", action="getPermissionsByNameLike")
  /// @realtimeApi
  /// 通过 WebSocket eventbus 按权限名称搜索权限配置。
  ///
  /// [name] 权限名称关键字；为空时传递空字符串给后端。
  ///
  /// 返回 eventbus 原始权限对象列表；result 不是列表时返回 `null`。
  ///
  /// 抛出 [AppException]：当 WebSocket 响应包含 `error` 字段时。
  ///
  /// 对应实时动作：PermissionManagement.getPermissionsByNameLike
  Future<List<Object>?> eventbusPermissionsSearchGet({String? name}) async {
    final msg = {
      "service": "PermissionManagement",
      "action": "getPermissionsByNameLike",
      "args": [name ?? ""]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw AppException.http(400, respMap["error"]);
    }
    if (respMap["result"] is List) {
      return (respMap["result"] as List).cast<Object>();
    }
    return null;
  }

  // HTTP: GET /api/permissions/parent/{parentId} - æç¶èç¹æ¥è¯¢æé
  /// 按父权限 ID 获取子权限列表。
  ///
  /// [parentId] 父权限主键。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 50。
  ///
  /// 返回 [PermissionManagement] 列表；调用方需要具备后端要求的权限管理角色。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 或后端角色校验失败时。
  ///
  /// 对应接口：GET /api/permissions/parent/{parentId}
  Future<List<PermissionManagement>> listPermissionsByParent({
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
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return PermissionManagement.listFromJson(data);
  }

  // HTTP: GET /api/permissions/search/code/prefix
  /// 按权限编码前缀搜索权限配置。
  ///
  /// [permissionCode] 权限编码前缀。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 50。
  ///
  /// 返回 [PermissionManagement] 列表；调用方需要具备后端要求的权限管理角色。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 或后端角色校验失败时。
  ///
  /// 对应接口：GET /api/permissions/search/code/prefix
  Future<List<PermissionManagement>> searchPermissionsByCodePrefix({
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
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return PermissionManagement.listFromJson(data);
  }

  // HTTP: GET /api/permissions/search/code/fuzzy
  /// 按权限编码模糊搜索权限配置。
  ///
  /// [permissionCode] 权限编码关键字，模糊匹配规则由后端定义。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 50。
  ///
  /// 返回 [PermissionManagement] 列表；调用方需要具备后端要求的权限管理角色。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 或后端角色校验失败时。
  ///
  /// 对应接口：GET /api/permissions/search/code/fuzzy
  Future<List<PermissionManagement>> searchPermissionsByCodeFuzzy({
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
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return PermissionManagement.listFromJson(data);
  }

  // HTTP: GET /api/permissions/search/name/prefix
  /// 按权限名称前缀搜索权限配置。
  ///
  /// [permissionName] 权限名称前缀。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 50。
  ///
  /// 返回 [PermissionManagement] 列表；调用方需要具备后端要求的权限管理角色。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 或后端角色校验失败时。
  ///
  /// 对应接口：GET /api/permissions/search/name/prefix
  Future<List<PermissionManagement>> searchPermissionsByNamePrefix({
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
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return PermissionManagement.listFromJson(data);
  }

  // HTTP: GET /api/permissions/search/name/fuzzy
  /// 按权限名称模糊搜索权限配置。
  ///
  /// [permissionName] 权限名称关键字，模糊匹配规则由后端定义。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 50。
  ///
  /// 返回 [PermissionManagement] 列表；调用方需要具备后端要求的权限管理角色。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 或后端角色校验失败时。
  ///
  /// 对应接口：GET /api/permissions/search/name/fuzzy
  Future<List<PermissionManagement>> searchPermissionsByNameFuzzy({
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
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return PermissionManagement.listFromJson(data);
  }

  // HTTP: GET /api/permissions/search/type
  /// 按权限类型搜索权限配置。
  ///
  /// [permissionType] 权限类型，例如菜单权限、接口权限等后端定义值。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 50。
  ///
  /// 返回 [PermissionManagement] 列表；调用方需要具备后端要求的权限管理角色。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 或后端角色校验失败时。
  ///
  /// 对应接口：GET /api/permissions/search/type
  Future<List<PermissionManagement>> searchPermissionsByType({
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
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return PermissionManagement.listFromJson(data);
  }

  // HTTP: GET /api/permissions/search/api-path
  /// 按后端 API 路径搜索权限配置。
  ///
  /// [apiPath] API 路径或路径片段，匹配规则由后端定义。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 50。
  ///
  /// 返回 [PermissionManagement] 列表；调用方需要具备后端要求的权限管理角色。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 或后端角色校验失败时。
  ///
  /// 对应接口：GET /api/permissions/search/api-path
  Future<List<PermissionManagement>> searchPermissionsByApiPath({
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
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return PermissionManagement.listFromJson(data);
  }

  // HTTP: GET /api/permissions/search/menu-path
  /// 按前端菜单路径搜索权限配置。
  ///
  /// [menuPath] 菜单路径或路径片段，匹配规则由后端定义。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 50。
  ///
  /// 返回 [PermissionManagement] 列表；调用方需要具备后端要求的权限管理角色。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 或后端角色校验失败时。
  ///
  /// 对应接口：GET /api/permissions/search/menu-path
  Future<List<PermissionManagement>> searchPermissionsByMenuPath({
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
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return PermissionManagement.listFromJson(data);
  }

  // HTTP: GET /api/permissions/search/visible
  /// 按菜单可见性搜索权限配置。
  ///
  /// [isVisible] 是否为可见权限或菜单项。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 50。
  ///
  /// 返回 [PermissionManagement] 列表；调用方需要具备后端要求的权限管理角色。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 或后端角色校验失败时。
  ///
  /// 对应接口：GET /api/permissions/search/visible
  Future<List<PermissionManagement>> searchPermissionsByVisible({
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
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return PermissionManagement.listFromJson(data);
  }

  // HTTP: GET /api/permissions/search/external
  /// 按是否外部链接搜索权限配置。
  ///
  /// [isExternal] 是否为外部资源或外部菜单链接。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 50。
  ///
  /// 返回 [PermissionManagement] 列表；调用方需要具备后端要求的权限管理角色。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 或后端角色校验失败时。
  ///
  /// 对应接口：GET /api/permissions/search/external
  Future<List<PermissionManagement>> searchPermissionsByExternal({
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
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return PermissionManagement.listFromJson(data);
  }

  // HTTP: GET /api/permissions/search/status
  /// 按权限状态搜索权限配置。
  ///
  /// [status] 权限状态，例如启用、禁用等后端定义值。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 50。
  ///
  /// 返回 [PermissionManagement] 列表；调用方需要具备后端要求的权限管理角色。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 或后端角色校验失败时。
  ///
  /// 对应接口：GET /api/permissions/search/status
  Future<List<PermissionManagement>> searchPermissionsByStatus({
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
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return PermissionManagement.listFromJson(data);
  }
}
