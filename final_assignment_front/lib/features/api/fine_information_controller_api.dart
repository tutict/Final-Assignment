import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/features/model/fine_information.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';

final ApiClient defaultApiClient = ApiClient();

class FineInformationControllerApi with BaseApiClient {
  @override
  final ApiClient apiClient;

  FineInformationControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  Future<void> initializeWithJwt() => initializeClientWithJwt();

  Future<void> createFine({
    required FineInformation fineInformation,
    required String idempotencyKey,
  }) {
    requireNotBlank(idempotencyKey, 'idempotencyKey');
    return requestVoid(
      'POST',
      '/api/fines',
      body: fineInformation.toJson(),
      contentType: 'application/json',
      idempotencyKey: idempotencyKey,
    );
  }

  Future<FineInformation?> getFine({required int fineId}) {
    return requestNullableObject(
      'GET',
      '/api/fines/$fineId',
      FineInformation.fromJson,
    );
  }

  Future<List<FineInformation>> listFines({
    Map<String, dynamic>? params,
  }) {
    return requestList(
      'GET',
      '/api/fines',
      FineInformation.fromJson,
      queryParams: queryParamsFromMap(params ?? const {}),
    );
  }

  Future<List<FineInformation>> listFinesByDriver({
    required int driverId,
    int page = 1,
    int size = 20,
  }) {
    return _list('/api/fines/driver/$driverId', page: page, size: size);
  }

  Future<FineInformation> updateFine({
    required int fineId,
    required FineInformation fineInformation,
    required String idempotencyKey,
  }) {
    requireNotBlank(idempotencyKey, 'idempotencyKey');
    return requestObject(
      'PUT',
      '/api/fines/$fineId',
      FineInformation.fromJson,
      body: fineInformation.toJson(),
      contentType: 'application/json',
      idempotencyKey: idempotencyKey,
    );
  }

  Future<void> deleteFine({required int fineId}) {
    return requestVoid('DELETE', '/api/fines/$fineId');
  }

  Future<List<FineInformation>> listFinesByPayee({
    required String payee,
  }) {
    requireNotBlank(payee, 'payee');
    return requestList(
      'GET',
      '/api/fines/payee/${Uri.encodeComponent(payee)}',
      FineInformation.fromJson,
    );
  }

  Future<List<FineInformation>> searchFinesByTimeRange({
    String startDate = '1970-01-01',
    String endDate = '2100-01-01',
  }) {
    return _search('/api/fines/search/date-range', {
      'startDate': startDate,
      'endDate': endDate,
    });
  }

  Future<FineInformation?> getFineByReceiptNumber({
    required String receiptNumber,
  }) {
    requireNotBlank(receiptNumber, 'receiptNumber');
    return requestNullableObject(
      'GET',
      '/api/fines/receiptNumber/${Uri.encodeComponent(receiptNumber)}',
      FineInformation.fromJson,
    );
  }

  Future<List<FineInformation>> listFinesByOffense({
    required int offenseId,
    int page = 1,
    int size = 20,
  }) {
    return _list('/api/fines/offense/$offenseId', page: page, size: size);
  }

