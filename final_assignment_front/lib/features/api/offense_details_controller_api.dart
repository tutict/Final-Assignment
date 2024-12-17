import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:http/http.dart'; // 用于 Response 和 MultipartRequest

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class OffenseDetailsControllerApi {
  final ApiClient apiClient;

  // 更新后的构造函数，apiClient 参数可为空
  OffenseDetailsControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  // 解码响应体的辅助方法
  String _decodeBodyBytes(Response response) {
    return response.body;
  }

  /// 获取所有违规详情记录 with HTTP info returned
  ///
  ///
  Future<Response> apiOffenseDetailsGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/offense-details".replaceAll("{format}", "json");

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

  /// 获取所有违规详情记录
  ///
  ///
  Future<List<Object>?> apiOffenseDetailsGet() async {
    Response response = await apiOffenseDetailsGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }

  /// 根据 ID 获取违规详情 with HTTP info returned
  ///
  ///
  Future<Response> apiOffenseDetailsIdGetWithHttpInfo(
      {required String id}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    if (id.isEmpty) {
      throw ApiException(400, "Missing required param: id");
    }

    // 创建路径和映射变量
    String path = "/api/offense-details/{id}"
        .replaceAll("{format}", "json")
        .replaceAll("{id}", id);

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

  /// 根据 ID 获取违规详情
  ///
  ///
  Future<Object?> apiOffenseDetailsIdGet({required String id}) async {
    Response response = await apiOffenseDetailsIdGetWithHttpInfo(id: id);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// 创建方法，用于发送 OffenseDetails 对象到 Kafka 主题 with HTTP info returned
  ///
  ///
  Future<Response> apiOffenseDetailsSendToKafkaIdPostWithHttpInfo(
      {required String id}) async {
    Object postBody = ''; // POST 请求通常有 body

    // 验证必需参数已设置
    if (id.isEmpty) {
      throw ApiException(400, "Missing required param: id");
    }

    // 创建路径和映射变量
    String path = "/api/offense-details/send-to-kafka/{id}"
        .replaceAll("{format}", "json")
        .replaceAll("{id}", id);

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'POST', queryParams,
        postBody, headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// 创建方法，用于发送 OffenseDetails 对象到 Kafka 主题
  ///
  ///
  Future<Object?> apiOffenseDetailsSendToKafkaIdPost(
      {required String id}) async {
    Response response =
        await apiOffenseDetailsSendToKafkaIdPostWithHttpInfo(id: id);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// 获取所有违规详情记录 with HTTP info returned (eventbus)
  ///
  ///
  Future<Response> eventbusOffenseDetailsGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/eventbus/offense-details".replaceAll("{format}", "json");

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

  /// 获取所有违规详情记录 (eventbus)
  ///
  ///
  Future<List<Object>?> eventbusOffenseDetailsGet() async {
    Response response = await eventbusOffenseDetailsGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }

  /// 根据 ID 获取违规详情 with HTTP info returned (eventbus)
  ///
  ///
  Future<Response> eventbusOffenseDetailsIdGetWithHttpInfo(
      {required String id}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    if (id.isEmpty) {
      throw ApiException(400, "Missing required param: id");
    }

    // 创建路径和映射变量
    String path = "/eventbus/offense-details/{id}"
        .replaceAll("{format}", "json")
        .replaceAll("{id}", id);

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

  /// 根据 ID 获取违规详情 (eventbus)
  ///
  ///
  Future<Object?> eventbusOffenseDetailsIdGet({required String id}) async {
    Response response = await eventbusOffenseDetailsIdGetWithHttpInfo(id: id);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// 创建方法，用于发送 OffenseDetails 对象到 Kafka 主题 with HTTP info returned (eventbus)
  ///
  ///
  Future<Response> eventbusOffenseDetailsSendToKafkaIdPostWithHttpInfo(
      {required String id}) async {
    Object postBody = ''; // POST 请求通常有 body

    // 验证必需参数已设置
    if (id.isEmpty) {
      throw ApiException(400, "Missing required param: id");
    }

    // 创建路径和映射变量
    String path = "/eventbus/offense-details/send-to-kafka/{id}"
        .replaceAll("{format}", "json")
        .replaceAll("{id}", id);

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'POST', queryParams,
        postBody, headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// 创建方法，用于发送 OffenseDetails 对象到 Kafka 主题 (eventbus)
  ///
  ///
  Future<Object?> eventbusOffenseDetailsSendToKafkaIdPost(
      {required String id}) async {
    Response response =
        await eventbusOffenseDetailsSendToKafkaIdPostWithHttpInfo(id: id);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }
}
