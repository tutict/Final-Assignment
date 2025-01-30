import 'package:final_assignment_front/features/model/system_logs.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:http/http.dart'; // 用于 Response 和 MultipartRequest

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class SystemLogsControllerApi {
  final ApiClient apiClient;

  // 更新后的构造函数，apiClient 参数可为空
  SystemLogsControllerApi([ApiClient? apiClient])
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

  /// getAllSystemLogs with HTTP info returned
  ///
  ///
  Future<Response> apiSystemLogsGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/systemLogs".replaceAll("{format}", "json");

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

  /// getAllSystemLogs
  ///
  ///
  Future<List<Object>?> apiSystemLogsGet() async {
    Response response = await apiSystemLogsGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }

  /// deleteSystemLog with HTTP info returned
  ///
  ///
  Future<Response> apiSystemLogsLogIdDeleteWithHttpInfo(
      {required String logId}) async {
    Object postBody = ''; // DELETE 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/systemLogs/{logId}"
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

  /// deleteSystemLog
  ///
  ///
  Future<Object?> apiSystemLogsLogIdDelete({required String logId}) async {
    Response response =
        await apiSystemLogsLogIdDeleteWithHttpInfo(logId: logId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getSystemLogById with HTTP info returned
  ///
  ///
  Future<Response> apiSystemLogsLogIdGetWithHttpInfo(
      {required String logId}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/systemLogs/{logId}"
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

  /// getSystemLogById
  ///
  ///
  Future<Object?> apiSystemLogsLogIdGet({required String logId}) async {
    Response response = await apiSystemLogsLogIdGetWithHttpInfo(logId: logId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// updateSystemLog with HTTP info returned
  ///
  ///
  Future<Response> apiSystemLogsLogIdPutWithHttpInfo(
      {required String logId, int? updateValue}) async {
    Object postBody = updateValue ?? 0; // 根据实际需求设置默认值

    // 创建路径和映射变量
    String path = "/api/systemLogs/{logId}"
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

  /// updateSystemLog
  ///
  ///
  Future<Object?> apiSystemLogsLogIdPut(
      {required String logId, int? updateValue}) async {
    Response response = await apiSystemLogsLogIdPutWithHttpInfo(
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

  /// getSystemLogsByOperationUser with HTTP info returned
  ///
  ///
  Future<Response> apiSystemLogsOperationUserOperationUserGetWithHttpInfo(
      {required String operationUser}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/systemLogs/operationUser/{operationUser}"
        .replaceAll("{format}", "json")
        .replaceAll("{operationUser}", operationUser);

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

  /// getSystemLogsByOperationUser
  ///
  ///
  Future<List<Object>?> apiSystemLogsOperationUserOperationUserGet(
      {required String operationUser}) async {
    Response response =
        await apiSystemLogsOperationUserOperationUserGetWithHttpInfo(
            operationUser: operationUser);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }

  /// createSystemLog with HTTP info returned
  ///
  ///
  Future<Response> apiSystemLogsPostWithHttpInfo(
      {required SystemLogs systemLogs}) async {
    Object postBody = systemLogs;

    // 创建路径和映射变量
    String path = "/api/systemLogs".replaceAll("{format}", "json");

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

  /// createSystemLog
  ///
  ///
  Future<Object?> apiSystemLogsPost({required SystemLogs systemLogs}) async {
    Response response =
        await apiSystemLogsPostWithHttpInfo(systemLogs: systemLogs);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getSystemLogsByTimeRange with HTTP info returned
  ///
  ///
  Future<Response> apiSystemLogsTimeRangeGetWithHttpInfo(
      {String? startTime, String? endTime}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/systemLogs/timeRange".replaceAll("{format}", "json");

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

  /// getSystemLogsByTimeRange
  ///
  ///
  Future<List<Object>?> apiSystemLogsTimeRangeGet(
      {String? startTime, String? endTime}) async {
    Response response = await apiSystemLogsTimeRangeGetWithHttpInfo(
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

  /// getSystemLogsByType with HTTP info returned
  ///
  ///
  Future<Response> apiSystemLogsTypeLogTypeGetWithHttpInfo(
      {required String logType}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/systemLogs/type/{logType}"
        .replaceAll("{format}", "json")
        .replaceAll("{logType}", logType);

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

  /// getSystemLogsByType
  ///
  ///
  Future<List<Object>?> apiSystemLogsTypeLogTypeGet(
      {required String logType}) async {
    Response response =
        await apiSystemLogsTypeLogTypeGetWithHttpInfo(logType: logType);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }

  /// getAllSystemLogs (WebSocket)
  /// 对应后端: @WsAction(service="SystemLogsService", action="getAllSystemLogs")
  Future<List<Object>?> eventbusSystemLogsGet() async {
    final msg = {
      "service": "SystemLogsService",
      "action": "getAllSystemLogs",
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

  /// deleteSystemLog (WebSocket)
  /// 对应后端: @WsAction(service="SystemLogsService", action="deleteSystemLog")
  Future<Object?> eventbusSystemLogsLogIdDelete({required String logId}) async {
    final msg = {
      "service": "SystemLogsService",
      "action": "deleteSystemLog",
      "args": [int.parse(logId)] // 如果后端方法签名是: deleteSystemLog(int logId)
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// getSystemLogById (WebSocket)
  /// 对应后端: @WsAction(service="SystemLogsService", action="getSystemLogById")
  Future<Object?> eventbusSystemLogsLogIdGet({required String logId}) async {
    final msg = {
      "service": "SystemLogsService",
      "action": "getSystemLogById",
      "args": [int.parse(logId)]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// updateSystemLog (WebSocket)
  /// 对应后端: @WsAction(service="SystemLogsService", action="updateSystemLog")
  /// 例如: updateSystemLog(int logId, int updateValue)
  Future<Object?> eventbusSystemLogsLogIdPut(
      {required String logId, int? updateValue}) async {
    final msg = {
      "service": "SystemLogsService",
      "action": "updateSystemLog",
      "args": [int.parse(logId), updateValue ?? 0]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// getSystemLogsByOperationUser (WebSocket)
  /// 对应后端: @WsAction(service="SystemLogsService", action="getSystemLogsByOperationUser")
  Future<List<Object>?> eventbusSystemLogsOperationUserOperationUserGet(
      {required String operationUser}) async {
    final msg = {
      "service": "SystemLogsService",
      "action": "getSystemLogsByOperationUser",
      "args": [operationUser]
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

  /// createSystemLog (WebSocket)
  /// 对应后端: @WsAction(service="SystemLogsService", action="createSystemLog")
  Future<Object?> eventbusSystemLogsPost(
      {required SystemLogs systemLogs}) async {
    // 序列化
    final logsMap = systemLogs.toJson();

    final msg = {
      "service": "SystemLogsService",
      "action": "createSystemLog",
      "args": [logsMap]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// getSystemLogsByTimeRange (WebSocket)
  /// 对应后端: @WsAction(service="SystemLogsService", action="getSystemLogsByTimeRange")
  Future<List<Object>?> eventbusSystemLogsTimeRangeGet(
      {String? startTime, String? endTime}) async {
    final msg = {
      "service": "SystemLogsService",
      "action": "getSystemLogsByTimeRange",
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

  /// getSystemLogsByType (WebSocket)
  /// 对应后端: @WsAction(service="SystemLogsService", action="getSystemLogsByType")
  Future<List<Object>?> eventbusSystemLogsTypeLogTypeGet(
      {required String logType}) async {
    final msg = {
      "service": "SystemLogsService",
      "action": "getSystemLogsByType",
      "args": [logType]
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
}
