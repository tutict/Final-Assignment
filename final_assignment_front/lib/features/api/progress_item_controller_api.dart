// progress_controller_api.dart
import 'package:final_assignment_front/features/model/progress_item.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // 用于 Response
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class ProgressControllerApi {
  final ApiClient apiClient;

  // 更新后的构造函数，apiClient 参数可为空
  ProgressControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  /// 从 SharedPreferences 中读取 jwtToken 并设置到 ApiClient 中
  Future<void> initializeWithJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('未登录，请重新登录');
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint('Initialized SystemSettingsControllerApi with token: $jwtToken');
  }

  // 解码响应体的辅助方法
  String _decodeBodyBytes(http.Response response) {
    return response.body;
  }

  // 辅助方法：转换查询参数
  List<QueryParam> _convertParametersForCollectionFormat(
      String collectionFormat, String name, dynamic value) {
    return [QueryParam(name, value.toString())];
  }

  /// 创建新的进度记录。 with HTTP info returned
  ///
  Future<http.Response> apiProgressPostWithHttpInfo({
    required ProgressItem progressItem,
    Map<String, String>? headers,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw ApiException(401, 'No JWT token found');
    }

    Object postBody = progressItem;

    // 创建路径和映射变量
    String path = "/api/progress".replaceAll("{format}", "json");

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {
      ...?headers,
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    };
    Map<String, String> formParams = {};

    List<String> contentTypes = ["application/json"];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'POST', queryParams,
        postBody, headerParams, formParams, nullableContentType, authNames);
    return response as http.Response;
  }

  /// 创建新的进度记录。
  ///
  Future<ProgressItem> apiProgressPost({
    required ProgressItem progressItem,
    Map<String, String>? headers,
  }) async {
    http.Response response = await apiProgressPostWithHttpInfo(
        progressItem: progressItem, headers: headers);
    if (response.statusCode == 201) {
      return ProgressItem.fromJson(jsonDecode(_decodeBodyBytes(response)));
    }
    throw ApiException(response.statusCode, _decodeBodyBytes(response));
  }

  /// 获取所有进度记录。 with HTTP info returned
  ///
  Future<http.Response> apiProgressGetWithHttpInfo({
    Map<String, String>? headers,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw ApiException(401, 'No JWT token found');
    }

    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/progress".replaceAll("{format}", "json");

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {
      ...?headers,
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    };
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response as http.Response;
  }

  /// 获取所有进度记录。
  ///
  Future<List<ProgressItem>> apiProgressGet({
    Map<String, String>? headers,
  }) async {
    http.Response response = await apiProgressGetWithHttpInfo(headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(_decodeBodyBytes(response));
      return data.map((json) => ProgressItem.fromJson(json)).toList();
    }
    throw ApiException(response.statusCode, _decodeBodyBytes(response));
  }

  /// 根据用户名获取进度记录。 with HTTP info returned
  ///
  Future<http.Response> apiProgressUsernameGetWithHttpInfo({
    required String username,
    Map<String, String>? headers,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw ApiException(401, 'No JWT token found');
    }

    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/progress".replaceAll("{format}", "json");

    // 查询参数
    List<QueryParam> queryParams = [
      QueryParam('username', username),
    ];
    Map<String, String> headerParams = {
      ...?headers,
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    };
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response as http.Response;
  }

  /// 根据用户名获取进度记录。
  ///
  Future<List<ProgressItem>> apiProgressUsernameGet({
    required String username,
    Map<String, String>? headers,
  }) async {
    http.Response response = await apiProgressUsernameGetWithHttpInfo(
        username: username, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(_decodeBodyBytes(response));
      return data.map((json) => ProgressItem.fromJson(json)).toList();
    }
    throw ApiException(response.statusCode, _decodeBodyBytes(response));
  }

  /// 根据进度ID更新进度状态。 with HTTP info returned
  ///
  Future<http.Response> apiProgressProgressIdPutWithHttpInfo({
    required int progressId,
    required ProgressItem progressItem,
    Map<String, String>? headers,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw ApiException(401, 'No JWT token found');
    }

    Object postBody = {
      'status': progressItem.status,
      'details': progressItem.details,
    };

    // 创建路径和映射变量
    String path = "/api/progress/$progressId".replaceAll("{format}", "json");

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {
      ...?headers,
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    };
    Map<String, String> formParams = {};

    List<String> contentTypes = ["application/json"];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'PUT', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response as http.Response;
  }

  /// 根据进度ID更新进度状态。
  ///
  Future<ProgressItem> apiProgressProgressIdPut({
    required int progressId,
    required ProgressItem progressItem,
    Map<String, String>? headers,
  }) async {
    http.Response response = await apiProgressProgressIdPutWithHttpInfo(
        progressId: progressId, progressItem: progressItem, headers: headers);
    if (response.statusCode == 200) {
      return ProgressItem.fromJson(jsonDecode(_decodeBodyBytes(response)));
    }
    throw ApiException(response.statusCode, _decodeBodyBytes(response));
  }

  /// 删除指定进度记录。 with HTTP info returned
  ///
  Future<http.Response> apiProgressProgressIdDeleteWithHttpInfo({
    required int progressId,
    Map<String, String>? headers,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw ApiException(401, 'No JWT token found');
    }

    Object postBody = ''; // DELETE 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/progress/$progressId".replaceAll("{format}", "json");

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {
      ...?headers,
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    };
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'DELETE', queryParams,
        postBody, headerParams, formParams, nullableContentType, authNames);
    return response as http.Response;
  }

  /// 删除指定进度记录。
  ///
  Future<void> apiProgressProgressIdDelete({
    required int progressId,
    Map<String, String>? headers,
  }) async {
    http.Response response = await apiProgressProgressIdDeleteWithHttpInfo(
        progressId: progressId, headers: headers);
    if (response.statusCode != 204) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// 根据状态获取进度记录。 with HTTP info returned
  ///
  Future<http.Response> apiProgressStatusStatusGetWithHttpInfo({
    required String status,
    Map<String, String>? headers,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw ApiException(401, 'No JWT token found');
    }

    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/progress/status/$status".replaceAll("{format}", "json");

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {
      ...?headers,
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    };
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response as http.Response;
  }

  /// 根据状态获取进度记录。
  ///
  Future<List<ProgressItem>> apiProgressStatusStatusGet({
    required String status,
    Map<String, String>? headers,
  }) async {
    http.Response response = await apiProgressStatusStatusGetWithHttpInfo(
        status: status, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(_decodeBodyBytes(response));
      return data.map((json) => ProgressItem.fromJson(json)).toList();
    }
    throw ApiException(response.statusCode, _decodeBodyBytes(response));
  }

  /// 根据时间范围获取进度记录。 with HTTP info returned
  ///
  Future<http.Response> apiProgressTimeRangeGetWithHttpInfo({
    String? startTime,
    String? endTime,
    Map<String, String>? headers,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw ApiException(401, 'No JWT token found');
    }

    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/progress/timeRange".replaceAll("{format}", "json");

    // 查询参数
    List<QueryParam> queryParams = [];
    if (startTime != null) {
      queryParams.addAll(
          _convertParametersForCollectionFormat("", "startTime", startTime));
    }
    if (endTime != null) {
      queryParams.addAll(
          _convertParametersForCollectionFormat("", "endTime", endTime));
    }
    Map<String, String> headerParams = {
      ...?headers,
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    };
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response as http.Response;
  }

  /// 根据时间范围获取进度记录。
  ///
  Future<List<ProgressItem>> apiProgressTimeRangeGet({
    String? startTime,
    String? endTime,
    Map<String, String>? headers,
  }) async {
    http.Response response = await apiProgressTimeRangeGetWithHttpInfo(
        startTime: startTime, endTime: endTime, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(_decodeBodyBytes(response));
      return data.map((json) => ProgressItem.fromJson(json)).toList();
    }
    throw ApiException(response.statusCode, _decodeBodyBytes(response));
  }

  /// 根据用户名获取进度记录 (WebSocket)
  /// 对应后端: @WsAction(service="ProgressItem", action="getProgressByUsername")
  Future<List<Object>?> eventbusProgressUsernameGet({
    required String username,
  }) async {
    final msg = {
      "service": "ProgressItem",
      "action": "getProgressByUsername",
      "args": [username]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    if (respMap["result"] is List) {
      return (respMap["result"] as List).cast<Object>();
    }
    return null;
  }

  /// 获取所有进度记录 (WebSocket)
  /// 对应 @WsAction(service="ProgressItem", action="getAllProgress")
  Future<List<Object>?> eventbusProgressGet() async {
    final msg = {
      "service": "ProgressItem",
      "action": "getAllProgress",
      "args": []
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    if (respMap["result"] is List) {
      return (respMap["result"] as List).cast<Object>();
    }
    return null;
  }

  /// 根据状态获取进度记录 (WebSocket)
  /// 对应 @WsAction(service="ProgressItem", action="getProgressByStatus")
  Future<List<Object>?> eventbusProgressStatusStatusGet({
    required String status,
  }) async {
    final msg = {
      "service": "ProgressItem",
      "action": "getProgressByStatus",
      "args": [status]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    if (respMap["result"] is List) {
      return (respMap["result"] as List).cast<Object>();
    }
    return null;
  }

  /// 根据时间范围获取进度记录 (WebSocket)
  /// 对应 @WsAction(service="ProgressItem", action="getProgressByTimeRange")
  Future<List<Object>?> eventbusProgressTimeRangeGet({
    String? startTime,
    String? endTime,
  }) async {
    final msg = {
      "service": "ProgressItem",
      "action": "getProgressByTimeRange",
      "args": [startTime ?? "", endTime ?? ""]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    if (respMap["result"] is List) {
      return (respMap["result"] as List).cast<Object>();
    }
    return null;
  }

  /// 根据进度ID删除进度记录 (WebSocket)
  /// 对应 @WsAction(service="ProgressItem", action="deleteProgress")
  Future<Object?> eventbusProgressProgressIdDelete({
    required int progressId,
  }) async {
    final msg = {
      "service": "ProgressItem",
      "action": "deleteProgress",
      "args": [progressId]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// 根据进度ID获取进度记录 (WebSocket)
  /// 对应 @WsAction(service="ProgressItem", action="getProgressById")
  Future<Object?> eventbusProgressProgressIdGet({
    required int progressId,
  }) async {
    final msg = {
      "service": "ProgressItem",
      "action": "getProgressById",
      "args": [progressId]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// 根据进度ID更新进度状态 (WebSocket)
  /// 对应 @WsAction(service="ProgressItem", action="updateProgressStatus")
  Future<Object?> eventbusProgressProgressIdPut({
    required int progressId,
    required ProgressItem progressItem,
  }) async {
    final msg = {
      "service": "ProgressItem",
      "action": "updateProgressStatus",
      "args": [progressId, progressItem.toJson()]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }
}
