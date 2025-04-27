import 'dart:convert';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
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
    required String idCardNumber,
    int maxSuggestions = 5,
  }) async {
    if (idCardNumber.trim().isEmpty) {
      throw Exception('ID card number is required.');
    }

    final queryParameters = <String, dynamic>{
      'prefix': Uri.encodeQueryComponent(prefix),
      'maxSuggestions': maxSuggestions.toString(),
      'idCardNumber': Uri.encodeQueryComponent(idCardNumber),
    };

    final uri = Uri.parse(
            'http://localhost:8081/api/vehicles/autocomplete/license-plate/me')
        .replace(queryParameters: queryParameters);

    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('JWT token not found in SharedPreferences');
    }
    debugPrint('Request URL: $uri');
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
    } else if (response.statusCode == 400) {
      debugPrint('Invalid idCardNumber or prefix: ${response.body}');
      throw Exception('Invalid ID card number or prefix: ${response.body}');
    } else if (response.statusCode == 404) {
      debugPrint(
          'No license plate suggestions found for prefix: $prefix, idCardNumber: $idCardNumber');
      return [];
    }
    throw Exception(
        'Failed to fetch license plate suggestions: ${response.statusCode} - ${response.body}');
  }

  // Autocomplete suggestions for vehicle type (current user)
  Future<List<String>> apiVehiclesAutocompleteVehicleTypeMeGet({
    required String prefix,
    required String idCardNumber,
    int maxSuggestions = 5,
  }) async {
    if (idCardNumber.trim().isEmpty) {
      throw Exception('ID card number is required.');
    }

    final queryParameters = <String, dynamic>{
      'prefix': Uri.encodeQueryComponent(prefix),
      'maxSuggestions': maxSuggestions.toString(),
      'idCardNumber': Uri.encodeQueryComponent(idCardNumber),
    };

    final uri = Uri.parse(
            'http://localhost:8081/api/vehicles/autocomplete/vehicle-type/me')
        .replace(queryParameters: queryParameters);

    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('JWT token not found in SharedPreferences');
    }
    debugPrint('Request URL: $uri');
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
    } else if (response.statusCode == 400) {
      debugPrint('Invalid idCardNumber or prefix: ${response.body}');
      throw Exception('Invalid ID card number or prefix: ${response.body}');
    } else if (response.statusCode == 404) {
      debugPrint(
          'No vehicle type suggestions found for prefix: $prefix, idCardNumber: $idCardNumber');
      return [];
    }
    throw Exception(
        'Failed to fetch vehicle type suggestions: ${response.statusCode} - ${response.body}');
  }

  // Existing methods (e.g., getAllVehicles, getVehiclesByOwnerIdCardNumber) remain unchanged
  Future<List<VehicleInformation>?> getAllVehicles({
    required int page,
    required int size,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'size': size,
    };

    final uri = Uri.parse('http://localhost:8081/api/vehicles/all')
        .replace(queryParameters: queryParameters);

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
      final List<dynamic> data = jsonDecode(decodedBody);
      return data.map((json) => VehicleInformation.fromJson(json)).toList();
    }
    debugPrint(
        'Error fetching all vehicles: ${response.statusCode} - ${response.body}');
    return null;
  }

  Future<List<VehicleInformation>?> getVehiclesByOwnerIdCardNumber({
    required String idCardNumber,
    required int page,
    required int size,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'size': size,
    };

    final uri =
        Uri.parse('http://localhost:8081/api/vehicles/owner/$idCardNumber')
            .replace(queryParameters: queryParameters);

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
      final List<dynamic> data = jsonDecode(decodedBody);
      return data.map((json) => VehicleInformation.fromJson(json)).toList();
    }
    debugPrint(
        'Error fetching vehicles by idCardNumber: ${response.statusCode} - ${response.body}');
    return null;
  }

  Future<List<String>> apiVehiclesLicensePlateGloballyGet({
    required String licensePlate,
  }) async {
    final queryParameters = <String, dynamic>{
      'licensePlate': Uri.encodeQueryComponent(licensePlate),
    };

    final uri = Uri.parse(
            'http://localhost:8081/api/vehicles/autocomplete/license-plate-globally/me')
        .replace(queryParameters: queryParameters);

    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('JWT token not found in SharedPreferences');
    }
    debugPrint('Request URL: $uri');
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
      debugPrint('Raw response body (license plate suggestions): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      return data.cast<String>();
    } else if (response.statusCode == 404 || response.statusCode == 400) {
      debugPrint('No license plate suggestions found for: $licensePlate');
      return [];
    }
    throw Exception(
        'Failed to fetch license plate suggestions: ${response.statusCode} - ${response.body}');
  }

  // Get vehicle type suggestions globally
  Future<List<String>> apiVehiclesTypeGloballyGet({
    required String vehicleType,
  }) async {
    final queryParameters = <String, dynamic>{
      'vehicleType': Uri.encodeQueryComponent(vehicleType),
    };

    final uri = Uri.parse(
            'http://localhost:8081/api/vehicles/autocomplete/vehicle-type-globally/me')
        .replace(queryParameters: queryParameters);

    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('JWT token not found in SharedPreferences');
    }
    debugPrint('Request URL: $uri');
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
      debugPrint('Raw response body (vehicle type suggestions): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      return data.cast<String>();
    } else if (response.statusCode == 404 || response.statusCode == 400) {
      debugPrint('No vehicle type suggestions found for: $vehicleType');
      return [];
    }
    throw Exception(
        'Failed to fetch vehicle type suggestions: ${response.statusCode} - ${response.body}');
  }

  // Get vehicle by license plate
  Future<VehicleInformation?> getVehicleByLicensePlate({
    required String licensePlate,
  }) async {
    final uri = Uri.parse(
        'http://localhost:8081/api/vehicles/license-plate/${Uri.encodeComponent(licensePlate)}');

    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('JWT token not found in SharedPreferences');
    }
    debugPrint('Request URL: $uri');
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
      debugPrint('Raw response body (vehicle by license plate): $decodedBody');
      return VehicleInformation.fromJson(jsonDecode(decodedBody));
    } else if (response.statusCode == 404) {
      debugPrint('No vehicle found for license plate: $licensePlate');
      return null;
    } else if (response.statusCode == 400) {
      debugPrint('Invalid license plate: ${response.body}');
      throw Exception('Invalid license plate: ${response.body}');
    }
    throw Exception(
        'Failed to fetch vehicle by license plate: ${response.statusCode} - ${response.body}');
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
  Future<List<VehicleInformation>> apiVehiclesGet() async {
    final response = await _apiClient.invokeAPI(
      '/api/vehicles',
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
      debugPrint('Raw response body (get all vehicles): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      return VehicleInformation.listFromJson(data);
    } else if (response.statusCode == 404) {
      debugPrint('No vehicles found (404)');
      return [];
    } else if (response.statusCode == 403) {
      debugPrint('Access denied: Invalid or missing JWT (403)');
      throw Exception('认证失败：请重新登录');
    } else if (response.statusCode == 401) {
      debugPrint('Unauthorized: Invalid JWT (401)');
      throw Exception('未授权：请重新登录');
    }
    debugPrint(
        'Failed to fetch vehicles: ${response.statusCode} - ${response.body}');
    throw Exception('获取车辆信息失败：${response.statusCode}');
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

// Get vehicles by owner's ID card number
  Future<List<VehicleInformation>> apiVehiclesOwnerIdCardNumberGet({
    required String idCardNumber,
    int page = 1,
    int size = 10,
  }) async {
    if (idCardNumber.trim().isEmpty) {
      throw Exception('ID card number is required.');
    }
    final queryParams = [
      QueryParam('page', page.toString()),
      QueryParam('size', size.toString()),
    ];
    final response = await _apiClient.invokeAPI(
      '/api/vehicles/id-card-number/$idCardNumber',
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
      debugPrint(
          'Raw response body (get by owner ID card number): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      return VehicleInformation.listFromJson(data);
    } else if (response.statusCode == 404) {
      return [];
    }
    throw Exception(
        "Failed to fetch vehicles by owner's ID card number: ${response.statusCode} - ${response.body}");
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
    final queryParams = [
      QueryParam('page', page.toString()),
      QueryParam('size', size.toString()),
    ];
    final response = await _apiClient.invokeAPI(
      '/api/vehicles/owner/$effectiveOwnerName',
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
      debugPrint('Raw response body (get by owner): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      return VehicleInformation.listFromJson(data);
    } else if (response.statusCode == 404) {
      return [];
    }
    throw Exception(
        'Failed to fetch vehicles by owner: ${response.statusCode} - ${response.body}');
  }

// Get vehicles by status
  Future<List<VehicleInformation>> apiVehiclesStatusGet({
    required String currentStatus,
    int page = 1,
    int size = 10,
  }) async {
    final queryParams = [
      QueryParam('page', page.toString()),
      QueryParam('size', size.toString()),
    ];
    final response = await _apiClient.invokeAPI(
      '/api/vehicles/status/$currentStatus',
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
      debugPrint('Raw response body (get by status): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      return VehicleInformation.listFromJson(data);
    } else if (response.statusCode == 404) {
      return [];
    }
    throw Exception(
        'Failed to fetch vehicles by status: ${response.statusCode} - ${response.body}');
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
        'Failed to check license plate existence: ${response.statusCode} - ${response.body}');
  }
}
