import 'package:final_assignment_front/features/model/system_settings.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class SystemSettingsControllerApi {
  final ApiClient apiClient;

  /// 构造函数，可传入 ApiClient，否则使用全局默认实例
  SystemSettingsControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  /// 从 SharedPreferences 中读取 jwtToken 并设置到 ApiClient 中
  Future<void> initializeWithJwt() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      throw Exception('未登录，请重新登录');
    }
    apiClient.setJwtToken(jwtToken);
    debugPrint('Initialized SystemSettingsControllerApi with token: $jwtToken');
  }

  /// 解码响应体字节到字符串
  String _decodeBodyBytes(Response response) => response.body;

  /// GET /api/systemSettings/copyrightInfo - 获取版权信息
  Future<String?> apiSystemSettingsCopyrightInfoGet() async {
    final response = await apiClient.invokeAPI(
      '/api/systemSettings/copyrightInfo',
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
    return apiClient.deserialize(_decodeBodyBytes(response), 'String')
        as String?;
  }

  /// GET /api/systemSettings/dateFormat - 获取日期格式
  Future<String?> apiSystemSettingsDateFormatGet() async {
    final response = await apiClient.invokeAPI(
      '/api/systemSettings/dateFormat',
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
    return apiClient.deserialize(_decodeBodyBytes(response), 'String')
        as String?;
  }

  /// GET /api/systemSettings/emailAccount - 获取邮箱账户
  Future<String?> apiSystemSettingsEmailAccountGet() async {
    final response = await apiClient.invokeAPI(
      '/api/systemSettings/emailAccount',
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
    return apiClient.deserialize(_decodeBodyBytes(response), 'String')
        as String?;
  }

  /// GET /api/systemSettings/emailPassword - 获取邮箱密码
  Future<String?> apiSystemSettingsEmailPasswordGet() async {
    final response = await apiClient.invokeAPI(
      '/api/systemSettings/emailPassword',
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
    return apiClient.deserialize(_decodeBodyBytes(response), 'String')
        as String?;
  }

  /// GET /api/systemSettings - 获取所有系统设置
  Future<SystemSettings?> apiSystemSettingsGet() async {
    final response = await apiClient.invokeAPI(
      '/api/systemSettings',
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
    return SystemSettings.fromJson(data);
  }

  /// GET /api/systemSettings/loginTimeout - 获取登录超时时间
  Future<int?> apiSystemSettingsLoginTimeoutGet() async {
    final response = await apiClient.invokeAPI(
      '/api/systemSettings/loginTimeout',
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
    return apiClient.deserialize(_decodeBodyBytes(response), 'int') as int?;
  }

  /// GET /api/systemSettings/pageSize - 获取分页大小
  Future<int?> apiSystemSettingsPageSizeGet() async {
    final response = await apiClient.invokeAPI(
      '/api/systemSettings/pageSize',
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
    return apiClient.deserialize(_decodeBodyBytes(response), 'int') as int?;
  }

  /// PUT /api/systemSettings - 更新系统设置 (仅管理员)
  Future<SystemSettings> apiSystemSettingsPut(
      {required SystemSettings systemSettings}) async {
    final response = await apiClient.invokeAPI(
      '/api/systemSettings',
      'PUT',
      [],
      systemSettings.toJson(),
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
    return SystemSettings.fromJson(data);
  }

  /// GET /api/systemSettings/sessionTimeout - 获取会话超时时间
  Future<int?> apiSystemSettingsSessionTimeoutGet() async {
    final response = await apiClient.invokeAPI(
      '/api/systemSettings/sessionTimeout',
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
    return apiClient.deserialize(_decodeBodyBytes(response), 'int') as int?;
  }

  /// GET /api/systemSettings/smtpServer - 获取SMTP服务器
  Future<String?> apiSystemSettingsSmtpServerGet() async {
    final response = await apiClient.invokeAPI(
      '/api/systemSettings/smtpServer',
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
    return apiClient.deserialize(_decodeBodyBytes(response), 'String')
        as String?;
  }

  /// GET /api/systemSettings/storagePath - 获取存储路径
  Future<String?> apiSystemSettingsStoragePathGet() async {
    final response = await apiClient.invokeAPI(
      '/api/systemSettings/storagePath',
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
    return apiClient.deserialize(_decodeBodyBytes(response), 'String')
        as String?;
  }

  /// GET /api/systemSettings/systemDescription - 获取系统描述
  Future<String?> apiSystemSettingsSystemDescriptionGet() async {
    final response = await apiClient.invokeAPI(
      '/api/systemSettings/systemDescription',
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
    return apiClient.deserialize(_decodeBodyBytes(response), 'String')
        as String?;
  }

  /// GET /api/systemSettings/systemName - 获取系统名称
  Future<String?> apiSystemSettingsSystemNameGet() async {
    final response = await apiClient.invokeAPI(
      '/api/systemSettings/systemName',
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
    return apiClient.deserialize(_decodeBodyBytes(response), 'String')
        as String?;
  }

  /// GET /api/systemSettings/systemVersion - 获取系统版本
  Future<String?> apiSystemSettingsSystemVersionGet() async {
    final response = await apiClient.invokeAPI(
      '/api/systemSettings/systemVersion',
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
    return apiClient.deserialize(_decodeBodyBytes(response), 'String')
        as String?;
  }

  // WebSocket Methods (Aligned with HTTP Endpoints)

  /// GET /api/systemSettings/copyrightInfo (WebSocket)
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

  /// GET /api/systemSettings/dateFormat (WebSocket)
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

  /// GET /api/systemSettings/emailAccount (WebSocket)
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

  /// GET /api/systemSettings/emailPassword (WebSocket)
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

  /// GET /api/systemSettings (WebSocket)
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

  /// GET /api/systemSettings/loginTimeout (WebSocket)
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

  /// GET /api/systemSettings/pageSize (WebSocket)
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

  /// PUT /api/systemSettings (WebSocket)
  /// 对应后端: @WsAction(service="SystemSettingsService", action="updateSystemSettings")
  Future<Object?> eventbusSystemSettingsPut(
      {required SystemSettings systemSettings}) async {
    final msg = {
      "service": "SystemSettingsService",
      "action": "updateSystemSettings",
      "args": [systemSettings.toJson()]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// GET /api/systemSettings/sessionTimeout (WebSocket)
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

  /// GET /api/systemSettings/smtpServer (WebSocket)
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

  /// GET /api/systemSettings/storagePath (WebSocket)
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

  /// GET /api/systemSettings/systemDescription (WebSocket)
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

  /// GET /api/systemSettings/systemName (WebSocket)
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

  /// GET /api/systemSettings/systemVersion (WebSocket)
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
