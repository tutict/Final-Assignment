import 'package:final_assignment_front/features/model/operation_log.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:http/http.dart'; // 用于 Response 和 MultipartRequest

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class OperationLogControllerApi {
  final ApiClient apiClient;

  // 更新后的构造函数，apiClient 参数可为空
  OperationLogControllerApi([ApiClient? apiClient])
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

  /// getAllOperationLogs with HTTP info returned
  ///
  ///
  Future<Response> apiOperationLogsGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/operationLogs".replaceAll("{format}", "json");

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

  /// getAllOperationLogs
  ///
  ///
  Future<List<Object>?> apiOperationLogsGet() async {
    Response response = await apiOperationLogsGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }

  /// deleteOperationLog with HTTP info returned
  ///
  ///
  Future<Response> apiOperationLogsLogIdDeleteWithHttpInfo(
      {required String logId}) async {
    Object postBody = ''; // DELETE 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/operationLogs/{logId}"
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

  /// deleteOperationLog
  ///
  ///
  Future<Object?> apiOperationLogsLogIdDelete({required String logId}) async {
    Response response =
        await apiOperationLogsLogIdDeleteWithHttpInfo(logId: logId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getOperationLog with HTTP info returned
  ///
  ///
  Future<Response> apiOperationLogsLogIdGetWithHttpInfo(
      {required String logId}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/operationLogs/{logId}"
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

  /// getOperationLog
  ///
  ///
  Future<Object?> apiOperationLogsLogIdGet({required String logId}) async {
    Response response =
        await apiOperationLogsLogIdGetWithHttpInfo(logId: logId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// updateOperationLog with HTTP info returned
  ///
  ///
  Future<Response> apiOperationLogsLogIdPutWithHttpInfo(
      {required String logId, int? updateValue}) async {
    Object postBody = updateValue ?? 0; // 根据实际需求设置默认值

    // 创建路径和映射变量
    String path = "/api/operationLogs/{logId}"
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

  /// updateOperationLog
  ///
  ///
  Future<Object?> apiOperationLogsLogIdPut(
      {required String logId, int? updateValue}) async {
    Response response = await apiOperationLogsLogIdPutWithHttpInfo(
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

  /// createOperationLog with HTTP info returned
  ///
  ///
  Future<Response> apiOperationLogsPostWithHttpInfo(
      {required OperationLog operationLog}) async {
    Object postBody = operationLog;

    // 创建路径和映射变量
    String path = "/api/operationLogs".replaceAll("{format}", "json");

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

  /// createOperationLog
  ///
  ///
  Future<Object?> apiOperationLogsPost(
      {required OperationLog operationLog}) async {
    Response response =
        await apiOperationLogsPostWithHttpInfo(operationLog: operationLog);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getOperationLogsByResult with HTTP info returned
  ///
  ///
  Future<Response> apiOperationLogsResultResultGetWithHttpInfo(
      {required String result}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/operationLogs/result/{result}"
        .replaceAll("{format}", "json")
        .replaceAll("{result}", result);

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

  /// getOperationLogsByResult
  ///
  ///
  Future<List<Object>?> apiOperationLogsResultResultGet(
      {required String result}) async {
    Response response =
        await apiOperationLogsResultResultGetWithHttpInfo(result: result);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }

  /// getOperationLogsByTimeRange with HTTP info returned
  ///
  ///
  Future<Response> apiOperationLogsTimeRangeGetWithHttpInfo(
      {String? startTime, String? endTime}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/operationLogs/timeRange".replaceAll("{format}", "json");

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

  /// getOperationLogsByTimeRange
  ///
  ///
  Future<List<Object>?> apiOperationLogsTimeRangeGet(
      {String? startTime, String? endTime}) async {
    Response response = await apiOperationLogsTimeRangeGetWithHttpInfo(
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

  /// getOperationLogsByUserId with HTTP info returned
  ///
  ///
  Future<Response> apiOperationLogsUserIdUserIdGetWithHttpInfo(
      {required String userId}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/operationLogs/userId/{userId}"
        .replaceAll("{format}", "json")
        .replaceAll("{userId}", userId);

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

  /// getOperationLogsByUserId
  ///
  ///
  Future<List<Object>?> apiOperationLogsUserIdUserIdGet(
      {required String userId}) async {
    Response response =
        await apiOperationLogsUserIdUserIdGetWithHttpInfo(userId: userId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }

  /// getAllOperationLogs (WebSocket)
  /// 对应后端: @WsAction(service="OperationLogService", action="getAllOperationLogs")
  Future<List<Object>?> eventbusOperationLogsGet() async {
    final msg = {
      "service": "OperationLogService",
      "action": "getAllOperationLogs",
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

  /// deleteOperationLog (WebSocket)
  /// 对应后端: @WsAction(service="OperationLogService", action="deleteOperationLog")
  Future<Object?> eventbusOperationLogsLogIdDelete(
      {required String logId}) async {
    // 这里看后端是 String or int
    final msg = {
      "service": "OperationLogService",
      "action": "deleteOperationLog",
      "args": [int.parse(logId)] // 如果后端方法是 deleteOperationLog(int logId)
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// getOperationLog (WebSocket)
  /// 对应后端: @WsAction(service="OperationLogService", action="getOperationLog")
  Future<Object?> eventbusOperationLogsLogIdGet({required String logId}) async {
    final msg = {
      "service": "OperationLogService",
      "action": "getOperationLog",
      "args": [int.parse(logId)]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// updateOperationLog (WebSocket)
  /// 对应后端: @WsAction(service="OperationLogService", action="updateOperationLog")
  Future<Object?> eventbusOperationLogsLogIdPut(
      {required String logId, int? updateValue}) async {
    final msg = {
      "service": "OperationLogService",
      "action": "updateOperationLog",
      "args": [
        int.parse(logId),
        updateValue ?? 0 // 或者根据你的后端参数签名
      ]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// createOperationLog (WebSocket)
  /// 对应后端: @WsAction(service="OperationLogService", action="createOperationLog")
  Future<Object?> eventbusOperationLogsPost(
      {required OperationLog operationLog}) async {
    // 序列化
    final opLogMap = operationLog.toJson();
    final msg = {
      "service": "OperationLogService",
      "action": "createOperationLog",
      "args": [opLogMap]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// getOperationLogsByResult (WebSocket)
  /// 对应后端: @WsAction(service="OperationLogService", action="getOperationLogsByResult")
  Future<List<Object>?> eventbusOperationLogsResultResultGet(
      {required String result}) async {
    final msg = {
      "service": "OperationLogService",
      "action": "getOperationLogsByResult",
      "args": [result]
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

  /// getOperationLogsByTimeRange (WebSocket)
  /// 对应后端: @WsAction(service="OperationLogService", action="getOperationLogsByTimeRange")
  Future<List<Object>?> eventbusOperationLogsTimeRangeGet(
      {String? startTime, String? endTime}) async {
    final msg = {
      "service": "OperationLogService",
      "action": "getOperationLogsByTimeRange",
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

  /// getOperationLogsByUserId (WebSocket)
  /// 对应后端: @WsAction(service="OperationLogService", action="getOperationLogsByUserId")
  Future<List<Object>?> eventbusOperationLogsUserIdUserIdGet(
      {required String userId}) async {
    final msg = {
      "service": "OperationLogService",
      "action": "getOperationLogsByUserId",
      "args": [int.parse(userId)] // 假设是 int userId
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
