import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'dart:convert';

import 'package:final_assignment_front/features/model/appeal_record.dart';
import 'package:final_assignment_front/features/model/appeal_review.dart';
import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

final ApiClient defaultApiClient = ApiClient();

class AppealManagementControllerApi with BaseApiClient {
  @override
  final ApiClient apiClient;

  AppealManagementControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  Future<void> initializeWithJwt() async {
    final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null || jwtToken.isEmpty) {
      throw Exception('Not authenticated. Please log in again.');
    }
    apiClient.setJwtToken(jwtToken);
    AppLogger.debug(
        'Initialized AppealManagementControllerApi with token: $jwtToken');
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

  List<AppealRecordModel> _parseAppealList(String body) {
    if (body.isEmpty) return [];
    final payload = unwrapPayload(jsonDecode(body));
    final List<dynamic> raw = switch (payload) {
      List<dynamic> value => value,
      Map<String, dynamic> value when value['content'] is List<dynamic> =>
        value['content'] as List<dynamic>,
      Map<String, dynamic> value when value['items'] is List<dynamic> =>
        value['items'] as List<dynamic>,
      Map<String, dynamic> value when value['records'] is List<dynamic> =>
        value['records'] as List<dynamic>,
      _ => const <dynamic>[],
    };
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
  Future<AppealRecordModel> createAppeal({
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
        unwrapPayload(jsonDecode(body)) as Map<String, dynamic>);
  }

  /// PUT /api/appeals/{appealId}
  Future<AppealRecordModel> updateAppeal({
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
        unwrapPayload(jsonDecode(body)) as Map<String, dynamic>);
  }

  /// DELETE /api/appeals/{appealId}
  Future<void> deleteAppeal({required int appealId}) async {
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
  Future<AppealRecordModel?> getAppeal({required int appealId}) async {
    final response = await apiClient.invokeAPI(
      '/api/appeals/$appealId',
      'GET',
      const [],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
      passThroughStatusCodes: const {404},
    );
    if (response.statusCode == 404) {
      return null;
    }
    _ensureSuccess(response);
    if (response.body.isEmpty) {
      return null;
    }
    return AppealRecordModel.fromJson(
        unwrapPayload(jsonDecode(_decodeBodyBytes(response)))
            as Map<String, dynamic>);
  }

  Future<List<AppealRecordModel>> listMyAppeals({
    int page = 0,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/appeals/my',
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
    return _parseAppealList(_decodeBodyBytes(response));
  }

  /// GET /api/appeals?offenseId=...&page=...&size=...
  Future<List<AppealRecordModel>> listAppeals({
    required int offenseId,
    int page = 1,
    int size = 20,
  }) async {
    if (offenseId <= 0) {
      throw AppException.http(400, 'Missing required param: offenseId');
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
      passThroughStatusCodes: const {404},
    );
    if (response.statusCode == 404) {
      return [];
    }
    _ensureSuccess(response);
    return _parseAppealList(_decodeBodyBytes(response));
  }

  /// GET /api/appeals/search/number/prefix
  Future<List<AppealRecordModel>> searchAppealsByNumberPrefix({
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
  Future<List<AppealRecordModel>> searchAppealsByNumberFuzzy({
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
  Future<List<AppealRecordModel>> searchAppealsByAppellantNamePrefix({
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
  Future<List<AppealRecordModel>> searchAppealsByAppellantNameFuzzy({
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
  Future<List<AppealRecordModel>> searchAppealsByAppellantIdCard({
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
  Future<List<AppealRecordModel>> searchAppealsByAcceptanceStatus({
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
  Future<List<AppealRecordModel>> searchAppealsByProcessStatus({
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
  Future<List<AppealRecordModel>> searchAppealsByTimeRange({
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
  Future<List<AppealRecordModel>> searchAppealsByHandler({
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
  Future<AppealReviewModel> createAppealReview({
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
  Future<AppealReviewModel> updateAppealReview({
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
  Future<void> deleteAppealReview({required int reviewId}) async {
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
  Future<AppealReviewModel?> getAppealReview({required int reviewId}) async {
    final response = await apiClient.invokeAPI(
      '/api/appeals/reviews/$reviewId',
      'GET',
      const [],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
      passThroughStatusCodes: const {404},
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
  Future<List<AppealReviewModel>> listAppealReviews() async {
    final response = await apiClient.invokeAPI(
      '/api/appeals/reviews',
      'GET',
      const [],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
      passThroughStatusCodes: const {404},
    );
    if (response.statusCode == 404) {
      return [];
    }
    _ensureSuccess(response);
    return _parseReviewList(_decodeBodyBytes(response));
  }

  /// GET /api/appeals/reviews/search/reviewer
  Future<List<AppealReviewModel>> searchAppealReviewsByReviewer({
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
  Future<List<AppealReviewModel>> searchAppealReviewsByReviewerDept({
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
  Future<List<AppealReviewModel>> searchAppealReviewsByTimeRange({
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
  Future<int> countAppealReviews({
    required String reviewLevel,
  }) async {
    if (reviewLevel.trim().isEmpty) {
      throw AppException.http(400, 'Missing required param: reviewLevel');
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
    final data = jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>;
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
