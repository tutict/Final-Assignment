import 'package:final_assignment_front/features/model/login_request.dart';
import 'package:final_assignment_front/features/model/register_request.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
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
  String _decodeBodyBytes(Response response) {
    return response.body;
  }

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
  Future<Object?> apiAuthRegisterPost(
      {required RegisterRequest registerRequest}) async {
    Response response =
        await apiAuthRegisterPostWithHttpInfo(registerRequest: registerRequest);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
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

  /// 使用 HTTP 信息进行登录（事件总线）
  ///
  ///
  Future<Response> eventbusAuthLoginPostWithHttpInfo(
      {required LoginRequest loginRequest}) async {
    Object postBody = loginRequest;

    // 验证必需参数已设置
    // 因为使用了 'required'，无需检查是否为 null

    // 创建路径和映射变量
    String path = "/eventbus/auth/login".replaceAll("{format}", "json");

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

  /// 登录（事件总线）
  ///
  ///
  Future<Object?> eventbusAuthLoginPost(
      {required LoginRequest loginRequest}) async {
    Response response =
        await eventbusAuthLoginPostWithHttpInfo(loginRequest: loginRequest);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// 使用 HTTP 信息进行用户注册（事件总线）
  ///
  ///
  Future<Response> eventbusAuthRegisterPostWithHttpInfo(
      {required RegisterRequest registerRequest}) async {
    Object postBody = registerRequest;

    // 验证必需参数已设置
    // 因为使用了 'required'，无需检查是否为 null

    // 创建路径和映射变量
    String path = "/eventbus/auth/register".replaceAll("{format}", "json");

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

  /// 用户注册（事件总线）
  ///
  ///
  Future<Object?> eventbusAuthRegisterPost(
      {required RegisterRequest registerRequest}) async {
    Response response = await eventbusAuthRegisterPostWithHttpInfo(
        registerRequest: registerRequest);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// 使用 HTTP 信息获取所有用户（事件总线）
  ///
  ///
  Future<Response> eventbusAuthUsersGetWithHttpInfo() async {
    Object? postBody;

    // 验证必需参数已设置
    // 假设此端点无需必需参数

    // 创建路径和映射变量
    String path = "/eventbus/auth/users".replaceAll("{format}", "json");

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

  /// 获取所有用户（事件总线）
  ///
  ///
  Future<Object?> eventbusAuthUsersGet() async {
    Response response = await eventbusAuthUsersGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }
}
