import 'dart:convert';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class VehicleInformationControllerApi {
  final Map<String, String> _headers = {};
  final String _baseUrl = 'http://localhost:8081';

  VehicleInformationControllerApi();

  /// 初始化JWT认证头
  Future<void> initializeWithJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken != null) {
      _headers['Authorization'] = 'Bearer $jwtToken';
      _headers['Content-Type'] = 'application/json; charset=utf-8';
    }
  }

  /// 搜索车辆（支持分页）
  Future<List<VehicleInformation>> apiVehiclesSearchGet({
    required String query,
    int page = 1,
    int size = 10,
  }) async {
    final uri =
        Uri.parse('$_baseUrl/api/vehicles/search').replace(queryParameters: {
      'query': query,
      'page': page.toString(),
      'size': size.toString(),
    });
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final jsonString = utf8.decode(response.bodyBytes);
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => VehicleInformation.fromJson(json)).toList();
    }
    throw Exception('Failed to search vehicles: ${response.statusCode}');
  }

  /// 创建车辆信息
  Future<void> apiVehiclesPost({
    required VehicleInformation vehicleInformation,
    required String idempotencyKey,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/vehicles'),
      headers: {..._headers, 'Idempotency-Key': idempotencyKey},
      body: jsonEncode(vehicleInformation.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception(
          'Failed to create vehicle: ${response.statusCode} - ${response.body}');
    }
  }

  /// 获取所有车辆信息
  Future<List<VehicleInformation>> apiVehiclesGet() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/vehicles'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final jsonString = utf8.decode(response.bodyBytes);
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => VehicleInformation.fromJson(json)).toList();
    }
    throw Exception('Failed to fetch all vehicles: ${response.statusCode}');
  }

  /// 根据ID获取车辆信息
  Future<VehicleInformation?> apiVehiclesVehicleIdGet(
      {required int vehicleId}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/vehicles/$vehicleId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final jsonString = utf8.decode(response.bodyBytes);
      return VehicleInformation.fromJson(jsonDecode(jsonString));
    } else if (response.statusCode == 404) {
      return null;
    }
    throw Exception('Failed to fetch vehicle by ID: ${response.statusCode}');
  }

  /// 根据车牌号获取车辆信息
  Future<VehicleInformation?> apiVehiclesLicensePlateGet(
      {required String licensePlate}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/vehicles/license-plate/$licensePlate'),
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

  /// 根据车辆类型获取车辆信息
  Future<List<VehicleInformation>> apiVehiclesTypeGet(
      {required String vehicleType}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/vehicles/type/$vehicleType'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final jsonString = utf8.decode(response.bodyBytes);
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => VehicleInformation.fromJson(json)).toList();
    }
    throw Exception('Failed to fetch vehicles by type: ${response.statusCode}');
  }

  /// 根据车主姓名获取车辆信息
  Future<List<VehicleInformation>> apiVehiclesOwnerGet(
      {required String ownerName}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/vehicles/owner/$ownerName'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final jsonString = utf8.decode(response.bodyBytes);
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => VehicleInformation.fromJson(json)).toList();
    }
    throw Exception(
        'Failed to fetch vehicles by owner: ${response.statusCode}');
  }

  /// 根据状态获取车辆信息
  Future<List<VehicleInformation>> apiVehiclesStatusGet(
      {required String currentStatus}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/vehicles/status/$currentStatus'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final jsonString = utf8.decode(response.bodyBytes);
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => VehicleInformation.fromJson(json)).toList();
    }
    throw Exception(
        'Failed to fetch vehicles by status: ${response.statusCode}');
  }

  /// 更新车辆信息
  Future<VehicleInformation> apiVehiclesVehicleIdPut({
    required int vehicleId,
    required VehicleInformation vehicleInformation,
    required String idempotencyKey,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/vehicles/$vehicleId'),
      headers: {..._headers, 'Idempotency-Key': idempotencyKey},
      body: jsonEncode(vehicleInformation.toJson()),
    );
    if (response.statusCode == 200) {
      final jsonString = utf8.decode(response.bodyBytes);
      return VehicleInformation.fromJson(jsonDecode(jsonString));
    }
    throw Exception(
        'Failed to update vehicle: ${response.statusCode} - ${response.body}');
  }

  /// 根据ID删除车辆信息
  Future<void> apiVehiclesVehicleIdDelete({required int vehicleId}) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/vehicles/$vehicleId'),
      headers: _headers,
    );
    if (response.statusCode != 204) {
      throw Exception(
          'Failed to delete vehicle: ${response.statusCode} - ${response.body}');
    }
  }

  /// 根据车牌号删除车辆信息
  Future<void> apiVehiclesLicensePlateDelete(
      {required String licensePlate}) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/vehicles/license-plate/$licensePlate'),
      headers: _headers,
    );
    if (response.statusCode != 204) {
      throw Exception(
          'Failed to delete vehicle by license plate: ${response.statusCode} - ${response.body}');
    }
  }

  /// 检查车牌号是否存在
  Future<bool> apiVehiclesExistsGet({required String licensePlate}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/vehicles/exists/$licensePlate'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as bool;
    }
    throw Exception(
        'Failed to check license plate existence: ${response.statusCode}');
  }
}
