import 'dart:convert';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'appeal_management_controller_api.dart';

class VehicleInformationControllerApi {
  final ApiClient apiClient;
  final Map<String, String> _headers = {};
  final String _baseUrl = 'http://localhost:8081';


  /// 构造函数，可传入 ApiClient，否则使用全局默认实例
  VehicleInformationControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  Future<void> initializeWithJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken != null) {
      _headers['Authorization'] = 'Bearer $jwtToken';
      _headers['Content-Type'] = 'application/json; charset=utf-8';
    }
  }

  Future<List<VehicleInformation>> apiVehiclesGet({
    int page = 0,
    int size = 10,
    String? ownerName,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'size': size.toString(),
      'sortBy': 'licensePlate',
      if (ownerName != null) 'ownerName': ownerName,
    };
    final uri = Uri.parse('$_baseUrl/api/vehicles')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final jsonString = utf8.decode(response.bodyBytes);
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => VehicleInformation.fromJson(json)).toList();
    }
    throw Exception('Failed to fetch vehicles: ${response.statusCode}');
  }

  Future<void> apiVehiclesPost({
    required VehicleInformation vehicleInformation,
    required String idempotencyKey,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/vehicles'),
      headers: {..._headers, 'Idempotency-Key': idempotencyKey},
      body: jsonEncode(vehicleInformation.toJson()), // Fixed serialization
    );
    if (response.statusCode != 201) {
      throw Exception(
          'Failed to create vehicle: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> apiVehiclesVehicleIdPut({
    required int vehicleId,
    required VehicleInformation vehicleInformation,
    required String idempotencyKey,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/vehicles/$vehicleId'),
      headers: {..._headers, 'Idempotency-Key': idempotencyKey},
      body: jsonEncode(vehicleInformation.toJson()), // Fixed serialization
    );
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to update vehicle: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> apiVehiclesVehicleIdDelete({required int vehicleId}) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/vehicles/$vehicleId'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to delete vehicle: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> apiVehiclesLicensePlateLicensePlateDelete(
      {required String licensePlate}) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/vehicles/licensePlate/$licensePlate'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to delete vehicle by license plate: ${response.statusCode} - ${response.body}');
    }
  }

  Future<VehicleInformation?> apiVehiclesLicensePlateLicensePlateGet(
      {required String licensePlate}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/vehicles/licensePlate/$licensePlate'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final jsonString = utf8.decode(response.bodyBytes);
      return VehicleInformation.fromJson(jsonDecode(jsonString));
    } else if (response.statusCode == 404) {
      return null;
    }
    throw Exception(
        'Failed to fetch vehicle by license plate: ${response.statusCode}');
  }

  Future<List<VehicleInformation>> apiVehiclesTypeVehicleTypeGet({
    required String vehicleType,
    int page = 0,
    int size = 10,
  }) async {
    final queryParams = {
      'vehicleType': vehicleType,
      'page': page.toString(),
      'size': size.toString(),
    };
    final uri = Uri.parse('$_baseUrl/api/vehicles/type')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final jsonString = utf8.decode(response.bodyBytes);
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => VehicleInformation.fromJson(json)).toList();
    }
    throw Exception('Failed to fetch vehicles by type: ${response.statusCode}');
  }

  Future<List<VehicleInformation>> apiVehiclesOwnerOwnerNameGet({
    required String ownerName,
    int page = 0,
    int size = 10,
  }) async {
    final queryParams = {
      'ownerName': ownerName,
      'page': page.toString(),
      'size': size.toString(),
    };
    final uri = Uri.parse('$_baseUrl/api/vehicles/owner')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final jsonString = utf8.decode(response.bodyBytes);
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => VehicleInformation.fromJson(json)).toList();
    }
    throw Exception(
        'Failed to fetch vehicles by owner: ${response.statusCode}');
  }

  Future<List<VehicleInformation>> apiVehiclesStatusCurrentStatusGet({
    required String currentStatus,
    int page = 0,
    int size = 10,
  }) async {
    final queryParams = {
      'currentStatus': currentStatus,
      'page': page.toString(),
      'size': size.toString(),
    };
    final uri = Uri.parse('$_baseUrl/api/vehicles/status')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final jsonString = utf8.decode(response.bodyBytes);
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => VehicleInformation.fromJson(json)).toList();
    }
    throw Exception(
        'Failed to fetch vehicles by status: ${response.statusCode}');
  }
}
