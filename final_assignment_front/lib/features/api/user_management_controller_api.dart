import 'dart:convert';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:flutter/material.dart';
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
  Future<void> initializeWithJwt() async {
    final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null) {
      throw Exception('Not authenticated. Please log in again.');
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint('Initialized JWT: $jwtToken');
  }

  // è§£ç ååºä½?
  String _decodeBodyBytes(http.Response response) => decodeBodyBytes(response);

  // è·åè¯·æ±å¤?
  Future<Map<String, String>> _getHeaders() async {
    return getHeaders();
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

  Future<List<UserManagement>> listUsers() async {
    try {
      final response = await _listUsersWithHttpInfo();
      debugPrint('Users get response status: ${response.statusCode}');
      debugPrint('Users get response body: ${response.body}');

      if (response.statusCode >= 400) {
        final errorMessage = response.body.isNotEmpty
            ? _decodeBodyBytes(response)
            : 'Unknown error';
        throw ApiException(response.statusCode, errorMessage);
      } else if (response.body.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
        return jsonList.map((json) => UserManagement.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Users get error: $e');
      rethrow;
    }
  }

  // removed: /api/users/me (not provided by backend controllers)

  // --- POST /api/users ---
  Future<http.Response> _createUserWithHttpInfo({
    required UserManagement userManagement,
    required String idempotencyKey,
  }) async {
    if (idempotencyKey.isEmpty) {
      throw ApiException(400, "Missing required param: idempotencyKey");
    }

    final path = "/api/users".replaceAll("{format}", "json");
    final queryParams = [QueryParam("idempotencyKey", idempotencyKey)];
    final headerParams = await _getHeaders();

    return await apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      userManagement.toJson(),
      headerParams,
      {},
      'application/json',
      ['bearerAuth'],
    );
  }

  Future<UserManagement?> createUser({
    required UserManagement userManagement,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _createUserWithHttpInfo(
        userManagement: userManagement,
        idempotencyKey: idempotencyKey,
      );
      debugPrint('Users post response status: ${response.statusCode}');
      debugPrint('Users post response body: ${response.body}');

      if (response.statusCode >= 400) {
        final errorMessage = response.body.isNotEmpty
            ? _decodeBodyBytes(response)
            : 'Unknown error';
        throw ApiException(response.statusCode, errorMessage);
      } else if (response.body.isNotEmpty) {
        return UserManagement.fromJson(jsonDecode(_decodeBodyBytes(response)));
      } else if (response.statusCode == 201) {
        return null; // 201 CREATEDï¼æ ååºä½?
      } else {
        throw ApiException(response.statusCode, 'Empty response body');
      }
    } catch (e) {
      debugPrint('Users post error: $e');
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
      throw ApiException(400, "Missing required param: status");
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
      throw ApiException(400, "Missing required param: department");
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

  Future<List<UserManagement>> searchUsersByDepartment({
    required String department,
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await _searchUsersByDepartmentWithHttpInfo(
          department: department, page: page, size: size);
      debugPrint(
          'Users search department response status: ${response.statusCode}');
      debugPrint('Users search department response body: ${response.body}');

      if (response.statusCode >= 400) {
        final errorMessage = response.body.isNotEmpty
            ? _decodeBodyBytes(response)
            : 'Unknown error';
        throw ApiException(response.statusCode, errorMessage);
      } else if (response.body.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
        return jsonList.map((json) => UserManagement.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Users search department error: $e');
      rethrow;
    }
  }

  // --- GET /api/users/search/username/prefix?username=&page=&size= ---
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
    if (response.statusCode >= 400) {
      final errorMessage = response.body.isNotEmpty
          ? _decodeBodyBytes(response)
          : 'Unknown error';
      throw ApiException(response.statusCode, errorMessage);
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.map((json) => UserManagement.fromJson(json)).toList();
  }

  // --- GET /api/users/search/username/fuzzy?username=&page=&size= ---
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
    if (response.statusCode >= 400) {
      final errorMessage = response.body.isNotEmpty
          ? _decodeBodyBytes(response)
          : 'Unknown error';
      throw ApiException(response.statusCode, errorMessage);
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.map((json) => UserManagement.fromJson(json)).toList();
  }

  // --- GET /api/users/search/real-name/prefix?realName=&page=&size= ---
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
    if (response.statusCode >= 400) {
      final errorMessage = response.body.isNotEmpty
          ? _decodeBodyBytes(response)
          : 'Unknown error';
      throw ApiException(response.statusCode, errorMessage);
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.map((json) => UserManagement.fromJson(json)).toList();
  }

  // --- GET /api/users/search/real-name/fuzzy?realName=&page=&size= ---
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
    if (response.statusCode >= 400) {
      final errorMessage = response.body.isNotEmpty
          ? _decodeBodyBytes(response)
          : 'Unknown error';
      throw ApiException(response.statusCode, errorMessage);
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.map((json) => UserManagement.fromJson(json)).toList();
  }

  // --- GET /api/users/search/id-card?idCardNumber=&page=&size= ---
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
    if (response.statusCode >= 400) {
      final errorMessage = response.body.isNotEmpty
          ? _decodeBodyBytes(response)
          : 'Unknown error';
      throw ApiException(response.statusCode, errorMessage);
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.map((json) => UserManagement.fromJson(json)).toList();
  }

  // --- GET /api/users/search/contact?contactNumber=&page=&size= ---
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
    if (response.statusCode >= 400) {
      final errorMessage = response.body.isNotEmpty
          ? _decodeBodyBytes(response)
          : 'Unknown error';
      throw ApiException(response.statusCode, errorMessage);
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.map((json) => UserManagement.fromJson(json)).toList();
  }

  // --- POST /api/users/{userId}/roles --- bind user role
  Future<http.Response> _bindUserRoleWithHttpInfo({
    required int userId,
    required Map<String, dynamic> body, // expects SysUserRoleModel.toJson()
    required String idempotencyKey,
  }) async {
    if (idempotencyKey.isEmpty) {
      throw ApiException(400, "Missing required param: idempotencyKey");
    }
    final path = "/api/users/$userId/roles".replaceAll("{format}", "json");
    final headerParams = await _getHeaders();
    final queryParams = [QueryParam("idempotencyKey", idempotencyKey)];
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
    if (response.statusCode >= 400) {
      final errorMessage = response.body.isNotEmpty
          ? _decodeBodyBytes(response)
          : 'Unknown error';
      throw ApiException(response.statusCode, errorMessage);
    }
    return response.body.isNotEmpty
        ? jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>
        : null;
  }

  // --- DELETE /api/users/roles/{relationId} ---
  Future<void> deleteUserRoleBinding({required int relationId}) async {
    final path = "/api/users/roles/$relationId".replaceAll("{format}", "json");
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'DELETE',
      [],
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      final errorMessage = response.body.isNotEmpty
          ? _decodeBodyBytes(response)
          : 'Unknown error';
      throw ApiException(response.statusCode, errorMessage);
    }
  }

  // --- GET /api/users/{userId}/roles?page=&size= ---
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
    if (response.statusCode >= 400) {
      final errorMessage = response.body.isNotEmpty
          ? _decodeBodyBytes(response)
          : 'Unknown error';
      throw ApiException(response.statusCode, errorMessage);
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.cast<Map<String, dynamic>>();
  }

  // --- PUT /api/users/role-bindings/{relationId} ---
  Future<Map<String, dynamic>?> updateUserRoleBinding({
    required int relationId,
    required Map<String, dynamic> body,
    required String idempotencyKey,
  }) async {
    if (idempotencyKey.isEmpty) {
      throw ApiException(400, "Missing required param: idempotencyKey");
    }
    final path =
        "/api/users/role-bindings/$relationId".replaceAll("{format}", "json");
    final headerParams = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'PUT',
      [QueryParam("idempotencyKey", idempotencyKey)],
      body,
      headerParams,
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      final errorMessage = response.body.isNotEmpty
          ? _decodeBodyBytes(response)
          : 'Unknown error';
      throw ApiException(response.statusCode, errorMessage);
    }
    return response.body.isNotEmpty
        ? jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>
        : null;
  }

  // --- GET /api/users/role-bindings/{relationId} ---
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
    if (response.statusCode >= 400) {
      final errorMessage = response.body.isNotEmpty
          ? _decodeBodyBytes(response)
          : 'Unknown error';
      throw ApiException(response.statusCode, errorMessage);
    }
    return response.body.isNotEmpty
        ? jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>
        : null;
  }

  // --- GET /api/users/role-bindings?page=&size= ---
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
    if (response.statusCode >= 400) {
      final errorMessage = response.body.isNotEmpty
          ? _decodeBodyBytes(response)
          : 'Unknown error';
      throw ApiException(response.statusCode, errorMessage);
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.cast<Map<String, dynamic>>();
  }

  // --- GET /api/users/role-bindings/by-role/{roleId}?page=&size= ---
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
    if (response.statusCode >= 400) {
      final errorMessage = response.body.isNotEmpty
          ? _decodeBodyBytes(response)
          : 'Unknown error';
      throw ApiException(response.statusCode, errorMessage);
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.cast<Map<String, dynamic>>();
  }

  // --- GET /api/users/search/department/prefix?department=&page=&size= ---
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
    if (response.statusCode >= 400) {
      final errorMessage = response.body.isNotEmpty
          ? _decodeBodyBytes(response)
          : 'Unknown error';
      throw ApiException(response.statusCode, errorMessage);
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.map((json) => UserManagement.fromJson(json)).toList();
  }

  // --- GET /api/users/search/employee-number?employeeNumber=&page=&size= ---
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
    if (response.statusCode >= 400) {
      final errorMessage = response.body.isNotEmpty
          ? _decodeBodyBytes(response)
          : 'Unknown error';
      throw ApiException(response.statusCode, errorMessage);
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.map((json) => UserManagement.fromJson(json)).toList();
  }

  // --- GET /api/users/search/last-login-range?startTime=&endTime=&page=&size= ---
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
    if (response.statusCode >= 400) {
      final errorMessage = response.body.isNotEmpty
          ? _decodeBodyBytes(response)
          : 'Unknown error';
      throw ApiException(response.statusCode, errorMessage);
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.map((json) => UserManagement.fromJson(json)).toList();
  }

  // --- GET /api/users/role-bindings/search?userId=&roleId=&page=&size= ---
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
    if (response.statusCode >= 400) {
      final errorMessage = response.body.isNotEmpty
          ? _decodeBodyBytes(response)
          : 'Unknown error';
      throw ApiException(response.statusCode, errorMessage);
    }
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.cast<Map<String, dynamic>>();
  }

  Future<List<UserManagement>> searchUsersByStatus({
    required String status,
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await _searchUsersByStatusWithHttpInfo(
          status: status, page: page, size: size);
      debugPrint('Users search status response status: ${response.statusCode}');
      debugPrint('Users search status response body: ${response.body}');

      if (response.statusCode >= 400) {
        final errorMessage = response.body.isNotEmpty
            ? _decodeBodyBytes(response)
            : 'Unknown error';
        throw ApiException(response.statusCode, errorMessage);
      } else if (response.body.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
        return jsonList.map((json) => UserManagement.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Users search status error: $e');
      rethrow;
    }
  }

  // removed: /api/users/type/{userType} (not provided by backend controllers)

  // --- DELETE /api/users/{userId} ---
  Future<http.Response> _deleteUserWithHttpInfo({
    required String userId,
  }) async {
    if (userId.isEmpty) {
      throw ApiException(400, "Missing required param: userId");
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

  Future<void> deleteUser({
    required String userId,
  }) async {
    try {
      final response = await _deleteUserWithHttpInfo(userId: userId);
      debugPrint('Users delete response status: ${response.statusCode}');
      debugPrint('Users delete response body: ${response.body}');

      if (response.statusCode >= 400) {
        final errorMessage = response.body.isNotEmpty
            ? _decodeBodyBytes(response)
            : 'Unknown error';
        throw ApiException(response.statusCode, errorMessage);
      }
    } catch (e) {
      debugPrint('Users delete error: $e');
      rethrow;
    }
  }

  // --- GET /api/users/{userId} ---
  Future<http.Response> _getUserWithHttpInfo({
    required String userId,
  }) async {
    if (userId.isEmpty) {
      throw ApiException(400, "Missing required param: userId");
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

  Future<UserManagement?> getUser({
    required String userId,
  }) async {
    try {
      final response = await _getUserWithHttpInfo(userId: userId);
      debugPrint('Users userId get response status: ${response.statusCode}');
      debugPrint('Users userId get response body: ${response.body}');

      if (response.statusCode >= 400) {
        final errorMessage = response.body.isNotEmpty
            ? _decodeBodyBytes(response)
            : 'Unknown error';
        throw ApiException(response.statusCode, errorMessage);
      } else if (response.body.isNotEmpty) {
        return UserManagement.fromJson(jsonDecode(_decodeBodyBytes(response)));
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Users userId get error: $e');
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
      throw ApiException(400, "Missing required param: userId");
    }
    if (idempotencyKey.isEmpty) {
      throw ApiException(400, "Missing required param: idempotencyKey");
    }

    final path = "/api/users/$userId".replaceAll("{format}", "json");
    final queryParams = [QueryParam("idempotencyKey", idempotencyKey)];
    final headerParams = await _getHeaders();

    return await apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      userManagement.toJson(),
      headerParams,
      {},
      'application/json',
      ['bearerAuth'],
    );
  }

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
      debugPrint('Users userId put response status: ${response.statusCode}');
      debugPrint('Users userId put response body: ${response.body}');

      if (response.statusCode >= 400) {
        final errorMessage = response.body.isNotEmpty
            ? _decodeBodyBytes(response)
            : 'Unknown error';
        throw ApiException(response.statusCode, errorMessage);
      }
    } catch (e) {
      debugPrint('Users userId put error: $e');
      rethrow;
    }
  }

  // --- DELETE /api/users/username/{username} ---
  // ignore: unused_element
  Future<http.Response> _deleteUserByUsernameWithHttpInfo({
    required String username,
  }) async {
    if (username.isEmpty) {
      throw ApiException(400, "Missing required param: username");
    }

    // removed endpoint
    throw ApiException(
        410, "Endpoint removed: DELETE /api/users/username/{username}");
  }

  Future<void> deleteUserByUsername({
    required String username,
  }) async {
    // removed endpoint
    throw ApiException(
        410, "Endpoint removed: DELETE /api/users/username/{username}");
  }

  // --- GET /api/users/username/{username} ---
  // ignore: unused_element
  Future<http.Response> _getUserByUsernameWithHttpInfo({
    required String username,
  }) async {
    if (username.isEmpty) {
      throw ApiException(400, "Missing required param: username");
    }

    // replaced by /api/users/search/username/{username}
    return await _searchUsersByUsernameWithHttpInfo(username: username);
  }

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
      throw ApiException(400, "Missing required param: username");
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

  Future<UserManagement?> searchUsersByUsername({
    required String username,
  }) async {
    try {
      final response =
          await _searchUsersByUsernameWithHttpInfo(username: username);
      debugPrint(
          'Users search username response status: ${response.statusCode}');
      debugPrint('Users search username response body: ${response.body}');

      if (response.statusCode >= 400) {
        final errorMessage = response.body.isNotEmpty
            ? _decodeBodyBytes(response)
            : 'Unknown error';
        throw ApiException(response.statusCode, errorMessage);
      } else if (response.body.isNotEmpty) {
        return UserManagement.fromJson(jsonDecode(_decodeBodyBytes(response)));
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Users search username error: $e');
      rethrow;
    }
  }

  // --- GET /api/users/autocomplete/usernames ---
  Future<http.Response> _autocompleteUsernamesWithHttpInfo({
    required String prefix,
  }) async {
    if (prefix.isEmpty) {
      throw ApiException(400, "Missing required param: prefix");
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

  Future<List<String>> autocompleteUsernames({
    required String prefix,
  }) async {
    try {
      final response = await _autocompleteUsernamesWithHttpInfo(prefix: prefix);
      debugPrint(
          'Users autocomplete usernames response status: ${response.statusCode}');
      debugPrint(
          'Users autocomplete usernames response body: ${response.body}');

      if (response.statusCode >= 400) {
        final errorMessage = response.body.isNotEmpty
            ? _decodeBodyBytes(response)
            : 'Unknown error';
        throw ApiException(response.statusCode, errorMessage);
      } else if (response.body.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
        return jsonList.cast<String>();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Users autocomplete usernames error: $e');
      rethrow;
    }
  }

  // --- GET /api/users/autocomplete/statuses ---
  // ignore: unused_element
  Future<http.Response> _autocompleteUserStatusesWithHttpInfo({
    required String prefix,
  }) async {
    throw ApiException(
        410, "Endpoint removed: /api/users/autocomplete/statuses");
  }

  Future<List<String>> autocompleteUserStatuses({
    required String prefix,
  }) async {
    throw ApiException(
        410, "Endpoint removed: /api/users/autocomplete/statuses");
  }

  // --- GET /api/users/autocomplete/phone-numbers ---
  // ignore: unused_element
  Future<http.Response> _autocompleteUserPhoneNumbersWithHttpInfo({
    required String prefix,
  }) async {
    throw ApiException(
        410, "Endpoint removed: /api/users/autocomplete/phone-numbers");
  }

  Future<List<String>> autocompleteUserPhoneNumbers({
    required String prefix,
  }) async {
    throw ApiException(
        410, "Endpoint removed: /api/users/autocomplete/phone-numbers");
  }

  // --- WebSocket Methods ---

  // getAllUsers (WebSocket)
  Future<List<UserManagement>?> eventbusUsersGet() async {
    final msg = {
      "service": "UserManagementService",
      "action": "getAllUsers",
      "args": [],
    };
    try {
      final respMap = await apiClient.sendWsMessage(msg);
      debugPrint('WebSocket users get response: $respMap');

      if (respMap.containsKey("error")) {
        throw ApiException(400, respMap["error"]);
      }
      if (respMap.containsKey("result") && respMap["result"] is List) {
        return (respMap["result"] as List)
            .map((json) => UserManagement.fromJson(json))
            .toList();
      }
      return null;
    } catch (e) {
      debugPrint('WebSocket users get error: $e');
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
      debugPrint('WebSocket users me get response: $respMap');

      if (respMap.containsKey("error")) {
        throw ApiException(400, respMap["error"]);
      }
      if (respMap.containsKey("result") && respMap["result"] != null) {
        return UserManagement.fromJson(respMap["result"]);
      }
      return null;
    } catch (e) {
      debugPrint('WebSocket users me get error: $e');
      rethrow;
    }
  }

  Future<UserManagement> getCurrentUser({
    required String username,
  }) async {
    final user = await _getCurrentUserViaEventbus(username: username);
    if (user == null) {
      throw ApiException(404, "Current user not found");
    }
    return user;
  }

  // updateCurrentUser (WebSocket)
  Future<void> eventbusUsersMePut({
    required String username,
    required UserManagement userManagement,
    required String idempotencyKey,
  }) async {
    final msg = {
      "service": "UserManagementService",
      "action": "updateCurrentUser",
      "args": [username, userManagement.toJson(), idempotencyKey],
    };
    try {
      final respMap = await apiClient.sendWsMessage(msg);
      debugPrint('WebSocket users me put response: $respMap');

      if (respMap.containsKey("error")) {
        throw ApiException(400, respMap["error"]);
      }
    } catch (e) {
      debugPrint('WebSocket users me put error: $e');
      rethrow;
    }
  }

  // createUser (WebSocket)
  Future<UserManagement?> eventbusUsersPost({
    required UserManagement userManagement,
    required String idempotencyKey,
  }) async {
    final msg = {
      "service": "UserManagementService",
      "action": "createUser",
      "args": [userManagement.toJson(), idempotencyKey],
    };
    try {
      final respMap = await apiClient.sendWsMessage(msg);
      debugPrint('WebSocket users post response: $respMap');

      if (respMap.containsKey("error")) {
        throw ApiException(400, respMap["error"]);
      }
      if (respMap.containsKey("result") && respMap["result"] != null) {
        return UserManagement.fromJson(respMap["result"]);
      }
      return null;
    } catch (e) {
      debugPrint('WebSocket users post error: $e');
      rethrow;
    }
  }

  // getUsersByStatus (WebSocket)
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
      debugPrint('WebSocket users status get response: $respMap');

      if (respMap.containsKey("error")) {
        throw ApiException(400, respMap["error"]);
      }
      if (respMap.containsKey("result") && respMap["result"] is List) {
        return (respMap["result"] as List)
            .map((json) => UserManagement.fromJson(json))
            .toList();
      }
      return null;
    } catch (e) {
      debugPrint('WebSocket users status get error: $e');
      rethrow;
    }
  }

  // getUsersByType (WebSocket)
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
      debugPrint('WebSocket users type get response: $respMap');

      if (respMap.containsKey("error")) {
        throw ApiException(400, respMap["error"]);
      }
      if (respMap.containsKey("result") && respMap["result"] is List) {
        return (respMap["result"] as List)
            .map((json) => UserManagement.fromJson(json))
            .toList();
      }
      return null;
    } catch (e) {
      debugPrint('WebSocket users type get error: $e');
      rethrow;
    }
  }

  // deleteUser (WebSocket)
  Future<void> eventbusUsersUserIdDelete({required String userId}) async {
    final msg = {
      "service": "UserManagementService",
      "action": "deleteUser",
      "args": [userId],
    };
    try {
      final respMap = await apiClient.sendWsMessage(msg);
      debugPrint('WebSocket users delete response: $respMap');

      if (respMap.containsKey("error")) {
        throw ApiException(400, respMap["error"]);
      }
    } catch (e) {
      debugPrint('WebSocket users delete error: $e');
      rethrow;
    }
  }

  // getUserById (WebSocket)
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
      debugPrint('WebSocket users userId get response: $respMap');

      if (respMap.containsKey("error")) {
        throw ApiException(400, respMap["error"]);
      }
      if (respMap.containsKey("result") && respMap["result"] != null) {
        return UserManagement.fromJson(respMap["result"]);
      }
      return null;
    } catch (e) {
      debugPrint('WebSocket users userId get error: $e');
      rethrow;
    }
  }

  // updateUser (WebSocket)
  Future<void> eventbusUsersUserIdPut({
    required String userId,
    required UserManagement userManagement,
    required String idempotencyKey,
  }) async {
    final msg = {
      "service": "UserManagementService",
      "action": "updateUser",
      "args": [userId, userManagement.toJson(), idempotencyKey],
    };
    try {
      final respMap = await apiClient.sendWsMessage(msg);
      debugPrint('WebSocket users userId put response: $respMap');

      if (respMap.containsKey("error")) {
        throw ApiException(400, respMap["error"]);
      }
    } catch (e) {
      debugPrint('WebSocket users userId put error: $e');
      rethrow;
    }
  }

  // deleteUserByUsername (WebSocket)
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
      debugPrint('WebSocket users username delete response: $respMap');

      if (respMap.containsKey("error")) {
        throw ApiException(400, respMap["error"]);
      }
    } catch (e) {
      debugPrint('WebSocket users username delete error: $e');
      rethrow;
    }
  }

  // getUserByUsername (WebSocket)
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
      debugPrint('WebSocket users username get response: $respMap');

      if (respMap.containsKey("error")) {
        throw ApiException(400, respMap["error"]);
      }
      if (respMap.containsKey("result") && respMap["result"] != null) {
        return UserManagement.fromJson(respMap["result"]);
      }
      return null;
    } catch (e) {
      debugPrint('WebSocket users username get error: $e');
      rethrow;
    }
  }

  // getUsernameAutocompleteSuggestionsGlobally (WebSocket)
  Future<List<String>> eventbusUsersAutocompleteUsernamesGet({
    required String prefix,
  }) async {
    if (prefix.isEmpty) {
      throw ApiException(400, "Missing required param: prefix");
    }
    final msg = {
      "service": "UserManagementService",
      "action": "getUsernameAutocompleteSuggestionsGlobally",
      "args": [prefix],
    };
    try {
      final respMap = await apiClient.sendWsMessage(msg);
      debugPrint('WebSocket users autocomplete usernames response: $respMap');

      if (respMap.containsKey("error")) {
        throw ApiException(400, respMap["error"]);
      }
      if (respMap.containsKey("result") && respMap["result"] is List) {
        return (respMap["result"] as List).cast<String>();
      }
      return [];
    } catch (e) {
      debugPrint('WebSocket users autocomplete usernames error: $e');
      rethrow;
    }
  }

  // getStatusAutocompleteSuggestionsGlobally (WebSocket)
  Future<List<String>> eventbusUsersAutocompleteStatusesGet({
    required String prefix,
  }) async {
    if (prefix.isEmpty) {
      throw ApiException(400, "Missing required param: prefix");
    }
    final msg = {
      "service": "UserManagementService",
      "action": "getStatusAutocompleteSuggestionsGlobally",
      "args": [prefix],
    };
    try {
      final respMap = await apiClient.sendWsMessage(msg);
      debugPrint('WebSocket users autocomplete statuses response: $respMap');

      if (respMap.containsKey("error")) {
        throw ApiException(400, respMap["error"]);
      }
      if (respMap.containsKey("result") && respMap["result"] is List) {
        return (respMap["result"] as List).cast<String>();
      }
      return [];
    } catch (e) {
      debugPrint('WebSocket users autocomplete statuses error: $e');
      rethrow;
    }
  }

  // getPhoneNumberAutocompleteSuggestionsGlobally (WebSocket)
  Future<List<String>> eventbusUsersAutocompletePhoneNumbersGet({
    required String prefix,
  }) async {
    if (prefix.isEmpty) {
      throw ApiException(400, "Missing required param: prefix");
    }
    final msg = {
      "service": "UserManagementService",
      "action": "getPhoneNumberAutocompleteSuggestionsGlobally",
      "args": [prefix],
    };
    try {
      final respMap = await apiClient.sendWsMessage(msg);
      debugPrint(
          'WebSocket users autocomplete phone-numbers response: $respMap');

      if (respMap.containsKey("error")) {
        throw ApiException(400, respMap["error"]);
      }
      if (respMap.containsKey("result") && respMap["result"] is List) {
        return (respMap["result"] as List).cast<String>();
      }
      return [];
    } catch (e) {
      debugPrint('WebSocket users autocomplete phone-numbers error: $e');
      rethrow;
    }
  }
}
