import 'package:final_assignment_front/features/model/deduction_record.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';

final ApiClient defaultApiClient = ApiClient();

class DeductionInformationControllerApi with BaseApiClient {
  @override
  final ApiClient apiClient;

  DeductionInformationControllerApi([ApiClient? client])
      : apiClient = client ?? defaultApiClient;

  Future<void> initializeWithJwt() => initializeClientWithJwt();

  Future<DeductionRecordModel> createDeduction({
    required DeductionRecordModel body,
    required String idempotencyKey,
  }) {
    requireNotBlank(idempotencyKey, 'idempotencyKey');
    return requestObject(
      'POST',
      '/api/deductions',
      DeductionRecordModel.fromJson,
      body: body.toJson(),
      contentType: 'application/json',
      idempotencyKey: idempotencyKey,
    );
  }

  Future<DeductionRecordModel?> getDeduction({
    required int deductionId,
  }) {
    return requestNullableObject(
      'GET',
      '/api/deductions/$deductionId',
      DeductionRecordModel.fromJson,
    );
  }

  Future<List<DeductionRecordModel>> listDeductions() {
    return requestList(
      'GET',
      '/api/deductions',
      DeductionRecordModel.fromJson,
    );
  }

  Future<DeductionRecordModel> updateDeduction({
    required int deductionId,
    required DeductionRecordModel body,
    required String idempotencyKey,
  }) {
    requireNotBlank(idempotencyKey, 'idempotencyKey');
    return requestObject(
      'PUT',
      '/api/deductions/$deductionId',
      DeductionRecordModel.fromJson,
      body: body.toJson(),
      contentType: 'application/json',
      idempotencyKey: idempotencyKey,
    );
  }

  Future<void> deleteDeduction({required int deductionId}) {
    return requestVoid('DELETE', '/api/deductions/$deductionId');
  }

  Future<void> clearCache() {
    return requestVoid('POST', '/api/cache/clear');
  }

  Future<List<DeductionRecordModel>> listDeductionsByDriver({
    required int driverId,
    int page = 1,
    int size = 20,
  }) {
    return requestList(
      'GET',
      '/api/deductions/driver/$driverId',
      DeductionRecordModel.fromJson,
      queryParams: pageParams(page, size),
    );
  }

  Future<List<DeductionRecordModel>> listDeductionsByOffense({
    required int offenseId,
    int page = 1,
    int size = 20,
  }) {
    return requestList(
      'GET',
      '/api/deductions/offense/$offenseId',
      DeductionRecordModel.fromJson,
      queryParams: pageParams(page, size),
    );
  }

  Future<List<DeductionRecordModel>> searchDeductionsByHandler({
    required String handler,
    String mode = 'prefix',
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(handler, 'handler');
    return _search(
      '/api/deductions/search/handler',
      {
        'handler': handler,
        'mode': mode,
        'page': page,
        'size': size,
      },
    );
  }

  Future<List<DeductionRecordModel>> searchDeductionsByStatus({
    required String status,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(status, 'status');
    return _search(
      '/api/deductions/search/status',
      {
        'status': status,
        'page': page,
        'size': size,
      },
    );
  }

  Future<List<DeductionRecordModel>> searchDeductionsByTimeRange({
    required String startTime,
    required String endTime,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(startTime, 'startTime');
    requireNotBlank(endTime, 'endTime');
    return _search(
      '/api/deductions/search/time-range',
      {
        'startTime': startTime,
        'endTime': endTime,
        'page': page,
        'size': size,
      },
    );
  }

  Future<List<DeductionRecordModel>> _search(
    String path,
    Map<String, Object?> params,
  ) {
    return requestList(
      'GET',
      path,
      DeductionRecordModel.fromJson,
      queryParams: queryParamsFromMap(params),
    );
  }
}
