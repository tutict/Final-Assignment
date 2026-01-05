import 'dart:convert';

import 'package:final_assignment_front/features/model/payment_record.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final ApiClient defaultApiClient = ApiClient();

class PaymentRecordControllerApi {
  final ApiClient apiClient;

  PaymentRecordControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  Future<void> initializeWithJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null || jwtToken.isEmpty) {
      throw Exception('JWT token not found in SharedPreferences');
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint('Initialized PaymentRecordControllerApi with token: $jwtToken');
  }

  String _decodeBodyBytes(http.Response response) {
    return utf8.decode(response.bodyBytes);
  }

  Future<Map<String, String>> _getHeaders({String? idempotencyKey}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken') ?? '';
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
    };
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (idempotencyKey != null && idempotencyKey.trim().isNotEmpty) {
      headers['Idempotency-Key'] = idempotencyKey.trim();
    }
    return headers;
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 400) {
      final message = response.body.isNotEmpty
          ? _decodeBodyBytes(response)
          : 'Request failed with status ${response.statusCode}';
      throw ApiException(response.statusCode, message);
    }
  }

  List<PaymentRecordModel> _parseList(String body) {
    if (body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(body) as List<dynamic>;
    return jsonList
        .map((item) => PaymentRecordModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/payments
  Future<PaymentRecordModel> apiPaymentsPost({
    required PaymentRecordModel paymentRecord,
    String? idempotencyKey,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/payments',
      'POST',
      const [],
      paymentRecord.toJson(),
      await _getHeaders(idempotencyKey: idempotencyKey),
      const {},
      'application/json',
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return PaymentRecordModel.fromJson(
        jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>);
  }

  /// PUT /api/payments/{paymentId}
  Future<PaymentRecordModel> apiPaymentsPaymentIdPut({
    required int paymentId,
    required PaymentRecordModel paymentRecord,
    String? idempotencyKey,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/payments/$paymentId',
      'PUT',
      const [],
      paymentRecord.toJson(),
      await _getHeaders(idempotencyKey: idempotencyKey),
      const {},
      'application/json',
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return PaymentRecordModel.fromJson(
        jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>);
  }

  /// DELETE /api/payments/{paymentId}
  Future<void> apiPaymentsPaymentIdDelete({required int paymentId}) async {
    final response = await apiClient.invokeAPI(
      '/api/payments/$paymentId',
      'DELETE',
      const [],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      _ensureSuccess(response);
    }
  }

  /// GET /api/payments/{paymentId}
  Future<PaymentRecordModel?> apiPaymentsPaymentIdGet({
    required int paymentId,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/payments/$paymentId',
      'GET',
      const [],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode == 404) return null;
    _ensureSuccess(response);
    if (response.body.isEmpty) return null;
    return PaymentRecordModel.fromJson(
        jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>);
  }

  /// GET /api/payments
  Future<List<PaymentRecordModel>> apiPaymentsGet() async {
    final response = await apiClient.invokeAPI(
      '/api/payments',
      'GET',
      const [],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }

  /// GET /api/payments/fine/{fineId}?page=&size=
  Future<List<PaymentRecordModel>> apiPaymentsFineFineIdGet({
    required int fineId,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/payments/fine/$fineId',
      'GET',
      [
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }

  /// GET /api/payments/search/payer?idCard=&page=&size=
  Future<List<PaymentRecordModel>> apiPaymentsSearchPayerGet({
    required String idCard,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/payments/search/payer',
      'GET',
      [
        QueryParam('idCard', idCard),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }

  /// GET /api/payments/search/status?status=&page=&size=
  Future<List<PaymentRecordModel>> apiPaymentsSearchStatusGet({
    required String status,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/payments/search/status',
      'GET',
      [
        QueryParam('status', status),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }

  /// GET /api/payments/search/transaction?transactionId=&page=&size=
  Future<List<PaymentRecordModel>> apiPaymentsSearchTransactionGet({
    required String transactionId,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/payments/search/transaction',
      'GET',
      [
        QueryParam('transactionId', transactionId),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }

  /// GET /api/payments/search/payment-number?paymentNumber=&page=&size=
  Future<List<PaymentRecordModel>> apiPaymentsSearchPaymentNumberGet({
    required String paymentNumber,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/payments/search/payment-number',
      'GET',
      [
        QueryParam('paymentNumber', paymentNumber),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }

  /// GET /api/payments/search/payer-name?payerName=&page=&size=
  Future<List<PaymentRecordModel>> apiPaymentsSearchPayerNameGet({
    required String payerName,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/payments/search/payer-name',
      'GET',
      [
        QueryParam('payerName', payerName),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }

  /// GET /api/payments/search/payment-method?paymentMethod=&page=&size=
  Future<List<PaymentRecordModel>> apiPaymentsSearchPaymentMethodGet({
    required String paymentMethod,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/payments/search/payment-method',
      'GET',
      [
        QueryParam('paymentMethod', paymentMethod),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }

  /// GET /api/payments/search/payment-channel?paymentChannel=&page=&size=
  Future<List<PaymentRecordModel>> apiPaymentsSearchPaymentChannelGet({
    required String paymentChannel,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/payments/search/payment-channel',
      'GET',
      [
        QueryParam('paymentChannel', paymentChannel),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }

  /// GET /api/payments/search/time-range?startTime=&endTime=&page=&size=
  Future<List<PaymentRecordModel>> apiPaymentsSearchTimeRangeGet({
    required String startTime,
    required String endTime,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/payments/search/time-range',
      'GET',
      [
        QueryParam('startTime', startTime),
        QueryParam('endTime', endTime),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }

  /// PUT /api/payments/{paymentId}/status/{state}
  Future<PaymentRecordModel> apiPaymentsPaymentIdStatusPut({
    required int paymentId,
    required String state,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/payments/$paymentId/status/$state',
      'PUT',
      const [],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return PaymentRecordModel.fromJson(
        jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>);
  }
}
