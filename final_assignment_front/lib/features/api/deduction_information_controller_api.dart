import 'package:final_assignment_front/features/model/deduction_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class DeductionInformationControllerApi {
  final ApiClient apiClient;

  /// 构造函数，可传入 ApiClient，否则使用全局默认实例
  DeductionInformationControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  /// 从 SharedPreferences 中读取 jwtToken 并设置到 ApiClient 中
  Future<void> initializeWithJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('未登录，请重新登录');
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint(
        'Initialized DeductionInformationControllerApi with token: $jwtToken');
  }

  /// 解码响应体字节到字符串
  String _decodeBodyBytes(Response response) => response.body;

  /// 辅助方法：添加查询参数（如时间范围）
  List<QueryParam> _addQueryParams({String? startTime, String? endTime}) {
    final queryParams = <QueryParam>[];
    if (startTime != null) queryParams.add(QueryParam('startTime', startTime));
    if (endTime != null) queryParams.add(QueryParam('endTime', endTime));
    return queryParams;
  }

  /// DELETE /api/deductions/{deductionId} - 删除扣分记录 (仅管理员)
  Future<void> apiDeductionsDeductionIdDelete(
      {required String deductionId}) async {
    if (deductionId.isEmpty) {
      throw ApiException(400, "Missing required param: deductionId");
    }
    final response = await apiClient.invokeAPI(
      '/api/deductions/$deductionId',
      'DELETE',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// GET /api/deductions/{deductionId} - 根据ID获取扣分记录
  Future<DeductionInformation?> apiDeductionsDeductionIdGet(
      {required String deductionId}) async {
    if (deductionId.isEmpty) {
      throw ApiException(400, "Missing required param: deductionId");
    }
    final response = await apiClient.invokeAPI(
      '/api/deductions/$deductionId',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return DeductionInformation.fromJson(data);
  }

  /// PUT /api/deductions/{deductionId} - 更新扣分记录 (仅管理员)
  Future<DeductionInformation> apiDeductionsDeductionIdPut({
    required String deductionId,
    required DeductionInformation deductionInformation,
  }) async {
    if (deductionId.isEmpty) {
      throw ApiException(400, "Missing required param: deductionId");
    }
    final response = await apiClient.invokeAPI(
      '/api/deductions/$deductionId',
      'PUT',
      [],
      deductionInformation.toJson(),
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return DeductionInformation.fromJson(data);
  }

  /// GET /api/deductions - 获取所有扣分记录
  Future<List<DeductionInformation>> apiDeductionsGet() async {
    final response = await apiClient.invokeAPI(
      '/api/deductions',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return DeductionInformation.listFromJson(data);
  }

  /// GET /api/deductions/handler/{handler} - 根据处理人获取扣分记录
  Future<List<DeductionInformation>> apiDeductionsHandlerHandlerGet(
      {required String handler}) async {
    if (handler.isEmpty) {
      throw ApiException(400, "Missing required param: handler");
    }
    final response = await apiClient.invokeAPI(
      '/api/deductions/handler/$handler',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return DeductionInformation.listFromJson(data);
  }

  /// POST /api/deductions - 创建扣分记录 (仅管理员)
  Future<DeductionInformation> apiDeductionsPost({
    required DeductionInformation deductionInformation,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/deductions',
      'POST',
      [],
      deductionInformation.toJson(),
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return DeductionInformation.fromJson(data);
  }

  /// GET /api/deductions/timeRange - 根据时间范围获取扣分记录
  Future<List<DeductionInformation>> apiDeductionsTimeRangeGet({
    String? startTime,
    String? endTime,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/deductions/timeRange',
      'GET',
      _addQueryParams(startTime: startTime, endTime: endTime),
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return DeductionInformation.listFromJson(data);
  }

  // WebSocket Methods (Aligned with HTTP Endpoints)

  /// DELETE /api/deductions/{deductionId} (WebSocket)
  /// 对应后端: @WsAction(service="DeductionInformation", action="deleteDeduction")
  Future<bool> eventbusDeductionsDeductionIdDelete(
      {required String deductionId}) async {
    if (deductionId.isEmpty) {
      throw ApiException(400, "Missing required param: deductionId");
    }
    final msg = {
      "service": "DeductionInformation",
      "action": "deleteDeduction",
      "args": [int.parse(deductionId)]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return true; // Success if no error
  }

  /// GET /api/deductions/{deductionId} (WebSocket)
  /// 对应后端: @WsAction(service="DeductionInformation", action="getDeductionById")
  Future<Object?> eventbusDeductionsDeductionIdGet(
      {required String deductionId}) async {
    if (deductionId.isEmpty) {
      throw ApiException(400, "Missing required param: deductionId");
    }
    final msg = {
      "service": "DeductionInformation",
      "action": "getDeductionById",
      "args": [int.parse(deductionId)]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// PUT /api/deductions/{deductionId} (WebSocket)
  /// 对应后端: @WsAction(service="DeductionInformation", action="updateDeduction")
  Future<Object?> eventbusDeductionsDeductionIdPut({
    required String deductionId,
    required DeductionInformation deductionInformation,
  }) async {
    if (deductionId.isEmpty) {
      throw ApiException(400, "Missing required param: deductionId");
    }
    final msg = {
      "service": "DeductionInformation",
      "action": "updateDeduction",
      "args": [int.parse(deductionId), deductionInformation.toJson()]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/deductions (WebSocket)
  /// 对应后端: @WsAction(service="DeductionInformation", action="getAllDeductions")
  Future<List<Object>?> eventbusDeductionsGet() async {
    final msg = {
      "service": "DeductionInformation",
      "action": "getAllDeductions",
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

  /// GET /api/deductions/handler/{handler} (WebSocket)
  /// 对应后端: @WsAction(service="DeductionInformation", action="getDeductionsByHandler")
  Future<List<Object>?> eventbusDeductionsHandlerHandlerGet(
      {required String handler}) async {
    if (handler.isEmpty) {
      throw ApiException(400, "Missing required param: handler");
    }
    final msg = {
      "service": "DeductionInformation",
      "action": "getDeductionsByHandler",
      "args": [handler]
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

  /// POST /api/deductions (WebSocket)
  /// 对应后端: @WsAction(service="DeductionInformation", action="createDeduction")
  Future<Object?> eventbusDeductionsPost(
      {required DeductionInformation deductionInformation}) async {
    final msg = {
      "service": "DeductionInformation",
      "action": "createDeduction",
      "args": [deductionInformation.toJson()]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/deductions/timeRange (WebSocket)
  /// 对应后端: @WsAction(service="DeductionInformation", action="getDeductionsByTimeRange")
  Future<List<Object>?> eventbusDeductionsTimeRangeGet(
      {String? startTime, String? endTime}) async {
    final msg = {
      "service": "DeductionInformation",
      "action": "getDeductionsByTimeRange",
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
}
