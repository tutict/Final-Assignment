import 'dart:convert';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

final ApiClient defaultApiClient = ApiClient();

class UserManagementControllerApi {
  final ApiClient apiClient;

  UserManagementControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  // åå§å?JWT
  Future<void> initializeWithJwt() async {
      final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null) {
      throw Exception('æªç»å½ï¼è¯·éæ°ç»å½?);
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint('Initialized JWT: $jwtToken');
  }

  // è§£ç ååºä½?
  String _decodeBodyBytes(http.Response response) => response.body;

  // è·åè¯·æ±å¤?
  Future<Map<String, String>> _getHeaders() async {
      final token = (await AuthTokenStore.instance.getJwtToken()) ?? '';
    debugPrint('Using JWT for request: $token');
    return {
      'Content-Type': 'application/json; charset=utf-8',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

// --- GET /api/users ---
  Future<http.Response> apiUsersGetWithHttpInfo() async {
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

  Future<List<UserManagement>> apiUsersGet() async {
    try {
      final response = await apiUsersGetWithHttpInfo();
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
  Future<http.Response> apiUsersPostWithHttpInfo({
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

  Future<UserManagement?> apiUsersPost({
    required UserManagement userManagement,
    required String idempotencyKey,
  }) async {
    try {
      final response = await apiUsersPostWithHttpInfo(
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
  Future<http.Response> apiUsersSearchStatusGetWithHttpInfo({
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
  Future<http.Response> apiUsersSearchDepartmentGetWithHttpInfo({
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

  Future<List<UserManagement>> apiUsersSearchDepartmentGet({
    required String department,
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await apiUsersSearchDepartmentGetWithHttpInfo(
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
  Future<List<UserManagement>> apiUsersSearchUsernamePrefixGet({
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
  Future<List<UserManagement>> apiUsersSearchUsernameFuzzyGet({
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
  Future<List<UserManagement>> apiUsersSearchRealNamePrefixGet({
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
  Future<List<UserManagement>> apiUsersSearchRealNameFuzzyGet({
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
  Future<List<UserManagement>> apiUsersSearchIdCardGet({
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
  Future<List<UserManagement>> apiUsersSearchContactGet({
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
  Future<http.Response> apiUsersUserIdRolesPostWithHttpInfo({
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

  Future<Map<String, dynamic>?> apiUsersUserIdRolesPost({
    required int userId,
    required Map<String, dynamic> body,
    required String idempotencyKey,
  }) async {
    final response = await apiUsersUserIdRolesPostWithHttpInfo(
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
  Future<void> apiUsersRolesRelationIdDelete({required int relationId}) async {
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
  Future<List<Map<String, dynamic>>> apiUsersUserIdRolesGet({
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
  Future<Map<String, dynamic>?> apiUsersRoleBindingsRelationIdPut({
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
  Future<Map<String, dynamic>?> apiUsersRoleBindingsRelationIdGet({
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
  Future<List<Map<String, dynamic>>> apiUsersRoleBindingsGet({
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
  Future<List<Map<String, dynamic>>> apiUsersRoleBindingsByRoleRoleIdGet({
    required int roleId,
    int page = 1,
    int size = 20,
  }) async {
    final path =
        "/api/users/role-bindings/by-role/$roleId".replaceAll("{format}", "json");
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
  Future<List<UserManagement>> apiUsersSearchDepartmentPrefixGet({
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
  Future<List<UserManagement>> apiUsersSearchEmployeeNumberGet({
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
  Future<List<UserManagement>> apiUsersSearchLastLoginRangeGet({
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
  Future<List<Map<String, dynamic>>> apiUsersRoleBindingsSearchGet({
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
  Future<List<UserManagement>> apiUsersSearchStatusGet({
    required String status,
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await apiUsersSearchStatusGetWithHttpInfo(
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
  Future<http.Response> apiUsersUserIdDeleteWithHttpInfo({
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

  Future<void> apiUsersUserIdDelete({
    required String userId,
  }) async {
    try {
      final response = await apiUsersUserIdDeleteWithHttpInfo(userId: userId);
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
  Future<http.Response> apiUsersUserIdGetWithHttpInfo({
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

  Future<UserManagement?> apiUsersUserIdGet({
    required String userId,
  }) async {
    try {
      final response = await apiUsersUserIdGetWithHttpInfo(userId: userId);
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
  Future<http.Response> apiUsersUserIdPutWithHttpInfo({
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

  Future<void> apiUsersUserIdPut({
    required String userId,
    required UserManagement userManagement,
    required String idempotencyKey,
  }) async {
    try {
      final response = await apiUsersUserIdPutWithHttpInfo(
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
  Future<http.Response> apiUsersUsernameUsernameDeleteWithHttpInfo({
    required String username,
  }) async {
    if (username.isEmpty) {
      throw ApiException(400, "Missing required param: username");
    }

    // removed endpoint
    throw ApiException(410, "Endpoint removed: DELETE /api/users/username/{username}");
  }

  Future<void> apiUsersUsernameUsernameDelete({
    required String username,
  }) async {
    // removed endpoint
    throw ApiException(410, "Endpoint removed: DELETE /api/users/username/{username}");
  }

  // --- GET /api/users/username/{username} ---
  Future<http.Response> apiUsersUsernameUsernameGetWithHttpInfo({
    required String username,
  }) async {
    if (username.isEmpty) {
      throw ApiException(400, "Missing required param: username");
    }

    // replaced by /api/users/search/username/{username}
    return await apiUsersSearchUsernameGetWithHttpInfo(username: username);
  }

  Future<UserManagement?> apiUsersUsernameUsernameGet({
    required String username,
  }) async {
    return await apiUsersSearchUsernameGet(username: username);
  }

  // --- GET /api/users/search/username/{username} ---
  Future<http.Response> apiUsersSearchUsernameGetWithHttpInfo({
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

  Future<UserManagement?> apiUsersSearchUsernameGet({
    required String username,
  }) async {
    try {
      final response =
          await apiUsersSearchUsernameGetWithHttpInfo(username: username);
      debugPrint('Users search username response status: ${response.statusCode}');
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
  Future<http.Response> apiUsersAutocompleteUsernamesGetWithHttpInfo({
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

  Future<List<String>> apiUsersAutocompleteUsernamesGet({
    required String prefix,
  }) async {
    try {
      final response =
          await apiUsersAutocompleteUsernamesGetWithHttpInfo(prefix: prefix);
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
  Future<http.Response> apiUsersAutocompleteStatusesGetWithHttpInfo({
    required String prefix,
  }) async {
    throw ApiException(410, "Endpoint removed: /api/users/autocomplete/statuses");
  }

  Future<List<String>> apiUsersAutocompleteStatusesGet({
    required String prefix,
  }) async {
    throw ApiException(410, "Endpoint removed: /api/users/autocomplete/statuses");
  }

  // --- GET /api/users/autocomplete/phone-numbers ---
  Future<http.Response> apiUsersAutocompletePhoneNumbersGetWithHttpInfo({
    required String prefix,
  }) async {
    throw ApiException(410, "Endpoint removed: /api/users/autocomplete/phone-numbers");
  }

  Future<List<String>> apiUsersAutocompletePhoneNumbersGet({
    required String prefix,
  }) async {
    throw ApiException(410, "Endpoint removed: /api/users/autocomplete/phone-numbers");
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

  // getCurrentUser (WebSocket)
  Future<UserManagement?> eventbusUsersMeGet({required String username}) async {
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
