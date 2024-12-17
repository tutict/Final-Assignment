import 'package:final_assignment_front/features/model/deduction_information.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:http/http.dart'; // 用于 Response 和 MultipartRequest
import 'package:final_assignment_front/utils/services/api_client.dart';

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class DeductionInformationControllerApi {
  final ApiClient apiClient;

  // 更新后的构造函数，apiClient 参数可为空
  DeductionInformationControllerApi([ApiClient? apiClient])
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

  /// deleteDeduction with HTTP info returned
  ///
  ///
  Future<Response> apiDeductionsDeductionIdDeleteWithHttpInfo(
      {required String deductionId}) async {
    Object postBody = ''; // DELETE 请求通常没有 body

    // 验证必需参数已设置
    if (deductionId.isEmpty) {
      throw ApiException(400, "Missing required param: deductionId");
    }

    // 创建路径和映射变量
    String path = "/api/deductions/{deductionId}"
        .replaceAll("{format}", "json")
        .replaceAll("{deductionId}", deductionId);

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

  /// deleteDeduction
  ///
  ///
  Future<Object?> apiDeductionsDeductionIdDelete(
      {required String deductionId}) async {
    Response response = await apiDeductionsDeductionIdDeleteWithHttpInfo(
        deductionId: deductionId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getDeductionById with HTTP info returned
  ///
  ///
  Future<Response> apiDeductionsDeductionIdGetWithHttpInfo(
      {required String deductionId}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    if (deductionId.isEmpty) {
      throw ApiException(400, "Missing required param: deductionId");
    }

    // 创建路径和映射变量
    String path = "/api/deductions/{deductionId}"
        .replaceAll("{format}", "json")
        .replaceAll("{deductionId}", deductionId);

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

  /// getDeductionById
  ///
  ///
  Future<Object?> apiDeductionsDeductionIdGet(
      {required String deductionId}) async {
    Response response =
        await apiDeductionsDeductionIdGetWithHttpInfo(deductionId: deductionId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// updateDeduction with HTTP info returned
  ///
  ///
  Future<Response> apiDeductionsDeductionIdPutWithHttpInfo(
      {required String deductionId, int? deductionAmount}) async {
    Object postBody = deductionAmount ?? 0; // 根据实际需求设置默认值

    // 验证必需参数已设置
    if (deductionId.isEmpty) {
      throw ApiException(400, "Missing required param: deductionId");
    }

    // 创建路径和映射变量
    String path = "/api/deductions/{deductionId}"
        .replaceAll("{format}", "json")
        .replaceAll("{deductionId}", deductionId);

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

  /// updateDeduction
  ///
  ///
  Future<Object?> apiDeductionsDeductionIdPut(
      {required String deductionId, int? deductionAmount}) async {
    Response response = await apiDeductionsDeductionIdPutWithHttpInfo(
        deductionId: deductionId, deductionAmount: deductionAmount);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getAllDeductions with HTTP info returned
  ///
  ///
  Future<Response> apiDeductionsGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/deductions".replaceAll("{format}", "json");

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

  /// getAllDeductions
  ///
  ///
  Future<List<Object>?> apiDeductionsGet() async {
    Response response = await apiDeductionsGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }

  /// getDeductionsByHandler with HTTP info returned
  ///
  ///
  Future<Response> apiDeductionsHandlerHandlerGetWithHttpInfo(
      {required String handler}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    if (handler.isEmpty) {
      throw ApiException(400, "Missing required param: handler");
    }

    // 创建路径和映射变量
    String path = "/api/deductions/handler/{handler}"
        .replaceAll("{format}", "json")
        .replaceAll("{handler}", handler);

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

  /// getDeductionsByHandler
  ///
  ///
  Future<List<Object>?> apiDeductionsHandlerHandlerGet(
      {required String handler}) async {
    Response response =
        await apiDeductionsHandlerHandlerGetWithHttpInfo(handler: handler);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }

  /// createDeduction with HTTP info returned
  ///
  ///
  Future<Response> apiDeductionsPostWithHttpInfo(
      {required DeductionInformation deductionInformation}) async {
    Object postBody = deductionInformation;

    // 创建路径和映射变量
    String path = "/api/deductions".replaceAll("{format}", "json");

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

  /// createDeduction
  ///
  ///
  Future<Object?> apiDeductionsPost(
      {required DeductionInformation deductionInformation}) async {
    Response response = await apiDeductionsPostWithHttpInfo(
        deductionInformation: deductionInformation);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getDeductionsByTimeRange with HTTP info returned
  ///
  ///
  Future<Response> apiDeductionsTimeRangeGetWithHttpInfo(
      {String? startTime, String? endTime}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/deductions/timeRange".replaceAll("{format}", "json");

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

  /// getDeductionsByTimeRange
  ///
  ///
  Future<List<Object>?> apiDeductionsTimeRangeGet(
      {String? startTime, String? endTime}) async {
    Response response = await apiDeductionsTimeRangeGetWithHttpInfo(
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

  /// deleteDeduction with HTTP info returned (eventbus)
  ///
  ///
  Future<Response> eventbusDeductionsDeductionIdDeleteWithHttpInfo(
      {required String deductionId}) async {
    Object postBody = ''; // DELETE 请求通常没有 body

    // 验证必需参数已设置
    if (deductionId.isEmpty) {
      throw ApiException(400, "Missing required param: deductionId");
    }

    // 创建路径和映射变量
    String path = "/eventbus/deductions/{deductionId}"
        .replaceAll("{format}", "json")
        .replaceAll("{deductionId}", deductionId);

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

  /// deleteDeduction
  ///
  ///
  Future<Object?> eventbusDeductionsDeductionIdDelete(
      {required String deductionId}) async {
    Response response = await eventbusDeductionsDeductionIdDeleteWithHttpInfo(
        deductionId: deductionId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getDeductionById with HTTP info returned (eventbus)
  ///
  ///
  Future<Response> eventbusDeductionsDeductionIdGetWithHttpInfo(
      {required String deductionId}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    if (deductionId.isEmpty) {
      throw ApiException(400, "Missing required param: deductionId");
    }

    // 创建路径和映射变量
    String path = "/eventbus/deductions/{deductionId}"
        .replaceAll("{format}", "json")
        .replaceAll("{deductionId}", deductionId);

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

  /// getDeductionById (eventbus)
  ///
  ///
  Future<Object?> eventbusDeductionsDeductionIdGet(
      {required String deductionId}) async {
    Response response = await eventbusDeductionsDeductionIdGetWithHttpInfo(
        deductionId: deductionId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// updateDeduction with HTTP info returned (eventbus)
  ///
  ///
  Future<Response> eventbusDeductionsDeductionIdPutWithHttpInfo(
      {required String deductionId, int? deductionAmount}) async {
    Object postBody = deductionAmount ?? 0; // 根据实际需求设置默认值

    // 验证必需参数已设置
    if (deductionId.isEmpty) {
      throw ApiException(400, "Missing required param: deductionId");
    }

    // 创建路径和映射变量
    String path = "/eventbus/deductions/{deductionId}"
        .replaceAll("{format}", "json")
        .replaceAll("{deductionId}", deductionId);

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

  /// updateDeduction (eventbus)
  ///
  ///
  Future<Object?> eventbusDeductionsDeductionIdPut(
      {required String deductionId, int? deductionAmount}) async {
    Response response = await eventbusDeductionsDeductionIdPutWithHttpInfo(
        deductionId: deductionId, deductionAmount: deductionAmount);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getAllDeductions with HTTP info returned (eventbus)
  ///
  ///
  Future<Response> eventbusDeductionsGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/eventbus/deductions".replaceAll("{format}", "json");

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

  /// getAllDeductions (eventbus)
  ///
  ///
  Future<List<Object>?> eventbusDeductionsGet() async {
    Response response = await eventbusDeductionsGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }
}
