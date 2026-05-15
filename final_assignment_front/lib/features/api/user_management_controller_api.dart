import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'dart:convert';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:final_assignment_front/features/model/user_response.dart';
import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

final ApiClient defaultApiClient = ApiClient();

class UserManagementControllerApi with BaseApiClient {
  @override
  final ApiClient apiClient;

  UserManagementControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  // åå§å?JWT
  /// 使用当前登录态初始化用户管理 API 客户端的 JWT。
  ///
  /// 调用用户管理接口前应先完成初始化，确保后续请求携带 bearer token。
  ///
  /// 抛出 [Exception]：当本地登录态无有效 JWT 时。
  Future<void> initializeWithJwt() async {
    final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null) {
      throw Exception('Not authenticated. Please log in again.');
    }
    apiClient.setJwtToken(jwtToken);
    AppLogger.debug('Initialized JWT: $jwtToken');
  }

  // è§£ç ååºä½?
  String _decodeBodyBytes(http.Response response) => decodeBodyBytes(response);

  // è·åè¯·æ±å¤?
  Future<Map<String, String>> _getHeaders({String? idempotencyKey}) async {
    return getHeaders(idempotencyKey: idempotencyKey);
  }

  List<UserManagement> _parseUserListResponse(http.Response response) {
    if (response.body.isEmpty) return [];
    return parseListResponse(response, UserResponse.fromJson)
        .map(UserManagement.fromUserResponse)
        .toList();
  }

  UserManagement? _parseUserResponse(http.Response response) {
    if (response.body.isEmpty) return null;
    final userResponse = parseNullableResponse(
      response,
      UserResponse.fromJson,
      nullStatusCodes: const {},
    );
    return userResponse == null
        ? null
        : UserManagement.fromUserResponse(userResponse);
  }

  List<Map<String, dynamic>> _parseMapListResponse(http.Response response) {
    if (response.body.isEmpty) return [];
    return parseListResponse<Map<String, dynamic>>(response, (json) => json);
  }

  Map<String, dynamic>? _parseMapResponse(http.Response response) {
    if (response.body.isEmpty) return null;
    return parseMapResponse(response);
  }

  List<String> _parseStringListResponse(http.Response response) {
    if (response.body.isEmpty) return [];
    ensureSuccess(response);
    final payload = unwrapPayload(decodeJsonBody(response));
    final list = switch (payload) {
      List<dynamic> value => value,
      Map<String, dynamic> value when value['content'] is List<dynamic> =>
        value['content'] as List<dynamic>,
      Map value when value['content'] is List<dynamic> =>
        value['content'] as List<dynamic>,
      _ => const <dynamic>[],
    };
    return list.map((item) => item.toString()).toList();
  }

