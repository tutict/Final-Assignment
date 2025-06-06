import 'dart:convert';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class TrafficViolationControllerApi {
  final ApiClient apiClient;

  /// 构造函数，可传入 ApiClient，否则使用全局默认实例
  TrafficViolationControllerApi([ApiClient? apiClient])
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
        'Initialized TrafficViolationControllerApi with token: $jwtToken');
  }

  /// 解码响应体字节到字符串
  String _decodeBodyBytes(http.Response response) => response.body;

  /// 获取带有 JWT 的请求头
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken') ?? '';
    return {
      'Content-Type': 'application/json; charset=utf-8',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// 辅助方法：将查询参数转换为 QueryParam 列表
  List<QueryParam> _buildQueryParams(Map<String, String?> params) {
    return params.entries
        .where((entry) => entry.value != null)
        .map((entry) => QueryParam(entry.key, entry.value!))
        .toList();
  }

  /// 处理错误响应，提取错误信息
  void _handleErrorResponse(http.Response response) {
    final body = _decodeBodyBytes(response);
    try {
      final data = jsonDecode(body);
      String message = 'Error ${response.statusCode}';
      if (data is Map && data.containsKey('error_code')) {
        message += ': ${data['error_code']}';
        if (data.containsKey('message')) {
          message += ' - ${data['message']}';
        }
      } else if (data is List && data.isNotEmpty && data[0] is Map) {
        message += ': ${data[0]['error_code'] ?? response.statusCode}';
        if (data[0].containsKey('message')) {
          message += ' - ${data[0]['message']}';
        }
      }
      throw ApiException(response.statusCode, message);
    } catch (e) {
      throw ApiException(response.statusCode, 'Failed to parse error: $body');
    }
  }

  // HTTP Methods

  /// GET /api/traffic-violations/violation-types
  /// 获取违规类型统计
  /// 返回: Map<offenseType, count>
  /// 参数:
  /// - startTime: 可选，格式为 yyyy-MM-dd'T'HH:mm:ss
  /// - driverName: 可选，驾驶员姓名
  /// - licensePlate: 可选，车牌号
  Future<Map<String, int>> apiTrafficViolationsViolationTypesGet({
    String? startTime,
    String? driverName,
    String? licensePlate,
  }) async {
    const path = '/api/traffic-violations/violation-types';
    final queryParams = _buildQueryParams({
      'startTime': startTime,
      'driverName': driverName,
      'licensePlate': licensePlate,
    });
    final headerParams = await _getHeaders();
    debugPrint(
        'Requesting violation types with params: startTime=$startTime, driverName=$driverName, licensePlate=$licensePlate');
    final response = await apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      _handleErrorResponse(response);
    }
    final data = jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>;
    final result = data.map((key, value) => MapEntry(key, value as int));
    debugPrint('Violation types response: $result');
    return result;
  }

  /// GET /api/traffic-violations/time-series
  /// 获取时间序列数据
  /// 返回: List<{ time: yyyy-MM-dd, value1: totalFine, value2: totalPoints }>
  /// 参数:
  /// - startTime: 可选，格式为 yyyy-MM-dd'T'HH:mm:ss
  /// - driverName: 可选，驾驶员姓名
  Future<List<Map<String, dynamic>>> apiTrafficViolationsTimeSeriesGet({
    String? startTime,
    String? driverName,
  }) async {
    const path = '/api/traffic-violations/time-series';
    final queryParams = _buildQueryParams({
      'startTime': startTime,
      'driverName': driverName,
    });
    final headerParams = await _getHeaders();
    debugPrint(
        'Requesting time series with params: startTime=$startTime, driverName=$driverName');
    final response = await apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      _handleErrorResponse(response);
    }
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    final result = jsonList.cast<Map<String, dynamic>>();
    debugPrint('Time series response: $result');
    return result;
  }

  /// GET /api/traffic-violations/appeal-reasons
  /// 获取申诉理由统计
  /// 返回: Map<appealReason, count>
  /// 参数:
  /// - startTime: 可选，格式为 yyyy-MM-dd'T'HH:mm:ss
  /// - appealReason: 可选，申诉理由
  Future<Map<String, int>> apiTrafficViolationsAppealReasonsGet({
    String? startTime,
    String? appealReason,
  }) async {
    const path = '/api/traffic-violations/appeal-reasons';
    final queryParams = _buildQueryParams({
      'startTime': startTime,
      'appealReason': appealReason,
    });
    final headerParams = await _getHeaders();
    debugPrint(
        'Requesting appeal reasons with params: startTime=$startTime, appealReason=$appealReason');
    final response = await apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      _handleErrorResponse(response);
    }
    final data = jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>;
    final result = data.map((key, value) => MapEntry(key, value as int));
    debugPrint('Appeal reasons response: $result');
    return result;
  }

  /// GET /api/traffic-violations/fine-payment-status
  /// 获取罚款支付状态统计
  /// 返回: Map<"Paid"/"Unpaid", count>
  /// 参数:
  /// - startTime: 可选，格式为 yyyy-MM-dd'T'HH:mm:ss
  Future<Map<String, int>> apiTrafficViolationsFinePaymentStatusGet({
    String? startTime,
  }) async {
    const path = '/api/traffic-violations/fine-payment-status';
    final queryParams = _buildQueryParams({
      'startTime': startTime,
    });
    final headerParams = await _getHeaders();
    debugPrint(
        'Requesting fine payment status with params: startTime=$startTime');
    final response = await apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      null,
      headerParams,
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      _handleErrorResponse(response);
    }
    final data = jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>;
    final result = data.map((key, value) => MapEntry(key, value as int));
    debugPrint('Fine payment status response: $result');
    return result;
  }
}
