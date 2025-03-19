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
    debugPrint('Search query params: $queryParams');

    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    final uri = Uri.parse(
        'http://localhost:8081/api/vehicles/search?query=${Uri.encodeQueryComponent(query)}&page=$page&size=$size');
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
      debugPrint('Raw response body: $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      final vehicles =
          data.map((json) => VehicleInformation.fromJson(json)).toList();
      debugPrint(
          'Deserialized vehicles: ${vehicles.map((v) => v.toJson()).toList()}');
      return vehicles;
    }
    throw Exception(
        'Failed to search vehicles: ${response.statusCode} - ${response.body}');
  }

  // 新增方法：按车牌号搜索（仅当前用户）
  Future<List<VehicleInformation>>
      apiVehiclesSearchByLicensePlateForCurrentUser({
    required String licensePlate,
    int page = 1,
    int size = 10,
  }) async {
    final queryParams = [
      QueryParam('licensePlate', licensePlate),
      QueryParam('page', page.toString()),
      QueryParam('size', size.toString()),
    ];
    debugPrint(
        'Search by license plate (current user) query params: $queryParams');

    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    final uri = Uri.parse(
        'http://localhost:8081/api/vehicles/search/license-plate/me?licensePlate=${Uri.encodeQueryComponent(licensePlate)}&page=$page&size=$size');
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
          'Raw response body (search by license plate for current user): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      final vehicles =
          data.map((json) => VehicleInformation.fromJson(json)).toList();
      debugPrint(
          'Deserialized vehicles (search by license plate for current user): ${vehicles.map((v) => v.toJson()).toList()}');
      return vehicles;
    }
    throw Exception(
        'Failed to search vehicles by license plate for current user: ${response.statusCode} - ${response.body}');
  }

  // 新增方法：按车辆类型搜索（仅当前用户）
  Future<List<VehicleInformation>>
      apiVehiclesSearchByVehicleTypeForCurrentUser({
    required String vehicleType,
    int page = 1,
    int size = 10,
  }) async {
    final queryParams = [
      QueryParam('vehicleType', vehicleType),
      QueryParam('page', page.toString()),
      QueryParam('size', size.toString()),
    ];
    debugPrint(
        'Search by vehicle type (current user) query params: $queryParams');

    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    final uri = Uri.parse(
        'http://localhost:8081/api/vehicles/search/vehicle-type/me?vehicleType=${Uri.encodeQueryComponent(vehicleType)}&page=$page&size=$size');
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
          'Raw response body (search by vehicle type for current user): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      final vehicles =
          data.map((json) => VehicleInformation.fromJson(json)).toList();
      debugPrint(
          'Deserialized vehicles (search by vehicle type for current user): ${vehicles.map((v) => v.toJson()).toList()}');
      return vehicles;
    }
    throw Exception(
        'Failed to search vehicles by vehicle type for current user: ${response.statusCode} - ${response.body}');
  }

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
      debugPrint('Raw response body (apiVehiclesGet): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      final vehicles = VehicleInformation.listFromJson(data);
      debugPrint(
          'Deserialized vehicles (apiVehiclesGet): ${vehicles.map((v) => v.toJson()).toList()}');
      return vehicles;
    }
    throw Exception('Failed to fetch all vehicles: ${response.statusCode}');
  }

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
      debugPrint('Raw response body (apiVehiclesVehicleIdGet): $decodedBody');
      final vehicle = VehicleInformation.fromJson(jsonDecode(decodedBody));
      debugPrint(
          'Deserialized vehicle (apiVehiclesVehicleIdGet): ${vehicle.toJson()}');
      return vehicle;
    } else if (response.statusCode == 404) {
      return null;
    }
    throw Exception('Failed to fetch vehicle by ID: ${response.statusCode}');
  }

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
      debugPrint(
          'Raw response body (apiVehiclesLicensePlateGet): $decodedBody');
      final vehicle = VehicleInformation.fromJson(jsonDecode(decodedBody));
      debugPrint(
          'Deserialized vehicle (apiVehiclesLicensePlateGet): ${vehicle.toJson()}');
      return vehicle;
    } else if (response.statusCode == 404) {
      return null;
    }
    throw Exception(
        'Failed to fetch vehicle by license plate: ${response.statusCode}');
  }

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
      debugPrint('Raw response body (apiVehiclesTypeGet): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      final vehicles = VehicleInformation.listFromJson(data);
      debugPrint(
          'Deserialized vehicles (apiVehiclesTypeGet): ${vehicles.map((v) => v.toJson()).toList()}');
      return vehicles;
    }
    throw Exception('Failed to fetch vehicles by type: ${response.statusCode}');
  }

  Future<List<VehicleInformation>> apiVehiclesOwnerGet({
    String? ownerName,
  }) async {
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
      {'Content-Type': 'application/json; charset=UTF-8'},
      {'Accept': 'application/json; charset=UTF-8'},
      'application/json',
      ['bearerAuth'],
    );
    debugPrint('Owner Response: ${response.statusCode} - ${response.body}');
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint('Raw response body (apiVehiclesOwnerGet): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      final vehicles = VehicleInformation.listFromJson(data);
      debugPrint(
          'Deserialized vehicles (apiVehiclesOwnerGet): ${vehicles.map((v) => v.toJson()).toList()}');
      return vehicles;
    }
    throw Exception(
        'Failed to fetch vehicles by owner: ${response.statusCode} - ${response.body}');
  }

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
      debugPrint('Raw response body (apiVehiclesStatusGet): $decodedBody');
      final List<dynamic> data = jsonDecode(decodedBody);
      final vehicles = VehicleInformation.listFromJson(data);
      debugPrint(
          'Deserialized vehicles (apiVehiclesStatusGet): ${vehicles.map((v) => v.toJson()).toList()}');
      return vehicles;
    }
    throw Exception(
        'Failed to fetch vehicles by status: ${response.statusCode}');
  }

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
      debugPrint('Raw response body (apiVehiclesVehicleIdPut): $decodedBody');
      final vehicle = VehicleInformation.fromJson(jsonDecode(decodedBody));
      debugPrint(
          'Deserialized vehicle (apiVehiclesVehicleIdPut): ${vehicle.toJson()}');
      return vehicle;
    }
    throw Exception(
        'Failed to update vehicle: ${response.statusCode} - ${response.body}');
  }

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
      debugPrint('Raw response body (apiVehiclesExistsGet): $decodedBody');
      return jsonDecode(decodedBody) as bool;
    }
    throw Exception(
        'Failed to check license plate existence: ${response.statusCode}');
  }
}
