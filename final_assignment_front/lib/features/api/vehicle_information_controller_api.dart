import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'dart:convert';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

final ApiClient defaultApiClient = ApiClient();

class VehicleInformationControllerApi with BaseApiClient {
  @override
  final ApiClient apiClient;
  VehicleInformationControllerApi([ApiClient? client])
      : apiClient = client ?? defaultApiClient;

  /// 使用当前登录态初始化车辆 API 客户端的 JWT。
  ///
  /// 调用车辆相关接口前应先完成初始化，确保后续请求携带 bearer token。
  ///
  /// 抛出 [Exception]：当本地登录态无有效 JWT 时。
  Future<void> initializeWithJwt() async {
    final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null) {
      throw Exception('Not authenticated. Please log in again.');
    }
    apiClient.setJwtToken(jwtToken);
    AppLogger.debug(
        'Initialized VehicleInformationControllerApi with token: $jwtToken');
  }

  String _decode(http.Response r) => decodeBodyBytes(r);

  Future<Map<String, String>> _headers({String? idempotencyKey}) async {
    return getHeaders(idempotencyKey: idempotencyKey);
  }

  // GET /api/vehicles
  /// 获取车辆列表。
  ///
  /// 返回 [VehicleInformation] 列表；后端返回空响应时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/vehicles
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
    if (r.statusCode >= 400) throw AppException.http(r.statusCode, _decode(r));
    if (r.body.isEmpty) return [];
    final List<dynamic> data = jsonDecode(_decode(r));
    return data.map((e) => VehicleInformation.fromJson(e)).toList();
  }

  // GET /api/vehicles/{vehicleId}
  /// 根据车辆 ID 获取单条车辆信息。
  ///
  /// [vehicleId] 车辆主键。
  ///
  /// 返回 [VehicleInformation]；后端返回 404 或空响应时返回 `null`。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 且不是 404 时。
  ///
  /// 对应接口：GET /api/vehicles/{vehicleId}
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
      passThroughStatusCodes: const {404},
    );
    if (r.statusCode == 404) return null;
    if (r.statusCode >= 400) throw AppException.http(r.statusCode, _decode(r));
    if (r.body.isEmpty) return null;
    return VehicleInformation.fromJson(jsonDecode(_decode(r)));
  }

  // POST /api/vehicles
  /// 创建车辆信息。
  ///
  /// [vehicle] 车辆请求体。
  /// [idempotencyKey] 幂等键，用于防止重复提交。
  ///
  /// 返回后端创建后的 [VehicleInformation]。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：POST /api/vehicles
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
    if (r.statusCode >= 400) throw AppException.http(r.statusCode, _decode(r));
    return VehicleInformation.fromJson(jsonDecode(_decode(r)));
  }

  // PUT /api/vehicles/{vehicleId}
  /// 更新车辆信息。
  ///
  /// [vehicleId] 待更新的车辆主键。
  /// [vehicle] 更新后的车辆数据。
  /// [idempotencyKey] 幂等键，用于防止重复提交。
  ///
  /// 返回后端更新后的 [VehicleInformation]。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：PUT /api/vehicles/{vehicleId}
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
    if (r.statusCode >= 400) throw AppException.http(r.statusCode, _decode(r));
    return VehicleInformation.fromJson(jsonDecode(_decode(r)));
  }

  // DELETE /api/vehicles/{vehicleId}
  /// 根据车辆 ID 删除车辆信息。
  ///
  /// [vehicleId] 待删除的车辆主键。
  ///
  /// 删除成功时无返回值；当前实现期望后端返回 204。
  ///
  /// 抛出 [AppException]：当 HTTP 状态码不是 204 时。
  ///
  /// 对应接口：DELETE /api/vehicles/{vehicleId}
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
    if (r.statusCode != 204) throw AppException.http(r.statusCode, _decode(r));
  }

  // DELETE /api/vehicles/license/{licensePlate}
  /// 根据车牌号删除车辆信息。
  ///
  /// [licensePlate] 待删除车辆的车牌号。
  ///
  /// 删除成功时无返回值；当前实现期望后端返回 204。
  ///
  /// 抛出 [AppException]：当 HTTP 状态码不是 204 时。
  ///
  /// 对应接口：DELETE /api/vehicles/license/{licensePlate}
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
    if (r.statusCode != 204) throw AppException.http(r.statusCode, _decode(r));
  }

  // GET /api/vehicles/search/license?licensePlate=
  /// 按车牌号精确查询车辆信息。
  ///
  /// [licensePlate] 车牌号查询值。
  ///
  /// 返回 [VehicleInformation]；未找到或空响应时返回 `null`。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 且不是 404 时。
  ///
  /// 对应接口：GET /api/vehicles/search/license
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
      passThroughStatusCodes: const {404},
    );
    if (r.statusCode == 404) return null;
    if (r.statusCode >= 400) throw AppException.http(r.statusCode, _decode(r));
    if (r.body.isEmpty) return null;
    return VehicleInformation.fromJson(jsonDecode(_decode(r)));
  }

  // GET /api/vehicles/search/owner?idCard=
  /// 按车主身份证号查询车辆列表。
  ///
  /// [idCard] 车主身份证号；用于查找该车主绑定的车辆。
  ///
  /// 返回 [VehicleInformation] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/vehicles/search/owner
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
    if (r.statusCode >= 400) throw AppException.http(r.statusCode, _decode(r));
    if (r.body.isEmpty) return [];
    final List<dynamic> data = jsonDecode(_decode(r));
    return data.map((e) => VehicleInformation.fromJson(e)).toList();
  }

  // GET /api/vehicles/search/type?type=
  /// 按车辆类型查询车辆列表。
  ///
  /// [type] 车辆类型查询值。
  ///
  /// 返回 [VehicleInformation] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/vehicles/search/type
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
    if (r.statusCode >= 400) throw AppException.http(r.statusCode, _decode(r));
    if (r.body.isEmpty) return [];
    final List<dynamic> data = jsonDecode(_decode(r));
    return data.map((e) => VehicleInformation.fromJson(e)).toList();
  }

  // GET /api/vehicles/search/owner/name?ownerName=
  /// 按车主姓名查询车辆列表。
  ///
  /// [ownerName] 车主姓名查询值；与 [searchVehiclesByOwner] 的身份证维度不同。
  ///
  /// 返回 [VehicleInformation] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/vehicles/search/owner/name
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
    if (r.statusCode >= 400) throw AppException.http(r.statusCode, _decode(r));
    if (r.body.isEmpty) return [];
    final List<dynamic> data = jsonDecode(_decode(r));
    return data.map((e) => VehicleInformation.fromJson(e)).toList();
  }

  // GET /api/vehicles/search/status?status=
  /// 按车辆状态查询车辆列表。
  ///
  /// [status] 车辆当前状态查询值；区别于车牌状态快照等历史状态字段。
  ///
  /// 返回 [VehicleInformation] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/vehicles/search/status
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
    if (r.statusCode >= 400) throw AppException.http(r.statusCode, _decode(r));
    if (r.body.isEmpty) return [];
    final List<dynamic> data = jsonDecode(_decode(r));
    return data.map((e) => VehicleInformation.fromJson(e)).toList();
  }

  // GET /api/vehicles/search/general?keywords=&page=&size=
  /// 按综合关键字搜索车辆列表。
  ///
  /// [keywords] 综合搜索关键字，通常覆盖车牌、车主、车型等后端定义的维度。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [VehicleInformation] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/vehicles/search/general
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
    if (r.statusCode >= 400) throw AppException.http(r.statusCode, _decode(r));
    if (r.body.isEmpty) return [];
    final List<dynamic> data = jsonDecode(_decode(r));
    return data.map((e) => VehicleInformation.fromJson(e)).toList();
  }

  // GET /api/vehicles/search/license/global?prefix=&size=
  /// 全局搜索车牌号候选项。
  ///
  /// [prefix] 车牌号前缀。
  /// [size] 返回结果最大条数，默认 10。
  ///
  /// 返回车牌号字符串列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/vehicles/search/license/global
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
    if (r.statusCode >= 400) throw AppException.http(r.statusCode, _decode(r));
    if (r.body.isEmpty) return [];
    final List<dynamic> data = jsonDecode(_decode(r));
    return data.cast<String>();
  }

  // GET /api/vehicles/autocomplete/plates?prefix=&size=&idCard=
  /// 获取指定车主名下车牌号自动补全候选项。
  ///
  /// [prefix] 车牌号前缀。
  /// [idCard] 车主身份证号，用于限制候选范围。
  /// [size] 返回结果最大条数，默认 10。
  ///
  /// 返回车牌号字符串列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/vehicles/autocomplete/plates
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
    if (r.statusCode >= 400) throw AppException.http(r.statusCode, _decode(r));
    if (r.body.isEmpty) return [];
    final List<dynamic> data = jsonDecode(_decode(r));
    return data.cast<String>();
  }

  // GET /api/vehicles/autocomplete/types?idCard=&prefix=&size=
  /// 获取指定车主名下车辆类型自动补全候选项。
  ///
  /// [idCard] 车主身份证号，用于限制候选范围。
  /// [prefix] 车辆类型前缀。
  /// [size] 返回结果最大条数，默认 10。
  ///
  /// 返回车辆类型字符串列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/vehicles/autocomplete/types
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
    if (r.statusCode >= 400) throw AppException.http(r.statusCode, _decode(r));
    if (r.body.isEmpty) return [];
    final List<dynamic> data = jsonDecode(_decode(r));
    return data.cast<String>();
  }

  // GET /api/vehicles/autocomplete/types/global?prefix=&size=
  /// 获取全局车辆类型自动补全候选项。
  ///
  /// [prefix] 车辆类型前缀。
  /// [size] 返回结果最大条数，默认 10。
  ///
  /// 返回车辆类型字符串列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/vehicles/autocomplete/types/global
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
    if (r.statusCode >= 400) throw AppException.http(r.statusCode, _decode(r));
    if (r.body.isEmpty) return [];
    final List<dynamic> data = jsonDecode(_decode(r));
    return data.cast<String>();
  }

  // GET /api/vehicles/exists/{licensePlate} -> {"exists": true/false}
  /// 检查车牌号是否已存在。
  ///
  /// [licensePlate] 待检查的车牌号。
  ///
  /// 返回 `true` 表示车牌已存在，返回 `false` 表示不存在或响应缺少 `exists` 字段。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时；业务不存在不会通过异常表示。
  ///
  /// 对应接口：GET /api/vehicles/exists/{licensePlate}
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
    if (r.statusCode >= 400) throw AppException.http(r.statusCode, _decode(r));
    final Map<String, dynamic> data = jsonDecode(_decode(r));
    return (data['exists'] as bool?) ?? false;
  }
}
