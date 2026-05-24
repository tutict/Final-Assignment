import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';

final ApiClient defaultApiClient = ApiClient();

class VehicleInformationControllerApi with BaseApiClient {
  @override
  final ApiClient apiClient;

  VehicleInformationControllerApi([ApiClient? client])
      : apiClient = client ?? defaultApiClient;

  Future<void> initializeWithJwt() => initializeClientWithJwt();

  Future<List<VehicleInformation>> listVehicles() {
    return requestList(
      'GET',
      '/api/vehicles',
      VehicleInformation.fromJson,
    );
  }

  Future<VehicleInformation?> getVehicle({required int vehicleId}) {
    return requestNullableObject(
      'GET',
      '/api/vehicles/$vehicleId',
      VehicleInformation.fromJson,
    );
  }

  Future<VehicleInformation> createVehicle({
    required VehicleInformation vehicle,
    required String idempotencyKey,
  }) {
    requireNotBlank(idempotencyKey, 'idempotencyKey');
    return requestObject(
      'POST',
      '/api/vehicles',
      VehicleInformation.fromJson,
      body: vehicle.toJson(),
      contentType: 'application/json',
      idempotencyKey: idempotencyKey,
    );
  }

  Future<List<VehicleInformation>> listVehicleRecordsByDriver({
    required int driverId,
    int page = 1,
    int size = 20,
  }) {
    return requestList(
      'GET',
      '/api/vehicles/drivers/$driverId/records',
      VehicleInformation.fromJson,
      queryParams: pageParams(page, size),
    );
  }

  Future<VehicleInformation> updateVehicle({
    required int vehicleId,
    required VehicleInformation vehicle,
    required String idempotencyKey,
  }) {
    requireNotBlank(idempotencyKey, 'idempotencyKey');
    return requestObject(
      'PUT',
      '/api/vehicles/$vehicleId',
      VehicleInformation.fromJson,
      body: vehicle.toJson(),
      contentType: 'application/json',
      idempotencyKey: idempotencyKey,
    );
  }

  Future<void> deleteVehicle({required int vehicleId}) {
    return requestVoid('DELETE', '/api/vehicles/$vehicleId');
  }

  Future<void> deleteVehicleByLicense({required String licensePlate}) {
    requireNotBlank(licensePlate, 'licensePlate');
    return requestVoid(
      'DELETE',
      '/api/vehicles/license/${Uri.encodeComponent(licensePlate)}',
    );
  }

  Future<VehicleInformation?> searchVehiclesByLicense({
    required String licensePlate,
  }) {
    requireNotBlank(licensePlate, 'licensePlate');
    return requestNullableObject(
      'GET',
      '/api/vehicles/search/license',
      VehicleInformation.fromJson,
      queryParams: [QueryParam('licensePlate', licensePlate)],
    );
  }

  Future<List<VehicleInformation>> searchVehiclesByOwner({
    required String idCard,
  }) {
    requireNotBlank(idCard, 'idCard');
    return _searchList('/api/vehicles/search/owner', {'idCard': idCard});
  }

  Future<List<VehicleInformation>> searchVehiclesByType({
    required String type,
  }) {
    requireNotBlank(type, 'type');
    return _searchList('/api/vehicles/search/type', {'type': type});
  }

  Future<List<VehicleInformation>> searchVehiclesByOwnerName({
    required String ownerName,
  }) {
    requireNotBlank(ownerName, 'ownerName');
    return _searchList(
      '/api/vehicles/search/owner/name',
      {'ownerName': ownerName},
    );
  }

  Future<List<VehicleInformation>> searchVehiclesByStatus({
    required String status,
  }) {
    requireNotBlank(status, 'status');
    return _searchList('/api/vehicles/search/status', {'status': status});
  }

  Future<List<VehicleInformation>> searchVehiclesByGeneral({
    required String keywords,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(keywords, 'keywords');
    return _searchList('/api/vehicles/search/general', {
      'keywords': keywords,
      'page': page,
      'size': size,
    });
  }

  Future<List<String>> searchVehiclesByLicenseGlobal({
    required String prefix,
    int size = 10,
  }) {
    return _stringList('/api/vehicles/search/license/global', {
      'prefix': prefix,
      'size': size,
    });
  }

  Future<List<String>> autocompleteVehiclePlates({
    required String prefix,
    required String idCard,
    int size = 10,
  }) {
    return _stringList('/api/vehicles/autocomplete/plates', {
      'prefix': prefix,
      'size': size,
      'idCard': idCard,
    });
  }

  Future<List<String>> autocompleteVehicleTypes({
    required String idCard,
    required String prefix,
    int size = 10,
  }) {
    return _stringList('/api/vehicles/autocomplete/types', {
      'idCard': idCard,
      'prefix': prefix,
      'size': size,
    });
  }

  Future<List<String>> autocompleteVehicleTypesGlobal({
    required String prefix,
    int size = 10,
  }) {
    return _stringList('/api/vehicles/autocomplete/types/global', {
      'prefix': prefix,
      'size': size,
    });
  }

  Future<bool> vehicleLicensePlateExists({
    required String licensePlate,
  }) async {
    requireNotBlank(licensePlate, 'licensePlate');
    final data = await requestMap(
      'GET',
      '/api/vehicles/exists/${Uri.encodeComponent(licensePlate)}',
    );
    return data['exists'] as bool? ?? false;
  }

  Future<List<VehicleInformation>> _searchList(
    String path,
    Map<String, Object?> params,
  ) {
    return requestList(
      'GET',
      path,
      VehicleInformation.fromJson,
      queryParams: queryParamsFromMap(params),
    );
  }

  Future<List<String>> _stringList(
    String path,
    Map<String, Object?> params,
  ) {
    return requestValueList(
      'GET',
      path,
      (value) => value.toString(),
      queryParams: queryParamsFromMap(params),
    );
  }
}
