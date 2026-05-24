import 'package:final_assignment_front/features/model/payment_record.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';

final ApiClient defaultApiClient = ApiClient();

class PaymentRecordControllerApi with BaseApiClient {
  @override
  final ApiClient apiClient;

  PaymentRecordControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  Future<void> initializeWithJwt() => initializeClientWithJwt();

  Future<PaymentRecordModel> createPayment({
    required PaymentRecordModel paymentRecord,
    String? idempotencyKey,
  }) {
    return requestObject(
      'POST',
      '/api/payments',
      PaymentRecordModel.fromJson,
      body: paymentRecord.toJson(),
      contentType: 'application/json',
      idempotencyKey: idempotencyKey,
    );
  }

  Future<PaymentRecordModel> createPaymentForDriver({
    required int driverId,
    required PaymentRecordModel paymentRecord,
    String? idempotencyKey,
  }) {
    return requestObject(
      'POST',
      '/api/payments/driver/$driverId',
      PaymentRecordModel.fromJson,
      body: paymentRecord.copyWith(driverId: driverId).toJson(),
      contentType: 'application/json',
      idempotencyKey: idempotencyKey,
    );
  }

  Future<PaymentRecordModel> updatePayment({
    required int paymentId,
    required PaymentRecordModel paymentRecord,
    String? idempotencyKey,
  }) {
    return requestObject(
      'PUT',
      '/api/payments/$paymentId',
      PaymentRecordModel.fromJson,
      body: paymentRecord.toJson(),
      contentType: 'application/json',
      idempotencyKey: idempotencyKey,
    );
  }

  Future<void> deletePayment({required int paymentId}) {
    return requestVoid('DELETE', '/api/payments/$paymentId');
  }

  Future<PaymentRecordModel?> getPayment({
    required int paymentId,
  }) {
    return requestNullableObject(
      'GET',
      '/api/payments/$paymentId',
      PaymentRecordModel.fromJson,
    );
  }

  Future<List<PaymentRecordModel>> listPayments() {
    return requestList(
      'GET',
      '/api/payments',
      PaymentRecordModel.fromJson,
    );
  }

  Future<List<PaymentRecordModel>> listPaymentsByFine({
    required int fineId,
    int page = 1,
    int size = 20,
  }) {
    return _list('/api/payments/fine/$fineId', page: page, size: size);
  }

  Future<List<PaymentRecordModel>> listPaymentsByDriver({
    required int driverId,
    int page = 1,
    int size = 20,
  }) {
    return _list('/api/payments/driver/$driverId', page: page, size: size);
  }

  Future<List<PaymentRecordModel>> searchPaymentsByPayer({
    required String idCard,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(idCard, 'idCard');
    return _search('/api/payments/search/payer', {
      'idCard': idCard,
      'page': page,
      'size': size,
    });
  }

  Future<List<PaymentRecordModel>> searchPaymentsByStatus({
    required String status,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(status, 'status');
    return _search('/api/payments/search/status', {
      'status': status,
      'page': page,
      'size': size,
    });
  }

  Future<List<PaymentRecordModel>> searchPaymentsByTransaction({
    required String transactionId,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(transactionId, 'transactionId');
    return _search('/api/payments/search/transaction', {
      'transactionId': transactionId,
      'page': page,
      'size': size,
    });
  }

  Future<List<PaymentRecordModel>> searchPaymentsByPaymentNumber({
    required String paymentNumber,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(paymentNumber, 'paymentNumber');
    return _search('/api/payments/search/payment-number', {
      'paymentNumber': paymentNumber,
      'page': page,
      'size': size,
    });
  }

  Future<List<PaymentRecordModel>> searchPaymentsByPayerName({
    required String payerName,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(payerName, 'payerName');
    return _search('/api/payments/search/payer-name', {
      'payerName': payerName,
      'page': page,
      'size': size,
    });
  }

  Future<List<PaymentRecordModel>> searchPaymentsByPaymentMethod({
    required String paymentMethod,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(paymentMethod, 'paymentMethod');
    return _search('/api/payments/search/payment-method', {
      'paymentMethod': paymentMethod,
      'page': page,
      'size': size,
    });
  }

  Future<List<PaymentRecordModel>> searchPaymentsByPaymentChannel({
    required String paymentChannel,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(paymentChannel, 'paymentChannel');
    return _search('/api/payments/search/payment-channel', {
      'paymentChannel': paymentChannel,
      'page': page,
      'size': size,
    });
  }

  Future<List<PaymentRecordModel>> searchPaymentsByTimeRange({
    required String startTime,
    required String endTime,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(startTime, 'startTime');
    requireNotBlank(endTime, 'endTime');
    return _search('/api/payments/search/time-range', {
      'startTime': startTime,
      'endTime': endTime,
      'page': page,
      'size': size,
    });
  }

  Future<void> updatePaymentStatus(
    int id,
    String state, {
    required String idempotencyKey,
  }) {
    requireNotBlank(idempotencyKey, 'idempotencyKey');
    final upperState = state.toUpperCase();
    return requestVoid(
      'PUT',
      '/api/payments/$id/status/$upperState',
      idempotencyKey: idempotencyKey,
    );
  }

  Future<List<PaymentRecordModel>> _list(
    String path, {
    required int page,
    required int size,
  }) {
    return requestList(
      'GET',
      path,
      PaymentRecordModel.fromJson,
      queryParams: pageParams(page, size),
    );
  }

  Future<List<PaymentRecordModel>> _search(
    String path,
    Map<String, Object?> params,
  ) {
    return requestList(
      'GET',
      path,
      PaymentRecordModel.fromJson,
      queryParams: queryParamsFromMap(params),
    );
  }
}
