import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/features/model/appeal_record.dart';
import 'package:final_assignment_front/features/model/appeal_review.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';

final ApiClient defaultApiClient = ApiClient();

class AppealManagementControllerApi with BaseApiClient {
  @override
  final ApiClient apiClient;

  AppealManagementControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  Future<void> initializeWithJwt() => initializeClientWithJwt();

  Future<AppealRecordModel> createAppeal({
    required AppealRecordModel appealRecord,
    String? idempotencyKey,
  }) {
    return requestObject(
      'POST',
      '/api/appeals',
      AppealRecordModel.fromJson,
      body: appealRecord.toJson(),
      contentType: BaseApiClient.defaultContentType,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<AppealRecordModel> updateAppeal({
    required int appealId,
    required AppealRecordModel appealRecord,
    String? idempotencyKey,
  }) {
    return requestObject(
      'PUT',
      '/api/appeals/$appealId',
      AppealRecordModel.fromJson,
      body: appealRecord.toJson(),
      contentType: BaseApiClient.defaultContentType,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<void> deleteAppeal({required int appealId}) {
    return requestVoid('DELETE', '/api/appeals/$appealId');
  }

  Future<AppealRecordModel> submitWorkflowEvent({
    required int appealId,
    required String eventCode,
    required String idempotencyKey,
  }) {
    requireNotBlank(eventCode, 'eventCode');
    requireNotBlank(idempotencyKey, 'idempotencyKey');
    return requestObject(
      'POST',
      '/api/workflow/appeals/$appealId/events/${Uri.encodeComponent(eventCode)}',
      AppealRecordModel.fromJson,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<AppealRecordModel?> getAppeal({required int appealId}) {
    return requestNullableObject(
      'GET',
      '/api/appeals/$appealId',
      AppealRecordModel.fromJson,
    );
  }

  Future<List<AppealRecordModel>> listMyAppeals({
    int page = 0,
    int size = 20,
  }) {
    return _listAppeals(
      '/api/appeals/my',
      {'page': page, 'size': size},
    );
  }

  Future<List<AppealRecordModel>> listAppeals({
    required int offenseId,
    int page = 1,
    int size = 20,
  }) {
    if (offenseId <= 0) {
      throw AppException.http(400, 'Missing required param: offenseId');
    }
    return _listAppeals(
      '/api/appeals',
      {'offenseId': offenseId, 'page': page, 'size': size},
      treatNotFoundAsEmpty: true,
    );
  }

  Future<List<AppealRecordModel>> listAllAppeals({
    int page = 1,
    int size = 20,
  }) {
    return _listAppeals(
      '/api/appeals',
      {'page': page, 'size': size},
      treatNotFoundAsEmpty: true,
    );
  }

  Future<List<AppealRecordModel>> searchAppealsByNumberPrefix({
    required String appealNumber,
    int page = 1,
    int size = 20,
  }) {
    return _searchAppeals(
      '/api/appeals/search/number/prefix',
      {'appealNumber': appealNumber},
      page,
      size,
    );
  }

  Future<List<AppealRecordModel>> searchAppealsByNumberFuzzy({
    required String appealNumber,
    int page = 1,
    int size = 20,
  }) {
    return _searchAppeals(
      '/api/appeals/search/number/fuzzy',
      {'appealNumber': appealNumber},
      page,
      size,
    );
  }

  Future<List<AppealRecordModel>> searchAppealsByAppellantNamePrefix({
    required String appellantName,
    int page = 1,
    int size = 20,
  }) {
    return _searchAppeals(
      '/api/appeals/search/appellant/name/prefix',
      {'appellantName': appellantName},
      page,
      size,
    );
  }

  Future<List<AppealRecordModel>> searchAppealsByAppellantNameFuzzy({
    required String appellantName,
    int page = 1,
    int size = 20,
  }) {
    return _searchAppeals(
      '/api/appeals/search/appellant/name/fuzzy',
      {'appellantName': appellantName},
      page,
      size,
    );
  }

  Future<List<AppealRecordModel>> searchAppealsByAppellantIdCard({
    required String appellantIdCard,
    int page = 1,
    int size = 20,
  }) {
    return _searchAppeals(
      '/api/appeals/search/appellant/id-card',
      {'appellantIdCard': appellantIdCard},
      page,
      size,
    );
  }

  Future<List<AppealRecordModel>> searchAppealsByAcceptanceStatus({
    required String acceptanceStatus,
    int page = 1,
    int size = 20,
  }) {
    return _searchAppeals(
      '/api/appeals/search/acceptance-status',
      {'acceptanceStatus': acceptanceStatus},
      page,
      size,
    );
  }

  Future<List<AppealRecordModel>> searchAppealsByProcessStatus({
    required String processStatus,
    int page = 1,
    int size = 20,
  }) {
    return _searchAppeals(
      '/api/appeals/search/process-status',
      {'processStatus': processStatus},
      page,
      size,
    );
  }

  Future<List<AppealRecordModel>> searchAppealsByTimeRange({
    required String startTime,
    required String endTime,
    int page = 1,
    int size = 20,
  }) {
    return _searchAppeals(
      '/api/appeals/search/time-range',
      {'startTime': startTime, 'endTime': endTime},
      page,
      size,
    );
  }

  Future<List<AppealRecordModel>> searchAppealsByHandler({
    required String acceptanceHandler,
    int page = 1,
    int size = 20,
  }) {
    return _searchAppeals(
      '/api/appeals/search/handler',
      {'acceptanceHandler': acceptanceHandler},
      page,
      size,
    );
  }

  Future<AppealReviewModel> createAppealReview({
    required int appealId,
    required AppealReviewModel review,
    String? idempotencyKey,
  }) {
    return requestObject(
      'POST',
      '/api/appeals/$appealId/reviews',
      AppealReviewModel.fromJson,
      body: review.toJson(),
      contentType: BaseApiClient.defaultContentType,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<AppealReviewModel> updateAppealReview({
    required int reviewId,
    required AppealReviewModel review,
    String? idempotencyKey,
  }) {
    return requestObject(
      'PUT',
      '/api/appeals/reviews/$reviewId',
      AppealReviewModel.fromJson,
      body: review.toJson(),
      contentType: BaseApiClient.defaultContentType,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<void> deleteAppealReview({required int reviewId}) {
    return requestVoid('DELETE', '/api/appeals/reviews/$reviewId');
  }

  Future<AppealReviewModel?> getAppealReview({required int reviewId}) {
    return requestNullableObject(
      'GET',
      '/api/appeals/reviews/$reviewId',
      AppealReviewModel.fromJson,
    );
  }

  Future<List<AppealReviewModel>> listAppealReviews() {
    return _listReviews('/api/appeals/reviews', const {},
        treatNotFoundAsEmpty: true);
  }

  Future<List<AppealReviewModel>> searchAppealReviewsByReviewer({
    required String reviewer,
    int page = 1,
    int size = 20,
  }) {
    return _searchReviews(
      '/api/appeals/reviews/search/reviewer',
      {'reviewer': reviewer},
      page,
      size,
    );
  }

  Future<List<AppealReviewModel>> searchAppealReviewsByReviewerDept({
    required String reviewerDept,
    int page = 1,
    int size = 20,
  }) {
    return _searchReviews(
      '/api/appeals/reviews/search/reviewer-dept',
      {'reviewerDept': reviewerDept},
      page,
      size,
    );
  }

  Future<List<AppealReviewModel>> searchAppealReviewsByTimeRange({
    required String startTime,
    required String endTime,
    int page = 1,
    int size = 20,
  }) {
    return _searchReviews(
      '/api/appeals/reviews/search/time-range',
      {'startTime': startTime, 'endTime': endTime},
      page,
      size,
    );
  }

  Future<int> countAppealReviews({required String reviewLevel}) async {
    if (reviewLevel.trim().isEmpty) {
      throw AppException.http(400, 'Missing required param: reviewLevel');
    }
    final data = await requestMap(
      'GET',
      '/api/appeals/reviews/count',
      queryParams: [QueryParam('level', reviewLevel)],
    );
    final count = data['count'];
    if (count is int) {
      return count;
    }
    if (count is num) {
      return count.toInt();
    }
    return 0;
  }

  Future<List<AppealRecordModel>> _searchAppeals(
    String path,
    Map<String, Object?> filters,
    int page,
    int size,
  ) {
    return _listAppeals(path, {...filters, 'page': page, 'size': size});
  }

  Future<List<AppealRecordModel>> _listAppeals(
    String path,
    Map<String, Object?> params, {
    bool treatNotFoundAsEmpty = false,
  }) {
    return requestList(
      'GET',
      path,
      AppealRecordModel.fromJson,
      queryParams: queryParamsFromMap(params),
      emptyStatusCodes: treatNotFoundAsEmpty ? const {204, 404} : const {204},
      passThroughStatusCodes: treatNotFoundAsEmpty ? const {404} : const {},
    );
  }

  Future<List<AppealReviewModel>> _searchReviews(
    String path,
    Map<String, Object?> filters,
    int page,
    int size,
  ) {
    return _listReviews(path, {...filters, 'page': page, 'size': size});
  }

  Future<List<AppealReviewModel>> _listReviews(
    String path,
    Map<String, Object?> params, {
    bool treatNotFoundAsEmpty = false,
  }) {
    return requestList(
      'GET',
      path,
      AppealReviewModel.fromJson,
      queryParams: queryParamsFromMap(params),
      emptyStatusCodes: treatNotFoundAsEmpty ? const {204, 404} : const {204},
      passThroughStatusCodes: treatNotFoundAsEmpty ? const {404} : const {},
    );
  }
}
