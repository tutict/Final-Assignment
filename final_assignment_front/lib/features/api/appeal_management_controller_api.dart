import 'dart:convert';

import 'package:final_assignment_front/features/model/appeal_record.dart';
import 'package:final_assignment_front/features/model/appeal_review.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

final ApiClient defaultApiClient = ApiClient();

class AppealManagementControllerApi {
  final ApiClient apiClient;

  AppealManagementControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  Future<void> initializeWithJwt() async {
      final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null || jwtToken.isEmpty) {
      throw Exception('Not authenticated. Please log in again.');
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint('Initialized AppealManagementControllerApi with token: $jwtToken');
  }

  String _decodeBodyBytes(http.Response response) {
    return utf8.decode(response.bodyBytes);
  }

  Future<Map<String, String>> _getHeaders({String? idempotencyKey}) async {
      final token = (await AuthTokenStore.instance.getJwtToken()) ?? '';
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

  List<AppealRecordModel> _parseAppealList(String body) {
    if (body.isEmpty) return [];
    final List<dynamic> raw = jsonDecode(body) as List<dynamic>;
    return raw
        .map((item) => AppealRecordModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  List<AppealReviewModel> _parseReviewList(String body) {
    if (body.isEmpty) return [];
    final List<dynamic> raw = jsonDecode(body) as List<dynamic>;
    return raw
        .map((item) => AppealReviewModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/appeals
  Future<AppealRecordModel> apiAppealsPost({
    required AppealRecordModel appealRecord,
    String? idempotencyKey,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/appeals',
      'POST',
      const [],
      appealRecord.toJson(),
      await _getHeaders(idempotencyKey: idempotencyKey),
      const {},
      'application/json',
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    final body = _decodeBodyBytes(response);
    return AppealRecordModel.fromJson(
        jsonDecode(body) as Map<String, dynamic>);
  }

  /// PUT /api/appeals/{appealId}
  Future<AppealRecordModel> apiAppealsAppealIdPut({
    required int appealId,
    required AppealRecordModel appealRecord,
    String? idempotencyKey,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/appeals/$appealId',
      'PUT',
      const [],
      appealRecord.toJson(),
      await _getHeaders(idempotencyKey: idempotencyKey),
      const {},
      'application/json',
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    final body = _decodeBodyBytes(response);
    return AppealRecordModel.fromJson(
        jsonDecode(body) as Map<String, dynamic>);
  }

  /// DELETE /api/appeals/{appealId}
  Future<void> apiAppealsAppealIdDelete({required int appealId}) async {
    final response = await apiClient.invokeAPI(
      '/api/appeals/$appealId',
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

  /// GET /api/appeals/{appealId}
  Future<AppealRecordModel?> apiAppealsAppealIdGet(
      {required int appealId}) async {
    final response = await apiClient.invokeAPI(
      '/api/appeals/$appealId',
      'GET',
      const [],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode == 404) {
      return null;
    }
    _ensureSuccess(response);
    if (response.body.isEmpty) {
      return null;
    }
    return AppealRecordModel.fromJson(
        jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>);
  }

  /// GET /api/appeals?offenseId=...&page=...&size=...
  Future<List<AppealRecordModel>> apiAppealsGet({
    required int offenseId,
    int page = 1,
    int size = 20,
  }) async {
    if (offenseId <= 0) {
      throw ApiException(400, 'Missing required param: offenseId');
    }
    final queryParams = <QueryParam>[
      QueryParam('offenseId', offenseId.toString()),
      QueryParam('page', page.toString()),
      QueryParam('size', size.toString()),
    ];
    final response = await apiClient.invokeAPI(
      '/api/appeals',
      'GET',
      queryParams,
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode == 404) {
      return [];
    }
    _ensureSuccess(response);
    return _parseAppealList(_decodeBodyBytes(response));
  }

  /// GET /api/appeals/search/number/prefix
  Future<List<AppealRecordModel>> apiAppealsSearchNumberPrefixGet({
    required String appealNumber,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/appeals/search/number/prefix',
      'GET',
      [
        QueryParam('appealNumber', appealNumber),
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
    return _parseAppealList(_decodeBodyBytes(response));
  }

  /// GET /api/appeals/search/number/fuzzy
  Future<List<AppealRecordModel>> apiAppealsSearchNumberFuzzyGet({
    required String appealNumber,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/appeals/search/number/fuzzy',
      'GET',
      [
        QueryParam('appealNumber', appealNumber),
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
    return _parseAppealList(_decodeBodyBytes(response));
  }

  /// GET /api/appeals/search/appellant/name/prefix
  Future<List<AppealRecordModel>> apiAppealsSearchAppellantNamePrefixGet({
    required String appellantName,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/appeals/search/appellant/name/prefix',
      'GET',
      [
        QueryParam('appellantName', appellantName),
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
    return _parseAppealList(_decodeBodyBytes(response));
  }

  /// GET /api/appeals/search/appellant/name/fuzzy
  Future<List<AppealRecordModel>> apiAppealsSearchAppellantNameFuzzyGet({
    required String appellantName,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/appeals/search/appellant/name/fuzzy',
      'GET',
      [
        QueryParam('appellantName', appellantName),
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
    return _parseAppealList(_decodeBodyBytes(response));
  }

  /// GET /api/appeals/search/appellant/id-card
  Future<List<AppealRecordModel>> apiAppealsSearchAppellantIdCardGet({
    required String appellantIdCard,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/appeals/search/appellant/id-card',
      'GET',
      [
        QueryParam('appellantIdCard', appellantIdCard),
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
    return _parseAppealList(_decodeBodyBytes(response));
  }

  /// GET /api/appeals/search/acceptance-status
  Future<List<AppealRecordModel>> apiAppealsSearchAcceptanceStatusGet({
    required String acceptanceStatus,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/appeals/search/acceptance-status',
      'GET',
      [
        QueryParam('acceptanceStatus', acceptanceStatus),
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
    return _parseAppealList(_decodeBodyBytes(response));
  }

  /// GET /api/appeals/search/process-status
  Future<List<AppealRecordModel>> apiAppealsSearchProcessStatusGet({
    required String processStatus,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/appeals/search/process-status',
      'GET',
      [
        QueryParam('processStatus', processStatus),
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
    return _parseAppealList(_decodeBodyBytes(response));
  }

  /// GET /api/appeals/search/time-range
  Future<List<AppealRecordModel>> apiAppealsSearchTimeRangeGet({
    required String startTime,
    required String endTime,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/appeals/search/time-range',
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
    return _parseAppealList(_decodeBodyBytes(response));
  }

  /// GET /api/appeals/search/handler
  Future<List<AppealRecordModel>> apiAppealsSearchHandlerGet({
    required String acceptanceHandler,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/appeals/search/handler',
      'GET',
      [
        QueryParam('acceptanceHandler', acceptanceHandler),
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
    return _parseAppealList(_decodeBodyBytes(response));
  }

  /// POST /api/appeals/{appealId}/reviews
  Future<AppealReviewModel> apiAppealsAppealIdReviewsPost({
    required int appealId,
    required AppealReviewModel review,
    String? idempotencyKey,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/appeals/$appealId/reviews',
      'POST',
      const [],
      review.toJson(),
      await _getHeaders(idempotencyKey: idempotencyKey),
      const {},
      'application/json',
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return AppealReviewModel.fromJson(
        jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>);
  }

  /// PUT /api/appeals/reviews/{reviewId}
  Future<AppealReviewModel> apiAppealsReviewsReviewIdPut({
    required int reviewId,
    required AppealReviewModel review,
    String? idempotencyKey,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/appeals/reviews/$reviewId',
      'PUT',
      const [],
      review.toJson(),
      await _getHeaders(idempotencyKey: idempotencyKey),
      const {},
      'application/json',
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return AppealReviewModel.fromJson(
        jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>);
  }

  /// DELETE /api/appeals/reviews/{reviewId}
  Future<void> apiAppealsReviewsReviewIdDelete(
      {required int reviewId}) async {
    final response = await apiClient.invokeAPI(
      '/api/appeals/reviews/$reviewId',
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

  /// GET /api/appeals/reviews/{reviewId}
  Future<AppealReviewModel?> apiAppealsReviewsReviewIdGet(
      {required int reviewId}) async {
    final response = await apiClient.invokeAPI(
      '/api/appeals/reviews/$reviewId',
      'GET',
      const [],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode == 404) {
      return null;
    }
    _ensureSuccess(response);
    if (response.body.isEmpty) {
      return null;
    }
    return AppealReviewModel.fromJson(
        jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>);
  }

  /// GET /api/appeals/reviews
  Future<List<AppealReviewModel>> apiAppealsReviewsGet() async {
    final response = await apiClient.invokeAPI(
      '/api/appeals/reviews',
      'GET',
      const [],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode == 404) {
      return [];
    }
    _ensureSuccess(response);
    return _parseReviewList(_decodeBodyBytes(response));
  }

  /// GET /api/appeals/reviews/search/reviewer
  Future<List<AppealReviewModel>> apiAppealsReviewsSearchReviewerGet({
    required String reviewer,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/appeals/reviews/search/reviewer',
      'GET',
      [
        QueryParam('reviewer', reviewer),
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
    return _parseReviewList(_decodeBodyBytes(response));
  }

  /// GET /api/appeals/reviews/search/reviewer-dept
  Future<List<AppealReviewModel>> apiAppealsReviewsSearchReviewerDeptGet({
    required String reviewerDept,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/appeals/reviews/search/reviewer-dept',
      'GET',
      [
        QueryParam('reviewerDept', reviewerDept),
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
    return _parseReviewList(_decodeBodyBytes(response));
  }

  /// GET /api/appeals/reviews/search/time-range
  Future<List<AppealReviewModel>> apiAppealsReviewsSearchTimeRangeGet({
    required String startTime,
    required String endTime,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/appeals/reviews/search/time-range',
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
    return _parseReviewList(_decodeBodyBytes(response));
  }

  /// GET /api/appeals/reviews/count?level=xxx
  Future<int> apiAppealsReviewsCountGet({
    required String reviewLevel,
  }) async {
    if (reviewLevel.trim().isEmpty) {
      throw ApiException(400, 'Missing required param: reviewLevel');
    }
    final response = await apiClient.invokeAPI(
      '/api/appeals/reviews/count',
      'GET',
      [QueryParam('level', reviewLevel)],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    if (response.body.isEmpty) {
      return 0;
    }
    final data =
        jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>;
    final count = data['count'];
    if (count is int) {
      return count;
    }
    if (count is num) {
      return count.toInt();
    }
    return 0;
  }
}
