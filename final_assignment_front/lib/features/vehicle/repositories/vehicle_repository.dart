import 'dart:convert';

import 'package:final_assignment_front/core/repository/base_repository.dart';
import 'package:final_assignment_front/features/api/vehicle_information_controller_api.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';

abstract class VehicleRepository {
  Future<void> initializeWithJwt();

  Future<List<VehicleInformation>> getVehicles();

  Future<VehicleInformation?> getVehicle({required int vehicleId});

  Future<VehicleInformation> createVehicle({
    required VehicleInformation vehicle,
    required String idempotencyKey,
  });

  Future<VehicleInformation> updateVehicle({
    required int vehicleId,
    required VehicleInformation vehicle,
    required String idempotencyKey,
  });

  Future<void> deleteVehicle({required int vehicleId});

  Future<void> deleteVehicleByLicensePlate({required String licensePlate});

  Future<VehicleInformation?> searchByLicensePlate({
    required String licensePlate,
  });

  Future<List<VehicleInformation>> searchByOwnerIdCard({
    required String idCard,
  });

  Future<List<VehicleInformation>> searchByType({required String type});

  Future<List<VehicleInformation>> searchByOwnerName({
    required String ownerName,
  });

  Future<List<VehicleInformation>> searchByStatus({required String status});

  Future<List<VehicleInformation>> searchGeneral({
    required String keywords,
    int page = 1,
    int size = 20,
  });

  Future<List<String>> autocompleteLicensePlatesGlobal({
    required String prefix,
    int size = 10,
  });

  Future<List<String>> autocompleteLicensePlates({
    required String prefix,
    required String idCard,
    int size = 10,
  });

  Future<List<String>> autocompleteTypes({
    required String idCard,
    required String prefix,
    int size = 10,
  });

  Future<List<String>> autocompleteTypesGlobal({
    required String prefix,
    int size = 10,
  });

  Future<bool> existsLicensePlate({required String licensePlate});
}

