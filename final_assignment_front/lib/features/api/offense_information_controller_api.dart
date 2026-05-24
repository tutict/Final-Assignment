import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/features/model/offense_information.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';

final ApiClient defaultApiClient = ApiClient();

class OffenseInformationControllerApi with BaseApiClient {
  OffenseInformationControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  @override
  final ApiClient apiClient;

  Future<void> initializeWithJwt() => initializeClientWithJwt();

  Future<OffenseInformation> createOffense(OffenseInformation body) async {
    final idempotencyKey = resolveIdempotencyKey(body.idempotencyKey);
    final statusMessages = {
      400: 'Invalid request data',
      409:
          'Duplicate request detected with idempotencyKey: ${body.idempotencyKey}',
    };
    final response = await request(
      'POST',
      '/api/offenses',
      body: body.toJson(),
      contentType: BaseApiClient.defaultContentType,
      idempotencyKey: idempotencyKey,
    );
    if (decodeBodyBytes(response).trim().isEmpty) {
      ensureSuccess(response, statusMessages: statusMessages);
      return body;
    }
    return parseResponse(
      response,
      OffenseInformation.fromJson,
      statusMessages: statusMessages,
    );
  }

  Future<OffenseInformation?> getOffense({required int offenseId}) {
    return requestNullableObject(
      'GET',
      '/api/offenses/$offenseId',
      OffenseInformation.fromJson,
    );
  }

  Future<List<OffenseInformation>> listOffenses() {
    return requestList('GET', '/api/offenses', OffenseInformation.fromJson);
  }

  Future<OffenseInformation> updateOffense({
    required int offenseId,
    required OffenseInformation offenseInformation,
    required String idempotencyKey,
  }) {
    return requestObject(
      'PUT',
      '/api/offenses/$offenseId',
      OffenseInformation.fromJson,
      body: offenseInformation.toJson(),
      contentType: BaseApiClient.defaultContentType,
      idempotencyKey: idempotencyKey,
      statusMessages: {
        404: 'Offense not found with ID: $offenseId',
        409: 'Duplicate request detected with idempotencyKey: $idempotencyKey',
      },
    );
  }

  Future<void> deleteOffense({required int offenseId}) {
    return requestVoid(
      'DELETE',
      '/api/offenses/$offenseId',
      statusMessages: {
        404: 'Offense not found with ID: $offenseId',
        403: 'Unauthorized: Only ADMIN can delete offenses',
      },
    );
  }

  Future<List<OffenseInformation>> searchOffensesByTimeRange({
    String startTime = '1970-01-01T00:00:00',
    String endTime = '2100-01-01T23:59:59',
  }) {
    return _listOffenses(
      '/api/offenses/search/time-range',
      {'startTime': startTime, 'endTime': endTime},
    );
  }

  Future<List<OffenseInformation>> listOffensesByOffenseType({
    required String query,
    int page = 1,
    int size = 10,
  }) {
    if (query.isEmpty) {
      throw AppException.http(400, 'Missing required param: query');
    }
    return _listOffenses(
      '/api/offenses/search/code',
      {'offenseCode': query, 'page': page, 'size': size},
    );
  }

  Future<List<OffenseInformation>> listOffensesByDriverName({
    required String query,
    int page = 1,
    int size = 10,
  }) async {
    if (query.isEmpty) {
      throw AppException.http(400, 'Missing required param: query');
    }

    final drivers = await requestList(
      'GET',
      '/api/drivers/search/name',
      DriverInformation.fromJson,
      queryParams: queryParamsFromMap({
        'keywords': query,
        'page': 1,
        'size': 20,
      }),
    );
    if (drivers.isEmpty) {
      return <OffenseInformation>[];
    }

    final merged = <int, OffenseInformation>{};
    for (final driver in drivers) {
      final driverId = driver.driverId;
      if (driverId == null) {
        continue;
      }
      final offenses = await _listOffenses(
        '/api/offenses/driver/$driverId',
        {'page': page, 'size': size},
        swallowErrors: true,
      );
      for (final offense in offenses) {
        final offenseId = offense.offenseId;
        if (offenseId != null) {
          merged[offenseId] = offense;
        }
      }
    }
    return merged.values.toList();
  }

