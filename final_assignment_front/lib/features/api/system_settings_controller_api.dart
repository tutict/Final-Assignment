import 'package:final_assignment_front/features/model/system_settings.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:http/http.dart'; // 用于 Response 和 MultipartRequest

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class SystemSettingsControllerApi {
  final ApiClient apiClient;

  // 更新后的构造函数，apiClient 参数可为空
  SystemSettingsControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  // 解码响应体的辅助方法
  String _decodeBodyBytes(Response response) {
    return response.body;
  }

  /// getCopyrightInfo with HTTP info returned
  ///
  ///
  Future<Response> apiSystemSettingsCopyrightInfoGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path =
        "/api/systemSettings/copyrightInfo".replaceAll("{format}", "json");

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

  /// getCopyrightInfo
  ///
  ///
  Future<Object?> apiSystemSettingsCopyrightInfoGet() async {
    Response response = await apiSystemSettingsCopyrightInfoGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getDateFormat with HTTP info returned
  ///
  ///
  Future<Response> apiSystemSettingsDateFormatGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path =
        "/api/systemSettings/dateFormat".replaceAll("{format}", "json");

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

  /// getDateFormat
  ///
  ///
  Future<Object?> apiSystemSettingsDateFormatGet() async {
    Response response = await apiSystemSettingsDateFormatGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getEmailAccount with HTTP info returned
  ///
  ///
  Future<Response> apiSystemSettingsEmailAccountGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path =
        "/api/systemSettings/emailAccount".replaceAll("{format}", "json");

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

  /// getEmailAccount
  ///
  ///
  Future<Object?> apiSystemSettingsEmailAccountGet() async {
    Response response = await apiSystemSettingsEmailAccountGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getEmailPassword with HTTP info returned
  ///
  ///
  Future<Response> apiSystemSettingsEmailPasswordGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path =
        "/api/systemSettings/emailPassword".replaceAll("{format}", "json");

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

  /// getEmailPassword
  ///
  ///
  Future<Object?> apiSystemSettingsEmailPasswordGet() async {
    Response response = await apiSystemSettingsEmailPasswordGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getSystemSettings with HTTP info returned
  ///
  ///
  Future<Response> apiSystemSettingsGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/systemSettings".replaceAll("{format}", "json");

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

  /// getSystemSettings
  ///
  ///
  Future<Object?> apiSystemSettingsGet() async {
    Response response = await apiSystemSettingsGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getLoginTimeout with HTTP info returned
  ///
  ///
  Future<Response> apiSystemSettingsLoginTimeoutGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path =
        "/api/systemSettings/loginTimeout".replaceAll("{format}", "json");

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

  /// getLoginTimeout
  ///
  ///
  Future<Object?> apiSystemSettingsLoginTimeoutGet() async {
    Response response = await apiSystemSettingsLoginTimeoutGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getPageSize with HTTP info returned
  ///
  ///
  Future<Response> apiSystemSettingsPageSizeGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/systemSettings/pageSize".replaceAll("{format}", "json");

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

  /// getPageSize
  ///
  ///
  Future<Object?> apiSystemSettingsPageSizeGet() async {
    Response response = await apiSystemSettingsPageSizeGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// updateSystemSettings with HTTP info returned
  ///
  ///
  Future<Response> apiSystemSettingsPutWithHttpInfo(
      {required SystemSettings systemSettings}) async {
    Object postBody = systemSettings;

    // 创建路径和映射变量
    String path = "/api/systemSettings".replaceAll("{format}", "json");

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

  /// updateSystemSettings
  ///
  ///
  Future<Object?> apiSystemSettingsPut(
      {required SystemSettings systemSettings}) async {
    Response response =
        await apiSystemSettingsPutWithHttpInfo(systemSettings: systemSettings);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getSessionTimeout with HTTP info returned
  ///
  ///
  Future<Response> apiSystemSettingsSessionTimeoutGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path =
        "/api/systemSettings/sessionTimeout".replaceAll("{format}", "json");

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

  /// getSessionTimeout
  ///
  ///
  Future<Object?> apiSystemSettingsSessionTimeoutGet() async {
    Response response = await apiSystemSettingsSessionTimeoutGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getSmtpServer with HTTP info returned
  ///
  ///
  Future<Response> apiSystemSettingsSmtpServerGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path =
        "/api/systemSettings/smtpServer".replaceAll("{format}", "json");

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

  /// getSmtpServer
  ///
  ///
  Future<Object?> apiSystemSettingsSmtpServerGet() async {
    Response response = await apiSystemSettingsSmtpServerGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getStoragePath with HTTP info returned
  ///
  ///
  Future<Response> apiSystemSettingsStoragePathGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path =
        "/api/systemSettings/storagePath".replaceAll("{format}", "json");

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

  /// getStoragePath
  ///
  ///
  Future<Object?> apiSystemSettingsStoragePathGet() async {
    Response response = await apiSystemSettingsStoragePathGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getSystemDescription with HTTP info returned
  ///
  ///
  Future<Response> apiSystemSettingsSystemDescriptionGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path =
        "/api/systemSettings/systemDescription".replaceAll("{format}", "json");

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

  /// getSystemDescription
  ///
  ///
  Future<Object?> apiSystemSettingsSystemDescriptionGet() async {
    Response response =
        await apiSystemSettingsSystemDescriptionGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getSystemName with HTTP info returned
  ///
  ///
  Future<Response> apiSystemSettingsSystemNameGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path =
        "/api/systemSettings/systemName".replaceAll("{format}", "json");

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

  /// getSystemName
  ///
  ///
  Future<Object?> apiSystemSettingsSystemNameGet() async {
    Response response = await apiSystemSettingsSystemNameGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getSystemVersion with HTTP info returned
  ///
  ///
  Future<Response> apiSystemSettingsSystemVersionGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path =
        "/api/systemSettings/systemVersion".replaceAll("{format}", "json");

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

  /// getSystemVersion
  ///
  ///
  Future<Object?> apiSystemSettingsSystemVersionGet() async {
    Response response = await apiSystemSettingsSystemVersionGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getCopyrightInfo (WebSocket)
  /// 对应后端: @WsAction(service="SystemSettingsService", action="getCopyrightInfo")
  Future<Object?> eventbusSystemSettingsCopyrightInfoGet() async {
    final msg = {
      "service": "SystemSettingsService",
      "action": "getCopyrightInfo",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// getDateFormat (WebSocket)
  /// 对应后端: @WsAction(service="SystemSettingsService", action="getDateFormat")
  Future<Object?> eventbusSystemSettingsDateFormatGet() async {
    final msg = {
      "service": "SystemSettingsService",
      "action": "getDateFormat",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// getEmailAccount (WebSocket)
  /// 对应后端: @WsAction(service="SystemSettingsService", action="getEmailAccount")
  Future<Object?> eventbusSystemSettingsEmailAccountGet() async {
    final msg = {
      "service": "SystemSettingsService",
      "action": "getEmailAccount",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// getEmailPassword (WebSocket)
  /// 对应后端: @WsAction(service="SystemSettingsService", action="getEmailPassword")
  Future<Object?> eventbusSystemSettingsEmailPasswordGet() async {
    final msg = {
      "service": "SystemSettingsService",
      "action": "getEmailPassword",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// getSystemSettings (WebSocket)
  /// 对应后端: @WsAction(service="SystemSettingsService", action="getSystemSettings")
  Future<Object?> eventbusSystemSettingsGet() async {
    final msg = {
      "service": "SystemSettingsService",
      "action": "getSystemSettings",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// getLoginTimeout (WebSocket)
  /// 对应后端: @WsAction(service="SystemSettingsService", action="getLoginTimeout")
  Future<Object?> eventbusSystemSettingsLoginTimeoutGet() async {
    final msg = {
      "service": "SystemSettingsService",
      "action": "getLoginTimeout",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// getPageSize (WebSocket)
  /// 对应后端: @WsAction(service="SystemSettingsService", action="getPageSize")
  Future<Object?> eventbusSystemSettingsPageSizeGet() async {
    final msg = {
      "service": "SystemSettingsService",
      "action": "getPageSize",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// updateSystemSettings (WebSocket)
  /// 对应后端: @WsAction(service="SystemSettingsService", action="updateSystemSettings")
  /// 需要传 1 个 SystemSettings(对象)
  Future<Object?> eventbusSystemSettingsPut(
      {required SystemSettings systemSettings}) async {
    final mapSettings = systemSettings.toJson();
    final msg = {
      "service": "SystemSettingsService",
      "action": "updateSystemSettings",
      "args": [mapSettings]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// getSessionTimeout (WebSocket)
  /// 对应后端: @WsAction(service="SystemSettingsService", action="getSessionTimeout")
  Future<Object?> eventbusSystemSettingsSessionTimeoutGet() async {
    final msg = {
      "service": "SystemSettingsService",
      "action": "getSessionTimeout",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// getSmtpServer (WebSocket)
  /// 对应后端: @WsAction(service="SystemSettingsService", action="getSmtpServer")
  Future<Object?> eventbusSystemSettingsSmtpServerGet() async {
    final msg = {
      "service": "SystemSettingsService",
      "action": "getSmtpServer",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// getStoragePath (WebSocket)
  /// 对应后端: @WsAction(service="SystemSettingsService", action="getStoragePath")
  Future<Object?> eventbusSystemSettingsStoragePathGet() async {
    final msg = {
      "service": "SystemSettingsService",
      "action": "getStoragePath",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// getSystemDescription (WebSocket)
  /// 对应后端: @WsAction(service="SystemSettingsService", action="getSystemDescription")
  Future<Object?> eventbusSystemSettingsSystemDescriptionGet() async {
    final msg = {
      "service": "SystemSettingsService",
      "action": "getSystemDescription",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// getSystemName (WebSocket)
  /// 对应后端: @WsAction(service="SystemSettingsService", action="getSystemName")
  Future<Object?> eventbusSystemSettingsSystemNameGet() async {
    final msg = {
      "service": "SystemSettingsService",
      "action": "getSystemName",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// getSystemVersion (WebSocket)
  /// 对应后端: @WsAction(service="SystemSettingsService", action="getSystemVersion")
  Future<Object?> eventbusSystemSettingsSystemVersionGet() async {
    final msg = {
      "service": "SystemSettingsService",
      "action": "getSystemVersion",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }
}
