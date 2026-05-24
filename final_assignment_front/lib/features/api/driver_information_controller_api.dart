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
    _throwWsError(respMap, idempotencyKey: idempotencyKey);
  }

  Future<DriverInformation?> eventbusDriversDriverIdGet({
    required int driverId,
  }) async {
    final respMap = await sendWsRaw(
      service: 'DriverInformationService',
      action: 'getDriverById',
      args: [driverId],
    );
    if (_isWsNotFound(respMap)) return null;
    _throwWsError(respMap);
    return _driverFromWsResult(respMap);
  }

  Future<List<DriverInformation>> eventbusDriversGet() async {
    final respMap = await sendWsRaw(
      service: 'DriverInformationService',
      action: 'getAllDrivers',
    );
    _throwWsError(respMap);
    return _driverListFromWsResult(respMap);
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
    if (_isWsNotFound(respMap)) {
      throw AppException.http(404, 'Driver not found with ID: $driverId');
    }
    _throwWsError(respMap, idempotencyKey: idempotencyKey);
  }

  Future<void> eventbusDriversDriverIdDelete({
    required int driverId,
  }) async {
    final respMap = await sendWsRaw(
      service: 'DriverInformationService',
      action: 'deleteDriver',
      args: [driverId],
    );
    if (_isWsNotFound(respMap)) {
      throw AppException.http(404, 'Driver not found with ID: $driverId');
    }
    if (_wsError(respMap).contains('Unauthorized')) {
      throw AppException.http(
        403,
        'Unauthorized: Only ADMIN can delete drivers',
      );
    }
    _throwWsError(respMap);
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

  DriverInformation? _driverFromWsResult(Map<String, dynamic> response) {
    final result = response['result'];
    if (result == null) return null;
    return DriverInformation.fromJson(Map<String, dynamic>.from(result as Map));
  }

  List<DriverInformation> _driverListFromWsResult(
    Map<String, dynamic> response,
  ) {
    final result = response['result'];
    if (result is! List) return [];
    return result
        .map((json) => DriverInformation.fromJson(
              Map<String, dynamic>.from(json as Map),
            ))
        .toList();
  }

  bool _isWsNotFound(Map<String, dynamic> response) {
    return _wsError(response).toLowerCase().contains('not found');
  }

  String _wsError(Map<String, dynamic> response) {
    return response['error']?.toString() ?? '';
  }

  void _throwWsError(
    Map<String, dynamic> response, {
    String? idempotencyKey,
  }) {
    final error = _wsError(response);
    if (error.isEmpty) return;
    if (error.contains('Duplicate request')) {
      throw AppException.http(
        409,
        'Duplicate request detected with idempotencyKey: $idempotencyKey',
      );
    }
    throw AppException.http(400, error);
  }
}
