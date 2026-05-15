import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'dart:convert';

import 'package:final_assignment_front/features/model/payment_record.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

final ApiClient defaultApiClient = ApiClient();

class PaymentRecordControllerApi with BaseApiClient {
  @override
  final ApiClient apiClient;

  PaymentRecordControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  Future<void> initializeWithJwt() async {
    final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null || jwtToken.isEmpty) {
      throw Exception('JWT token not found in SharedPreferences');
    }
    apiClient.setJwtToken(jwtToken);
    AppLogger.debug(
        'Initialized PaymentRecordControllerApi with token: $jwtToken');
  }

  String _decodeBodyBytes(http.Response response) {
    return decodeBodyBytes(response);
  }

  Future<Map<String, String>> _getHeaders({String? idempotencyKey}) async {
    return getHeaders(idempotencyKey: idempotencyKey);
  }

  void _ensureSuccess(http.Response response) {
    ensureSuccess(response);
  }

  List<PaymentRecordModel> _parseList(http.Response response) {
    if (response.body.isEmpty) return [];
    return parseListResponse(response, PaymentRecordModel.fromJson);
  }

  /// POST /api/payments
  Future<PaymentRecordModel> createPayment({
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
    return unwrapApiResponse(
      jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>,
      (data) => PaymentRecordModel.fromJson(data as Map<String, dynamic>),
    );
  }

  /// PUT /api/payments/{paymentId}
  Future<PaymentRecordModel> updatePayment({
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
    return unwrapApiResponse(
      jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>,
      (data) => PaymentRecordModel.fromJson(data as Map<String, dynamic>),
    );
  }

  /// DELETE /api/payments/{paymentId}
  Future<void> deletePayment({required int paymentId}) async {
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
    _ensureSuccess(response);
  }

  /// GET /api/payments/{paymentId}
  Future<PaymentRecordModel?> getPayment({
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
      passThroughStatusCodes: const {404},
    );
    if (response.statusCode == 404) return null;
    _ensureSuccess(response);
    if (response.body.isEmpty) return null;
    return unwrapApiResponse(
      jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>,
      (data) => PaymentRecordModel.fromJson(data as Map<String, dynamic>),
    );
  }

  /// GET /api/payments
  Future<List<PaymentRecordModel>> listPayments() async {
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
    return _parseList(response);
  }

  /// GET /api/payments/fine/{fineId}?page=&size=
  Future<List<PaymentRecordModel>> listPaymentsByFine({
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
    return _parseList(response);
  }

  /// GET /api/payments/search/payer?idCard=&page=&size=
  Future<List<PaymentRecordModel>> searchPaymentsByPayer({
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
    return _parseList(response);
  }

  /// GET /api/payments/search/status?status=&page=&size=
  Future<List<PaymentRecordModel>> searchPaymentsByStatus({
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
    return _parseList(response);
  }

  /// GET /api/payments/search/transaction?transactionId=&page=&size=
  Future<List<PaymentRecordModel>> searchPaymentsByTransaction({
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
    return _parseList(response);
  }

  /// GET /api/payments/search/payment-number?paymentNumber=&page=&size=
  Future<List<PaymentRecordModel>> searchPaymentsByPaymentNumber({
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
    return _parseList(response);
  }

  /// GET /api/payments/search/payer-name?payerName=&page=&size=
  Future<List<PaymentRecordModel>> searchPaymentsByPayerName({
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
    return _parseList(response);
  }

  /// GET /api/payments/search/payment-method?paymentMethod=&page=&size=
  Future<List<PaymentRecordModel>> searchPaymentsByPaymentMethod({
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
    return _parseList(response);
  }

  /// GET /api/payments/search/payment-channel?paymentChannel=&page=&size=
  Future<List<PaymentRecordModel>> searchPaymentsByPaymentChannel({
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
    return _parseList(response);
  }

  /// GET /api/payments/search/time-range?startTime=&endTime=&page=&size=
  Future<List<PaymentRecordModel>> searchPaymentsByTimeRange({
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
    return _parseList(response);
  }

  /// PUT /api/payments/{paymentId}/status/{state}
  Future<void> updatePaymentStatus(
    int id,
    String state, {
    required String idempotencyKey,
  }) async {
    final upperState = state.toUpperCase();
    final response = await apiClient.invokeAPI(
      '/api/payments/$id/status/$upperState',
      'PUT',
      const [],
      null,
      await _getHeaders(idempotencyKey: idempotencyKey),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    if (response.body.isEmpty) return;
    unwrapApiResponse(
      jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>,
      (_) => null,
    );
  }
}
