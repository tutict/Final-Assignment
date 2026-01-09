import 'dart:convert';
import 'package:final_assignment_front/features/model/offense_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

// Global default client
final ApiClient defaultApiClient = ApiClient();

class TrafficViolationControllerApi {
  final ApiClient apiClient;

  TrafficViolationControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  // Read jwt and configure client
  Future<void> initializeWithJwt() async {
      final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null) {
      throw Exception('Not authenticated. Please log in again.');
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint('Initialized TrafficViolationControllerApi with token: $jwtToken');
  }

  // Decode body
  String _decodeBodyBytes(http.Response response) => response.body;

  // Auth headers
  Future<Map<String, String>> _getHeaders() async {
      final token = (await AuthTokenStore.instance.getJwtToken()) ?? '';
    return {
      'Content-Type': 'application/json; charset=utf-8',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // Build query params
  List<QueryParam> _buildQueryParams(Map<String, String?> params) {
    return params.entries
        .where((e) => e.value != null)
        .map((e) => QueryParam(e.key, e.value!))
        .toList();
  }

  Never _handleError(http.Response response) {
    final body = _decodeBodyBytes(response);
    throw ApiException(response.statusCode, body.isEmpty ? 'HTTP ${response.statusCode}' : body);
  }

  // GET /api/violations - all violations
  Future<List<OffenseInformation>> apiViolationsGet() async {
    const path = '/api/violations';
    final headers = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'GET',
      const [],
      null,
      headers,
      const {},
      null,
      const ['bearerAuth'],
    );
    if (response.statusCode >= 400) _handleError(response);
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.map((e) => OffenseInformation.fromJson(e)).toList();
  }

  // GET /api/violations/{offenseId} - full chain details
  // Returns a payload map with keys: offense, fines, payments, deductions, appeals
  Future<Map<String, dynamic>> apiViolationsOffenseIdGet({
    required int offenseId,
  }) async {
    final path = '/api/violations/$offenseId';
    final headers = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'GET',
      const [],
      null,
      headers,
      const {},
      null,
      const ['bearerAuth'],
    );
    if (response.statusCode >= 400) _handleError(response);
    if (response.body.isEmpty) return {};
    return jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>;
  }

  // GET /api/violations/status?processStatus=...&page=1&size=20
  Future<List<OffenseInformation>> apiViolationsStatusGet({
    required String processStatus,
    int page = 1,
    int size = 20,
  }) async {
    const path = '/api/violations/status';
    final headers = await _getHeaders();
    final response = await apiClient.invokeAPI(
      path,
      'GET',
      _buildQueryParams({
        'processStatus': processStatus,
        'page': '$page',
        'size': '$size',
      }),
      null,
      headers,
      const {},
      null,
      const ['bearerAuth'],
    );
    if (response.statusCode >= 400) _handleError(response);
    if (response.body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(_decodeBodyBytes(response));
    return jsonList.map((e) => OffenseInformation.fromJson(e)).toList();
  }
}

