import 'dart:convert';
import 'package:final_assignment_front/features/model/vehicle_information.dart'; // Assuming this is the correct model
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class VehicleInformationControllerApi {
  final ApiClient _apiClient;
  String? _username;

  VehicleInformationControllerApi()
      : _apiClient = ApiClient(basePath: 'http://localhost:8081');

  Future<void> initializeWithJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken != null) {
      _apiClient.setJwtToken(jwtToken);
      final decodedToken = JwtDecoder.decode(jwtToken);
      _username = decodedToken['sub'] ?? 'Unknown';
      debugPrint('Initialized with username: $_username');
    } else {
      throw Exception('JWT token not found in SharedPreferences');
    }
  }

  // Search vehicles by query
  Future<List<VehicleInformation>> apiVehiclesSearchGet({
    required String query,
    int page = 1,
    int size = 10,
  }) async {
    final uri = Uri.parse(
        'http://localhost:8081/api/vehicles/search?query=${Uri.encodeQueryComponent(query)}&page=$page&size=$size');
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint('Raw response body (search): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      return data.map((json) => VehicleInformation.fromJson(json)).toList();
    } else if (response.statusCode == 400 || response.statusCode == 404) {
      return [];
    }
    throw Exception(
        'Failed to search vehicles: ${response.statusCode} - ${response.body}');
  }

  // Autocomplete suggestions for license plate (current user)
  Future<List<String>> apiVehiclesAutocompleteLicensePlateMeGet({
    required String prefix,
    int maxSuggestions = 5,
  }) async {
    final uri = Uri.parse(
        'http://localhost:8081/api/vehicles/autocomplete/license-plate/me?prefix=${Uri.encodeQueryComponent(prefix)}&maxSuggestions=$maxSuggestions');
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('JWT token not found in SharedPreferences');
    }

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint(
          'Raw response body (license plate autocomplete): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      return data.cast<String>();
    } else if (response.statusCode == 404) {
      debugPrint('No license plate suggestions found for prefix: $prefix');
      return [];
    } else if (response.statusCode == 400) {
      throw Exception('Invalid prefix for license plate: ${response.body}');
    }
    throw Exception(
        'Failed to fetch license plate suggestions: ${response.statusCode} - ${response.body}');
  }

  // Autocomplete suggestions for vehicle type (current user)
  Future<List<String>> apiVehiclesAutocompleteVehicleTypeMeGet({
    required String prefix,
    int maxSuggestions = 5,
  }) async {
    final uri = Uri.parse(
        'http://localhost:8081/api/vehicles/autocomplete/vehicle-type/me?prefix=${Uri.encodeQueryComponent(prefix)}&maxSuggestions=$maxSuggestions');
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('JWT token not found in SharedPreferences');
    }

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint('Raw response body (vehicle type autocomplete): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      return data.cast<String>();
    } else if (response.statusCode == 404) {
      debugPrint('No vehicle type suggestions found for prefix: $prefix');
      return [];
    } else if (response.statusCode == 400) {
      throw Exception('Invalid prefix for vehicle type: ${response.body}');
    }
    throw Exception(
        'Failed to fetch vehicle type suggestions: ${response.statusCode} - ${response.body}');
  }

  // Create vehicle
  Future<void> apiVehiclesPost({
    required VehicleInformation vehicleInformation,
    required String idempotencyKey,
  }) async {
    if (_username == null) {
      throw Exception('User not authenticated. Call initializeWithJwt first.');
    }
    vehicleInformation.ownerName = _username;
    final queryParams = [QueryParam('idempotencyKey', idempotencyKey)];
    final response = await _apiClient.invokeAPI(
      '/api/vehicles',
      'POST',
      queryParams,
      vehicleInformation,
      {'Content-Type': 'application/json; charset=UTF-8'},
      {'Accept': 'application/json; charset=UTF-8'},
      'application/json',
      ['bearerAuth'],
    );
    debugPrint('POST Response: ${response.statusCode} - ${response.body}');
    if (response.statusCode != 201) {
      throw Exception(
          'Failed to create vehicle: ${response.statusCode} - ${response.body}');
    }
  }

  // Get all vehicles
  Future<List<VehicleInformation>> apiVehiclesGet({
    int page = 1,
    int size = 10,
  }) async {
    final queryParams = [
      QueryParam('page', page.toString()),
      QueryParam('size', size.toString()),
    ];
    final response = await _apiClient.invokeAPI(
      '/api/vehicles',
      'GET',
      queryParams,
      null,
      {'Content-Type': 'application/json; charset=UTF-8'},
      {'Accept': 'application/json; charset=UTF-8'},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint('Raw response body (get all): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      return VehicleInformation.listFromJson(data);
    } else if (response.statusCode == 404) {
      return [];
    }
    throw Exception('Failed to fetch all vehicles: ${response.statusCode}');
  }

  // Get vehicle by ID
  Future<VehicleInformation?> apiVehiclesVehicleIdGet({
    required int vehicleId,
  }) async {
    final response = await _apiClient.invokeAPI(
      '/api/vehicles/$vehicleId',
      'GET',
      [],
      null,
      {'Content-Type': 'application/json; charset=UTF-8'},
      {'Accept': 'application/json; charset=UTF-8'},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint('Raw response body (get by ID): $decodedBody');
      return VehicleInformation.fromJson(jsonDecode(decodedBody));
    } else if (response.statusCode == 404) {
      return null;
    }
    throw Exception('Failed to fetch vehicle by ID: ${response.statusCode}');
  }

  // Get vehicle by license plate
  Future<VehicleInformation?> apiVehiclesLicensePlateGet({
    required String licensePlate,
  }) async {
    final response = await _apiClient.invokeAPI(
      '/api/vehicles/license-plate/$licensePlate',
      'GET',
      [],
      null,
      {'Content-Type': 'application/json; charset=UTF-8'},
      {'Accept': 'application/json; charset=UTF-8'},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint('Raw response body (get by license plate): $decodedBody');
      return VehicleInformation.fromJson(jsonDecode(decodedBody));
    } else if (response.statusCode == 404) {
      return null;
    }
    throw Exception(
        'Failed to fetch vehicle by license plate: ${response.statusCode}');
  }

  // Get vehicles by type
  Future<List<VehicleInformation>> apiVehiclesTypeGet({
    required String vehicleType,
    int page = 1,
    int size = 10,
  }) async {
    final queryParams = [
      QueryParam('page', page.toString()),
      QueryParam('size', size.toString()),
    ];
    final response = await _apiClient.invokeAPI(
      '/api/vehicles/type/$vehicleType',
      'GET',
      queryParams,
      null,
      {'Content-Type': 'application/json; charset=UTF-8'},
      {'Accept': 'application/json; charset=UTF-8'},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint('Raw response body (get by type): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      return VehicleInformation.listFromJson(data);
    } else if (response.statusCode == 404) {
      return [];
    }
    throw Exception('Failed to fetch vehicles by type: ${response.statusCode}');
  }

  // Get vehicles by owner
  Future<List<VehicleInformation>> apiVehiclesOwnerGet({
    String? ownerName,
    int page = 1,
    int size = 10,
  }) async {
    final effectiveOwnerName = ownerName ?? _username;
    if (effectiveOwnerName == null) {
      throw Exception('User not authenticated and no ownerName provided.');
    }
    final response = await _apiClient.invokeAPI(
      '/api/vehicles/owner/$effectiveOwnerName',
      'GET',
      [],
      null,
      {'Content-Type': 'application/json; charset=UTF-8'},
      {'Accept': 'application/json; charset=UTF-8'},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint('Raw response body (get by owner): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      return VehicleInformation.listFromJson(data);
    } else if (response.statusCode == 404) {
      return [];
    }
    throw Exception(
        'Failed to fetch vehicles by owner: ${response.statusCode}');
  }

  // Get vehicles by status
  Future<List<VehicleInformation>> apiVehiclesStatusGet({
    required String currentStatus,
  }) async {
    final response = await _apiClient.invokeAPI(
      '/api/vehicles/status/$currentStatus',
      'GET',
      [],
      null,
      {'Content-Type': 'application/json; charset=UTF-8'},
      {'Accept': 'application/json; charset=UTF-8'},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint('Raw response body (get by status): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      return VehicleInformation.listFromJson(data);
    } else if (response.statusCode == 404) {
      return [];
    }
    throw Exception(
        'Failed to fetch vehicles by status: ${response.statusCode}');
  }

  // Update vehicle
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
      {'Content-Type': 'application/json; charset=UTF-8'},
      {'Accept': 'application/json; charset=UTF-8'},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint('Raw response body (update): $decodedBody');
      return VehicleInformation.fromJson(jsonDecode(decodedBody));
    }
    throw Exception(
        'Failed to update vehicle: ${response.statusCode} - ${response.body}');
  }

  // Delete vehicle by ID
  Future<void> apiVehiclesVehicleIdDelete({
    required int vehicleId,
  }) async {
    final response = await _apiClient.invokeAPI(
      '/api/vehicles/$vehicleId',
      'DELETE',
      [],
      null,
      {'Content-Type': 'application/json; charset=UTF-8'},
      {'Accept': 'application/json; charset=UTF-8'},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode != 204) {
      throw Exception(
          'Failed to delete vehicle: ${response.statusCode} - ${response.body}');
    }
  }

  // Delete vehicle by license plate
  Future<void> apiVehiclesLicensePlateDelete({
    required String licensePlate,
  }) async {
    final response = await _apiClient.invokeAPI(
      '/api/vehicles/license-plate/$licensePlate',
      'DELETE',
      [],
      null,
      {'Content-Type': 'application/json; charset=UTF-8'},
      {'Accept': 'application/json; charset=UTF-8'},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode != 204) {
      throw Exception(
          'Failed to delete vehicle by license plate: ${response.statusCode} - ${response.body}');
    }
  }

  // Check if license plate exists
  Future<bool> apiVehiclesExistsGet({
    required String licensePlate,
  }) async {
    final response = await _apiClient.invokeAPI(
      '/api/vehicles/exists/$licensePlate',
      'GET',
      [],
      null,
      {'Content-Type': 'application/json; charset=UTF-8'},
      {'Accept': 'application/json; charset=UTF-8'},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint('Raw response body (exists): $decodedBody');
      return jsonDecode(decodedBody) as bool;
    }
    throw Exception(
        'Failed to check license plate existence: ${response.statusCode}');
  }
}
