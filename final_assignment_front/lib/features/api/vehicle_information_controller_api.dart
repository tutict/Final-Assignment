import 'dart:convert';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:final_assignment_front/utils/services/api_client.dart'; // Import ApiClient
import 'package:jwt_decoder/jwt_decoder.dart'; // For JWT parsing
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class VehicleInformationControllerApi {
  final ApiClient _apiClient;
  String? _username; // Store the logged-in user's username

  VehicleInformationControllerApi()
      : _apiClient = ApiClient(basePath: 'http://localhost:8081');

  /// Initialize with JWT and extract username
  Future<void> initializeWithJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken != null) {
      _apiClient.setJwtToken(jwtToken); // Set token in ApiClient
      final decodedToken = JwtDecoder.decode(jwtToken);
      _username = decodedToken['sub'] ??
          'Unknown'; // Extract username (e.g., hgl@hgl.com)
      debugPrint('Initialized with username: $_username');
    } else {
      throw Exception('JWT token not found in SharedPreferences');
    }
  }

  /// Search vehicles (supports pagination)
  Future<List<VehicleInformation>> apiVehiclesSearchGet({
    required String query,
    int page = 1,
    int size = 10,
  }) async {
    final queryParams = [
      QueryParam('query', query),
      QueryParam('page', page.toString()),
      QueryParam('size', size.toString()),
    ];
    final response = await _apiClient.invokeAPI(
      '/api/vehicles/search',
      'GET',
      queryParams,
      null,
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode == 200) {
      return _apiClient.deserialize(response.body, 'List<VehicleInformation>')
          as List<VehicleInformation>;
    }
    throw Exception(
        'Failed to search vehicles: ${response.statusCode} - ${response.body}');
  }

  /// Create vehicle information, setting ownerName to the logged-in user's username
  Future<void> apiVehiclesPost({
    required VehicleInformation vehicleInformation,
    required String idempotencyKey,
  }) async {
    if (_username == null) {
      throw Exception('User not authenticated. Call initializeWithJwt first.');
    }
    vehicleInformation.ownerName = _username; // Set ownerName to username
    final queryParams = [QueryParam('idempotencyKey', idempotencyKey)];
    final response = await _apiClient.invokeAPI(
      '/api/vehicles',
      'POST',
      queryParams,
      vehicleInformation,
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    debugPrint('POST Response: ${response.statusCode} - ${response.body}');
    if (response.statusCode != 201) {
      throw Exception(
          'Failed to create vehicle: ${response.statusCode} - ${response.body}');
    }
  }

  /// Get all vehicles
  Future<List<VehicleInformation>> apiVehiclesGet() async {
    final response = await _apiClient.invokeAPI(
      '/api/vehicles',
      'GET',
      [],
      null,
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode == 200) {
      return _apiClient.deserialize(response.body, 'List<VehicleInformation>')
          as List<VehicleInformation>;
    }
    throw Exception('Failed to fetch all vehicles: ${response.statusCode}');
  }

  /// Get vehicle by ID
  Future<VehicleInformation?> apiVehiclesVehicleIdGet(
      {required int vehicleId}) async {
    final response = await _apiClient.invokeAPI(
      '/api/vehicles/$vehicleId',
      'GET',
      [],
      null,
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode == 200) {
      return _apiClient.deserialize(response.body, 'VehicleInformation')
          as VehicleInformation;
    } else if (response.statusCode == 404) {
      return null;
    }
    throw Exception('Failed to fetch vehicle by ID: ${response.statusCode}');
  }

  /// Get vehicle by license plate
  Future<VehicleInformation?> apiVehiclesLicensePlateGet(
      {required String licensePlate}) async {
    final response = await _apiClient.invokeAPI(
      '/api/vehicles/license-plate/$licensePlate',
      'GET',
      [],
      null,
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode == 200) {
      return _apiClient.deserialize(response.body, 'VehicleInformation')
          as VehicleInformation;
    } else if (response.statusCode == 404) {
      return null;
    }
    throw Exception(
        'Failed to fetch vehicle by license plate: ${response.statusCode}');
  }

  /// Get vehicles by type
  Future<List<VehicleInformation>> apiVehiclesTypeGet(
      {required String vehicleType}) async {
    final response = await _apiClient.invokeAPI(
      '/api/vehicles/type/$vehicleType',
      'GET',
      [],
      null,
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode == 200) {
      return _apiClient.deserialize(response.body, 'List<VehicleInformation>')
          as List<VehicleInformation>;
    }
    throw Exception('Failed to fetch vehicles by type: ${response.statusCode}');
  }

  /// Get vehicles by owner (supports optional ownerName for admin search)
  Future<List<VehicleInformation>> apiVehiclesOwnerGet(
      {String? ownerName}) async {
    final effectiveOwnerName = ownerName ?? _username;
    if (effectiveOwnerName == null) {
      throw Exception(
          'User not authenticated and no ownerName provided. Call initializeWithJwt first.');
    }
    final response = await _apiClient.invokeAPI(
      '/api/vehicles/owner/$effectiveOwnerName',
      'GET',
      [],
      null,
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    debugPrint('Owner Response: ${response.statusCode} - ${response.body}');
    if (response.statusCode == 200) {
      return _apiClient.deserialize(response.body, 'List<VehicleInformation>')
          as List<VehicleInformation>;
    }
    throw Exception(
        'Failed to fetch vehicles by owner: ${response.statusCode} - ${response.body}');
  }

  /// Get vehicles by status
  Future<List<VehicleInformation>> apiVehiclesStatusGet(
      {required String currentStatus}) async {
    final response = await _apiClient.invokeAPI(
      '/api/vehicles/status/$currentStatus',
      'GET',
      [],
      null,
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode == 200) {
      return _apiClient.deserialize(response.body, 'List<VehicleInformation>')
          as List<VehicleInformation>;
    }
    throw Exception(
        'Failed to fetch vehicles by status: ${response.statusCode}');
  }

  /// Update vehicle information
  Future<VehicleInformation> apiVehiclesVehicleIdPut({
    required int vehicleId,
    required VehicleInformation vehicleInformation,
    required String idempotencyKey,
  }) async {
    final queryParams = [QueryParam('idempotencyKey', idempotencyKey)];
    final response = await _apiClient.invokeAPI(
      '/api/vehicles/$vehicleId',
      'PUT',
      queryParams,
      vehicleInformation,
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode == 200) {
      return _apiClient.deserialize(response.body, 'VehicleInformation')
          as VehicleInformation;
    }
    throw Exception(
        'Failed to update vehicle: ${response.statusCode} - ${response.body}');
  }

  /// Delete vehicle by ID
  Future<void> apiVehiclesVehicleIdDelete({required int vehicleId}) async {
    final response = await _apiClient.invokeAPI(
      '/api/vehicles/$vehicleId',
      'DELETE',
      [],
      null,
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode != 204) {
      throw Exception(
          'Failed to delete vehicle: ${response.statusCode} - ${response.body}');
    }
  }

  /// Delete vehicle by license plate
  Future<void> apiVehiclesLicensePlateDelete(
      {required String licensePlate}) async {
    final response = await _apiClient.invokeAPI(
      '/api/vehicles/license-plate/$licensePlate',
      'DELETE',
      [],
      null,
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode != 204) {
      throw Exception(
          'Failed to delete vehicle by license plate: ${response.statusCode} - ${response.body}');
    }
  }

  /// Check if license plate exists
  Future<bool> apiVehiclesExistsGet({required String licensePlate}) async {
    final response = await _apiClient.invokeAPI(
      '/api/vehicles/exists/$licensePlate',
      'GET',
      [],
      null,
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode == 200) {
      return _apiClient.deserialize(response.body, 'bool') as bool;
    }
    throw Exception(
        'Failed to check license plate existence: ${response.statusCode}');
  }
}