  Future<List<FineInformation>> searchFinesByHandler({
    required String handler,
    String mode = 'prefix',
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(handler, 'handler');
    return _search('/api/fines/search/handler', {
      'handler': handler,
      'mode': mode,
      'page': page,
      'size': size,
    });
  }

  Future<List<FineInformation>> searchFinesByStatus({
    required String status,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(status, 'status');
    return _search('/api/fines/search/status', {
      'status': status,
      'page': page,
      'size': size,
    });
  }

  Future<List<FineInformation>> listFinesByTimeRange({
    required String startTime,
    required String endTime,
    int maxSuggestions = 10,
  }) {
    requireNotBlank(startTime, 'startTime');
    requireNotBlank(endTime, 'endTime');
    return _search('/api/fines/by-time-range', {
      'startTime': startTime,
      'endTime': endTime,
      'maxSuggestions': maxSuggestions,
    });
  }

  Future<void> eventbusFinesPost({
    required FineInformation fineInformation,
    required String idempotencyKey,
  }) async {
    final respMap = await sendWsRaw(
      service: 'FineRecordService',
      action: 'checkAndInsertIdempotency',
      args: [idempotencyKey, fineInformation.toJson(), 'create'],
    );
    throwWsError(respMap);
  }

  Future<FineInformation?> eventbusFinesFineIdGet({
    required int fineId,
  }) {
    return sendWsObjectChecked(
      service: 'FineRecordService',
      action: 'getFineById',
      args: [fineId],
      fromJson: FineInformation.fromJson,
    );
  }

  Future<List<FineInformation>> eventbusFinesGet() {
    return sendWsListChecked(
      service: 'FineRecordService',
      action: 'getAllFines',
      fromJson: FineInformation.fromJson,
    );
  }

  Future<FineInformation?> eventbusFinesFineIdPut({
    required int fineId,
    required FineInformation fineInformation,
    required String idempotencyKey,
  }) async {
    final respMap = await sendWsRaw(
      service: 'FineRecordService',
      action: 'checkAndInsertIdempotency',
      args: [idempotencyKey, fineInformation.toJson(), 'update'],
    );
    if (isWsNotFound(respMap)) {
      throw AppException.http(404, 'Fine not found with ID: $fineId');
    }
    throwWsError(respMap);
    final result = respMap['result'];
    if (result == null) return null;
    if (result is Map<String, dynamic>) return FineInformation.fromJson(result);
    if (result is Map) {
      return FineInformation.fromJson(Map<String, dynamic>.from(result));
    }
    throw AppException.http(
      400,
      'Expected WebSocket object result, got ${result.runtimeType}',
    );
  }

  Future<void> eventbusFinesFineIdDelete({
    required int fineId,
  }) async {
    final respMap = await sendWsRaw(
      service: 'FineRecordService',
      action: 'deleteFine',
      args: [fineId],
    );
    if (isWsNotFound(respMap)) {
      throw AppException.http(404, 'Fine not found with ID: $fineId');
    }
    if (wsError(respMap).contains('Unauthorized')) {
      throw AppException.http(403, 'Unauthorized: Only ADMIN can delete fines');
    }
    throwWsError(respMap);
  }

  Future<List<FineInformation>> eventbusFinesPayeePayeeGet({
    required String payee,
  }) {
    requireNotBlank(payee, 'payee');
    return sendWsListChecked(
      service: 'FineRecordService',
      action: 'getFinesByPayee',
      args: [payee],
      fromJson: FineInformation.fromJson,
    );
  }

  Future<FineInformation?> eventbusFinesReceiptNumberReceiptNumberGet({
    required String receiptNumber,
  }) {
    requireNotBlank(receiptNumber, 'receiptNumber');
    return sendWsObjectChecked(
      service: 'FineRecordService',
      action: 'getFineByReceiptNumber',
      args: [receiptNumber],
      fromJson: FineInformation.fromJson,
    );
  }

  Future<List<FineInformation>> eventbusFinesTimeRangeGet({
    String startTime = '1970-01-01',
    String endTime = '2100-01-01',
  }) {
    return sendWsListChecked(
      service: 'FineRecordService',
      action: 'getFinesByTimeRange',
      args: [startTime, endTime],
      fromJson: FineInformation.fromJson,
    );
  }

  Future<List<FineInformation>> _list(
    String path, {
    required int page,
    required int size,
  }) {
    return requestList(
      'GET',
      path,
      FineInformation.fromJson,
      queryParams: pageParams(page, size),
    );
  }

  Future<List<FineInformation>> _search(
    String path,
    Map<String, Object?> params,
  ) {
    return requestList(
      'GET',
      path,
      FineInformation.fromJson,
      queryParams: queryParamsFromMap(params),
    );
  }
}
