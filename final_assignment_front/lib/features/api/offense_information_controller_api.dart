import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/features/model/offense_information.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:http/http.dart' as http;

final ApiClient defaultApiClient = ApiClient();

class OffenseInformationControllerApi with BaseApiClient {
  OffenseInformationControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  @override
  final ApiClient apiClient;

  /// 使用当前登录态初始化 API 客户端的 JWT。
  ///
  /// 调用业务接口前应先完成初始化，确保后续请求携带 bearer token。
  ///
  /// 抛出 [Exception]：当本地登录态无有效 JWT 时。
  Future<void> initializeWithJwt() => initializeClientWithJwt();

  Future<http.Response> _apiOffensesPost(OffenseInformation body) async {
    final idempotencyKey = resolveIdempotencyKey(body.idempotencyKey);
    return apiClient.invokeAPI(
      '/api/offenses',
      'POST',
      const [],
      body.toJson(),
      await getHeaders(idempotencyKey: idempotencyKey),
      const {},
      'application/json',
      const ['bearerAuth'],
    );
  }

  /// 创建违法记录。
  ///
  /// [body] 违法记录请求体；其中 [OffenseInformation.idempotencyKey] 会作为幂等键使用。
  ///
  /// 返回后端创建后的 [OffenseInformation]；空响应但 HTTP 成功时返回原始 [body]。
  ///
  /// 抛出 [AppException]：当请求数据无效、幂等键重复或 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：POST /api/offenses
  Future<OffenseInformation> createOffense(OffenseInformation body) async {
    final response = await _apiOffensesPost(body);
    final statusMessages = {
      400: 'Invalid request data',
      409:
          'Duplicate request detected with idempotencyKey: ${body.idempotencyKey}',
    };
    if (decodeBodyBytes(response).trim().isEmpty) {
      ensureSuccess(response, statusMessages: statusMessages);
      return body;
    }
    return parseResponse(
      response,
      OffenseInformation.fromJson,
      statusMessages: statusMessages,
    );
  }

