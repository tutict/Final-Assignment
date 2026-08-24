import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';

final ApiClient defaultApiClient = ApiClient();

class DriverInformationControllerApi with BaseApiClient {
  @override
  final ApiClient apiClient;

  DriverInformationControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  Future<void> initializeWithJwt() => initializeClientWithJwt();

  Future<void> createDriver({
    required DriverInformation driverInformation,
    required String idempotencyKey,
  }) {
    requireNotBlank(idempotencyKey, 'idempotencyKey');
    return requestVoid(
      'POST',
      '/api/drivers',
      body: driverInformation.toJson(),
      contentType: 'application/json',
      idempotencyKey: idempotencyKey,
    );
  }

  Future<DriverInformation?> getDriver({
    required int driverId,
  }) {
    return requestNullableObject(
      'GET',
      '/api/drivers/$driverId',
      DriverInformation.fromJson,
    );
  }

  Future<List<DriverInformation>> listDrivers() {
    return requestList('GET', '/api/drivers', DriverInformation.fromJson);
  }

  Future<void> updateDriverName({
    required int driverId,
    required String name,
    required String idempotencyKey,
  }) {
    requireNotBlank(idempotencyKey, 'idempotencyKey');
    return _updateStringField(driverId, 'name', name, idempotencyKey);
  }

  Future<void> updateDriverContactNumber({
    required int driverId,
    required String contactNumber,
    required String idempotencyKey,
  }) {
    requireNotBlank(idempotencyKey, 'idempotencyKey');
    return _updateStringField(
      driverId,
      'contactNumber',
      contactNumber,
      idempotencyKey,
    );
  }

  Future<void> updateDriverIdCardNumber({
    required int driverId,
    required String idCardNumber,
    required String idempotencyKey,
  }) {
    requireNotBlank(idempotencyKey, 'idempotencyKey');
    return _updateStringField(
      driverId,
      'idCardNumber',
      idCardNumber,
      idempotencyKey,
    );
  }

  Future<void> updateDriver({
    required int driverId,
    required DriverInformation driverInformation,
    required String idempotencyKey,
  }) {
    requireNotBlank(idempotencyKey, 'idempotencyKey');
    return requestVoid(
      'PUT',
      '/api/drivers/$driverId',
      body: driverInformation.toJson(),
      contentType: 'application/json',
      idempotencyKey: idempotencyKey,
    );
  }

  Future<void> deleteDriver({
    required int driverId,
  }) {
    return requestVoid('DELETE', '/api/drivers/$driverId');
  }

  Future<List<DriverInformation>> listDriversByIdCard({
    required String query,
    int page = 1,
    int size = 10,
  }) {
    return _search('/api/drivers/search/id-card', query, page, size);
  }

  Future<List<DriverInformation>> listDriversByLicenseNumber({
    required String query,
    int page = 1,
    int size = 10,
  }) {
    return _search('/api/drivers/search/license', query, page, size);
  }

  Future<List<DriverInformation>> listDriversByName({
    required String query,
    int page = 1,
    int size = 10,
  }) {
    return _search('/api/drivers/search/name', query, page, size);
  }

  Future<void> eventbusDriversPost({
    required DriverInformation driverInformation,
    required String idempotencyKey,
  }) async {
    final respMap = await sendWsRaw(
      service: 'DriverInformationService',
      action: 'checkAndInsertIdempotency',
      args: [idempotencyKey, driverInformation.toJson(), 'create'],
    );
    throwWsError(respMap, idempotencyKey: idempotencyKey);
  }

  Future<DriverInformation?> eventbusDriversDriverIdGet({
    required int driverId,
  }) {
    return sendWsObjectChecked(
      service: 'DriverInformationService',
      action: 'getDriverById',
      args: [driverId],
      fromJson: DriverInformation.fromJson,
    );
  }

  Future<List<DriverInformation>> eventbusDriversGet() {
    return sendWsListChecked(
      service: 'DriverInformationService',
      action: 'getAllDrivers',
      fromJson: DriverInformation.fromJson,
    );
  }

  Future<void> eventbusDriversDriverIdPut({
    required int driverId,
    required DriverInformation driverInformation,
    required String idempotencyKey,
  }) async {
    final respMap = await sendWsRaw(
      service: 'DriverInformationService',
      action: 'checkAndInsertIdempotency',
      args: [idempotencyKey, driverInformation.toJson(), 'update'],
    );
    if (isWsNotFound(respMap)) {
      throw AppException.http(404, 'Driver not found with ID: $driverId');
    }
    throwWsError(respMap, idempotencyKey: idempotencyKey);
  }

  Future<void> eventbusDriversDriverIdDelete({
    required int driverId,
  }) async {
    final respMap = await sendWsRaw(
      service: 'DriverInformationService',
      action: 'deleteDriver',
      args: [driverId],
    );
    if (isWsNotFound(respMap)) {
      throw AppException.http(404, 'Driver not found with ID: $driverId');
    }
    if (wsError(respMap).contains('Unauthorized')) {
      throw AppException.http(
        403,
        'Unauthorized: Only ADMIN can delete drivers',
      );
    }
    throwWsError(respMap);
  }

  Future<void> _updateStringField(
    int driverId,
    String field,
    String value,
    String idempotencyKey,
  ) {
    return requestVoid(
      'PUT',
      '/api/drivers/$driverId/$field',
      body: value,
      contentType: 'application/json',
      idempotencyKey: idempotencyKey,
    );
  }

  Future<List<DriverInformation>> _search(
    String path,
    String query,
    int page,
    int size,
  ) {
    requireNotBlank(query, 'query');
    return requestList(
      'GET',
      path,
      DriverInformation.fromJson,
      queryParams: queryParamsFromMap({
        'keywords': query,
        'page': page,
        'size': size,
      }),
    );
  }
}
