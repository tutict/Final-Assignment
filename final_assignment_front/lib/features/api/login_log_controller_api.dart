import 'package:final_assignment_front/features/model/login_log.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:http/http.dart'; // 用于 Response 和 MultipartRequest

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class LoginLogControllerApi {
  final ApiClient apiClient;

  // 更新后的构造函数，apiClient 参数可为空
  LoginLogControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  // 解码响应体的辅助方法
  String _decodeBodyBytes(Response response) {
    return response.body;
  }

  // 辅助方法：转换查询参数
  List<QueryParam> _convertParametersForCollectionFormat(
      String collectionFormat, String name, dynamic value) {
    // 根据 collectionFormat 实现参数转换逻辑
    // 这里提供一个简单的实现示例
    return [QueryParam(name, value.toString())];
  }

  /// getAllLoginLogs with HTTP info returned
  ///
  ///
  Future<Response> apiLoginLogsGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/loginLogs".replaceAll("{format}", "json");

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

  /// getAllLoginLogs
  ///
  ///
  Future<List<Object>?> apiLoginLogsGet() async {
    Response response = await apiLoginLogsGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }

  /// deleteLoginLog with HTTP info returned
  ///
  ///
  Future<Response> apiLoginLogsLogIdDeleteWithHttpInfo(
      {required String logId}) async {
    Object postBody = ''; // DELETE 请求通常没有 body

    // 验证必需参数已设置
    if (logId.isEmpty) {
      throw ApiException(400, "Missing required param: logId");
    }

    // 创建路径和映射变量
    String path = "/api/loginLogs/{logId}"
        .replaceAll("{format}", "json")
        .replaceAll("{logId}", logId);

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'DELETE', queryParams,
        postBody, headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// deleteLoginLog
  ///
  ///
  Future<Object?> apiLoginLogsLogIdDelete({required String logId}) async {
    Response response = await apiLoginLogsLogIdDeleteWithHttpInfo(logId: logId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getLoginLog with HTTP info returned
  ///
  ///
  Future<Response> apiLoginLogsLogIdGetWithHttpInfo(
      {required String logId}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    if (logId.isEmpty) {
      throw ApiException(400, "Missing required param: logId");
    }

    // 创建路径和映射变量
    String path = "/api/loginLogs/{logId}"
        .replaceAll("{format}", "json")
        .replaceAll("{logId}", logId);

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

  /// getLoginLog
  ///
  ///
  Future<Object?> apiLoginLogsLogIdGet({required String logId}) async {
    Response response = await apiLoginLogsLogIdGetWithHttpInfo(logId: logId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// updateLoginLog with HTTP info returned
  ///
  ///
  Future<Response> apiLoginLogsLogIdPutWithHttpInfo(
      {required String logId, int? updateValue}) async {
    Object postBody = updateValue ?? 0; // 根据实际需求设置默认值

    // 验证必需参数已设置
    if (logId.isEmpty) {
      throw ApiException(400, "Missing required param: logId");
    }

    // 创建路径和映射变量
    String path = "/api/loginLogs/{logId}"
        .replaceAll("{format}", "json")
        .replaceAll("{logId}", logId);

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = ["application/json"];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'PUT', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// updateLoginLog
  ///
  ///
  Future<Object?> apiLoginLogsLogIdPut(
      {required String logId, int? updateValue}) async {
    Response response = await apiLoginLogsLogIdPutWithHttpInfo(
        logId: logId, updateValue: updateValue);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getLoginLogsByLoginResult with HTTP info returned
  ///
  ///
  Future<Response> apiLoginLogsLoginResultLoginResultGetWithHttpInfo(
      {required String loginResult}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    if (loginResult.isEmpty) {
      throw ApiException(400, "Missing required param: loginResult");
    }

    // 创建路径和映射变量
    String path = "/api/loginLogs/loginResult/{loginResult}"
        .replaceAll("{format}", "json")
        .replaceAll("{loginResult}", loginResult);

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

  /// getLoginLogsByLoginResult
  ///
  ///
  Future<Object?> apiLoginLogsLoginResultLoginResultGet(
      {required String loginResult}) async {
    Response response = await apiLoginLogsLoginResultLoginResultGetWithHttpInfo(
        loginResult: loginResult);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// createLoginLog with HTTP info returned
  ///
  ///
  Future<Response> apiLoginLogsPostWithHttpInfo(
      {required LoginLog loginLog}) async {
    Object postBody = loginLog;

    // 创建路径和映射变量
    String path = "/api/loginLogs".replaceAll("{format}", "json");

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

  /// createLoginLog
  ///
  ///
  Future<Object?> apiLoginLogsPost({required LoginLog loginLog}) async {
    Response response = await apiLoginLogsPostWithHttpInfo(loginLog: loginLog);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getLoginLogsByTimeRange with HTTP info returned
  ///
  ///
  Future<Response> apiLoginLogsTimeRangeGetWithHttpInfo(
      {String? startTime, String? endTime}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/loginLogs/timeRange".replaceAll("{format}", "json");

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};
    if (startTime != null) {
      queryParams.addAll(
          _convertParametersForCollectionFormat("", "startTime", startTime));
    }
    if (endTime != null) {
      queryParams.addAll(
          _convertParametersForCollectionFormat("", "endTime", endTime));
    }

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// getLoginLogsByTimeRange
  ///
  ///
  Future<List<Object>?> apiLoginLogsTimeRangeGet(
      {String? startTime, String? endTime}) async {
    Response response = await apiLoginLogsTimeRangeGetWithHttpInfo(
        startTime: startTime, endTime: endTime);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }

  /// getLoginLogsByUsername with HTTP info returned
  ///
  ///
  Future<Response> apiLoginLogsUsernameUsernameGetWithHttpInfo(
      {required String username}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    if (username.isEmpty) {
      throw ApiException(400, "Missing required param: username");
    }

    // 创建路径和映射变量
    String path = "/api/loginLogs/username/{username}"
        .replaceAll("{format}", "json")
        .replaceAll("{username}", username);

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

  /// getLoginLogsByUsername
  ///
  ///
  Future<Object?> apiLoginLogsUsernameUsernameGet(
      {required String username}) async {
    Response response =
        await apiLoginLogsUsernameUsernameGetWithHttpInfo(username: username);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// createLoginLog (WebSocket)
  /// 对应后端: @WsAction(service="LoginLogService", action="createLoginLog")
  Future<Object?> eventbusLoginLogsPost({required LoginLog loginLog}) async {
    // 1) 将 loginLog => Map
    final logMap = loginLog.toJson();
    // 2) 构造请求
    final msg = {
      "service": "LoginLogService",
      "action": "createLoginLog",
      "args": [logMap]
    };

    // 3) 发送
    final respMap = await apiClient.sendWsMessage(msg);

    // 4) 判断 error/result
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// getLoginLogsByTimeRange (WebSocket)
  /// 对应后端: @WsAction(service="LoginLogService", action="getLoginLogsByTimeRange")
  Future<List<Object>?> eventbusLoginLogsTimeRangeGet(
      {String? startTime, String? endTime}) async {
    // 这里可能后端方法签名: getLoginLogsByTimeRange(String start, String end)
    // => 2个参数
    final msg = {
      "service": "LoginLogService",
      "action": "getLoginLogsByTimeRange",
      "args": [startTime ?? "", endTime ?? ""]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    // 如果 result 是个列表
    if (respMap["result"] is List) {
      return respMap["result"].cast<Object>();
    }
    return null;
  }

  /// getLoginLogsByUsername (WebSocket)
  /// 对应后端: @WsAction(service="LoginLogService", action="getLoginLogsByUsername")
  Future<Object?> eventbusLoginLogsUsernameUsernameGet(
      {required String username}) async {
    if (username.isEmpty) {
      throw ApiException(400, "Missing required param: username");
    }

    final msg = {
      "service": "LoginLogService",
      "action": "getLoginLogsByUsername",
      "args": [username]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }
}
