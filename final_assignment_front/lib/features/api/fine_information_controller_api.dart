import 'package:final_assignment_front/features/model/fine_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart';

final ApiClient defaultApiClient = ApiClient();

class FineInformationControllerApi {
  final ApiClient apiClient;

  FineInformationControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  /// 从 SharedPreferences 中读取 jwtToken 并设置到 ApiClient 中
  Future<void> initializeWithJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('未登录，请重新登录');
    }
    apiClient.setJwtToken(jwtToken);
  }

  String _decodeBodyBytes(Response response) => response.body;

  List<QueryParam> _addIdempotencyKey(String idempotencyKey) {
    return [QueryParam('idempotencyKey', idempotencyKey)];
  }

  /// DELETE /api/fines/{fineId} - 删除罚款 (仅管理员)
  Future<void> apiFinesFineIdDelete({required int fineId}) async {
    final response = await apiClient.invokeAPI(
      '/api/fines/$fineId',
      'DELETE',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// GET /api/fines/{fineId} - 获取罚款信息 (用户及管理员)
  Future<FineInformation?> apiFinesFineIdGet({required int fineId}) async {
    final response = await apiClient.invokeAPI(
      '/api/fines/$fineId',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return FineInformation.fromJson(data);
  }

  /// PUT /api/fines/{fineId} - 更新罚款 (仅管理员)
  Future<FineInformation> apiFinesFineIdPut({
    required int fineId,
    required FineInformation fineInformation,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/fines/$fineId',
      'PUT',
      _addIdempotencyKey(idempotencyKey),
      fineInformation.toJson(),
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return FineInformation.fromJson(data);
  }

  /// GET /api/fines - 获取所有罚款 (用户及管理员)
  Future<List<FineInformation>> apiFinesGet() async {
    final response = await apiClient.invokeAPI(
      '/api/fines',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return FineInformation.listFromJson(data);
  }

  /// GET /api/fines/payee/{payee} - 根据缴款人获取罚款 (用户及管理员)
  Future<List<FineInformation>> apiFinesPayeePayeeGet(
      {required String payee}) async {
    final response = await apiClient.invokeAPI(
      '/api/fines/payee/$payee',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return FineInformation.listFromJson(data);
  }

  /// POST /api/fines - 创建罚款 (仅管理员)
  Future<void> apiFinesPost({
    required FineInformation fineInformation,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/fines',
      'POST',
      _addIdempotencyKey(idempotencyKey),
      fineInformation.toJson(),
      {},
      {},
      'application/json',
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// GET /api/fines/receiptNumber/{receiptNumber} - 根据收据编号获取罚款 (用户及管理员)
  Future<FineInformation?> apiFinesReceiptNumberReceiptNumberGet(
      {required String receiptNumber}) async {
    final response = await apiClient.invokeAPI(
      '/api/fines/receiptNumber/$receiptNumber',
      'GET',
      [],
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    if (response.body.isEmpty) return null;
    final data = apiClient.deserialize(
        _decodeBodyBytes(response), 'Map<String, dynamic>');
    return FineInformation.fromJson(data);
  }

  /// GET /api/fines/timeRange - 根据时间范围获取罚款 (用户及管理员)
  Future<List<FineInformation>> apiFinesTimeRangeGet({
    String? startTime,
    String? endTime,
  }) async {
    final queryParams = <QueryParam>[];
    if (startTime != null) queryParams.add(QueryParam('startTime', startTime));
    if (endTime != null) queryParams.add(QueryParam('endTime', endTime));

    final response = await apiClient.invokeAPI(
      '/api/fines/timeRange',
      'GET',
      queryParams,
      '',
      {},
      {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
    final List<dynamic> data =
        apiClient.deserialize(_decodeBodyBytes(response), 'List<dynamic>');
    return FineInformation.listFromJson(data);
  }

  // WebSocket 方法（保持不变）
  Future<Object?> eventbusFinesFineIdDelete({required String fineId}) async {
    final msg = {
      "service": "FineInformation",
      "action": "deleteFine",
      "args": [int.parse(fineId)]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  Future<Object?> eventbusFinesFineIdGet({required String fineId}) async {
    final msg = {
      "service": "FineInformation",
      "action": "getFineById",
      "args": [int.parse(fineId)]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  Future<Object?> eventbusFinesFineIdPut(
      {required String fineId, int? updateValue}) async {
    final msg = {
      "service": "FineInformation",
      "action": "updateFine",
      "args": [int.parse(fineId), updateValue ?? 0]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  Future<List<Object>?> eventbusFinesGet() async {
    final msg = {
      "service": "FineInformation",
      "action": "getAllFines",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    if (respMap["result"] is List) {
      return (respMap["result"] as List).cast<Object>();
    }
    return null;
  }

  Future<Object?> eventbusFinesPayeePayeeGet({required String payee}) async {
    if (payee.isEmpty) {
      throw ApiException(400, "Missing required param: payee");
    }
    final msg = {
      "service": "FineInformation",
      "action": "getFinesByPayee",
      "args": [payee]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  Future<Object?> eventbusFinesPost(
      {required FineInformation fineInformation}) async {
    final fiMap = fineInformation.toJson();
    final msg = {
      "service": "FineInformation",
      "action": "createFine",
      "args": [fiMap]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  Future<Object?> eventbusFinesReceiptNumberReceiptNumberGet(
      {required String receiptNumber}) async {
    if (receiptNumber.isEmpty) {
      throw ApiException(400, "Missing required param: receiptNumber");
    }
    final msg = {
      "service": "FineInformation",
      "action": "getFineByReceiptNumber",
      "args": [receiptNumber]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }
}