// --- GET /api/users ---
  Future<http.Response> _listUsersWithHttpInfo() async {
    final path = "/api/users".replaceAll("{format}", "json");
    final headerParams = await _getHeaders();

    return await apiClient.invokeAPI(
      path,
      'GET',
      [],
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
  }

  /// 获取用户列表。
  ///
  /// 返回 [UserManagement] 列表；后端返回空响应时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/users
  Future<PageResult<UserResponse>> listUsersPage() async {
    try {
      final response = await _listUsersWithHttpInfo();
      AppLogger.debug('Users get response status: ${response.statusCode}');
      AppLogger.debug('Users get response body: ${response.body}');

      if (response.body.isNotEmpty) {
        return unwrapPageResponse(
          jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>,
          UserResponse.fromJson,
        );
      } else {
        return const PageResult<UserResponse>(
          content: [],
          total: 0,
          page: 0,
          size: 20,
        );
      }
    } catch (e) {
      AppLogger.error('Users get error: $e');
      rethrow;
    }
  }

  Future<List<UserManagement>> listUsers() async {
    final result = await listUsersPage();
    return result.content.map(UserManagement.fromUserResponse).toList();
  }

  // removed: /api/users/me (not provided by backend controllers)

  // --- POST /api/users ---
  Future<http.Response> _createUserWithHttpInfo({
    required UserManagement userManagement,
    required String idempotencyKey,
  }) async {
    if (idempotencyKey.isEmpty) {
      throw AppException.http(400, "Missing required param: idempotencyKey");
    }

    final path = "/api/users".replaceAll("{format}", "json");
    final queryParams = <QueryParam>[];
    final headerParams = await _getHeaders(idempotencyKey: idempotencyKey);

    return await apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      userManagement.toUserRequestJson(),
      headerParams,
      {},
      'application/json',
      ['bearerAuth'],
    );
  }

  /// 创建用户。
  ///
  /// [userManagement] 待创建的用户数据。
  /// [idempotencyKey] 幂等键，用于防止重复提交。
  ///
  /// 返回后端创建后的 [UserManagement]；201 且空响应时返回 `null`。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 或响应体异常时。
  ///
  /// 对应接口：POST /api/users
  Future<UserManagement?> createUser({
    required UserManagement userManagement,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _createUserWithHttpInfo(
        userManagement: userManagement,
        idempotencyKey: idempotencyKey,
      );
      AppLogger.debug('Users post response status: ${response.statusCode}');
      AppLogger.debug('Users post response body: ${response.body}');

      if (response.body.isNotEmpty) {
        final userResponse = unwrapApiResponse(
          jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>,
          (data) => UserResponse.fromJson(data as Map<String, dynamic>),
        );
        return UserManagement.fromUserResponse(userResponse);
      } else if (response.statusCode == 201) {
        return null; // 201 CREATEDï¼æ ååºä½?
      } else {
        throw AppException.http(response.statusCode, 'Empty response body');
      }
    } catch (e) {
      AppLogger.error('Users post error: $e');
      rethrow;
    }
  }

  // --- GET /api/users/search/status?status=&page=&size= ---
  Future<http.Response> _searchUsersByStatusWithHttpInfo({
    required String status,
    int page = 1,
    int size = 20,
  }) async {
    if (status.isEmpty) {
      throw AppException.http(400, "Missing required param: status");
    }
    final path = "/api/users/search/status".replaceAll("{format}", "json");
    final headerParams = await _getHeaders();
    final queryParams = [
      QueryParam("status", status),
      QueryParam("page", page.toString()),
      QueryParam("size", size.toString()),
    ];
    return await apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
  }

  // --- GET /api/users/search/department?department=&page=&size= ---
  Future<http.Response> _searchUsersByDepartmentWithHttpInfo({
    required String department,
    int page = 1,
    int size = 20,
  }) async {
    if (department.isEmpty) {
      throw AppException.http(400, "Missing required param: department");
    }
    final path = "/api/users/search/department".replaceAll("{format}", "json");
    final headerParams = await _getHeaders();
    final queryParams = [
      QueryParam("department", department),
      QueryParam("page", page.toString()),
      QueryParam("size", size.toString()),
    ];
    return await apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
  }

  /// 按部门精确搜索用户。
  ///
  /// [department] 部门名称或编码。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [UserManagement] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 [department] 为空或 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/users/search/department
  Future<List<UserManagement>> searchUsersByDepartment({
    required String department,
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await _searchUsersByDepartmentWithHttpInfo(
          department: department, page: page, size: size);
      AppLogger.debug(
          'Users search department response status: ${response.statusCode}');
      AppLogger.debug(
          'Users search department response body: ${response.body}');

      return _parseUserListResponse(response);
    } catch (e) {
      AppLogger.error('Users search department error: $e');
      rethrow;
    }
  }

  // --- GET /api/users/search/username/prefix?username=&page=&size= ---
  /// 按用户名前缀搜索用户。
  ///
  /// [username] 用户名前缀。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [UserManagement] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/users/search/username/prefix
  Future<List<UserManagement>> searchUsersByUsernamePrefix({
    required String username,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/users/search/username/prefix',
      'GET',
      [
        QueryParam('username', username),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    return _parseUserListResponse(response);
  }

  // --- GET /api/users/search/username/fuzzy?username=&page=&size= ---
  /// 按用户名模糊搜索用户。
  ///
  /// [username] 用户名关键字，模糊匹配规则由后端定义。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [UserManagement] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/users/search/username/fuzzy
  Future<List<UserManagement>> searchUsersByUsernameFuzzy({
    required String username,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/users/search/username/fuzzy',
      'GET',
      [
        QueryParam('username', username),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    return _parseUserListResponse(response);
  }

  // --- GET /api/users/search/real-name/prefix?realName=&page=&size= ---
  /// 按真实姓名前缀搜索用户。
  ///
  /// [realName] 真实姓名前缀。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [UserManagement] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/users/search/real-name/prefix
  Future<List<UserManagement>> searchUsersByRealNamePrefix({
    required String realName,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/users/search/real-name/prefix',
      'GET',
      [
        QueryParam('realName', realName),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    return _parseUserListResponse(response);
  }

  // --- GET /api/users/search/real-name/fuzzy?realName=&page=&size= ---
  /// 按真实姓名模糊搜索用户。
  ///
  /// [realName] 真实姓名关键字，模糊匹配规则由后端定义。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [UserManagement] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/users/search/real-name/fuzzy
  Future<List<UserManagement>> searchUsersByRealNameFuzzy({
    required String realName,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/users/search/real-name/fuzzy',
      'GET',
      [
        QueryParam('realName', realName),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    return _parseUserListResponse(response);
  }

  // --- GET /api/users/search/id-card?idCardNumber=&page=&size= ---
  /// 按身份证号搜索用户。
  ///
  /// [idCardNumber] 身份证号查询值。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [UserManagement] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/users/search/id-card
  Future<List<UserManagement>> searchUsersByIdCard({
    required String idCardNumber,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/users/search/id-card',
      'GET',
      [
        QueryParam('idCardNumber', idCardNumber),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    return _parseUserListResponse(response);
  }

  // --- GET /api/users/search/contact?contactNumber=&page=&size= ---
  /// 按联系方式搜索用户。
  ///
  /// [contactNumber] 手机号或联系方式查询值。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [UserManagement] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/users/search/contact
  Future<List<UserManagement>> searchUsersByContact({
    required String contactNumber,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/users/search/contact',
      'GET',
      [
        QueryParam('contactNumber', contactNumber),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    return _parseUserListResponse(response);
  }

  // --- POST /api/users/{userId}/roles --- bind user role
  Future<http.Response> _bindUserRoleWithHttpInfo({
    required int userId,
    required Map<String, dynamic> body, // expects SysUserRoleModel.toJson()
    required String idempotencyKey,
  }) async {
    if (idempotencyKey.isEmpty) {
      throw AppException.http(400, "Missing required param: idempotencyKey");
    }
    final path = "/api/users/$userId/roles".replaceAll("{format}", "json");
    final headerParams = await _getHeaders(idempotencyKey: idempotencyKey);
    final queryParams = <QueryParam>[];
    return await apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      body,
      headerParams,
      {},
      'application/json',
      ['bearerAuth'],
    );
  }

  /// 为用户绑定角色。
  ///
  /// [userId] 用户主键。
  /// [body] 用户-角色关系请求体，通常为 SysUserRoleModel 的 JSON。
  /// [idempotencyKey] 幂等键，用于防止重复绑定。
  ///
  /// 该方法建立用户与角色的授权关系，决定用户可访问的菜单、接口和业务权限。
  ///
  /// 返回后端返回的绑定关系 Map；后端空响应时返回 `null`。
  ///
  /// 抛出 [AppException]：当 [idempotencyKey] 为空或 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：POST /api/users/{userId}/roles
  Future<Map<String, dynamic>?> bindUserRole({
    required int userId,
    required Map<String, dynamic> body,
    required String idempotencyKey,
  }) async {
    final response = await _bindUserRoleWithHttpInfo(
      userId: userId,
      body: body,
      idempotencyKey: idempotencyKey,
    );
    return _parseMapResponse(response);
  }

  // --- DELETE /api/users/roles/{relationId} ---
  /// 删除用户-角色绑定关系。
  ///
  /// [relationId] 用户角色关系主键。
  ///
  /// 删除成功时无返回值；该操作会撤销用户通过该绑定获得的对应角色权限。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：DELETE /api/users/roles/{relationId}
  Future<void> deleteUserRoleBinding({required int relationId}) async {
    final path = "/api/users/roles/$relationId".replaceAll("{format}", "json");
    final headerParams = await _getHeaders();
    await apiClient.invokeAPI(
      path,
      'DELETE',
      [],
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
  }

  // --- GET /api/users/{userId}/roles?page=&size= ---
  /// 查询指定用户已绑定的角色关系。
  ///
  /// [userId] 用户主键。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回用户角色绑定关系 Map 列表；无数据时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/users/{userId}/roles
  Future<List<Map<String, dynamic>>> listUserRoles({
    required int userId,
    int page = 1,
    int size = 20,
  }) async {
    final path = "/api/users/$userId/roles".replaceAll("{format}", "json");
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'GET',
      [QueryParam("page", "$page"), QueryParam("size", "$size")],
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
    return _parseMapListResponse(response);
  }

  // --- PUT /api/users/role-bindings/{relationId} ---
  /// 更新用户-角色绑定关系。
  ///
  /// [relationId] 用户角色关系主键。
  /// [body] 更新后的绑定关系请求体。
  /// [idempotencyKey] 幂等键，用于防止重复提交。
  ///
  /// 返回后端返回的绑定关系 Map；后端空响应时返回 `null`。
  ///
  /// 抛出 [AppException]：当 [idempotencyKey] 为空或 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：PUT /api/users/role-bindings/{relationId}
  Future<Map<String, dynamic>?> updateUserRoleBinding({
    required int relationId,
    required Map<String, dynamic> body,
    required String idempotencyKey,
  }) async {
    if (idempotencyKey.isEmpty) {
      throw AppException.http(400, "Missing required param: idempotencyKey");
    }
    final path =
        "/api/users/role-bindings/$relationId".replaceAll("{format}", "json");
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'PUT',
      const [],
      body,
      headerParams,
      {},
      'application/json',
      ['bearerAuth'],
    );
    return _parseMapResponse(response);
  }

  // --- GET /api/users/role-bindings/{relationId} ---
  /// 获取单条用户-角色绑定关系。
  ///
  /// [relationId] 用户角色关系主键。
  ///
  /// 返回绑定关系 Map；后端空响应时返回 `null`。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/users/role-bindings/{relationId}
  Future<Map<String, dynamic>?> getUserRoleBinding({
    required int relationId,
  }) async {
    final path =
        "/api/users/role-bindings/$relationId".replaceAll("{format}", "json");
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'GET',
      [],
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
    return _parseMapResponse(response);
  }

  // --- GET /api/users/role-bindings?page=&size= ---
  /// 分页获取用户-角色绑定关系列表。
  ///
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回绑定关系 Map 列表；无数据时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/users/role-bindings
  Future<List<Map<String, dynamic>>> listUserRoleBindings({
    int page = 1,
    int size = 20,
  }) async {
    final path = "/api/users/role-bindings".replaceAll("{format}", "json");
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'GET',
      [QueryParam("page", "$page"), QueryParam("size", "$size")],
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
    return _parseMapListResponse(response);
  }

  // --- GET /api/users/role-bindings/by-role/{roleId}?page=&size= ---
  /// 按角色 ID 查询用户-角色绑定关系列表。
  ///
  /// [roleId] 角色主键。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回绑定了该角色的关系 Map 列表；无数据时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/users/role-bindings/by-role/{roleId}
  Future<List<Map<String, dynamic>>> listUserRoleBindingsByRole({
    required int roleId,
    int page = 1,
    int size = 20,
  }) async {
    final path = "/api/users/role-bindings/by-role/$roleId"
        .replaceAll("{format}", "json");
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'GET',
      [QueryParam("page", "$page"), QueryParam("size", "$size")],
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
    return _parseMapListResponse(response);
  }

  // --- GET /api/users/search/department/prefix?department=&page=&size= ---
  /// 按部门前缀搜索用户。
  ///
  /// [department] 部门名称或编码前缀。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [UserManagement] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/users/search/department/prefix
  Future<List<UserManagement>> searchUsersByDepartmentPrefix({
    required String department,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/users/search/department/prefix',
      'GET',
      [
        QueryParam('department', department),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    return _parseUserListResponse(response);
  }

  // --- GET /api/users/search/employee-number?employeeNumber=&page=&size= ---
  /// 按员工编号搜索用户。
  ///
  /// [employeeNumber] 员工编号查询值。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [UserManagement] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/users/search/employee-number
  Future<List<UserManagement>> searchUsersByEmployeeNumber({
    required String employeeNumber,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/users/search/employee-number',
      'GET',
      [
        QueryParam('employeeNumber', employeeNumber),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    return _parseUserListResponse(response);
  }

  // --- GET /api/users/search/last-login-range?startTime=&endTime=&page=&size= ---
  /// 按最后登录时间范围搜索用户。
  ///
  /// [startTime] 查询开始时间。
  /// [endTime] 查询结束时间。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [UserManagement] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/users/search/last-login-range
  Future<List<UserManagement>> searchUsersByLastLoginRange({
    required String startTime,
    required String endTime,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/users/search/last-login-range',
      'GET',
      [
        QueryParam('startTime', startTime),
        QueryParam('endTime', endTime),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    return _parseUserListResponse(response);
  }

  // --- GET /api/users/role-bindings/search?userId=&roleId=&page=&size= ---
  /// 按用户 ID 和角色 ID 搜索用户-角色绑定关系。
  ///
  /// [userId] 用户主键。
  /// [roleId] 角色主键。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回匹配的绑定关系 Map 列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/users/role-bindings/search
  Future<List<Map<String, dynamic>>> searchUserRoleBindings({
    required int userId,
    required int roleId,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/users/role-bindings/search',
      'GET',
      [
        QueryParam('userId', '$userId'),
        QueryParam('roleId', '$roleId'),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      {},
      null,
      ['bearerAuth'],
    );
    return _parseMapListResponse(response);
  }

  /// 按用户状态搜索用户。
  ///
  /// [status] 用户状态，例如启用、禁用等后端定义值。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [UserManagement] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 [status] 为空或 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/users/search/status
  Future<List<UserManagement>> searchUsersByStatus({
    required String status,
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await _searchUsersByStatusWithHttpInfo(
          status: status, page: page, size: size);
      AppLogger.debug(
          'Users search status response status: ${response.statusCode}');
      AppLogger.debug('Users search status response body: ${response.body}');

      return _parseUserListResponse(response);
    } catch (e) {
      AppLogger.error('Users search status error: $e');
      rethrow;
    }
  }

  // removed: /api/users/type/{userType} (not provided by backend controllers)

  // --- DELETE /api/users/{userId} ---
  Future<http.Response> _deleteUserWithHttpInfo({
    required String userId,
  }) async {
    if (userId.isEmpty) {
      throw AppException.http(400, "Missing required param: userId");
    }

    final path = "/api/users/$userId".replaceAll("{format}", "json");
    final headerParams = await _getHeaders();

    return await apiClient.invokeAPI(
      path,
      'DELETE',
      [],
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
  }

  /// 根据用户 ID 删除用户。
  ///
  /// [userId] 用户主键，不能为空。
  ///
  /// 删除成功时无返回值。
  ///
  /// 抛出 [AppException]：当 [userId] 为空或 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：DELETE /api/users/{userId}
  Future<void> deleteUser({
    required String userId,
  }) async {
    try {
      final response = await _deleteUserWithHttpInfo(userId: userId);
      AppLogger.debug('Users delete response status: ${response.statusCode}');
      AppLogger.debug('Users delete response body: ${response.body}');
    } catch (e) {
      AppLogger.error('Users delete error: $e');
      rethrow;
    }
  }

  // --- GET /api/users/{userId} ---
  Future<http.Response> _getUserWithHttpInfo({
    required String userId,
  }) async {
    if (userId.isEmpty) {
      throw AppException.http(400, "Missing required param: userId");
    }

    final path = "/api/users/$userId".replaceAll("{format}", "json");
    final headerParams = await _getHeaders();

    return await apiClient.invokeAPI(
      path,
      'GET',
      [],
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
  }

  /// 根据用户 ID 获取用户信息。
  ///
  /// [userId] 用户主键，不能为空。
  ///
  /// 返回 [UserManagement]；后端返回空响应时返回 `null`。
  ///
  /// 抛出 [AppException]：当 [userId] 为空或 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/users/{userId}
  Future<UserManagement?> getUser({
    required String userId,
  }) async {
    try {
      final response = await _getUserWithHttpInfo(userId: userId);
      AppLogger.debug(
          'Users userId get response status: ${response.statusCode}');
      AppLogger.debug('Users userId get response body: ${response.body}');

      return _parseUserResponse(response);
    } catch (e) {
      AppLogger.error('Users userId get error: $e');
      rethrow;
    }
  }

  // --- PUT /api/users/{userId} ---
  Future<http.Response> _updateUserWithHttpInfo({
    required String userId,
    required UserManagement userManagement,
    required String idempotencyKey,
  }) async {
    if (userId.isEmpty) {
      throw AppException.http(400, "Missing required param: userId");
    }
    if (idempotencyKey.isEmpty) {
      throw AppException.http(400, "Missing required param: idempotencyKey");
    }

    final path = "/api/users/$userId".replaceAll("{format}", "json");
    final queryParams = <QueryParam>[];
    final headerParams = await _getHeaders(idempotencyKey: idempotencyKey);

    return await apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      userManagement.toUserRequestJson(),
      headerParams,
      {},
      'application/json',
      ['bearerAuth'],
    );
  }

  /// 更新用户信息。
  ///
  /// [userId] 待更新的用户主键，不能为空。
  /// [userManagement] 更新后的用户数据。
  /// [idempotencyKey] 幂等键，用于防止重复提交。
  ///
  /// 更新成功时无返回值。
  ///
  /// 抛出 [AppException]：当 [userId] 或 [idempotencyKey] 为空，或 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：PUT /api/users/{userId}
  Future<void> updateUser({
    required String userId,
    required UserManagement userManagement,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _updateUserWithHttpInfo(
        userId: userId,
        userManagement: userManagement,
        idempotencyKey: idempotencyKey,
      );
      AppLogger.debug(
          'Users userId put response status: ${response.statusCode}');
      AppLogger.debug('Users userId put response body: ${response.body}');
    } catch (e) {
      AppLogger.error('Users userId put error: $e');
      rethrow;
    }
  }

  // --- DELETE /api/users/username/{username} ---
  // ignore: unused_element
  Future<http.Response> _deleteUserByUsernameWithHttpInfo({
    required String username,
  }) async {
    if (username.isEmpty) {
      throw AppException.http(400, "Missing required param: username");
    }

    // removed endpoint
    throw AppException.http(
        410, "Endpoint removed: DELETE /api/users/username/{username}");
  }

  /// 按用户名删除用户。
  ///
  /// [username] 用户名，不能为空。
  ///
  /// 当前后端已移除该 REST 接口，调用会抛出 410 [AppException]。
  ///
  /// 对应接口：DELETE /api/users/username/{username}
  Future<void> deleteUserByUsername({
    required String username,
  }) async {
    // removed endpoint
    throw AppException.http(
        410, "Endpoint removed: DELETE /api/users/username/{username}");
  }

  // --- GET /api/users/username/{username} ---
  // ignore: unused_element
  Future<http.Response> _getUserByUsernameWithHttpInfo({
    required String username,
  }) async {
    if (username.isEmpty) {
      throw AppException.http(400, "Missing required param: username");
    }

    // replaced by /api/users/search/username/{username}
    return await _searchUsersByUsernameWithHttpInfo(username: username);
  }

  /// 按用户名获取用户信息。
  ///
  /// [username] 用户名，不能为空。
  ///
  /// 当前实现委托 [searchUsersByUsername]，使用新版搜索接口获取单个用户。
  ///
  /// 返回 [UserManagement]；后端返回空响应时返回 `null`。
  ///
  /// 抛出 [AppException]：当 [username] 为空或 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/users/search/username/{username}
  Future<UserManagement?> getUserByUsername({
    required String username,
  }) async {
    return await searchUsersByUsername(username: username);
  }

  // --- GET /api/users/search/username/{username} ---
  Future<http.Response> _searchUsersByUsernameWithHttpInfo({
    required String username,
  }) async {
    if (username.isEmpty) {
      throw AppException.http(400, "Missing required param: username");
    }
    final path = "/api/users/search/username/${Uri.encodeComponent(username)}"
        .replaceAll("{format}", "json");
    final headerParams = await _getHeaders();
    return await apiClient.invokeAPI(
      path,
      'GET',
      [],
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
  }

  /// 按用户名精确搜索用户。
  ///
  /// [username] 用户名，不能为空。
  ///
  /// 返回 [UserManagement]；后端返回空响应时返回 `null`。
  ///
  /// 抛出 [AppException]：当 [username] 为空或 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/users/search/username/{username}
  Future<UserManagement?> searchUsersByUsername({
    required String username,
  }) async {
    try {
      final response =
          await _searchUsersByUsernameWithHttpInfo(username: username);
      AppLogger.debug(
          'Users search username response status: ${response.statusCode}');
      AppLogger.debug('Users search username response body: ${response.body}');

      return _parseUserResponse(response);
    } catch (e) {
      AppLogger.error('Users search username error: $e');
      rethrow;
    }
  }

  // --- GET /api/users/autocomplete/usernames ---
  Future<http.Response> _autocompleteUsernamesWithHttpInfo({
    required String prefix,
  }) async {
    if (prefix.isEmpty) {
      throw AppException.http(400, "Missing required param: prefix");
    }

    final path =
        "/api/users/autocomplete/usernames".replaceAll("{format}", "json");
    final queryParams = [QueryParam("prefix", prefix)];
    final headerParams = await _getHeaders();

    return await apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
  }

  /// 获取用户名自动补全候选项。
  ///
  /// [prefix] 用户名前缀，不能为空。
  ///
  /// 返回用户名字符串列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 [prefix] 为空或 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/users/autocomplete/usernames
  Future<List<String>> autocompleteUsernames({
    required String prefix,
  }) async {
    try {
      final response = await _autocompleteUsernamesWithHttpInfo(prefix: prefix);
      AppLogger.debug(
          'Users autocomplete usernames response status: ${response.statusCode}');
      AppLogger.debug(
          'Users autocomplete usernames response body: ${response.body}');

      return _parseStringListResponse(response);
    } catch (e) {
      AppLogger.error('Users autocomplete usernames error: $e');
      rethrow;
    }
  }

  // --- GET /api/users/autocomplete/statuses ---
  // ignore: unused_element
  Future<http.Response> _autocompleteUserStatusesWithHttpInfo({
    required String prefix,
  }) async {
    throw AppException.http(
        410, "Endpoint removed: /api/users/autocomplete/statuses");
  }

  /// 获取用户状态自动补全候选项。
  ///
  /// [prefix] 状态前缀。
  ///
  /// 当前后端已移除该接口，调用会抛出 410 [AppException]。
  ///
  /// 对应接口：GET /api/users/autocomplete/statuses
  Future<List<String>> autocompleteUserStatuses({
    required String prefix,
  }) async {
    throw AppException.http(
        410, "Endpoint removed: /api/users/autocomplete/statuses");
  }

  // --- GET /api/users/autocomplete/phone-numbers ---
  // ignore: unused_element
  Future<http.Response> _autocompleteUserPhoneNumbersWithHttpInfo({
    required String prefix,
  }) async {
    throw AppException.http(
        410, "Endpoint removed: /api/users/autocomplete/phone-numbers");
  }

  /// 获取用户手机号自动补全候选项。
  ///
  /// [prefix] 手机号前缀。
  ///
  /// 当前后端已移除该接口，调用会抛出 410 [AppException]。
  ///
  /// 对应接口：GET /api/users/autocomplete/phone-numbers
  Future<List<String>> autocompleteUserPhoneNumbers({
    required String prefix,
  }) async {
    throw AppException.http(
        410, "Endpoint removed: /api/users/autocomplete/phone-numbers");
  }

  // --- WebSocket Methods ---

  // getAllUsers (WebSocket)
  /// @realtimeApi
  /// 通过 WebSocket eventbus 获取用户列表。
  ///
  /// 返回 [UserManagement] 列表；eventbus result 非列表时返回 `null`。
  ///
  /// 抛出 [AppException]：当 WebSocket 响应包含 `error` 字段时。
  ///
  /// 对应实时动作：UserManagementService.getAllUsers
  Future<List<UserManagement>?> eventbusUsersGet() async {
    final msg = {
      "service": "AuthWsService",
      "action": "getAllUsers",
      "args": [],
    };
    try {
      final respMap = await apiClient.sendWsMessage(msg);
      AppLogger.debug('WebSocket users get response: $respMap');

      if (respMap.containsKey("error")) {
        throw AppException.http(400, respMap["error"]);
      }
      if (respMap.containsKey("result") && respMap["result"] is List) {
        return (respMap["result"] as List)
            .map((json) => UserManagement.fromJson(json))
            .toList();
      }
      return null;
    } catch (e) {
      AppLogger.error('WebSocket users get error: $e');
      rethrow;
    }
  }

  Future<UserManagement?> _getCurrentUserViaEventbus({
    required String username,
  }) async {
    final msg = {
      "service": "UserManagementService",
      "action": "getCurrentUser",
      "args": [username],
    };
    try {
      final respMap = await apiClient.sendWsMessage(msg);
      AppLogger.debug('WebSocket users me get response: $respMap');

      if (respMap.containsKey("error")) {
        throw AppException.http(400, respMap["error"]);
      }
      if (respMap.containsKey("result") && respMap["result"] != null) {
        return UserManagement.fromJson(respMap["result"]);
      }
      return null;
    } catch (e) {
      AppLogger.error('WebSocket users me get error: $e');
      rethrow;
    }
  }

  /// @realtimeApi
  /// 通过 eventbus 获取当前用户信息。
  ///
  /// [username] 当前登录用户名。
  ///
  /// 返回 [UserManagement]；未找到当前用户时抛出 404 [AppException]。
  ///
  /// 抛出 [AppException]：当 WebSocket 响应包含 `error` 字段或用户不存在时。
  ///
  /// 对应实时动作：UserManagementService.getCurrentUser
  Future<UserManagement> getCurrentUser({
    required String username,
  }) async {
    final user = await _getCurrentUserViaEventbus(username: username);
    if (user == null) {
      throw AppException.http(404, "Current user not found");
    }
    return user;
  }

  // updateCurrentUser (WebSocket)
  /// @realtimeApi
  /// 通过 WebSocket eventbus 更新当前用户信息。
  ///
  /// [username] 当前登录用户名。
  /// [userManagement] 更新后的用户数据。
  /// [idempotencyKey] 幂等键，用于防止重复提交。
  ///
  /// 更新成功时无返回值。
  ///
  /// 抛出 [AppException]：当 WebSocket 响应包含 `error` 字段时。
  ///
  /// 对应实时动作：UserManagementService.updateCurrentUser
  Future<void> eventbusUsersMePut({
    required String username,
    required UserManagement userManagement,
    required String idempotencyKey,
  }) async {
    final msg = {
      "service": "SysUserService",
      "action": "checkAndInsertIdempotency",
      "args": [idempotencyKey, userManagement.toUserRequestJson(), "update"],
    };
    try {
      final respMap = await apiClient.sendWsMessage(msg);
      AppLogger.debug('WebSocket users me put response: $respMap');

      if (respMap.containsKey("error")) {
        throw AppException.http(400, respMap["error"]);
      }
    } catch (e) {
      AppLogger.error('WebSocket users me put error: $e');
      rethrow;
    }
  }

  // createUser (WebSocket)
  /// @realtimeApi
  /// 通过 WebSocket eventbus 创建用户。
  ///
  /// [userManagement] 待创建的用户数据。
  /// [idempotencyKey] 幂等键，用于防止重复提交。
  ///
  /// 返回创建后的 [UserManagement]；eventbus result 为空时返回 `null`。
  ///
  /// 抛出 [AppException]：当 WebSocket 响应包含 `error` 字段时。
  ///
  /// 对应实时动作：UserManagementService.createUser
  Future<UserManagement?> eventbusUsersPost({
    required UserManagement userManagement,
    required String idempotencyKey,
  }) async {
    final msg = {
      "service": "SysUserService",
      "action": "checkAndInsertIdempotency",
      "args": [idempotencyKey, userManagement.toUserRequestJson(), "create"],
    };
    try {
      final respMap = await apiClient.sendWsMessage(msg);
      AppLogger.debug('WebSocket users post response: $respMap');

      if (respMap.containsKey("error")) {
        throw AppException.http(400, respMap["error"]);
      }
      if (respMap.containsKey("result") && respMap["result"] != null) {
        return UserManagement.fromJson(respMap["result"]);
      }
      return null;
    } catch (e) {
      AppLogger.error('WebSocket users post error: $e');
      rethrow;
    }
  }

  // getUsersByStatus (WebSocket)
  /// @realtimeApi
  /// 通过 WebSocket eventbus 按用户状态获取用户列表。
  ///
  /// [status] 用户状态。
  ///
  /// 返回 [UserManagement] 列表；eventbus result 非列表时返回 `null`。
  ///
  /// 抛出 [AppException]：当 WebSocket 响应包含 `error` 字段时。
  ///
  /// 对应实时动作：UserManagementService.getUsersByStatus
  Future<List<UserManagement>?> eventbusUsersStatusStatusGet({
    required String status,
  }) async {
    final msg = {
      "service": "UserManagementService",
      "action": "getUsersByStatus",
      "args": [status],
    };
    try {
      final respMap = await apiClient.sendWsMessage(msg);
      AppLogger.debug('WebSocket users status get response: $respMap');

      if (respMap.containsKey("error")) {
        throw AppException.http(400, respMap["error"]);
      }
      if (respMap.containsKey("result") && respMap["result"] is List) {
        return (respMap["result"] as List)
            .map((json) => UserManagement.fromJson(json))
            .toList();
      }
      return null;
    } catch (e) {
      AppLogger.error('WebSocket users status get error: $e');
      rethrow;
    }
  }

  // getUsersByType (WebSocket)
  /// @realtimeApi
  /// 通过 WebSocket eventbus 按用户类型获取用户列表。
  ///
  /// [userType] 用户类型。
  ///
  /// 返回 [UserManagement] 列表；eventbus result 非列表时返回 `null`。
  ///
  /// 抛出 [AppException]：当 WebSocket 响应包含 `error` 字段时。
  ///
  /// 对应实时动作：UserManagementService.getUsersByType
  Future<List<UserManagement>?> eventbusUsersTypeUserTypeGet({
    required String userType,
  }) async {
    final msg = {
      "service": "UserManagementService",
      "action": "getUsersByType",
      "args": [userType],
    };
    try {
      final respMap = await apiClient.sendWsMessage(msg);
      AppLogger.debug('WebSocket users type get response: $respMap');

      if (respMap.containsKey("error")) {
        throw AppException.http(400, respMap["error"]);
      }
      if (respMap.containsKey("result") && respMap["result"] is List) {
        return (respMap["result"] as List)
            .map((json) => UserManagement.fromJson(json))
            .toList();
      }
      return null;
    } catch (e) {
      AppLogger.error('WebSocket users type get error: $e');
      rethrow;
    }
  }

  // deleteUser (WebSocket)
  /// @realtimeApi
  /// 通过 WebSocket eventbus 按用户 ID 删除用户。
  ///
  /// [userId] 用户主键。
  ///
  /// 删除成功时无返回值。
  ///
  /// 抛出 [AppException]：当 WebSocket 响应包含 `error` 字段时。
  ///
  /// 对应实时动作：UserManagementService.deleteUser
  Future<void> eventbusUsersUserIdDelete({required String userId}) async {
    final msg = {
      "service": "UserManagementService",
      "action": "deleteUser",
      "args": [userId],
    };
    try {
      final respMap = await apiClient.sendWsMessage(msg);
      AppLogger.debug('WebSocket users delete response: $respMap');

      if (respMap.containsKey("error")) {
        throw AppException.http(400, respMap["error"]);
      }
    } catch (e) {
      AppLogger.error('WebSocket users delete error: $e');
      rethrow;
    }
  }

  // getUserById (WebSocket)
  /// @realtimeApi
  /// 通过 WebSocket eventbus 按用户 ID 获取用户信息。
  ///
  /// [userId] 用户主键。
  ///
  /// 返回 [UserManagement]；eventbus result 为空时返回 `null`。
  ///
  /// 抛出 [AppException]：当 WebSocket 响应包含 `error` 字段时。
  ///
  /// 对应实时动作：UserManagementService.getUserById
  Future<UserManagement?> eventbusUsersUserIdGet({
    required String userId,
  }) async {
    final msg = {
      "service": "UserManagementService",
      "action": "getUserById",
      "args": [userId],
    };
    try {
      final respMap = await apiClient.sendWsMessage(msg);
      AppLogger.debug('WebSocket users userId get response: $respMap');

      if (respMap.containsKey("error")) {
        throw AppException.http(400, respMap["error"]);
      }
      if (respMap.containsKey("result") && respMap["result"] != null) {
        return UserManagement.fromJson(respMap["result"]);
      }
      return null;
    } catch (e) {
      AppLogger.error('WebSocket users userId get error: $e');
      rethrow;
    }
  }

  // updateUser (WebSocket)
  /// @realtimeApi
  /// 通过 WebSocket eventbus 更新用户信息。
  ///
  /// [userId] 待更新的用户主键。
  /// [userManagement] 更新后的用户数据。
  /// [idempotencyKey] 幂等键，用于防止重复提交。
  ///
  /// 更新成功时无返回值。
  ///
  /// 抛出 [AppException]：当 WebSocket 响应包含 `error` 字段时。
  ///
  /// 对应实时动作：UserManagementService.updateUser
  Future<void> eventbusUsersUserIdPut({
    required String userId,
    required UserManagement userManagement,
    required String idempotencyKey,
  }) async {
    final msg = {
      "service": "SysUserService",
      "action": "checkAndInsertIdempotency",
      "args": [idempotencyKey, userManagement.toUserRequestJson(), "update"],
    };
    try {
      final respMap = await apiClient.sendWsMessage(msg);
      AppLogger.debug('WebSocket users userId put response: $respMap');

      if (respMap.containsKey("error")) {
        throw AppException.http(400, respMap["error"]);
      }
    } catch (e) {
      AppLogger.error('WebSocket users userId put error: $e');
      rethrow;
    }
  }

  // deleteUserByUsername (WebSocket)
  /// @realtimeApi
  /// 通过 WebSocket eventbus 按用户名删除用户。
  ///
  /// [username] 用户名。
  ///
  /// 删除成功时无返回值。
  ///
  /// 抛出 [AppException]：当 WebSocket 响应包含 `error` 字段时。
  ///
  /// 对应实时动作：UserManagementService.deleteUserByUsername
  Future<void> eventbusUsersUsernameUsernameDelete({
    required String username,
  }) async {
    final msg = {
      "service": "UserManagementService",
      "action": "deleteUserByUsername",
      "args": [username],
    };
    try {
      final respMap = await apiClient.sendWsMessage(msg);
      AppLogger.debug('WebSocket users username delete response: $respMap');

      if (respMap.containsKey("error")) {
        throw AppException.http(400, respMap["error"]);
      }
    } catch (e) {
      AppLogger.error('WebSocket users username delete error: $e');
      rethrow;
    }
  }

  // getUserByUsername (WebSocket)
  /// @realtimeApi
  /// 通过 WebSocket eventbus 按用户名获取用户信息。
  ///
  /// [username] 用户名。
  ///
  /// 返回 [UserManagement]；eventbus result 为空时返回 `null`。
  ///
  /// 抛出 [AppException]：当 WebSocket 响应包含 `error` 字段时。
  ///
  /// 对应实时动作：UserManagementService.getUserByUsername
  Future<UserManagement?> eventbusUsersUsernameUsernameGet({
    required String username,
  }) async {
    final msg = {
      "service": "UserManagementService",
      "action": "getUserByUsername",
      "args": [username],
    };
    try {
      final respMap = await apiClient.sendWsMessage(msg);
      AppLogger.debug('WebSocket users username get response: $respMap');

      if (respMap.containsKey("error")) {
        throw AppException.http(400, respMap["error"]);
      }
      if (respMap.containsKey("result") && respMap["result"] != null) {
        return UserManagement.fromJson(respMap["result"]);
      }
      return null;
    } catch (e) {
      AppLogger.error('WebSocket users username get error: $e');
      rethrow;
    }
  }

  // getUsernameAutocompleteSuggestionsGlobally (WebSocket)
  /// @realtimeApi
  /// 通过 WebSocket eventbus 获取全局用户名自动补全候选项。
  ///
  /// [prefix] 用户名前缀，不能为空。
  ///
  /// 返回用户名字符串列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 [prefix] 为空或 WebSocket 响应包含 `error` 字段时。
  ///
  /// 对应实时动作：UserManagementService.getUsernameAutocompleteSuggestionsGlobally
  Future<List<String>> eventbusUsersAutocompleteUsernamesGet({
    required String prefix,
  }) async {
    if (prefix.isEmpty) {
      throw AppException.http(400, "Missing required param: prefix");
    }
    final msg = {
      "service": "UserManagementService",
      "action": "getUsernameAutocompleteSuggestionsGlobally",
      "args": [prefix],
    };
    try {
      final respMap = await apiClient.sendWsMessage(msg);
      AppLogger.debug(
          'WebSocket users autocomplete usernames response: $respMap');

      if (respMap.containsKey("error")) {
        throw AppException.http(400, respMap["error"]);
      }
      if (respMap.containsKey("result") && respMap["result"] is List) {
        return (respMap["result"] as List).cast<String>();
      }
      return [];
    } catch (e) {
      AppLogger.error('WebSocket users autocomplete usernames error: $e');
      rethrow;
    }
  }

  // getStatusAutocompleteSuggestionsGlobally (WebSocket)
  /// @realtimeApi
  /// 通过 WebSocket eventbus 获取全局用户状态自动补全候选项。
  ///
  /// [prefix] 状态前缀，不能为空。
  ///
  /// 返回状态字符串列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 [prefix] 为空或 WebSocket 响应包含 `error` 字段时。
  ///
  /// 对应实时动作：UserManagementService.getStatusAutocompleteSuggestionsGlobally
  Future<List<String>> eventbusUsersAutocompleteStatusesGet({
    required String prefix,
  }) async {
    if (prefix.isEmpty) {
      throw AppException.http(400, "Missing required param: prefix");
    }
    final msg = {
      "service": "UserManagementService",
      "action": "getStatusAutocompleteSuggestionsGlobally",
      "args": [prefix],
    };
    try {
      final respMap = await apiClient.sendWsMessage(msg);
      AppLogger.debug(
          'WebSocket users autocomplete statuses response: $respMap');

      if (respMap.containsKey("error")) {
        throw AppException.http(400, respMap["error"]);
      }
      if (respMap.containsKey("result") && respMap["result"] is List) {
        return (respMap["result"] as List).cast<String>();
      }
      return [];
    } catch (e) {
      AppLogger.error('WebSocket users autocomplete statuses error: $e');
      rethrow;
    }
  }

  // getPhoneNumberAutocompleteSuggestionsGlobally (WebSocket)
  /// @realtimeApi
  /// 通过 WebSocket eventbus 获取全局手机号自动补全候选项。
  ///
  /// [prefix] 手机号前缀，不能为空。
  ///
  /// 返回手机号字符串列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 [prefix] 为空或 WebSocket 响应包含 `error` 字段时。
  ///
  /// 对应实时动作：UserManagementService.getPhoneNumberAutocompleteSuggestionsGlobally
  Future<List<String>> eventbusUsersAutocompletePhoneNumbersGet({
    required String prefix,
  }) async {
    if (prefix.isEmpty) {
      throw AppException.http(400, "Missing required param: prefix");
    }
    final msg = {
      "service": "UserManagementService",
      "action": "getPhoneNumberAutocompleteSuggestionsGlobally",
      "args": [prefix],
    };
    try {
      final respMap = await apiClient.sendWsMessage(msg);
      AppLogger.debug(
          'WebSocket users autocomplete phone-numbers response: $respMap');

      if (respMap.containsKey("error")) {
        throw AppException.http(400, respMap["error"]);
      }
      if (respMap.containsKey("result") && respMap["result"] is List) {
        return (respMap["result"] as List).cast<String>();
      }
      return [];
    } catch (e) {
      AppLogger.error('WebSocket users autocomplete phone-numbers error: $e');
      rethrow;
    }
  }
}