class VehicleRepositoryImpl extends BaseRepository
    implements VehicleRepository {
  VehicleRepositoryImpl(
    VehicleInformationControllerApi api, {
    ApiClient? apiClient,
  })  : _api = api,
        _apiClient = apiClient ?? api.apiClient;

  final VehicleInformationControllerApi _api;
  final ApiClient _apiClient;

  @override
  Future<void> initializeWithJwt() {
    return guard(() => _api.initializeWithJwt());
  }

  @override
  Future<List<VehicleInformation>> getVehicles() {
    return guard(() async {
      await _api.initializeWithJwt();
      return _api.listVehicles();
    });
  }

  @override
  Future<VehicleInformation?> getVehicle({required int vehicleId}) {
    return guard(() async {
      await _api.initializeWithJwt();
      return _api.getVehicle(vehicleId: vehicleId);
    });
  }

  @override
  Future<VehicleInformation> createVehicle({
    required VehicleInformation vehicle,
    required String idempotencyKey,
  }) {
    return guard(() async {
      await _api.initializeWithJwt();
      final response = await _apiClient.invokeAPI(
        '/api/vehicles',
        'POST',
        const [],
        vehicle.toJson(),
        _headersWithIdempotencyKey(idempotencyKey),
        const {},
        'application/json',
        const ['bearerAuth'],
      );
      if (response.body.isEmpty) {
        throw ApiException(
            response.statusCode, 'Empty vehicle create response');
      }
      return VehicleInformation.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<VehicleInformation> updateVehicle({
    required int vehicleId,
    required VehicleInformation vehicle,
    required String idempotencyKey,
  }) {
    return guard(() async {
      await _api.initializeWithJwt();
      final response = await _apiClient.invokeAPI(
        '/api/vehicles/$vehicleId',
        'PUT',
        const [],
        vehicle.toJson(),
        _headersWithIdempotencyKey(idempotencyKey),
        const {},
        'application/json',
        const ['bearerAuth'],
      );
      if (response.body.isEmpty) {
        throw ApiException(
            response.statusCode, 'Empty vehicle update response');
      }
      return VehicleInformation.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<void> deleteVehicle({required int vehicleId}) {
    return guard(() async {
      await _api.initializeWithJwt();
      await _api.deleteVehicle(vehicleId: vehicleId);
    });
  }

  @override
  Future<void> deleteVehicleByLicensePlate({required String licensePlate}) {
    return guard(() async {
      await _api.initializeWithJwt();
      await _api.deleteVehicleByLicense(licensePlate: licensePlate);
    });
  }

  @override
  Future<VehicleInformation?> searchByLicensePlate({
    required String licensePlate,
  }) {
    return guard(() async {
      await _api.initializeWithJwt();
      return _api.searchVehiclesByLicense(licensePlate: licensePlate);
    });
  }

  @override
  Future<List<VehicleInformation>> searchByOwnerIdCard({
    required String idCard,
  }) {
    return guard(() async {
      await _api.initializeWithJwt();
      return _api.searchVehiclesByOwner(idCard: idCard);
    });
  }

  @override
  Future<List<VehicleInformation>> searchByType({required String type}) {
    return guard(() async {
      await _api.initializeWithJwt();
      return _api.searchVehiclesByType(type: type);
    });
  }

  @override
  Future<List<VehicleInformation>> searchByOwnerName({
    required String ownerName,
  }) {
    return guard(() async {
      await _api.initializeWithJwt();
      return _api.searchVehiclesByOwnerName(ownerName: ownerName);
    });
  }

  @override
  Future<List<VehicleInformation>> searchByStatus({required String status}) {
    return guard(() async {
      await _api.initializeWithJwt();
      return _api.searchVehiclesByStatus(status: status);
    });
  }

  @override
  Future<List<VehicleInformation>> searchGeneral({
    required String keywords,
    int page = 1,
    int size = 20,
  }) {
    return guard(() async {
      await _api.initializeWithJwt();
      return _api.searchVehiclesByGeneral(
        keywords: keywords,
        page: page,
        size: size,
      );
    });
  }

  @override
  Future<List<String>> autocompleteLicensePlatesGlobal({
    required String prefix,
    int size = 10,
  }) {
    return guard(() async {
      await _api.initializeWithJwt();
      return _api.searchVehiclesByLicenseGlobal(
        prefix: prefix,
        size: size,
      );
    });
  }

  @override
  Future<List<String>> autocompleteLicensePlates({
    required String prefix,
    required String idCard,
    int size = 10,
  }) {
    return guard(() async {
      await _api.initializeWithJwt();
      return _api.autocompleteVehiclePlates(
        prefix: prefix,
        idCard: idCard,
        size: size,
      );
    });
  }

  @override
  Future<List<String>> autocompleteTypes({
    required String idCard,
    required String prefix,
    int size = 10,
  }) {
    return guard(() async {
      await _api.initializeWithJwt();
      return _api.autocompleteVehicleTypes(
        idCard: idCard,
        prefix: prefix,
        size: size,
      );
    });
  }

  @override
  Future<List<String>> autocompleteTypesGlobal({
    required String prefix,
    int size = 10,
  }) {
    return guard(() async {
      await _api.initializeWithJwt();
      return _api.autocompleteVehicleTypesGlobal(
        prefix: prefix,
        size: size,
      );
    });
  }

  @override
  Future<bool> existsLicensePlate({required String licensePlate}) {
    return guard(() async {
      await _api.initializeWithJwt();
      return _api.vehicleLicensePlateExists(
        licensePlate: licensePlate,
      );
    });
  }

  Map<String, String> _headersWithIdempotencyKey(String idempotencyKey) {
    final trimmed = idempotencyKey.trim();
    if (trimmed.isEmpty) {
      throw ApiException(400, 'Missing required header: Idempotency-Key');
    }
    return {'Idempotency-Key': trimmed};
  }
}
