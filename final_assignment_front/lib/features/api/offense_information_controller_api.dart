import 'package:final_assignment_front/features/model/offense_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:http/http.dart'; // 用于 Response 和 MultipartRequest

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class OffenseInformationControllerApi {
  final ApiClient apiClient;

  // 更新后的构造函数，apiClient 参数可为空
  OffenseInformationControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  // 解码响应体的辅助方法
  String _decodeBodyBytes(Response response) {
    return response.body;
  }

  // 辅助方法：转换查询参数
  List<QueryParam> _convertParametersForCollectionFormat(
      String collectionFormat, String name, dynamic value) {
    // 根据 collectionFormat 实现参数转换逻辑
    // 这里提供一个简单的实现示例
    return [QueryParam(name, value.toString())];
  }

  /// 根据司机姓名获取违法行为信息。 with HTTP info returned
  ///
  ///
  Future<Response> apiOffensesDriverNameDriverNameGetWithHttpInfo(
      {required String driverName}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/offenses/driverName/{driverName}"
        .replaceAll("{format}", "json")
        .replaceAll("{driverName}", driverName);

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// 根据司机姓名获取违法行为信息。
  ///
  ///
  Future<Object?> apiOffensesDriverNameDriverNameGet(
      {required String driverName}) async {
    Response response = await apiOffensesDriverNameDriverNameGetWithHttpInfo(
        driverName: driverName);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// 获取所有违法行为的信息。 with HTTP info returned
  ///
  ///
  Future<Response> apiOffensesGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/offenses".replaceAll("{format}", "json");

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// 获取所有违法行为的信息。
  ///
  ///
  Future<List<Object>?> apiOffensesGet() async {
    Response response = await apiOffensesGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }

  /// 根据车牌号获取违法行为信息。 with HTTP info returned
  ///
  ///
  Future<Response> apiOffensesLicensePlateLicensePlateGetWithHttpInfo(
      {required String licensePlate}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/offenses/licensePlate/{licensePlate}"
        .replaceAll("{format}", "json")
        .replaceAll("{licensePlate}", licensePlate);

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// 根据车牌号获取违法行为信息。
  ///
  ///
  Future<Object?> apiOffensesLicensePlateLicensePlateGet(
      {required String licensePlate}) async {
    Response response =
        await apiOffensesLicensePlateLicensePlateGetWithHttpInfo(
            licensePlate: licensePlate);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// 删除指定违法行为的信息。 with HTTP info returned
  ///
  ///
  Future<Response> apiOffensesOffenseIdDeleteWithHttpInfo(
      {required String offenseId}) async {
    Object postBody = ''; // DELETE 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/offenses/{offenseId}"
        .replaceAll("{format}", "json")
        .replaceAll("{offenseId}", offenseId);

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'DELETE', queryParams,
        postBody, headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// 删除指定违法行为的信息。
  ///
  ///
  Future<Object?> apiOffensesOffenseIdDelete(
      {required String offenseId}) async {
    Response response =
        await apiOffensesOffenseIdDeleteWithHttpInfo(offenseId: offenseId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// 根据违法行为ID获取违法行为信息。 with HTTP info returned
  ///
  ///
  Future<Response> apiOffensesOffenseIdGetWithHttpInfo(
      {required String offenseId}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/offenses/{offenseId}"
        .replaceAll("{format}", "json")
        .replaceAll("{offenseId}", offenseId);

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// 根据违法行为ID获取违法行为信息。
  ///
  ///
  Future<Object?> apiOffensesOffenseIdGet({required String offenseId}) async {
    Response response =
        await apiOffensesOffenseIdGetWithHttpInfo(offenseId: offenseId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// 更新指定违法行为的信息。 with HTTP info returned
  ///
  ///
  Future<Response> apiOffensesOffenseIdPutWithHttpInfo(
      {required String offenseId, int? updateValue}) async {
    Object postBody = updateValue ?? 0; // 根据实际需求设置默认值

    // 创建路径和映射变量
    String path = "/api/offenses/{offenseId}"
        .replaceAll("{format}", "json")
        .replaceAll("{offenseId}", offenseId);

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = ["application/json"];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'PUT', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// 更新指定违法行为的信息。
  ///
  ///
  Future<Object?> apiOffensesOffenseIdPut(
      {required String offenseId, int? updateValue}) async {
    Response response = await apiOffensesOffenseIdPutWithHttpInfo(
        offenseId: offenseId, updateValue: updateValue);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// 创建新的违法行为信息。 with HTTP info returned
  ///
  ///
  Future<Response> apiOffensesPostWithHttpInfo(
      {required OffenseInformation offenseInformation}) async {
    Object postBody = offenseInformation;

    // 创建路径和映射变量
    String path = "/api/offenses".replaceAll("{format}", "json");

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = ["application/json"];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'POST', queryParams,
        postBody, headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// 创建新的违法行为信息。
  ///
  ///
  Future<Object?> apiOffensesPost(
      {required OffenseInformation offenseInformation}) async {
    Response response = await apiOffensesPostWithHttpInfo(
        offenseInformation: offenseInformation);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// 根据处理状态获取违法行为信息。 with HTTP info returned
  ///
  ///
  Future<Response> apiOffensesProcessStateProcessStateGetWithHttpInfo(
      {required String processState}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/offenses/processState/{processState}"
        .replaceAll("{format}", "json")
        .replaceAll("{processState}", processState);

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// 根据处理状态获取违法行为信息。
  ///
  ///
  Future<Object?> apiOffensesProcessStateProcessStateGet(
      {required String processState}) async {
    Response response =
        await apiOffensesProcessStateProcessStateGetWithHttpInfo(
            processState: processState);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// 根据时间范围获取违法行为信息。 with HTTP info returned
  ///
  ///
  Future<Response> apiOffensesTimeRangeGetWithHttpInfo(
      {String? startTime, String? endTime}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/offenses/timeRange".replaceAll("{format}", "json");

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};
    if (startTime != null) {
      queryParams.addAll(
          _convertParametersForCollectionFormat("", "startTime", startTime));
    }
    if (endTime != null) {
      queryParams.addAll(
          _convertParametersForCollectionFormat("", "endTime", endTime));
    }

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// 根据时间范围获取违法行为信息。
  ///
  ///
  Future<List<Object>?> apiOffensesTimeRangeGet(
      {String? startTime, String? endTime}) async {
    Response response = await apiOffensesTimeRangeGetWithHttpInfo(
        startTime: startTime, endTime: endTime);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }

  /// 根据司机姓名获取违法行为信息 (WebSocket)
  /// 对应后端: @WsAction(service="OffenseInformation", action="getOffensesByDriverName")
  Future<Object?> eventbusOffensesDriverNameDriverNameGet(
      {required String driverName}) async {
    // 构造 WebSocket 消息
    final msg = {
      "service": "OffenseInformation",
      "action": "getOffensesByDriverName", // 你后端WsAction method
      "args": [driverName]
    };

    // 调用 apiClient.sendWsMessage
    final respMap = await apiClient.sendWsMessage(msg);

    // 检查 error
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    // 返回 result
    return respMap["result"];
  }

  /// 获取所有违法行为的信息 (WebSocket)
  /// 对应 @WsAction(service="OffenseInformation", action="getAllOffenses")
  Future<List<Object>?> eventbusOffensesGet() async {
    final msg = {
      "service": "OffenseInformation",
      "action": "getAllOffenses",
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

  /// 根据车牌号获取违法行为信息 (WebSocket)
  /// 对应 @WsAction(service="OffenseInformation", action="getOffensesByLicensePlate")
  Future<Object?> eventbusOffensesLicensePlateLicensePlateGet(
      {required String licensePlate}) async {
    final msg = {
      "service": "OffenseInformation",
      "action": "getOffensesByLicensePlate",
      "args": [licensePlate]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// 删除指定违法行为的信息 (WebSocket)
  /// 对应 @WsAction(service="OffenseInformation", action="deleteOffense")
  Future<Object?> eventbusOffensesOffenseIdDelete(
      {required String offenseId}) async {
    final msg = {
      "service": "OffenseInformation",
      "action": "deleteOffense",
      "args": [int.parse(offenseId)] // 如果后端用 int offenseId
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// 根据违法行为ID获取违法行为信息 (WebSocket)
  /// 对应 @WsAction(service="OffenseInformation", action="getOffenseById")
  Future<Object?> eventbusOffensesOffenseIdGet(
      {required String offenseId}) async {
    final msg = {
      "service": "OffenseInformation",
      "action": "getOffenseById",
      "args": [int.parse(offenseId)]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// 更新指定违法行为的信息 (WebSocket)
  /// 对应 @WsAction(service="OffenseInformation", action="updateOffense")
  Future<Object?> eventbusOffensesOffenseIdPut(
      {required String offenseId, int? updateValue}) async {
    final msg = {
      "service": "OffenseInformation",
      "action": "updateOffense",
      "args": [int.parse(offenseId), updateValue ?? 0]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// 创建新的违法行为信息 (WebSocket)
  /// 对应 @WsAction(service="OffenseInformation", action="createOffense")
  Future<Object?> eventbusOffensesPost(
      {required OffenseInformation offenseInformation}) async {
    // 序列化 offenseInformation => map
    final offenseMap = offenseInformation.toJson();

    final msg = {
      "service": "OffenseInformation",
      "action": "createOffense",
      "args": [offenseMap]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// 根据处理状态获取违法行为信息 (WebSocket)
  /// 对应 @WsAction(service="OffenseInformation", action="getOffensesByProcessState")
  Future<Object?> eventbusOffensesProcessStateProcessStateGet(
      {required String processState}) async {
    final msg = {
      "service": "OffenseInformation",
      "action": "getOffensesByProcessState",
      "args": [processState]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// 根据时间范围获取违法行为信息 (WebSocket)
  /// 对应 @WsAction(service="OffenseInformation", action="getOffensesByTimeRange")
  /// 例如: getOffensesByTimeRange(String start, String end)
  Future<List<Object>?> eventbusOffensesTimeRangeGet(
      {String? startTime, String? endTime}) async {
    final msg = {
      "service": "OffenseInformation",
      "action": "getOffensesByTimeRange",
      "args": [startTime ?? "", endTime ?? ""]
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
}