  /// 根据违法记录 ID 获取单条违法记录。
  ///
  /// [offenseId] 违法记录主键。
  ///
  /// 返回 [OffenseInformation]；后端返回空响应或 404 时返回 `null`。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 且不是可空响应时。
  ///
  /// 对应接口：GET /api/offenses/{offenseId}
  Future<OffenseInformation?> getOffense({
    required int offenseId,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offenses/$offenseId',
      'GET',
      const [],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseNullableResponse(response, OffenseInformation.fromJson);
  }

  /// 获取违法记录列表。
  ///
  /// 返回 [OffenseInformation] 列表；无数据时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/offenses
  Future<List<OffenseInformation>> listOffenses() async {
    final response = await apiClient.invokeAPI(
      '/api/offenses',
      'GET',
      const [],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseListResponse(response, OffenseInformation.fromJson);
  }

  /// 更新违法记录。
  ///
  /// [offenseId] 待更新的违法记录主键。
  /// [offenseInformation] 更新后的违法记录数据。
  /// [idempotencyKey] 幂等键，用于防止重复提交。
  ///
  /// 返回后端更新后的 [OffenseInformation]。
  ///
  /// 抛出 [AppException]：当记录不存在、幂等键重复或 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：PUT /api/offenses/{offenseId}
  Future<OffenseInformation> updateOffense({
    required int offenseId,
    required OffenseInformation offenseInformation,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offenses/$offenseId',
      'PUT',
      const [],
      offenseInformation.toJson(),
      await getHeaders(idempotencyKey: idempotencyKey),
      const {},
      'application/json',
      const ['bearerAuth'],
    );
    return parseResponse(
      response,
      OffenseInformation.fromJson,
      statusMessages: {
        404: 'Offense not found with ID: $offenseId',
        409: 'Duplicate request detected with idempotencyKey: $idempotencyKey',
      },
    );
  }

  /// 删除违法记录。
  ///
  /// [offenseId] 待删除的违法记录主键。
  ///
  /// 删除成功时无返回值。
  ///
  /// 抛出 [AppException]：当记录不存在、无权限或 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：DELETE /api/offenses/{offenseId}
  Future<void> deleteOffense({
    required int offenseId,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offenses/$offenseId',
      'DELETE',
      const [],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    ensureSuccess(
      response,
      statusMessages: {
        404: 'Offense not found with ID: $offenseId',
        403: 'Unauthorized: Only ADMIN can delete offenses',
      },
    );
  }

  /// 按违法发生时间范围搜索违法记录。
  ///
  /// [startTime] 查询开始时间，默认 `1970-01-01`。
  /// [endTime] 查询结束时间，默认 `2100-01-01`。
  ///
  /// 返回匹配时间区间的 [OffenseInformation] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/offenses/search/time-range
  Future<List<OffenseInformation>> searchOffensesByTimeRange({
    String startTime = '1970-01-01',
    String endTime = '2100-01-01',
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offenses/search/time-range',
      'GET',
      [
        QueryParam('startTime', startTime),
        QueryParam('endTime', endTime),
      ],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseListResponse(response, OffenseInformation.fromJson);
  }

  /// 按违法类型代码搜索违法记录。
  ///
  /// [query] 违法类型或违法代码查询值，不能为空。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 10。
  ///
  /// 返回 [OffenseInformation] 列表；无匹配记录时返回空列表。
  ///
  /// 抛出 [AppException]：当 [query] 为空或 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/offenses/search/code
  Future<List<OffenseInformation>> listOffensesByOffenseType({
    required String query,
    int page = 1,
    int size = 10,
  }) async {
    if (query.isEmpty) {
      throw AppException.http(400, 'Missing required param: query');
    }
    final response = await apiClient.invokeAPI(
      '/api/offenses/search/code',
      'GET',
      [
        QueryParam('offenseCode', query),
        QueryParam('page', page.toString()),
        QueryParam('size', size.toString()),
      ],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseListResponse(response, OffenseInformation.fromJson);
  }

  /// 根据司机姓名搜索违法记录列表。
  ///
  /// [query] 司机姓名关键字，先通过司机姓名接口按 `keywords` 模糊匹配司机。
  /// [page] 查询每个司机名下违法记录的分页页码，当前客户端默认从 1 开始。
  /// [size] 查询每个司机名下违法记录的每页条数，默认 10。
  ///
  /// 查询流程为组合查询：先请求 `/api/drivers/search/name` 获取最多 20 个司机，
  /// 再按每个司机的 `driverId` 请求 `/api/offenses/driver/{driverId}`，
  /// 最后按 `offenseId` 去重并合并为 [OffenseInformation] 列表。
  ///
  /// 返回聚合后的 [OffenseInformation] 列表；无司机或无违法记录时返回空列表。
  ///
  /// 抛出 [AppException]：当 [query] 为空，或司机搜索接口 HTTP 响应非 2xx 时。
  /// 单个司机的违法记录查询失败会被跳过，不会中断其他司机的查询。
  ///
  /// 对应接口：GET /api/drivers/search/name + GET /api/offenses/driver/{driverId}
  Future<List<OffenseInformation>> listOffensesByDriverName({
    required String query,
    int page = 1,
    int size = 10,
  }) async {
    if (query.isEmpty) {
      throw AppException.http(400, 'Missing required param: query');
    }

    final headerParams = await getHeaders();
    final driverResp = await apiClient.invokeAPI(
      '/api/drivers/search/name',
      'GET',
      [
        QueryParam('keywords', query),
        QueryParam('page', '1'),
        QueryParam('size', '20'),
      ],
      null,
      headerParams,
      const {},
      null,
      const ['bearerAuth'],
    );
    final drivers = parseListResponse(driverResp, DriverInformation.fromJson);
    if (drivers.isEmpty) {
      return <OffenseInformation>[];
    }

    final merged = <int, OffenseInformation>{};
    for (final driver in drivers) {
      final driverId = driver.driverId;
      if (driverId == null) {
        continue;
      }
      final offensesResp = await apiClient.invokeAPI(
        '/api/offenses/driver/$driverId',
        'GET',
        [
          QueryParam('page', page.toString()),
          QueryParam('size', size.toString()),
        ],
        null,
        headerParams,
        const {},
        null,
        const ['bearerAuth'],
      );
      if (offensesResp.statusCode >= 400 ||
          decodeBodyBytes(offensesResp).trim().isEmpty) {
        continue;
      }
      final offenses =
          parseListResponse(offensesResp, OffenseInformation.fromJson);
      for (final offense in offenses) {
        final offenseId = offense.offenseId;
        if (offenseId != null) {
          merged[offenseId] = offense;
        }
      }
    }
    return merged.values.toList();
  }

  /// 按司机 ID 查询违法记录列表。
  ///
  /// [driverId] 司机主键。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [OffenseInformation] 列表；无记录时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/offenses/driver/{driverId}
  Future<List<OffenseInformation>> listOffensesByDriver({
    required int driverId,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offenses/driver/$driverId',
      'GET',
      [
        QueryParam('page', page.toString()),
        QueryParam('size', size.toString()),
      ],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseListResponse(response, OffenseInformation.fromJson);
  }

  /// 按车辆 ID 查询违法记录列表。
  ///
  /// [vehicleId] 车辆主键。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [OffenseInformation] 列表；无记录时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/offenses/vehicle/{vehicleId}
  Future<List<OffenseInformation>> listOffensesByVehicle({
    required int vehicleId,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offenses/vehicle/$vehicleId',
      'GET',
      [
        QueryParam('page', page.toString()),
        QueryParam('size', size.toString()),
      ],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseListResponse(response, OffenseInformation.fromJson);
  }

  /// 按处理状态搜索违法记录。
  ///
  /// [processStatus] workflow 处理状态，例如 Pending、Approved、Rejected。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [OffenseInformation] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/offenses/search/status
  Future<List<OffenseInformation>> searchOffensesByStatus({
    required String processStatus,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offenses/search/status',
      'GET',
      [
        QueryParam('status', processStatus),
        QueryParam('page', page.toString()),
        QueryParam('size', size.toString()),
      ],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseListResponse(response, OffenseInformation.fromJson);
  }

  /// 按违法编号搜索违法记录。
  ///
  /// [offenseNumber] 违法编号查询值。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [OffenseInformation] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/offenses/search/number
  Future<List<OffenseInformation>> searchOffensesByNumber({
    required String offenseNumber,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offenses/search/number',
      'GET',
      [
        QueryParam('offenseNumber', offenseNumber),
        QueryParam('page', page.toString()),
        QueryParam('size', size.toString()),
      ],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseListResponse(response, OffenseInformation.fromJson);
  }

  /// 按违法地点搜索违法记录。
  ///
  /// [offenseLocation] 违法地点关键字。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [OffenseInformation] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/offenses/search/location
  Future<List<OffenseInformation>> searchOffensesByLocation({
    required String offenseLocation,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offenses/search/location',
      'GET',
      [
        QueryParam('offenseLocation', offenseLocation),
        QueryParam('page', page.toString()),
        QueryParam('size', size.toString()),
      ],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseListResponse(response, OffenseInformation.fromJson);
  }

  /// 按违法发生省份搜索违法记录。
  ///
  /// [offenseProvince] 省份名称或编码。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [OffenseInformation] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/offenses/search/province
  Future<List<OffenseInformation>> searchOffensesByProvince({
    required String offenseProvince,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offenses/search/province',
      'GET',
      [
        QueryParam('offenseProvince', offenseProvince),
        QueryParam('page', page.toString()),
        QueryParam('size', size.toString()),
      ],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseListResponse(response, OffenseInformation.fromJson);
  }

  /// 按违法发生城市搜索违法记录。
  ///
  /// [offenseCity] 城市名称或编码。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [OffenseInformation] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/offenses/search/city
  Future<List<OffenseInformation>> searchOffensesByCity({
    required String offenseCity,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offenses/search/city',
      'GET',
      [
        QueryParam('offenseCity', offenseCity),
        QueryParam('page', page.toString()),
        QueryParam('size', size.toString()),
      ],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseListResponse(response, OffenseInformation.fromJson);
  }

  /// 按通知状态搜索违法记录。
  ///
  /// [notificationStatus] 通知状态，例如已通知、未通知或通知失败。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [OffenseInformation] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/offenses/search/notification
  Future<List<OffenseInformation>> searchOffensesByNotification({
    required String notificationStatus,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offenses/search/notification',
      'GET',
      [
        QueryParam('notificationStatus', notificationStatus),
        QueryParam('page', page.toString()),
        QueryParam('size', size.toString()),
      ],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseListResponse(response, OffenseInformation.fromJson);
  }

  /// 按执法机构搜索违法记录。
  ///
  /// [enforcementAgency] 执法机构名称或编码。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回 [OffenseInformation] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/offenses/search/agency
  Future<List<OffenseInformation>> searchOffensesByAgency({
    required String enforcementAgency,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offenses/search/agency',
      'GET',
      [
        QueryParam('enforcementAgency', enforcementAgency),
        QueryParam('page', page.toString()),
        QueryParam('size', size.toString()),
      ],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseListResponse(response, OffenseInformation.fromJson);
  }

  /// 按罚款金额区间搜索违法记录。
  ///
  /// [minAmount] 最小罚款金额。
  /// [maxAmount] 最大罚款金额。
  /// [page] 分页页码，当前客户端默认从 1 开始。
  /// [size] 每页条数，默认 20。
  ///
  /// 返回金额落在区间内的 [OffenseInformation] 列表；无匹配时返回空列表。
  ///
  /// 抛出 [AppException]：当 HTTP 响应非 2xx 时。
  ///
  /// 对应接口：GET /api/offenses/search/fine-range
  Future<List<OffenseInformation>> searchOffensesByFineRange({
    required double minAmount,
    required double maxAmount,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offenses/search/fine-range',
      'GET',
      [
        QueryParam('minAmount', minAmount.toString()),
        QueryParam('maxAmount', maxAmount.toString()),
        QueryParam('page', page.toString()),
        QueryParam('size', size.toString()),
      ],
      null,
      await getHeaders(),
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseListResponse(response, OffenseInformation.fromJson);
  }

  /// 根据车牌号搜索违法记录列表。
  ///
  /// [query] 车牌号查询值，先通过车辆车牌接口定位单个车辆。
  /// [page] 查询该车辆违法记录的分页页码，当前客户端默认从 1 开始。
  /// [size] 查询该车辆违法记录的每页条数，默认 10。
  ///
  /// 查询流程为组合查询：先请求 `/api/vehicles/search/license` 获取车辆，
  /// 再按 `vehicleId` 请求 `/api/offenses/vehicle/{vehicleId}` 获取违法记录。
  ///
  /// 返回 [OffenseInformation] 列表；车辆不存在、车辆 ID 为空或无违法记录时返回空列表。
  ///
  /// 抛出 [AppException]：当 [query] 为空，或车辆/违法记录接口返回非 2xx 且不是 404 空结果时。
  ///
  /// 对应接口：GET /api/vehicles/search/license + GET /api/offenses/vehicle/{vehicleId}
  Future<List<OffenseInformation>> listOffensesByLicensePlate({
    required String query,
    int page = 1,
    int size = 10,
  }) async {
    if (query.isEmpty) {
      throw AppException.http(400, 'Missing required param: query');
    }

    final headerParams = await getHeaders();
    final vehicleResp = await apiClient.invokeAPI(
      '/api/vehicles/search/license',
      'GET',
      [QueryParam('licensePlate', query)],
      null,
      headerParams,
      const {},
      null,
      const ['bearerAuth'],
      passThroughStatusCodes: const {404},
    );
    if (vehicleResp.statusCode == 404 ||
        decodeBodyBytes(vehicleResp).trim().isEmpty) {
      return <OffenseInformation>[];
    }
    final vehicle = parseResponse(vehicleResp, VehicleInformation.fromJson);
    final vehicleId = vehicle.vehicleId;
    if (vehicleId == null) {
      return <OffenseInformation>[];
    }

    final offenseResp = await apiClient.invokeAPI(
      '/api/offenses/vehicle/$vehicleId',
      'GET',
      [
        QueryParam('page', page.toString()),
        QueryParam('size', size.toString()),
      ],
      null,
      headerParams,
      const {},
      null,
      const ['bearerAuth'],
    );
    return parseListResponse(offenseResp, OffenseInformation.fromJson);
  }
}
