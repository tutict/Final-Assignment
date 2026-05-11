import 'dart:convert';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

final ApiClient defaultApiClient = ApiClient();

class VehicleInformationControllerApi with BaseApiClient {
  @override
  final ApiClient apiClient;
  VehicleInformationControllerApi([ApiClient? client])
      : apiClient = client ?? defaultApiClient;

  Future<void> initializeWithJwt() async {
    final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null) {
      throw Exception('Not authenticated. Please log in again.');
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint(
        'Initialized VehicleInformationControllerApi with token: $jwtToken');
  }

  String _decode(http.Response r) => decodeBodyBytes(r);

  Future<Map<String, String>> _headers({String? idempotencyKey}) async {
    return getHeaders(idempotencyKey: idempotencyKey);
  }

  // GET /api/vehicles
  Future<List<VehicleInformation>> listVehicles() async {
    final r = await apiClient.invokeAPI(
      '/api/vehicles',
      'GET',
      const [],
      null,
      await _headers(),
      const {},
      null,
      const ['bearerAuth'],
    );
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    if (r.body.isEmpty) return [];
    final List<dynamic> data = jsonDecode(_decode(r));
    return data.map((e) => VehicleInformation.fromJson(e)).toList();
  }

  // GET /api/vehicles/{vehicleId}
  Future<VehicleInformation?> getVehicle({required int vehicleId}) async {
    final r = await apiClient.invokeAPI(
      '/api/vehicles/$vehicleId',
      'GET',
      const [],
      null,
      await _headers(),
      const {},
      null,
      const ['bearerAuth'],
    );
    if (r.statusCode == 404) return null;
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    if (r.body.isEmpty) return null;
    return VehicleInformation.fromJson(jsonDecode(_decode(r)));
  }

  // POST /api/vehicles
  Future<VehicleInformation> createVehicle({
    required VehicleInformation vehicle,
    required String idempotencyKey,
  }) async {
    final r = await apiClient.invokeAPI(
      '/api/vehicles',
      'POST',
      const [],
      vehicle.toJson(),
      await _headers(idempotencyKey: idempotencyKey),
      const {},
      'application/json',
      const ['bearerAuth'],
    );
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    return VehicleInformation.fromJson(jsonDecode(_decode(r)));
  }

  // PUT /api/vehicles/{vehicleId}
  Future<VehicleInformation> updateVehicle({
    required int vehicleId,
    required VehicleInformation vehicle,
    required String idempotencyKey,
  }) async {
    final r = await apiClient.invokeAPI(
      '/api/vehicles/$vehicleId',
      'PUT',
      const [],
      vehicle.toJson(),
      await _headers(idempotencyKey: idempotencyKey),
      const {},
      'application/json',
      const ['bearerAuth'],
    );
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    return VehicleInformation.fromJson(jsonDecode(_decode(r)));
  }

  // DELETE /api/vehicles/{vehicleId}
  Future<void> deleteVehicle({required int vehicleId}) async {
    final r = await apiClient.invokeAPI(
      '/api/vehicles/$vehicleId',
      'DELETE',
      const [],
      null,
      await _headers(),
      const {},
      null,
      const ['bearerAuth'],
    );
    if (r.statusCode != 204) throw ApiException(r.statusCode, _decode(r));
  }

  // DELETE /api/vehicles/license/{licensePlate}
  Future<void> deleteVehicleByLicense({required String licensePlate}) async {
    final r = await apiClient.invokeAPI(
      '/api/vehicles/license/$licensePlate',
      'DELETE',
      const [],
      null,
      await _headers(),
      const {},
      null,
      const ['bearerAuth'],
    );
    if (r.statusCode != 204) throw ApiException(r.statusCode, _decode(r));
  }

  // GET /api/vehicles/search/license?licensePlate=
  Future<VehicleInformation?> searchVehiclesByLicense(
      {required String licensePlate}) async {
    final r = await apiClient.invokeAPI(
      '/api/vehicles/search/license',
      'GET',
      [QueryParam('licensePlate', licensePlate)],
      null,
      await _headers(),
      const {},
      null,
      const ['bearerAuth'],
    );
    if (r.statusCode == 404) return null;
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    if (r.body.isEmpty) return null;
    return VehicleInformation.fromJson(jsonDecode(_decode(r)));
  }

  // GET /api/vehicles/search/owner?idCard=
  Future<List<VehicleInformation>> searchVehiclesByOwner(
      {required String idCard}) async {
    final r = await apiClient.invokeAPI(
      '/api/vehicles/search/owner',
      'GET',
      [QueryParam('idCard', idCard)],
      null,
      await _headers(),
      const {},
      null,
      const ['bearerAuth'],
    );
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    if (r.body.isEmpty) return [];
    final List<dynamic> data = jsonDecode(_decode(r));
    return data.map((e) => VehicleInformation.fromJson(e)).toList();
  }

  // GET /api/vehicles/search/type?type=
  Future<List<VehicleInformation>> searchVehiclesByType(
      {required String type}) async {
    final r = await apiClient.invokeAPI(
      '/api/vehicles/search/type',
      'GET',
      [QueryParam('type', type)],
      null,
      await _headers(),
      const {},
      null,
      const ['bearerAuth'],
    );
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    if (r.body.isEmpty) return [];
    final List<dynamic> data = jsonDecode(_decode(r));
    return data.map((e) => VehicleInformation.fromJson(e)).toList();
  }

