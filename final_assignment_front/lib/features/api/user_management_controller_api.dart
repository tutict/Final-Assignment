import 'dart:convert';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ApiClient defaultApiClient = ApiClient();

class UserManagementControllerApi {
  final ApiClient apiClient;

  UserManagementControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  String _decodeBodyBytes(http.Response response) => response.body;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken') ?? '';
    return {
      'Content-Type': 'application/json; charset=utf-8',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // --- GET /api/users ---
  Future<http.Response> apiUsersGetWithHttpInfo() async {
    const path = "/api/users";
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
    final response = await apiUsersGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
      return jsonList.map((json) => UserManagement.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  // --- GET /api/users/me ---
  Future<http.Response> apiUsersMeGetWithHttpInfo() async {
    const path = "/api/users/me";
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
    final response = await apiUsersMeGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return UserManagement.fromJson(jsonDecode(_decodeBodyBytes(response)));
    }
    return null;
  }

  // --- PUT /api/users/me ---
  Future<http.Response> apiUsersMePutWithHttpInfo({
    required UserManagement userManagement,
    required String idempotencyKey,
  }) async {
    if (idempotencyKey.isEmpty) {
      throw ApiException(400, "Missing required param: idempotencyKey");
    }

    final path = "/api/users/me?idempotencyKey=$idempotencyKey";
    final headerParams = await _getHeaders();

    return await apiClient.invokeAPI(
      path,
      'PUT',
      [],
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
    final response = await apiUsersMePutWithHttpInfo(
        userManagement: userManagement, idempotencyKey: idempotencyKey);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  // --- POST /api/users ---
  Future<http.Response> apiUsersPostWithHttpInfo({
    required UserManagement userManagement,
  }) async {
    const path = "/api/users";
    final headerParams = await _getHeaders();

    return await apiClient.invokeAPI(
      path,
      'POST',
      [],
      userManagement.toJson(),
      headerParams,
      {},
      'application/json',
      ['bearerAuth'],
    );
  }

  Future<UserManagement?> apiUsersPost({
    required UserManagement userManagement,
  }) async {
    final response =
        await apiUsersPostWithHttpInfo(userManagement: userManagement);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return UserManagement.fromJson(jsonDecode(_decodeBodyBytes(response)));
    }
    return null;
  }

  // --- GET /api/users/status/{status} ---
  Future<http.Response> apiUsersStatusStatusGetWithHttpInfo({
    required String status,
  }) async {
    if (status.isEmpty) {
      throw ApiException(400, "Missing required param: status");
    }

    final path = "/api/users/status/${Uri.encodeComponent(status)}";
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
    final response = await apiUsersStatusStatusGetWithHttpInfo(status: status);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
      return jsonList.map((json) => UserManagement.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  // --- GET /api/users/type/{userType} ---
  Future<http.Response> apiUsersTypeUserTypeGetWithHttpInfo({
    required String userType,
  }) async {
    if (userType.isEmpty) {
      throw ApiException(400, "Missing required param: userType");
    }

    final path = "/api/users/type/${Uri.encodeComponent(userType)}";
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
    final response =
        await apiUsersTypeUserTypeGetWithHttpInfo(userType: userType);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
      return jsonList.map((json) => UserManagement.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  // --- DELETE /api/users/{userId} ---
  Future<http.Response> apiUsersUserIdDeleteWithHttpInfo({
    required String userId,
  }) async {
    if (userId.isEmpty) {
      throw ApiException(400, "Missing required param: userId");
    }

    final path = "/api/users/$userId";
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
    final response = await apiUsersUserIdDeleteWithHttpInfo(userId: userId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  // --- GET /api/users/{userId} ---
  Future<http.Response> apiUsersUserIdGetWithHttpInfo({
    required String userId,
  }) async {
    if (userId.isEmpty) {
      throw ApiException(400, "Missing required param: userId");
    }

    final path = "/api/users/$userId";
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
    final response = await apiUsersUserIdGetWithHttpInfo(userId: userId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return UserManagement.fromJson(jsonDecode(_decodeBodyBytes(response)));
    }
    return null;
  }

  // --- PUT /api/users/{userId} ---
  Future<http.Response> apiUsersUserIdPutWithHttpInfo({
    required String userId,
    required UserManagement userManagement,
  }) async {
    if (userId.isEmpty) {
      throw ApiException(400, "Missing required param: userId");
    }

    final path = "/api/users/$userId";
    final headerParams = await _getHeaders();

    return await apiClient.invokeAPI(
      path,
      'PUT',
      [],
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
  }) async {
    final response = await apiUsersUserIdPutWithHttpInfo(
        userId: userId, userManagement: userManagement);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  // --- DELETE /api/users/username/{username} ---
  Future<http.Response> apiUsersUsernameUsernameDeleteWithHttpInfo({
    required String username,
  }) async {
    if (username.isEmpty) {
      throw ApiException(400, "Missing required param: username");
    }

    final path = "/api/users/username/${Uri.encodeComponent(username)}";
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
    final response =
        await apiUsersUsernameUsernameDeleteWithHttpInfo(username: username);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  // --- GET /api/users/username/{username} ---
  Future<http.Response> apiUsersUsernameUsernameGetWithHttpInfo({
    required String username,
  }) async {
    if (username.isEmpty) {
      throw ApiException(400, "Missing required param: username");
    }

    final path = "/api/users/username/${Uri.encodeComponent(username)}";
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
    final response =
        await apiUsersUsernameUsernameGetWithHttpInfo(username: username);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return UserManagement.fromJson(jsonDecode(_decodeBodyBytes(response)));
    }
    return null;
  }

  // --- WebSocket Methods ---

  // getAllUsers (WebSocket)
  Future<List<UserManagement>?> eventbusUsersGet() async {
    final msg = {
      "service": "UserManagementService",
      "action": "getAllUsers",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
    if (respMap["result"] is List) {
      return (respMap["result"] as List)
          .map((json) => UserManagement.fromJson(json))
          .toList();
    }
    return null;
  }

  // getCurrentUser (WebSocket)
  Future<UserManagement?> eventbusUsersMeGet({required String username}) async {
    final msg = {
      "service": "UserManagementService",
      "action": "getCurrentUser",
      "args": [username]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
    if (respMap["result"] != null) {
      return UserManagement.fromJson(respMap["result"]);
    }
    return null;
  }

  // updateCurrentUser (WebSocket)
  Future<void> eventbusUsersMePut(
      {required String username, required UserManagement updated}) async {
    final updatedMap = updated.toJson();
    final msg = {
      "service": "UserManagementService",
      "action": "updateCurrentUser",
      "args": [username, updatedMap]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
  }

  // createUser (WebSocket)
  Future<UserManagement?> eventbusUsersPost(
      {required UserManagement userManagement}) async {
    final userMap = userManagement.toJson();
    final msg = {
      "service": "UserManagementService",
      "action": "createUser",
      "args": [userMap]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
    if (respMap["result"] != null) {
      return UserManagement.fromJson(respMap["result"]);
    }
    return null;
  }

  // getUsersByStatus (WebSocket)
  Future<List<UserManagement>?> eventbusUsersStatusStatusGet(
      {required String status}) async {
    final msg = {
      "service": "UserManagementService",
      "action": "getUsersByStatus",
      "args": [status]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
    if (respMap["result"] is List) {
      return (respMap["result"] as List)
          .map((json) => UserManagement.fromJson(json))
          .toList();
    }
    return null;
  }

  // getUsersByType (WebSocket)
  Future<List<UserManagement>?> eventbusUsersTypeUserTypeGet(
      {required String userType}) async {
    final msg = {
      "service": "UserManagementService",
      "action": "getUsersByType",
      "args": [userType]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
    if (respMap["result"] is List) {
      return (respMap["result"] as List)
          .map((json) => UserManagement.fromJson(json))
          .toList();
    }
    return null;
  }

  // deleteUser (WebSocket)
  Future<void> eventbusUsersUserIdDelete({required String userId}) async {
    final msg = {
      "service": "UserManagementService",
      "action": "deleteUser",
      "args": [int.parse(userId)]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
  }

  // getUserById (WebSocket)
  Future<UserManagement?> eventbusUsersUserIdGet(
      {required String userId}) async {
    final msg = {
      "service": "UserManagementService",
      "action": "getUserById",
      "args": [int.parse(userId)]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
    if (respMap["result"] != null) {
      return UserManagement.fromJson(respMap["result"]);
    }
    return null;
  }

  // updateUser (WebSocket)
  Future<void> eventbusUsersUserIdPut(
      {required String userId, required UserManagement userManagement}) async {
    final userMap = userManagement.toJson();
    final msg = {
      "service": "UserManagementService",
      "action": "updateUser",
      "args": [int.parse(userId), userMap]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
  }

  // deleteUserByUsername (WebSocket)
  Future<void> eventbusUsersUsernameUsernameDelete(
      {required String username}) async {
    final msg = {
      "service": "UserManagementService",
      "action": "deleteUserByUsername",
      "args": [username]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
  }

  // getUserByUsername (WebSocket)
  Future<UserManagement?> eventbusUsersUsernameUsernameGet(
      {required String username}) async {
    final msg = {
      "service": "UserManagementService",
      "action": "getUserByUsername",
      "args": [username]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) throw ApiException(400, respMap["error"]);
    if (respMap["result"] != null) {
      return UserManagement.fromJson(respMap["result"]);
    }
    return null;
  }
}
