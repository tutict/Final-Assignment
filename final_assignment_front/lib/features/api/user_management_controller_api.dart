import 'dart:convert';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ApiClient defaultApiClient = ApiClient();

class UserManagementControllerApi {
  final ApiClient apiClient;

  UserManagementControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  // 初始化 JWT
  Future<void> initializeWithJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('未登录，请重新登录');
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint('Initialized JWT: $jwtToken');
  }

  // 解码响应体
  String _decodeBodyBytes(http.Response response) => response.body;

  // 获取请求头
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken') ?? '';
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

// --- GET /api/users/me ---
  Future<http.Response> apiUsersMeGetWithHttpInfo() async {
    final path = "/api/users/me".replaceAll("{format}", "json");
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

  Future<UserManagement?> apiUsersMeGet() async {
    try {
      final response = await apiUsersMeGetWithHttpInfo();
      debugPrint('Users me get response status: ${response.statusCode}');
      debugPrint('Users me get response body: ${response.body}');

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
      debugPrint('Users me get error: $e');
      rethrow;
    }
  }

  // --- PUT /api/users/me ---
  Future<http.Response> apiUsersMePutWithHttpInfo({
    required UserManagement userManagement,
    required String idempotencyKey,
  }) async {
    if (idempotencyKey.isEmpty) {
      throw ApiException(400, "Missing required param: idempotencyKey");
    }

    final path = "/api/users/me".replaceAll("{format}", "json");
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

  Future<void> apiUsersMePut({
    required UserManagement userManagement,
    required String idempotencyKey,
  }) async {
    try {
      final response = await apiUsersMePutWithHttpInfo(
        userManagement: userManagement,
        idempotencyKey: idempotencyKey,
      );
      debugPrint('Users me put response status: ${response.statusCode}');
      debugPrint('Users me put response body: ${response.body}');

      if (response.statusCode >= 400) {
        final errorMessage = response.body.isNotEmpty
            ? _decodeBodyBytes(response)
            : 'Unknown error';
        throw ApiException(response.statusCode, errorMessage);
      }
    } catch (e) {
      debugPrint('Users me put error: $e');
      rethrow;
    }
  }

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
        return null; // 201 CREATED，无响应体
      } else {
        throw ApiException(response.statusCode, 'Empty response body');
      }
    } catch (e) {
      debugPrint('Users post error: $e');
      rethrow;
    }
  }

  // --- GET /api/users/status/{status} ---
  Future<http.Response> apiUsersStatusStatusGetWithHttpInfo({
    required String status,
  }) async {
    if (status.isEmpty) {
      throw ApiException(400, "Missing required param: status");
    }

    final path = "/api/users/status/${Uri.encodeComponent(status)}"
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

  Future<List<UserManagement>> apiUsersStatusStatusGet({
    required String status,
  }) async {
    try {
      final response =
          await apiUsersStatusStatusGetWithHttpInfo(status: status);
      debugPrint('Users status get response status: ${response.statusCode}');
      debugPrint('Users status get response body: ${response.body}');

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
      debugPrint('Users status get error: $e');
      rethrow;
    }
  }

  // --- GET /api/users/type/{userType} ---
  Future<http.Response> apiUsersTypeUserTypeGetWithHttpInfo({
    required String userType,
  }) async {
    if (userType.isEmpty) {
      throw ApiException(400, "Missing required param: userType");
    }

    final path = "/api/users/type/${Uri.encodeComponent(userType)}"
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

  Future<List<UserManagement>> apiUsersTypeUserTypeGet({
    required String userType,
  }) async {
    try {
      final response =
          await apiUsersTypeUserTypeGetWithHttpInfo(userType: userType);
      debugPrint('Users type get response status: ${response.statusCode}');
      debugPrint('Users type get response body: ${response.body}');

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
      debugPrint('Users type get error: $e');
      rethrow;
    }
  }

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

    final path = "/api/users/username/${Uri.encodeComponent(username)}"
        .replaceAll("{format}", "json");
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

  Future<void> apiUsersUsernameUsernameDelete({
    required String username,
  }) async {
    try {
      final response =
          await apiUsersUsernameUsernameDeleteWithHttpInfo(username: username);
      debugPrint(
          'Users username delete response status: ${response.statusCode}');
      debugPrint('Users username delete response body: ${response.body}');

      if (response.statusCode >= 400) {
        final errorMessage = response.body.isNotEmpty
            ? _decodeBodyBytes(response)
            : 'Unknown error';
        throw ApiException(response.statusCode, errorMessage);
      }
    } catch (e) {
      debugPrint('Users username delete error: $e');
      rethrow;
    }
  }

  // --- GET /api/users/username/{username} ---
  Future<http.Response> apiUsersUsernameUsernameGetWithHttpInfo({
    required String username,
  }) async {
    if (username.isEmpty) {
      throw ApiException(400, "Missing required param: username");
    }

    final path = "/api/users/username/${Uri.encodeComponent(username)}"
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

  Future<UserManagement?> apiUsersUsernameUsernameGet({
    required String username,
  }) async {
    try {
      final response =
          await apiUsersUsernameUsernameGetWithHttpInfo(username: username);
      debugPrint('Users username get response status: ${response.statusCode}');
      debugPrint('Users username get response body: ${response.body}');

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
      debugPrint('Users username get error: $e');
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
    if (prefix.isEmpty) {
      throw ApiException(400, "Missing required param: prefix");
    }

    final path =
        "/api/users/autocomplete/statuses".replaceAll("{format}", "json");
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

  Future<List<String>> apiUsersAutocompleteStatusesGet({
    required String prefix,
  }) async {
    try {
      final response =
          await apiUsersAutocompleteStatusesGetWithHttpInfo(prefix: prefix);
      debugPrint(
          'Users autocomplete statuses response status: ${response.statusCode}');
      debugPrint('Users autocomplete statuses response body: ${response.body}');

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
      debugPrint('Users autocomplete statuses error: $e');
      rethrow;
    }
  }

  // --- GET /api/users/autocomplete/phone-numbers ---
  Future<http.Response> apiUsersAutocompletePhoneNumbersGetWithHttpInfo({
    required String prefix,
  }) async {
    if (prefix.isEmpty) {
      throw ApiException(400, "Missing required param: prefix");
    }

    final path =
        "/api/users/autocomplete/phone-numbers".replaceAll("{format}", "json");
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

  Future<List<String>> apiUsersAutocompletePhoneNumbersGet({
    required String prefix,
  }) async {
    try {
      final response =
          await apiUsersAutocompletePhoneNumbersGetWithHttpInfo(prefix: prefix);
      debugPrint(
          'Users autocomplete phone-numbers response status: ${response.statusCode}');
      debugPrint(
          'Users autocomplete phone-numbers response body: ${response.body}');

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
      debugPrint('Users autocomplete phone-numbers error: $e');
      rethrow;
    }
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