  Future<List<OffenseInformation>> listOffensesByDriver({
    required int driverId,
    int page = 1,
    int size = 20,
  }) {
    return _listOffenses(
      '/api/offenses/driver/$driverId',
      {'page': page, 'size': size},
    );
  }

  Future<List<OffenseInformation>> listOffensesByVehicle({
    required int vehicleId,
    int page = 1,
    int size = 20,
  }) {
    return _listOffenses(
      '/api/offenses/vehicle/$vehicleId',
      {'page': page, 'size': size},
    );
  }

  Future<List<OffenseInformation>> searchOffensesByStatus({
    required String processStatus,
    int page = 1,
    int size = 20,
  }) {
    return _listOffenses(
      '/api/offenses/search/status',
      {'status': processStatus, 'page': page, 'size': size},
    );
  }

  Future<List<OffenseInformation>> searchOffensesByNumber({
    required String offenseNumber,
    int page = 1,
    int size = 20,
  }) {
    return _listOffenses(
      '/api/offenses/search/number',
      {'offenseNumber': offenseNumber, 'page': page, 'size': size},
    );
  }

  Future<List<OffenseInformation>> searchOffensesByLocation({
    required String offenseLocation,
    int page = 1,
    int size = 20,
  }) {
    return _listOffenses(
      '/api/offenses/search/location',
      {'offenseLocation': offenseLocation, 'page': page, 'size': size},
    );
  }

  Future<List<OffenseInformation>> searchOffensesByProvince({
    required String offenseProvince,
    int page = 1,
    int size = 20,
  }) {
    return _listOffenses(
      '/api/offenses/search/province',
      {'offenseProvince': offenseProvince, 'page': page, 'size': size},
    );
  }

  Future<List<OffenseInformation>> searchOffensesByCity({
    required String offenseCity,
    int page = 1,
    int size = 20,
  }) {
    return _listOffenses(
      '/api/offenses/search/city',
      {'offenseCity': offenseCity, 'page': page, 'size': size},
    );
  }

  Future<List<OffenseInformation>> searchOffensesByNotification({
    required String notificationStatus,
    int page = 1,
    int size = 20,
  }) {
    return _listOffenses(
      '/api/offenses/search/notification',
      {'notificationStatus': notificationStatus, 'page': page, 'size': size},
    );
  }

  Future<List<OffenseInformation>> searchOffensesByAgency({
    required String enforcementAgency,
    int page = 1,
    int size = 20,
  }) {
    return _listOffenses(
      '/api/offenses/search/agency',
      {'enforcementAgency': enforcementAgency, 'page': page, 'size': size},
    );
  }

  Future<List<OffenseInformation>> searchOffensesByFineRange({
    required double minAmount,
    required double maxAmount,
    int page = 1,
    int size = 20,
  }) {
    return _listOffenses(
      '/api/offenses/search/fine-range',
      {
        'minAmount': minAmount,
        'maxAmount': maxAmount,
        'page': page,
        'size': size,
      },
    );
  }

  Future<List<OffenseInformation>> listOffensesByLicensePlate({
    required String query,
    int page = 1,
    int size = 10,
  }) async {
    if (query.isEmpty) {
      throw AppException.http(400, 'Missing required param: query');
    }

    final vehicle = await requestNullableObject(
      'GET',
      '/api/vehicles/search/license',
      VehicleInformation.fromJson,
      queryParams: [QueryParam('licensePlate', query)],
    );
    final vehicleId = vehicle?.vehicleId;
    if (vehicleId == null) {
      return <OffenseInformation>[];
    }
    return _listOffenses(
      '/api/offenses/vehicle/$vehicleId',
      {'page': page, 'size': size},
    );
  }

  Future<List<OffenseInformation>> _listOffenses(
    String path,
    Map<String, Object?> params, {
    bool swallowErrors = false,
  }) async {
    try {
      return await requestList(
        'GET',
        path,
        OffenseInformation.fromJson,
        queryParams: queryParamsFromMap(params),
      );
    } on AppException {
      if (swallowErrors) {
        return <OffenseInformation>[];
      }
      rethrow;
    }
  }
}