  // GET /api/vehicles/search/owner/name?ownerName=
  Future<List<VehicleInformation>> searchVehiclesByOwnerName(
      {required String ownerName}) async {
    final r = await apiClient.invokeAPI(
      '/api/vehicles/search/owner/name',
      'GET',
      [QueryParam('ownerName', ownerName)],
      null,
      await _headers(),
      const {},
      null,
      const ['bearerAuth'],
    );
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    if (r.body.isEmpty) return [];
    final List<dynamic> data = jsonDecode(_decode(r));
    return data.map((e) => VehicleInformation.fromJson(e)).toList();
  }

  // GET /api/vehicles/search/status?status=
  Future<List<VehicleInformation>> searchVehiclesByStatus(
      {required String status}) async {
    final r = await apiClient.invokeAPI(
      '/api/vehicles/search/status',
      'GET',
      [QueryParam('status', status)],
      null,
      await _headers(),
      const {},
      null,
      const ['bearerAuth'],
    );
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    if (r.body.isEmpty) return [];
    final List<dynamic> data = jsonDecode(_decode(r));
    return data.map((e) => VehicleInformation.fromJson(e)).toList();
  }

  // GET /api/vehicles/search/general?keywords=&page=&size=
  Future<List<VehicleInformation>> searchVehiclesByGeneral({
    required String keywords,
    int page = 1,
    int size = 20,
  }) async {
    final r = await apiClient.invokeAPI(
      '/api/vehicles/search/general',
      'GET',
      [
        QueryParam('keywords', keywords),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _headers(),
      const {},
      null,
      const ['bearerAuth'],
    );
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    if (r.body.isEmpty) return [];
    final List<dynamic> data = jsonDecode(_decode(r));
    return data.map((e) => VehicleInformation.fromJson(e)).toList();
  }

  // GET /api/vehicles/search/license/global?prefix=&size=
  Future<List<String>> searchVehiclesByLicenseGlobal({
    required String prefix,
    int size = 10,
  }) async {
    final r = await apiClient.invokeAPI(
      '/api/vehicles/search/license/global',
      'GET',
      [
        QueryParam('prefix', prefix),
        QueryParam('size', '$size'),
      ],
      null,
      await _headers(),
      const {},
      null,
      const ['bearerAuth'],
    );
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    if (r.body.isEmpty) return [];
    final List<dynamic> data = jsonDecode(_decode(r));
    return data.cast<String>();
  }

  // GET /api/vehicles/autocomplete/plates?prefix=&size=&idCard=
  Future<List<String>> autocompleteVehiclePlates({
    required String prefix,
    required String idCard,
    int size = 10,
  }) async {
    final r = await apiClient.invokeAPI(
      '/api/vehicles/autocomplete/plates',
      'GET',
      [
        QueryParam('prefix', prefix),
        QueryParam('size', '$size'),
        QueryParam('idCard', idCard),
      ],
      null,
      await _headers(),
      const {},
      null,
      const ['bearerAuth'],
    );
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    if (r.body.isEmpty) return [];
    final List<dynamic> data = jsonDecode(_decode(r));
    return data.cast<String>();
  }

  // GET /api/vehicles/autocomplete/types?idCard=&prefix=&size=
  Future<List<String>> autocompleteVehicleTypes({
    required String idCard,
    required String prefix,
    int size = 10,
  }) async {
    final r = await apiClient.invokeAPI(
      '/api/vehicles/autocomplete/types',
      'GET',
      [
        QueryParam('idCard', idCard),
        QueryParam('prefix', prefix),
        QueryParam('size', '$size'),
      ],
      null,
      await _headers(),
      const {},
      null,
      const ['bearerAuth'],
    );
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    if (r.body.isEmpty) return [];
    final List<dynamic> data = jsonDecode(_decode(r));
    return data.cast<String>();
  }

  // GET /api/vehicles/autocomplete/types/global?prefix=&size=
  Future<List<String>> autocompleteVehicleTypesGlobal({
    required String prefix,
    int size = 10,
  }) async {
    final r = await apiClient.invokeAPI(
      '/api/vehicles/autocomplete/types/global',
      'GET',
      [
        QueryParam('prefix', prefix),
        QueryParam('size', '$size'),
      ],
      null,
      await _headers(),
      const {},
      null,
      const ['bearerAuth'],
    );
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    if (r.body.isEmpty) return [];
    final List<dynamic> data = jsonDecode(_decode(r));
    return data.cast<String>();
  }

  // GET /api/vehicles/exists/{licensePlate} -> {"exists": true/false}
  Future<bool> vehicleLicensePlateExists({required String licensePlate}) async {
    final r = await apiClient.invokeAPI(
      '/api/vehicles/exists/$licensePlate',
      'GET',
      const [],
      null,
      await _headers(),
      const {},
      null,
      const ['bearerAuth'],
    );
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _decode(r));
    final Map<String, dynamic> data = jsonDecode(_decode(r));
    return (data['exists'] as bool?) ?? false;
  }
}
