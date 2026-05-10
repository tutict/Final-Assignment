import 'dart:convert';
import 'package:final_assignment_front/features/model/login_request.dart';
import 'package:final_assignment_front/features/model/register_request.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // ç¨äº Response å?MultipartRequest
import 'package:final_assignment_front/utils/services/api_client.dart';

// å®ä¹ä¸ä¸ªå
// ¨å±ç?defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class AuthControllerApi with BaseApiClient {
  @override
  final ApiClient apiClient;

  // æ´æ°åçæé å½æ°ï¼apiClient åæ°å¯ä¸ºç©?
  AuthControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  // è§£ç ååºä½çè¾
// å©æ¹æ³
  String _decodeBodyBytes(http.Response response) => decodeBodyBytes(response);

  // è·åéç¨è¯·æ±å¤´ï¼å
// å« JWT
  Future<Map<String, String>> _getHeaders() async {
    return getHeaders();
  }

  /// ä½¿ç¨ HTTP ä¿¡æ¯è¿è¡ç»å½
  Future<http.Response> apiAuthLoginPostWithHttpInfo(
      {required LoginRequest loginRequest}) async {
    Object postBody = loginRequest;

    String path = "/api/auth/login".replaceAll("{format}", "json");

    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = await _getHeaders();
    Map<String, String> formParams = {};

    List<String> contentTypes = ["application/json"];
    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'POST', queryParams,
        postBody, headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// ç»å½
  Future<Map<String, dynamic>> apiAuthLoginPost(
      {required LoginRequest loginRequest}) async {
    try {
      http.Response response =
          await apiAuthLoginPostWithHttpInfo(loginRequest: loginRequest);
      debugPrint('Login response status: ${response.statusCode}');
      debugPrint('Login response body: ${response.body}');

      if (response.statusCode >= 400) {
        String errorMessage = response.body.isNotEmpty
            ? _decodeBodyBytes(response)
            : 'Unknown error';
        throw ApiException(response.statusCode, errorMessage);
      } else if (response.body.isNotEmpty) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {};
      }
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  /// ä½¿ç¨ HTTP ä¿¡æ¯è¿è¡ç¨æ·æ³¨å
  Future<http.Response> apiAuthRegisterPostWithHttpInfo(
      {required RegisterRequest registerRequest}) async {
    Object postBody = registerRequest;

    String path = "/api/auth/register".replaceAll("{format}", "json");

    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = await _getHeaders();
    Map<String, String> formParams = {};

    List<String> contentTypes = ["application/json"];
    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'POST', queryParams,
        postBody, headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// ç¨æ·æ³¨å
  Future<Map<String, dynamic>> apiAuthRegisterPost(
      {required RegisterRequest registerRequest}) async {
    try {
      http.Response response = await apiAuthRegisterPostWithHttpInfo(
          registerRequest: registerRequest);
      debugPrint('Register response status: ${response.statusCode}');
      debugPrint('Register response body: ${response.body}');

      if (response.statusCode >= 400) {
        String errorMessage = response.body.isNotEmpty
            ? _decodeBodyBytes(response)
            : 'Unknown error';
        throw ApiException(response.statusCode, errorMessage);
      } else if (response.body.isNotEmpty) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 201) {
        return {'status': 'CREATED'};
      } else {
        throw ApiException(response.statusCode, 'Empty response body');
      }
    } catch (e) {
      debugPrint('Register error: $e');
      rethrow;
    }
  }

  /// ä½¿ç¨ HTTP ä¿¡æ¯è·åææç¨æ?
  Future<http.Response> apiAuthUsersGetWithHttpInfo() async {
    String path = "/api/auth/users".replaceAll("{format}", "json");

    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = await _getHeaders();
    Map<String, String> formParams = {};

    List<String> contentTypes = [];
    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, null,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// è·åææç¨æ?
  Future<Map<String, dynamic>> apiAuthUsersGet() async {
    try {
      http.Response response = await apiAuthUsersGetWithHttpInfo();
      debugPrint('Users get response status: ${response.statusCode}');
      debugPrint('Users get response body: ${response.body}');

      if (response.statusCode >= 400) {
        String errorMessage = response.body.isNotEmpty
            ? _decodeBodyBytes(response)
            : 'Unknown error';
        throw ApiException(response.statusCode, errorMessage);
      } else if (response.body.isNotEmpty) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {};
      }
    } catch (e) {
      debugPrint('Users get error: $e');
      rethrow;
    }
  }

  /// è·åè§è²åè¡¨ï¼æ°å¢ï¼
  Future<http.Response> apiRolesGetWithHttpInfo() async {
    String path = "/api/roles".replaceAll("{format}", "json");

    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = await _getHeaders();
    Map<String, String> formParams = {};

    List<String> contentTypes = [];
    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, null,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// è·åè§è²åè¡¨
  Future<Map<String, dynamic>> apiRolesGet() async {
    try {
      http.Response response = await apiRolesGetWithHttpInfo();
      debugPrint('Roles get response status: ${response.statusCode}');
      debugPrint('Roles get response body: ${response.body}');

      if (response.statusCode >= 400) {
        String errorMessage = response.body.isNotEmpty
            ? _decodeBodyBytes(response)
            : 'Unknown error';
        throw ApiException(response.statusCode, errorMessage);
      } else if (response.body.isNotEmpty) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {};
      }
    } catch (e) {
      debugPrint('Roles get error: $e');
      rethrow;
    }
  }

  /// ç»å½ï¼WebSocketï¼?
  Future<Object?> eventbusAuthLoginPost(
      {required LoginRequest loginRequest}) async {
    final msg = <String, dynamic>{
      "service": "Auth",
      "action": "login",
      "args": [
        {"username": loginRequest.username, "password": loginRequest.password}
      ],
    };

    final respMap = await apiClient.sendWsMessage(msg);

    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    if (respMap.containsKey("result")) {
      return respMap["result"];
    }
    return null;
  }

  /// ç¨æ·æ³¨åï¼WebSocketï¼?
  Future<Object?> eventbusAuthRegisterPost(
      {required RegisterRequest registerRequest}) async {
    final msg = <String, dynamic>{
      "service": "Auth",
      "action": "register",
      "args": [
        {
          "username": registerRequest.username,
          "password": registerRequest.password,
          "role": registerRequest.role,
          "idempotencyKey": registerRequest.idempotencyKey
        }
      ],
    };

    final respMap = await apiClient.sendWsMessage(msg);

    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    if (respMap.containsKey("result")) {
      return respMap["result"];
    }
    return null;
  }

  /// è·åææç¨æ·ï¼WebSocketï¼?
  Future<Object?> eventbusAuthUsersGet() async {
    final msg = <String, dynamic>{
      "service": "Auth",
      "action": "getAllUsers",
      "args": []
    };

    final respMap = await apiClient.sendWsMessage(msg);

    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    if (respMap.containsKey("result")) {
      return respMap["result"];
    }
    return null;
  }
}
