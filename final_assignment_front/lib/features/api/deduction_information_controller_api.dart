import 'dart:convert';
import 'package:final_assignment_front/features/model/deduction_record.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

final ApiClient defaultApiClient = ApiClient();

class DeductionInformationControllerApi {
  final ApiClient apiClient;
  DeductionInformationControllerApi([ApiClient? client])
      : apiClient = client ?? defaultApiClient;

  Future<void> initializeWithJwt() async {
      final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null) {
      throw Exception('Not logged in, please login again.');
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint('Initialized DeductionInformationControllerApi with token: $jwtToken');
  }

  String _decode(http.Response r) => r.body;

  Future<Map<String, String>> _headers() async {
      final token = (await AuthTokenStore.instance.getJwtToken()) ?? '';
    return {
      'Content-Type': 'application/json; charset=utf-8',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  List<QueryParam> _idem(String key) => [QueryParam('idempotencyKey', key)];

  // POST /api/deductions
  Future<DeductionRecordModel> apiDeductionsPost({
    required DeductionRecordModel body,
    required String idempotencyKey,
  }) async {
    if (idempotencyKey.isEmpty) {
      throw ApiException(400, 'Missing required param: idempotencyKey');
    }
    final r = await apiClient.invokeAPI(
      '/api/deductions',
      'POST',
      _idem(idempotencyKey),
      body.toJson(),
      await _headers(),
      const {},
      'application/json',
      const ['bearerAuth'],
    );
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    return DeductionRecordModel.fromJson(jsonDecode(_decode(r)));
  }

  // GET /api/deductions/{deductionId}
  Future<DeductionRecordModel?> apiDeductionsDeductionIdGet({
    required int deductionId,
  }) async {
    final r = await apiClient.invokeAPI(
      '/api/deductions/$deductionId',
      'GET',
      const [],
      null,
      await _headers(),
      const {},
      null,
      const ['bearerAuth'],
    );
    if (r.statusCode == 404) return null;
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    if (r.body.isEmpty) return null;
    return DeductionRecordModel.fromJson(jsonDecode(_decode(r)));
  }

  // GET /api/deductions
  Future<List<DeductionRecordModel>> apiDeductionsGet() async {
    final r = await apiClient.invokeAPI(
      '/api/deductions',
      'GET',
      const [],
      null,
      await _headers(),
      const {},
      null,
      const ['bearerAuth'],
    );
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    if (r.body.isEmpty) return [];
    final List<dynamic> data = jsonDecode(_decode(r));
    return data.map((e) => DeductionRecordModel.fromJson(e)).toList();
  }

  // PUT /api/deductions/{deductionId}
  Future<DeductionRecordModel> apiDeductionsDeductionIdPut({
    required int deductionId,
    required DeductionRecordModel body,
    required String idempotencyKey,
  }) async {
    if (idempotencyKey.isEmpty) {
      throw ApiException(400, 'Missing required param: idempotencyKey');
    }
    final r = await apiClient.invokeAPI(
      '/api/deductions/$deductionId',
      'PUT',
      _idem(idempotencyKey),
      body.toJson(),
      await _headers(),
      const {},
      'application/json',
      const ['bearerAuth'],
    );
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    return DeductionRecordModel.fromJson(jsonDecode(_decode(r)));
  }

  // DELETE /api/deductions/{deductionId}
  Future<void> apiDeductionsDeductionIdDelete({required int deductionId}) async {
    final r = await apiClient.invokeAPI(
      '/api/deductions/$deductionId',
      'DELETE',
      const [],
      null,
      await _headers(),
      const {},
      null,
      const ['bearerAuth'],
    );
    if (r.statusCode != 204) throw ApiException(r.statusCode, _decode(r));
  }

  // GET /api/deductions/driver/{driverId}?page=&size=
  Future<List<DeductionRecordModel>> apiDeductionsDriverDriverIdGet({
    required int driverId,
    int page = 1,
    int size = 20,
  }) async {
    final r = await apiClient.invokeAPI(
      '/api/deductions/driver/$driverId',
      'GET',
      [QueryParam('page', '$page'), QueryParam('size', '$size')],
      null,
      await _headers(),
      const {},
      null,
      const ['bearerAuth'],
    );
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    if (r.body.isEmpty) return [];
    final List<dynamic> data = jsonDecode(_decode(r));
    return data.map((e) => DeductionRecordModel.fromJson(e)).toList();
  }

  // GET /api/deductions/offense/{offenseId}?page=&size=
  Future<List<DeductionRecordModel>> apiDeductionsOffenseOffenseIdGet({
    required int offenseId,
    int page = 1,
    int size = 20,
  }) async {
    final r = await apiClient.invokeAPI(
      '/api/deductions/offense/$offenseId',
      'GET',
      [QueryParam('page', '$page'), QueryParam('size', '$size')],
      null,
      await _headers(),
      const {},
      null,
      const ['bearerAuth'],
    );
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    if (r.body.isEmpty) return [];
    final List<dynamic> data = jsonDecode(_decode(r));
    return data.map((e) => DeductionRecordModel.fromJson(e)).toList();
  }

  // GET /api/deductions/search/handler?handler=&mode=&page=&size=
  Future<List<DeductionRecordModel>> apiDeductionsSearchHandlerGet({
    required String handler,
    String mode = 'prefix',
    int page = 1,
    int size = 20,
  }) async {
    final r = await apiClient.invokeAPI(
      '/api/deductions/search/handler',
      'GET',
      [
        QueryParam('handler', handler),
        QueryParam('mode', mode),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _headers(),
      const {},
      null,
      const ['bearerAuth'],
    );
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    if (r.body.isEmpty) return [];
    final List<dynamic> data = jsonDecode(_decode(r));
    return data.map((e) => DeductionRecordModel.fromJson(e)).toList();
  }

  // GET /api/deductions/search/status?status=&page=&size=
  Future<List<DeductionRecordModel>> apiDeductionsSearchStatusGet({
    required String status,
    int page = 1,
    int size = 20,
  }) async {
    final r = await apiClient.invokeAPI(
      '/api/deductions/search/status',
      'GET',
      [
        QueryParam('status', status),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _headers(),
      const {},
      null,
      const ['bearerAuth'],
    );
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    if (r.body.isEmpty) return [];
    final List<dynamic> data = jsonDecode(_decode(r));
    return data.map((e) => DeductionRecordModel.fromJson(e)).toList();
  }

  // GET /api/deductions/search/time-range?startTime=&endTime=&page=&size=
  Future<List<DeductionRecordModel>> apiDeductionsSearchTimeRangeGet({
    required String startTime,
    required String endTime,
    int page = 1,
    int size = 20,
  }) async {
    final r = await apiClient.invokeAPI(
      '/api/deductions/search/time-range',
      'GET',
      [
        QueryParam('startTime', startTime),
        QueryParam('endTime', endTime),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _headers(),
      const {},
      null,
      const ['bearerAuth'],
    );
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    if (r.body.isEmpty) return [];
    final List<dynamic> data = jsonDecode(_decode(r));
    return data.map((e) => DeductionRecordModel.fromJson(e)).toList();
  }
}

