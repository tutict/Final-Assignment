import 'package:final_assignment_front/features/model/login_request.dart';
import 'package:final_assignment_front/features/model/register_request.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart'; // 用于 Response 和 MultipartRequest
import 'package:final_assignment_front/utils/services/api_client.dart';

// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class AuthControllerApi {
  final ApiClient apiClient;

  // 更新后的构造函数，apiClient 参数可为空
  AuthControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  // 解码响应体的辅助方法
  String _decodeBodyBytes(Response response) => response.body;

  /// 使用 HTTP 信息进行登录
  ///
  ///
  Future<Response> apiAuthLoginPostWithHttpInfo(
      {required LoginRequest loginRequest}) async {
    Object postBody = loginRequest;

    // 验证必需参数已设置
    // 因为使用了 'required'，无需检查是否为 null

    // 创建路径和映射变量
    String path = "/api/auth/login".replaceAll("{format}", "json");

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = ["application/json"];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'POST', queryParams,
        postBody, headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// 登录
  ///
  ///
  Future<Object?> apiAuthLoginPost({required LoginRequest loginRequest}) async {
    Response response =
        await apiAuthLoginPostWithHttpInfo(loginRequest: loginRequest);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// 使用 HTTP 信息进行用户注册
  ///
  ///
  Future<Response> apiAuthRegisterPostWithHttpInfo(
      {required RegisterRequest registerRequest}) async {
    Object postBody = registerRequest;

    // 验证必需参数已设置
    // 因为使用了 'required'，无需检查是否为 null

    // 创建路径和映射变量
    String path = "/api/auth/register".replaceAll("{format}", "json");

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    // headerParams = _mergeHeaders(headerParams); // 加入自定义头
    Map<String, String> formParams = {};

    List<String> contentTypes = ["application/json"];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'POST', queryParams,
        postBody, headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// 用户注册
  ///
  ///
  Future<Map<String, dynamic>> apiAuthRegisterPost(
      {required RegisterRequest registerRequest}) async {
    try {
      Response response = await apiAuthRegisterPostWithHttpInfo(
          registerRequest: registerRequest);
      debugPrint('Register response status: ${response.statusCode}');
      debugPrint('Register response body: ${response.body}');

      if (response.statusCode >= 400) {
        throw ApiException(response.statusCode, _decodeBodyBytes(response));
      } else if (response.body.isNotEmpty) {
        return apiClient.deserialize(
                _decodeBodyBytes(response), 'Map<String, dynamic>')
            as Map<String, dynamic>;
      } else if (response.statusCode == 201) {
        return {'status': 'CREATED'}; // 默认成功响应
      } else {
        throw ApiException(response.statusCode, 'Empty response body');
      }
    } catch (e) {
      debugPrint('Register error: $e');
      rethrow;
    }
  }

  /// 使用 HTTP 信息获取所有用户
  ///
  ///
  Future<Response> apiAuthUsersGetWithHttpInfo() async {
    Object? postBody;

    // 验证必需参数已设置
    // 假设此端点无需必需参数

    // 创建路径和映射变量
    String path = "/api/auth/users".replaceAll("{format}", "json");

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// 获取所有用户
  ///
  ///
  Future<Object?> apiAuthUsersGet() async {
    Response response = await apiAuthUsersGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// 登录（WebSocket）
  Future<Object?> eventbusAuthLoginPost(
      {required LoginRequest loginRequest}) async {
    // 构造 message
    final msg = <String, dynamic>{
      "service": "Auth",
      "action": "login",
      "args": [
        // 这里序列化 loginRequest
        {"username": loginRequest.username, "password": loginRequest.password}
      ],
    };

    // 调用websocket
    final respMap = await apiClient.sendWsMessage(msg);

    // 解析返回
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
    // 构造 webSocket 消息
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
    // service=Auth, action=getAllUsers, 无参数 => args:[]
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
