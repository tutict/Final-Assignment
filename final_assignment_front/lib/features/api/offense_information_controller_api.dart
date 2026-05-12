import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/features/model/offense_information.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:http/http.dart' as http;

final ApiClient defaultApiClient = ApiClient();

class OffenseInformationControllerApi with BaseApiClient {
  OffenseInformationControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  @override
  final ApiClient apiClient;

  Future<void> initializeWithJwt() => initializeClientWithJwt();

  Future<http.Response> _apiOffensesPost(OffenseInformation body) async {
    final idempotencyKey = resolveIdempotencyKey(body.idempotencyKey);
    return apiClient.invokeAPI(
      '/api/offenses',
      'POST',
      idempotencyParams(idempotencyKey),
      body.toJson(),
      await getHeaders(idempotencyKey: idempotencyKey),
      const {},
      'application/json',
      const ['bearerAuth'],
    );
  }

  Future<OffenseInformation> createOffense(OffenseInformation body) async {
    final response = await _apiOffensesPost(body);
    final statusMessages = {
      400: 'Invalid request data',
      409:
          'Duplicate request detected with idempotencyKey: ${body.idempotencyKey}',
    };
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

  Future<OffenseInformation?> getOffense({
    required int offenseId,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offenses/$offenseId',
      'GET',
      const [],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseNullableResponse(response, OffenseInformation.fromJson);
  }

  Future<List<OffenseInformation>> listOffenses() async {
    final response = await apiClient.invokeAPI(
      '/api/offenses',
      'GET',
      const [],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseListResponse(response, OffenseInformation.fromJson);
  }

  Future<OffenseInformation> updateOffense({
    required int offenseId,
    required OffenseInformation offenseInformation,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offenses/$offenseId',
      'PUT',
      idempotencyParams(idempotencyKey),
      offenseInformation.toJson(),
      await getHeaders(idempotencyKey: idempotencyKey),
      const {},
      'application/json',
      const ['bearerAuth'],
    );
    return parseResponse(
      response,
      OffenseInformation.fromJson,
      statusMessages: {
        404: 'Offense not found with ID: $offenseId',
        409: 'Duplicate request detected with idempotencyKey: $idempotencyKey',
      },
    );
  }

  Future<void> deleteOffense({
    required int offenseId,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offenses/$offenseId',
      'DELETE',
      const [],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    ensureSuccess(
      response,
      statusMessages: {
        404: 'Offense not found with ID: $offenseId',
        403: 'Unauthorized: Only ADMIN can delete offenses',
      },
    );
  }

  Future<List<OffenseInformation>> searchOffensesByTimeRange({
    String startTime = '1970-01-01',
    String endTime = '2100-01-01',
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offenses/search/time-range',
      'GET',
      [
        QueryParam('startTime', startTime),
        QueryParam('endTime', endTime),
      ],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseListResponse(response, OffenseInformation.fromJson);
  }

  Future<List<OffenseInformation>> listOffensesByOffenseType({
    required String query,
    int page = 1,
    int size = 10,
  }) async {
    if (query.isEmpty) {
      throw ApiException(400, 'Missing required param: query');
    }
    final response = await apiClient.invokeAPI(
      '/api/offenses/search/code',
      'GET',
      [
        QueryParam('offenseCode', query),
        QueryParam('page', page.toString()),
        QueryParam('size', size.toString()),
      ],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseListResponse(response, OffenseInformation.fromJson);
  }

  Future<List<OffenseInformation>> listOffensesByDriverName({
    required String query,
    int page = 1,
    int size = 10,
  }) async {
    if (query.isEmpty) {
      throw ApiException(400, 'Missing required param: query');
    }

    final headerParams = await getHeaders();
    final driverResp = await apiClient.invokeAPI(
      '/api/drivers/search/name',
      'GET',
      [
        QueryParam('keywords', query),
        QueryParam('page', '1'),
        QueryParam('size', '20'),
      ],
      null,
      headerParams,
      const {},
      null,
      const ['bearerAuth'],
    );
    final drivers = parseListResponse(driverResp, DriverInformation.fromJson);
    if (drivers.isEmpty) {
      return <OffenseInformation>[];
    }

    final merged = <int, OffenseInformation>{};
    for (final driver in drivers) {
      final driverId = driver.driverId;
      if (driverId == null) {
        continue;
      }
      final offensesResp = await apiClient.invokeAPI(
        '/api/offenses/driver/$driverId',
        'GET',
        [
          QueryParam('page', page.toString()),
          QueryParam('size', size.toString()),
        ],
        null,
        headerParams,
        const {},
        null,
        const ['bearerAuth'],
      );
      if (offensesResp.statusCode >= 400 ||
          decodeBodyBytes(offensesResp).trim().isEmpty) {
        continue;
      }
      final offenses =
          parseListResponse(offensesResp, OffenseInformation.fromJson);
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
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offenses/driver/$driverId',
      'GET',
      [
        QueryParam('page', page.toString()),
        QueryParam('size', size.toString()),
      ],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseListResponse(response, OffenseInformation.fromJson);
  }

  Future<List<OffenseInformation>> listOffensesByVehicle({
    required int vehicleId,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offenses/vehicle/$vehicleId',
      'GET',
      [
        QueryParam('page', page.toString()),
        QueryParam('size', size.toString()),
      ],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseListResponse(response, OffenseInformation.fromJson);
  }

  Future<List<OffenseInformation>> searchOffensesByStatus({
    required String processStatus,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offenses/search/status',
      'GET',
      [
        QueryParam('processStatus', processStatus),
        QueryParam('page', page.toString()),
        QueryParam('size', size.toString()),
      ],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseListResponse(response, OffenseInformation.fromJson);
  }

  Future<List<OffenseInformation>> searchOffensesByNumber({
    required String offenseNumber,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offenses/search/number',
      'GET',
      [
        QueryParam('offenseNumber', offenseNumber),
        QueryParam('page', page.toString()),
        QueryParam('size', size.toString()),
      ],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseListResponse(response, OffenseInformation.fromJson);
  }

  Future<List<OffenseInformation>> searchOffensesByLocation({
    required String offenseLocation,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offenses/search/location',
      'GET',
      [
        QueryParam('offenseLocation', offenseLocation),
        QueryParam('page', page.toString()),
        QueryParam('size', size.toString()),
      ],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseListResponse(response, OffenseInformation.fromJson);
  }

  Future<List<OffenseInformation>> searchOffensesByProvince({
    required String offenseProvince,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offenses/search/province',
      'GET',
      [
        QueryParam('offenseProvince', offenseProvince),
        QueryParam('page', page.toString()),
        QueryParam('size', size.toString()),
      ],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseListResponse(response, OffenseInformation.fromJson);
  }

  Future<List<OffenseInformation>> searchOffensesByCity({
    required String offenseCity,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offenses/search/city',
      'GET',
      [
        QueryParam('offenseCity', offenseCity),
        QueryParam('page', page.toString()),
        QueryParam('size', size.toString()),
      ],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseListResponse(response, OffenseInformation.fromJson);
  }

  Future<List<OffenseInformation>> searchOffensesByNotification({
    required String notificationStatus,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offenses/search/notification',
      'GET',
      [
        QueryParam('notificationStatus', notificationStatus),
        QueryParam('page', page.toString()),
        QueryParam('size', size.toString()),
      ],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseListResponse(response, OffenseInformation.fromJson);
  }

  Future<List<OffenseInformation>> searchOffensesByAgency({
    required String enforcementAgency,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offenses/search/agency',
      'GET',
      [
        QueryParam('enforcementAgency', enforcementAgency),
        QueryParam('page', page.toString()),
        QueryParam('size', size.toString()),
      ],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseListResponse(response, OffenseInformation.fromJson);
  }

  Future<List<OffenseInformation>> searchOffensesByFineRange({
    required double minAmount,
    required double maxAmount,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offenses/search/fine-range',
      'GET',
      [
        QueryParam('minAmount', minAmount.toString()),
        QueryParam('maxAmount', maxAmount.toString()),
        QueryParam('page', page.toString()),
        QueryParam('size', size.toString()),
      ],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseListResponse(response, OffenseInformation.fromJson);
  }

  Future<List<OffenseInformation>> listOffensesByLicensePlate({
    required String query,
    int page = 1,
    int size = 10,
  }) async {
    if (query.isEmpty) {
      throw ApiException(400, 'Missing required param: query');
    }

    final headerParams = await getHeaders();
    final vehicleResp = await apiClient.invokeAPI(
      '/api/vehicles/search/license',
      'GET',
      [QueryParam('licensePlate', query)],
      null,
      headerParams,
      const {},
      null,
      const ['bearerAuth'],
    );
    if (vehicleResp.statusCode == 404 ||
        decodeBodyBytes(vehicleResp).trim().isEmpty) {
      return <OffenseInformation>[];
    }
    final vehicle = parseResponse(vehicleResp, VehicleInformation.fromJson);
    final vehicleId = vehicle.vehicleId;
    if (vehicleId == null) {
      return <OffenseInformation>[];
    }

    final offenseResp = await apiClient.invokeAPI(
      '/api/offenses/vehicle/$vehicleId',
      'GET',
      [
        QueryParam('page', page.toString()),
        QueryParam('size', size.toString()),
      ],
      null,
      headerParams,
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseListResponse(offenseResp, OffenseInformation.fromJson);
  }
}
