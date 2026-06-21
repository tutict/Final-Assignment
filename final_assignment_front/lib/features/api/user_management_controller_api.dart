import 'dart:convert';

import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:final_assignment_front/features/model/user_response.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';

final ApiClient defaultApiClient = ApiClient();

class UserManagementControllerApi with BaseApiClient {
  @override
  final ApiClient apiClient;

  UserManagementControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  Future<void> initializeWithJwt() => initializeClientWithJwt();

  Future<PageResult<UserResponse>> listUsersPage() async {
    final response = await request('GET', '/api/users');
    ensureSuccess(response);
    if (decodeBodyBytes(response).trim().isEmpty) {
      return const PageResult<UserResponse>(
        content: [],
        total: 0,
        page: 0,
        size: 20,
      );
    }
    final decoded = unwrapPayload(jsonDecode(decodeBodyBytes(response)));
    if (decoded is List) {
      final users = decoded
          .map((item) => UserResponse.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList();
      return PageResult<UserResponse>(
        content: users,
        total: users.length,
        page: 1,
        size: users.length,
      );
    }
    if (decoded is Map) {
      final page = Map<String, dynamic>.from(decoded);
      final content = page['content'] ?? page['records'] ?? page['items'];
      if (content is List) {
        return PageResult<UserResponse>(
          content: content
              .map((item) => UserResponse.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ))
              .toList(),
          total: _toInt(page['total'] ?? page['totalElements']) ??
              content.length,
          page: _toInt(page['page'] ?? page['number']) ?? 1,
          size: _toInt(page['size'] ?? page['pageSize']) ?? content.length,
        );
      }
    }
    throw AppException.http(
      response.statusCode,
      'Expected users list response, got ${decoded.runtimeType}',
    );
  }

  Future<List<UserManagement>> listUsers() async {
    final result = await listUsersPage();
    return result.content.map(UserManagement.fromUserResponse).toList();
  }

  Future<UserManagement?> createUser({
    required UserManagement userManagement,
    required String idempotencyKey,
  }) async {
    requireNotBlank(idempotencyKey, 'idempotencyKey');
    final response = await request(
      'POST',
      '/api/users',
      body: userManagement.toUserRequestJson(),
      contentType: BaseApiClient.defaultContentType,
      idempotencyKey: idempotencyKey,
    );
    ensureSuccess(response);
    if (decodeBodyBytes(response).trim().isEmpty) {
      if (response.statusCode == 201) {
        return null;
      }
      throw AppException.http(response.statusCode, 'Empty response body');
    }
    final decoded = unwrapPayload(jsonDecode(decodeBodyBytes(response)));
    final payload = decoded is Map && decoded.containsKey('data')
        ? decoded['data']
        : decoded;
    final userResponse =
        UserResponse.fromJson(Map<String, dynamic>.from(payload as Map));
    return UserManagement.fromUserResponse(userResponse);
  }

