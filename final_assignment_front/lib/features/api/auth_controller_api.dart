import 'dart:convert';
import 'package:final_assignment_front/features/model/login_request.dart';
import 'package:final_assignment_front/features/model/register_request.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // 用于 Response 和 MultipartRequest
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class AuthControllerApi {
  final ApiClient apiClient;

  // 更新后的构造函数，apiClient 参数可为空
  AuthControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  // 解码响应体的辅助方法
  String _decodeBodyBytes(http.Response response) => response.body;

  // 获取通用请求头，包含 JWT
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken') ?? '';
    debugPrint('Using JWT for request: $token');
    return {
      'Content-Type': 'application/json; charset=utf-8',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// 使用 HTTP 信息进行登录
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

    var response = await apiClient.invokeAPI(
        path,
        'POST',
        queryParams,
        postBody,
        headerParams,
        formParams,
        nullableContentType,
        authNames);
    return response;
  }

  /// 登录
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

  /// 使用 HTTP 信息进行用户注册
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

    var response = await apiClient.invokeAPI(
        path,
        'POST',
        queryParams,
        postBody,
        headerParams,
        formParams,
        nullableContentType,
        authNames);
    return response;
  }

  /// 用户注册
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

  /// 使用 HTTP 信息获取所有用户
  Future<http.Response> apiAuthUsersGetWithHttpInfo() async {
    String path = "/api/auth/users".replaceAll("{format}", "json");

    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = await _getHeaders();
    Map<String, String> formParams = {};

    List<String> contentTypes = [];
    String? nullableContentType =
    contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(
        path,
        'GET',
        queryParams,
        null,
        headerParams,
        formParams,
        nullableContentType,
        authNames);
    return response;
  }

  /// 获取所有用户
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

  /// 获取角色列表（新增）
  Future<http.Response> apiRolesGetWithHttpInfo() async {
    String path = "/api/roles".replaceAll("{format}", "json");

    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = await _getHeaders();
    Map<String, String> formParams = {};

    List<String> contentTypes = [];
    String? nullableContentType =
    contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(
        path,
        'GET',
        queryParams,
        null,
        headerParams,
        formParams,
        nullableContentType,
        authNames);
    return response;
  }

  /// 获取角色列表
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

  /// 登录（WebSocket）
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

  /// 用户注册（WebSocket）
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

  /// 获取所有用户（WebSocket）
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