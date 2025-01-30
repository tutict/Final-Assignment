import 'dart:convert';

import 'package:final_assignment_front/features/model/fine_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:http/http.dart'; // 用于 Response 和 MultipartRequest

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class FineInformationControllerApi {
  final ApiClient apiClient;

  // 更新后的构造函数，apiClient 参数可为空
  FineInformationControllerApi([ApiClient? apiClient])
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

  /// deleteFine with HTTP info returned
  ///
  ///
  Future<Response> apiFinesFineIdDeleteWithHttpInfo(
      {required String fineId}) async {
    Object postBody = ''; // DELETE 请求通常没有 body

    // 验证必需参数已设置
    if (fineId.isEmpty) {
      throw ApiException(400, "Missing required param: fineId");
    }

    // 创建路径和映射变量
    String path = "/api/fines/{fineId}"
        .replaceAll("{format}", "json")
        .replaceAll("{fineId}", fineId);

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

  /// deleteFine
  ///
  ///
  Future<Object?> apiFinesFineIdDelete({required String fineId}) async {
    Response response = await apiFinesFineIdDeleteWithHttpInfo(fineId: fineId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getFineById with HTTP info returned
  ///
  ///
  Future<Response> apiFinesFineIdGetWithHttpInfo(
      {required String fineId}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    if (fineId.isEmpty) {
      throw ApiException(400, "Missing required param: fineId");
    }

    // 创建路径和映射变量
    String path = "/api/fines/{fineId}"
        .replaceAll("{format}", "json")
        .replaceAll("{fineId}", fineId);

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

  /// getFineById
  ///
  ///
  Future<List<FineInformation>?> apiFinesFineIdGet(
      {required String fineId}) async {
    Response response = await apiFinesFineIdGetWithHttpInfo(fineId: fineId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
      return FineInformation.listFromJson(jsonList);
    } else {
      return null;
    }
  }

  /// updateFine with HTTP info returned
  ///
  ///
  Future<Response> apiFinesFineIdPutWithHttpInfo(
      {required String fineId, int? updateValue}) async {
    Object postBody = updateValue ?? 0; // 根据实际需求设置默认值

    // 验证必需参数已设置
    if (fineId.isEmpty) {
      throw ApiException(400, "Missing required param: fineId");
    }

    // 创建路径和映射变量
    String path = "/api/fines/{fineId}"
        .replaceAll("{format}", "json")
        .replaceAll("{fineId}", fineId);

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

  /// updateFine
  ///
  ///
  Future<Object?> apiFinesFineIdPut(
      {required String fineId, int? updateValue}) async {
    Response response = await apiFinesFineIdPutWithHttpInfo(
        fineId: fineId, updateValue: updateValue);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getAllFines with HTTP info returned
  ///
  ///
  Future<Response> apiFinesGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/fines".replaceAll("{format}", "json");

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

  /// getAllFines
  ///
  ///
  Future<List<Object>?> apiFinesGet() async {
    Response response = await apiFinesGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }

  /// getFinesByPayee with HTTP info returned
  ///
  ///
  Future<Response> apiFinesPayeePayeeGetWithHttpInfo(
      {required String payee}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    if (payee.isEmpty) {
      throw ApiException(400, "Missing required param: payee");
    }

    // 创建路径和映射变量
    String path = "/api/fines/payee/{payee}"
        .replaceAll("{format}", "json")
        .replaceAll("{payee}", payee);

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

  /// getFinesByPayee
  ///
  ///
  Future<Object?> apiFinesPayeePayeeGet({required String payee}) async {
    Response response = await apiFinesPayeePayeeGetWithHttpInfo(payee: payee);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// createFine with HTTP info returned
  ///
  ///
  Future<Response> apiFinesPostWithHttpInfo(
      {required FineInformation fineInformation}) async {
    Object postBody = fineInformation;

    // 创建路径和映射变量
    String path = "/api/fines".replaceAll("{format}", "json");

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

  /// createFine
  ///
  ///
  Future<Object?> apiFinesPost(
      {required FineInformation fineInformation}) async {
    Response response =
        await apiFinesPostWithHttpInfo(fineInformation: fineInformation);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getFineByReceiptNumber with HTTP info returned
  ///
  ///
  Future<Response> apiFinesReceiptNumberReceiptNumberGetWithHttpInfo(
      {required String receiptNumber}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    if (receiptNumber.isEmpty) {
      throw ApiException(400, "Missing required param: receiptNumber");
    }

    // 创建路径和映射变量
    String path = "/api/fines/receiptNumber/{receiptNumber}"
        .replaceAll("{format}", "json")
        .replaceAll("{receiptNumber}", receiptNumber);

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

  /// getFineByReceiptNumber
  ///
  ///
  Future<Object?> apiFinesReceiptNumberReceiptNumberGet(
      {required String receiptNumber}) async {
    Response response = await apiFinesReceiptNumberReceiptNumberGetWithHttpInfo(
        receiptNumber: receiptNumber);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getFinesByTimeRange with HTTP info returned
  ///
  ///
  Future<Response> apiFinesTimeRangeGetWithHttpInfo(
      {String? startTime, String? endTime}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    // 如果 startTime 和 endTime 是可选的，您可能不需要进行验证

    // 创建路径和映射变量
    String path = "/api/fines/timeRange".replaceAll("{format}", "json");

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

  /// getFinesByTimeRange
  ///
  ///
  Future<List<Object>?> apiFinesTimeRangeGet(
      {String? startTime, String? endTime}) async {
    Response response = await apiFinesTimeRangeGetWithHttpInfo(
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

  /// deleteFine (WebSocket)
  /// 对应后端: @WsAction(service="FineInformation", action="deleteFine")
  Future<Object?> eventbusFinesFineIdDelete({required String fineId}) async {
    // 1) 构造websocket消息
    final msg = {
      "service": "FineInformation",
      "action": "deleteFine",
      "args": [
        int.parse(fineId) // 假设deleteFine(int fineId)
      ]
    };

    // 2) 调用 sendWsMessage
    final respMap = await apiClient.sendWsMessage(msg);

    // 3) 检查 error/result
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"]; // or null if no result
  }

  /// getFineById (WebSocket)
  /// 对应后端: @WsAction(service="FineInformation", action="getFineById")
  Future<Object?> eventbusFinesFineIdGet({required String fineId}) async {
    final msg = {
      "service": "FineInformation",
      "action": "getFineById",
      "args": [int.parse(fineId)]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// updateFine (WebSocket)
  /// 对应后端: @WsAction(service="FineInformation", action="updateFine")
  Future<Object?> eventbusFinesFineIdPut(
      {required String fineId, int? updateValue}) async {
    final msg = {
      "service": "FineInformation",
      "action": "updateFine",
      "args": [int.parse(fineId), updateValue ?? 0]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// getAllFines (WebSocket)
  /// 对应后端: @WsAction(service="FineInformation", action="getAllFines")
  Future<List<Object>?> eventbusFinesGet() async {
    final msg = {
      "service": "FineInformation",
      "action": "getAllFines",
      "args": []
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    if (respMap["result"] is List) {
      return respMap["result"].cast<Object>();
    }
    return null;
  }

  /// getFinesByPayee (WebSocket)
  /// 对应后端: @WsAction(service="FineInformation", action="getFinesByPayee")
  Future<Object?> eventbusFinesPayeePayeeGet({required String payee}) async {
    if (payee.isEmpty) {
      throw ApiException(400, "Missing required param: payee");
    }

    final msg = {
      "service": "FineInformation",
      "action": "getFinesByPayee",
      "args": [payee]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// createFine (WebSocket)
  /// 对应后端: @WsAction(service="FineInformation", action="createFine")
  /// 可能签名: createFine(FineInformation fineInfo)
  Future<Object?> eventbusFinesPost(
      {required FineInformation fineInformation}) async {
    // 1) 序列化FineInformation => Map
    //   你可写 toJson
    final fiMap = fineInformation.toJson();
    // 2) 构造
    final msg = {
      "service": "FineInformation",
      "action": "createFine",
      "args": [fiMap]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// getFineByReceiptNumber (WebSocket)
  /// 对应后端: @WsAction(service="FineInformation", action="getFineByReceiptNumber")
  Future<Object?> eventbusFinesReceiptNumberReceiptNumberGet(
      {required String receiptNumber}) async {
    if (receiptNumber.isEmpty) {
      throw ApiException(400, "Missing required param: receiptNumber");
    }

    final msg = {
      "service": "FineInformation",
      "action": "getFineByReceiptNumber",
      "args": [receiptNumber]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }
}