  Future<List<UserManagement>> searchUsersByDepartment({
    required String department,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(department, 'department');
    return _requestUserList(
      '/api/users/search/department',
      {'department': department, 'page': page, 'size': size},
    );
  }

  Future<List<UserManagement>> searchUsersByUsernamePrefix({
    required String username,
    int page = 1,
    int size = 20,
  }) {
    return _requestUserList(
      '/api/users/search/username/prefix',
      {'username': username, 'page': page, 'size': size},
    );
  }

  Future<List<UserManagement>> searchUsersByUsernameFuzzy({
    required String username,
    int page = 1,
    int size = 20,
  }) {
    return _requestUserList(
      '/api/users/search/username/fuzzy',
      {'username': username, 'page': page, 'size': size},
    );
  }

  Future<List<UserManagement>> searchUsersByRealNamePrefix({
    required String realName,
    int page = 1,
    int size = 20,
  }) {
    return _requestUserList(
      '/api/users/search/real-name/prefix',
      {'realName': realName, 'page': page, 'size': size},
    );
  }

  Future<List<UserManagement>> searchUsersByRealNameFuzzy({
    required String realName,
    int page = 1,
    int size = 20,
  }) {
    return _requestUserList(
      '/api/users/search/real-name/fuzzy',
      {'realName': realName, 'page': page, 'size': size},
    );
  }

  Future<List<UserManagement>> searchUsersByIdCard({
    required String idCardNumber,
    int page = 1,
    int size = 20,
  }) {
    return _requestUserList(
      '/api/users/search/id-card',
      {'idCardNumber': idCardNumber, 'page': page, 'size': size},
    );
  }

  Future<List<UserManagement>> searchUsersByContact({
    required String contactNumber,
    int page = 1,
    int size = 20,
  }) {
    return _requestUserList(
      '/api/users/search/contact',
      {'contactNumber': contactNumber, 'page': page, 'size': size},
    );
  }

  Future<Map<String, dynamic>?> bindUserRole({
    required int userId,
    required Map<String, dynamic> body,
    required String idempotencyKey,
  }) {
    requireNotBlank(idempotencyKey, 'idempotencyKey');
    return _requestNullableMap(
      'POST',
      '/api/users/$userId/roles',
      body: body,
      contentType: BaseApiClient.defaultContentType,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<void> deleteUserRoleBinding({required int relationId}) {
    return requestVoid('DELETE', '/api/users/roles/$relationId');
  }

  Future<List<Map<String, dynamic>>> listUserRoles({
    required int userId,
    int page = 1,
    int size = 20,
  }) {
    return _requestMapList(
      '/api/users/$userId/roles',
      {'page': page, 'size': size},
    );
  }

  Future<Map<String, dynamic>?> updateUserRoleBinding({
    required int relationId,
    required Map<String, dynamic> body,
    required String idempotencyKey,
  }) {
    requireNotBlank(idempotencyKey, 'idempotencyKey');
    return _requestNullableMap(
      'PUT',
      '/api/users/role-bindings/$relationId',
      body: body,
      contentType: BaseApiClient.defaultContentType,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<Map<String, dynamic>?> getUserRoleBinding({
    required int relationId,
  }) {
    return _requestNullableMap(
      'GET',
      '/api/users/role-bindings/$relationId',
    );
  }

  Future<List<Map<String, dynamic>>> listUserRoleBindings({
    int page = 1,
    int size = 20,
  }) {
    return _requestMapList(
      '/api/users/role-bindings',
      {'page': page, 'size': size},
    );
  }

  Future<List<Map<String, dynamic>>> listUserRoleBindingsByRole({
    required int roleId,
    int page = 1,
    int size = 20,
  }) {
    return _requestMapList(
      '/api/users/role-bindings/by-role/$roleId',
      {'page': page, 'size': size},
    );
  }

  Future<List<UserManagement>> searchUsersByDepartmentPrefix({
    required String department,
    int page = 1,
    int size = 20,
  }) {
    return _requestUserList(
      '/api/users/search/department/prefix',
      {'department': department, 'page': page, 'size': size},
    );
  }

  Future<List<UserManagement>> searchUsersByEmployeeNumber({
    required String employeeNumber,
    int page = 1,
    int size = 20,
  }) {
    return _requestUserList(
      '/api/users/search/employee-number',
      {'employeeNumber': employeeNumber, 'page': page, 'size': size},
    );
  }

  Future<List<UserManagement>> searchUsersByLastLoginRange({
    required String startTime,
    required String endTime,
    int page = 1,
    int size = 20,
  }) {
    return _requestUserList(
      '/api/users/search/last-login-range',
      {'startTime': startTime, 'endTime': endTime, 'page': page, 'size': size},
    );
  }

  Future<List<Map<String, dynamic>>> searchUserRoleBindings({
    required int userId,
    required int roleId,
    int page = 1,
    int size = 20,
  }) {
    return _requestMapList(
      '/api/users/role-bindings/search',
      {'userId': userId, 'roleId': roleId, 'page': page, 'size': size},
    );
  }

  Future<List<UserManagement>> searchUsersByStatus({
    required String status,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(status, 'status');
    return _requestUserList(
      '/api/users/search/status',
      {'status': status, 'page': page, 'size': size},
    );
  }

  Future<void> deleteUser({required String userId}) {
    requireNotBlank(userId, 'userId');
    return requestVoid('DELETE', '/api/users/$userId');
  }

  Future<UserManagement?> getUser({required String userId}) {
    requireNotBlank(userId, 'userId');
    return _requestUser('/api/users/$userId');
  }

  Future<void> updateUser({
    required String userId,
    required UserManagement userManagement,
    required String idempotencyKey,
  }) {
    requireNotBlank(userId, 'userId');
    requireNotBlank(idempotencyKey, 'idempotencyKey');
    return requestVoid(
      'PUT',
      '/api/users/$userId',
      body: userManagement.toUserRequestJson(),
      contentType: BaseApiClient.defaultContentType,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<void> deleteUserByUsername({required String username}) async {
    throw AppException.http(
      410,
      'Endpoint removed: DELETE /api/users/username/{username}',
    );
  }

  Future<UserManagement?> getUserByUsername({required String username}) {
    return searchUsersByUsername(username: username);
  }

  Future<UserManagement?> searchUsersByUsername({
    required String username,
  }) {
    requireNotBlank(username, 'username');
    return _requestUser(
      '/api/users/search/username/${Uri.encodeComponent(username)}',
    );
  }

  Future<List<String>> autocompleteUsernames({required String prefix}) {
    requireNotBlank(prefix, 'prefix');
    return requestValueList<String>(
      'GET',
      '/api/users/autocomplete/usernames',
      (value) => value.toString(),
      queryParams: [QueryParam('prefix', prefix)],
    );
  }

  Future<List<String>> autocompleteUserStatuses({
    required String prefix,
  }) async {
    throw AppException.http(
      410,
      'Endpoint removed: /api/users/autocomplete/statuses',
    );
  }

  Future<List<String>> autocompleteUserPhoneNumbers({
    required String prefix,
  }) async {
    throw AppException.http(
      410,
      'Endpoint removed: /api/users/autocomplete/phone-numbers',
    );
  }

  Future<List<UserManagement>?> eventbusUsersGet() {
    return _sendUserListNullable(
      service: 'AuthWsService',
      action: 'getAllUsers',
    );
  }

  Future<UserManagement?> _getCurrentUserViaEventbus({
    required String username,
  }) {
    return _sendUserObject(
      service: 'UserManagementService',
      action: 'getCurrentUser',
      args: [username],
    );
  }

  Future<UserManagement> getCurrentUser({required String username}) async {
    final user = await _getCurrentUserViaEventbus(username: username);
    if (user == null) {
      throw AppException.http(404, 'Current user not found');
    }
    return user;
  }

  Future<void> eventbusUsersMePut({
    required String username,
    required UserManagement userManagement,
    required String idempotencyKey,
  }) {
    return _sendUserMutation(
      userManagement: userManagement,
      idempotencyKey: idempotencyKey,
      operation: 'update',
    );
  }

  Future<UserManagement?> eventbusUsersPost({
    required UserManagement userManagement,
    required String idempotencyKey,
  }) {
    return _sendUserObject(
      service: 'SysUserService',
      action: 'checkAndInsertIdempotency',
      args: [idempotencyKey, userManagement.toUserRequestJson(), 'create'],
    );
  }

  Future<List<UserManagement>?> eventbusUsersStatusStatusGet({
    required String status,
  }) {
    return _sendUserListNullable(
      service: 'UserManagementService',
      action: 'getUsersByStatus',
      args: [status],
    );
  }

  Future<List<UserManagement>?> eventbusUsersTypeUserTypeGet({
    required String userType,
  }) {
    return _sendUserListNullable(
      service: 'UserManagementService',
      action: 'getUsersByType',
      args: [userType],
    );
  }

  Future<void> eventbusUsersUserIdDelete({required String userId}) async {
    await sendWs(
      service: 'UserManagementService',
      action: 'deleteUser',
      args: [userId],
    );
  }

  Future<UserManagement?> eventbusUsersUserIdGet({
    required String userId,
  }) {
    return _sendUserObject(
      service: 'UserManagementService',
      action: 'getUserById',
      args: [userId],
    );
  }

  Future<void> eventbusUsersUserIdPut({
    required String userId,
    required UserManagement userManagement,
    required String idempotencyKey,
  }) {
    return _sendUserMutation(
      userManagement: userManagement,
      idempotencyKey: idempotencyKey,
      operation: 'update',
    );
  }

  Future<void> eventbusUsersUsernameUsernameDelete({
    required String username,
  }) async {
    await sendWs(
      service: 'UserManagementService',
      action: 'deleteUserByUsername',
      args: [username],
    );
  }

  Future<UserManagement?> eventbusUsersUsernameUsernameGet({
    required String username,
  }) {
    return _sendUserObject(
      service: 'UserManagementService',
      action: 'getUserByUsername',
      args: [username],
    );
  }

  Future<List<String>> eventbusUsersAutocompleteUsernamesGet({
    required String prefix,
  }) {
    requireNotBlank(prefix, 'prefix');
    return _sendStringList(
      service: 'UserManagementService',
      action: 'getUsernameAutocompleteSuggestionsGlobally',
      args: [prefix],
    );
  }

  Future<List<String>> eventbusUsersAutocompleteStatusesGet({
    required String prefix,
  }) {
    requireNotBlank(prefix, 'prefix');
    return _sendStringList(
      service: 'UserManagementService',
      action: 'getStatusAutocompleteSuggestionsGlobally',
      args: [prefix],
    );
  }

  Future<List<String>> eventbusUsersAutocompletePhoneNumbersGet({
    required String prefix,
  }) {
    requireNotBlank(prefix, 'prefix');
    return _sendStringList(
      service: 'UserManagementService',
      action: 'getPhoneNumberAutocompleteSuggestionsGlobally',
      args: [prefix],
    );
  }

  Future<List<UserManagement>> _requestUserList(
    String path,
    Map<String, Object?> params,
  ) async {
    final users = await requestList(
      'GET',
      path,
      UserResponse.fromJson,
      queryParams: queryParamsFromMap(params),
    );
    return users.map(UserManagement.fromUserResponse).toList();
  }

  Future<UserManagement?> _requestUser(String path) async {
    final userResponse = await requestNullableObject(
      'GET',
      path,
      UserResponse.fromJson,
    );
    return userResponse == null
        ? null
        : UserManagement.fromUserResponse(userResponse);
  }

  Future<List<Map<String, dynamic>>> _requestMapList(
    String path,
    Map<String, Object?> params,
  ) {
    return requestList<Map<String, dynamic>>(
      'GET',
      path,
      (json) => json,
      queryParams: queryParamsFromMap(params),
    );
  }

  Future<Map<String, dynamic>?> _requestNullableMap(
    String method,
    String path, {
    Object? body,
    String? contentType,
    String? idempotencyKey,
  }) async {
    final response = await request(
      method,
      path,
      body: body,
      contentType: contentType,
      idempotencyKey: idempotencyKey,
    );
    ensureSuccess(response);
    if (decodeBodyBytes(response).trim().isEmpty) {
      return null;
    }
    return parseMapResponse(response);
  }

  Future<UserManagement?> _sendUserObject({
    required String service,
    required String action,
    List<Object?> args = const [],
  }) async {
    final result = await sendWs(service: service, action: action, args: args);
    if (result == null) {
      return null;
    }
    return UserManagement.fromJson(Map<String, dynamic>.from(result as Map));
  }

  Future<List<UserManagement>?> _sendUserListNullable({
    required String service,
    required String action,
    List<Object?> args = const [],
  }) async {
    final result = await sendWs(service: service, action: action, args: args);
    if (result is! List) {
      return null;
    }
    return result
        .map((item) => UserManagement.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList();
  }

  Future<void> _sendUserMutation({
    required UserManagement userManagement,
    required String idempotencyKey,
    required String operation,
  }) async {
    await sendWs(
      service: 'SysUserService',
      action: 'checkAndInsertIdempotency',
      args: [
        idempotencyKey,
        userManagement.toUserRequestJson(),
        operation,
      ],
    );
  }

  Future<List<String>> _sendStringList({
    required String service,
    required String action,
    List<Object?> args = const [],
  }) async {
    final result = await sendWs(service: service, action: action, args: args);
    if (result is! List) {
      return <String>[];
    }
    return result.map((item) => item.toString()).toList();
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
