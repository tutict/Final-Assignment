import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'package:final_assignment_front/features/model/progress_item.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

// å®ä¹ä¸ä¸ªå
// ¨å±ç?defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class ProgressControllerApi with BaseApiClient {
  @override
  final ApiClient apiClient;

  // æ´æ°åçæé å½æ°ï¼apiClient åæ°å¯ä¸ºç©?
  ProgressControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  /// ä»?SharedPreferences ä¸­è¯»å?jwtToken å¹¶è®¾ç½®å° ApiClient ä¸?
  Future<void> initializeWithJwt() async {
    final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null) {
      throw Exception('Not authenticated. Please log in again.');
    }
    apiClient.setJwtToken(jwtToken);
    AppLogger.debug('Initialized ProgressControllerApi with token: $jwtToken');
  }

  // è§£ç ååºä½çè¾
// å©æ¹æ³
  String _decodeBodyBytes(http.Response response) {
    return decodeBodyBytes(response);
  }

  /// åå»ºæ°çè¿åº¦è®°å½ã?with HTTP info returned
  Future<http.Response> _createProgressItemWithHttpInfo({
    required ProgressItem progressItem,
    Map<String, String>? headers,
  }) async {
    final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null) {
      throw ApiException(401, 'No JWT token found');
    }

    Object postBody = progressItem.toJson();

    // åå»ºè·¯å¾åæ å°åé?
    String path = "/api/progress".replaceAll("{format}", "json");

    // æ¥è¯¢åæ°
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {
      ...?headers,
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    };
    Map<String, String> formParams = {};

    List<String> contentTypes = ["application/json"];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'POST', queryParams,
        postBody, headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// åå»ºæ°çè¿åº¦è®°å½ã?
  Future<ProgressItem> createProgressItem({
    required ProgressItem progressItem,
    Map<String, String>? headers,
  }) async {
    http.Response response = await _createProgressItemWithHttpInfo(
        progressItem: progressItem, headers: headers);
    if (response.statusCode == 201) {
      return ProgressItem.fromJson(jsonDecode(_decodeBodyBytes(response)));
    }
    throw ApiException(response.statusCode, _decodeBodyBytes(response));
  }

  /// è·åææè¿åº¦è®°å½ã?with HTTP info returned
  Future<http.Response> _listProgressItemsWithHttpInfo({
    Map<String, String>? headers,
  }) async {
    final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null) {
      throw ApiException(401, 'No JWT token found');
    }

    Object postBody = ''; // GET è¯·æ±éå¸¸æ²¡æ body

    // åå»ºè·¯å¾åæ å°åé?
    String path = "/api/progress".replaceAll("{format}", "json");

    // æ¥è¯¢åæ°
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {
      ...?headers,
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    };
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// è·åææè¿åº¦è®°å½ã?
  Future<List<ProgressItem>> listProgressItems({
    Map<String, String>? headers,
  }) async {
    http.Response response =
        await _listProgressItemsWithHttpInfo(headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(_decodeBodyBytes(response));
      return data.map((json) => ProgressItem.fromJson(json)).toList();
    }
    throw ApiException(response.statusCode, _decodeBodyBytes(response));
  }

  /// æ ¹æ®ç¨æ·åè·åè¿åº¦è®°å½ã?with HTTP info returned
  Future<http.Response> _listProgressItemsByUsernameWithHttpInfo({
    required String username,
    Map<String, String>? headers,
  }) async {
    final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null) {
      throw ApiException(401, 'No JWT token found');
    }

    Object postBody = ''; // GET è¯·æ±éå¸¸æ²¡æ body

    // åå»ºè·¯å¾åæ å°åé?
    String path = "/api/progress".replaceAll("{format}", "json");

    // æ¥è¯¢åæ°
    List<QueryParam> queryParams = [
      QueryParam('username', username),
    ];
    Map<String, String> headerParams = {
      ...?headers,
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    };
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// æ ¹æ®ç¨æ·åè·åè¿åº¦è®°å½ã?
  Future<List<ProgressItem>> listProgressItemsByUsername({
    required String username,
    Map<String, String>? headers,
  }) async {
    http.Response response = await _listProgressItemsByUsernameWithHttpInfo(
        username: username, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(_decodeBodyBytes(response));
      return data.map((json) => ProgressItem.fromJson(json)).toList();
    }
    throw ApiException(response.statusCode, _decodeBodyBytes(response));
  }

  /// æ ¹æ®è¿åº¦IDæ´æ°è¿åº¦ç¶æã?with HTTP info returned
  Future<http.Response> _updateProgressItemStatusWithHttpInfo({
    required int progressId,
    required String newStatus,
    Map<String, String>? headers,
  }) async {
    final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null) {
      throw ApiException(401, 'No JWT token found');
    }

    Object postBody =
        ''; // PUT è¯·æ±è¿éä¸éè¦?bodyï¼å ä¸ºåæ°å¨æ¥è¯¢å­ç¬¦ä¸²ä¸­

    // åå»ºè·¯å¾åæ å°åé?
    String path =
        "/api/progress/$progressId/status".replaceAll("{format}", "json");

    // æ¥è¯¢åæ°
    List<QueryParam> queryParams = [
      QueryParam('newStatus', newStatus),
    ];
    Map<String, String> headerParams = {
      ...?headers,
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    };
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'PUT', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// æ ¹æ®è¿åº¦IDæ´æ°è¿åº¦ç¶æã?
  Future<ProgressItem> updateProgressItemStatus({
    required int progressId,
    required String newStatus,
    Map<String, String>? headers,
  }) async {
    http.Response response = await _updateProgressItemStatusWithHttpInfo(
        progressId: progressId, newStatus: newStatus, headers: headers);
    if (response.statusCode == 200) {
      return ProgressItem.fromJson(jsonDecode(_decodeBodyBytes(response)));
    }
    throw ApiException(response.statusCode, _decodeBodyBytes(response));
  }

  /// å é¤æå®è¿åº¦è®°å½ã?with HTTP info returned
  Future<http.Response> _deleteProgressItemWithHttpInfo({
    required int progressId,
    Map<String, String>? headers,
  }) async {
    final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null) {
      throw ApiException(401, 'No JWT token found');
    }

    Object postBody = ''; // DELETE è¯·æ±éå¸¸æ²¡æ body

    // åå»ºè·¯å¾åæ å°åé?
    String path = "/api/progress/$progressId".replaceAll("{format}", "json");

    // æ¥è¯¢åæ°
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {
      ...?headers,
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    };
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'DELETE', queryParams,
        postBody, headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// å é¤æå®è¿åº¦è®°å½ã?
  Future<void> deleteProgressItem({
    required int progressId,
    Map<String, String>? headers,
  }) async {
    http.Response response = await _deleteProgressItemWithHttpInfo(
        progressId: progressId, headers: headers);
    if (response.statusCode != 204) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    }
  }

  /// æ ¹æ®ç¶æè·åè¿åº¦è®°å½ã?with HTTP info returned
  Future<http.Response> _listProgressItemsByStatusWithHttpInfo({
    required String status,
    Map<String, String>? headers,
  }) async {
    final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null) {
      throw ApiException(401, 'No JWT token found');
    }

    Object postBody = ''; // GET è¯·æ±éå¸¸æ²¡æ body

    // åå»ºè·¯å¾åæ å°åé?
    String path = "/api/progress/status/$status".replaceAll("{format}", "json");

    // æ¥è¯¢åæ°
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {
      ...?headers,
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    };
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// æ ¹æ®ç¶æè·åè¿åº¦è®°å½ã?
  Future<List<ProgressItem>> listProgressItemsByStatus({
    required String status,
    Map<String, String>? headers,
  }) async {
    http.Response response = await _listProgressItemsByStatusWithHttpInfo(
        status: status, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(_decodeBodyBytes(response));
      return data.map((json) => ProgressItem.fromJson(json)).toList();
    }
    throw ApiException(response.statusCode, _decodeBodyBytes(response));
  }

  /// æ ¹æ®æ¶é´èå´è·åè¿åº¦è®°å½ã?with HTTP info returned
  Future<http.Response> _searchProgressItemsByTimeRangeWithHttpInfo({
    required String startTime,
    required String endTime,
    Map<String, String>? headers,
  }) async {
    final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null) {
      throw ApiException(401, 'No JWT token found');
    }

    Object postBody = ''; // GET è¯·æ±éå¸¸æ²¡æ body

    // åå»ºè·¯å¾åæ å°åé?
    String path = "/api/progress/timeRange".replaceAll("{format}", "json");

    // æ¥è¯¢åæ°
    List<QueryParam> queryParams = [
      QueryParam('startTime', startTime),
      QueryParam('endTime', endTime),
    ];
    Map<String, String> headerParams = {
      ...?headers,
      'Authorization': 'Bearer $jwtToken',
      'Content-Type': 'application/json',
    };
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// æ ¹æ®æ¶é´èå´è·åè¿åº¦è®°å½ã?
  Future<List<ProgressItem>> searchProgressItemsByTimeRange({
    required String startTime,
    required String endTime,
    Map<String, String>? headers,
  }) async {
    http.Response response = await _searchProgressItemsByTimeRangeWithHttpInfo(
        startTime: startTime, endTime: endTime, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(_decodeBodyBytes(response));
      return data.map((json) => ProgressItem.fromJson(json)).toList();
    }
    throw ApiException(response.statusCode, _decodeBodyBytes(response));
  }

  /// æ ¹æ®ç¨æ·åè·åè¿åº¦è®°å½?(WebSocket)
  /// å¯¹åºåç«¯: @WsAction(service="ProgressItemService", action="getProgressByUsername")
  Future<List<Object>?> eventbusProgressUsernameGet({
    required String username,
  }) async {
    final msg = {
      "service": "ProgressItemService",
      "action": "getProgressByUsername",
      "args": [username]
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

  /// è·åææè¿åº¦è®°å½?(WebSocket)
  /// å¯¹åº @WsAction(service="ProgressItemService", action="getAllProgress")
  Future<List<Object>?> eventbusProgressGet() async {
    final msg = {
      "service": "ProgressItemService",
      "action": "getAllProgress",
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

  /// æ ¹æ®ç¶æè·åè¿åº¦è®°å½?(WebSocket)
  /// å¯¹åº @WsAction(service="ProgressItemService", action="getProgressByStatus")
  Future<List<Object>?> eventbusProgressStatusStatusGet({
    required String status,
  }) async {
    final msg = {
      "service": "ProgressItemService",
      "action": "getProgressByStatus",
      "args": [status]
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

  /// æ ¹æ®æ¶é´èå´è·åè¿åº¦è®°å½ (WebSocket)
  /// å¯¹åº @WsAction(service="ProgressItemService", action="getProgressByTimeRange")
  Future<List<Object>?> eventbusProgressTimeRangeGet({
    required String startTime,
    required String endTime,
  }) async {
    final msg = {
      "service": "ProgressItemService",
      "action": "getProgressByTimeRange",
      "args": [startTime, endTime]
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

  /// æ ¹æ®è¿åº¦IDå é¤è¿åº¦è®°å½ (WebSocket)
  /// å¯¹åº @WsAction(service="ProgressItemService", action="deleteProgress")
  Future<Object?> eventbusProgressProgressIdDelete({
    required int progressId,
  }) async {
    final msg = {
      "service": "ProgressItemService",
      "action": "deleteProgress",
      "args": [progressId]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// æ ¹æ®è¿åº¦IDæ´æ°è¿åº¦ç¶æ?(WebSocket)
  /// å¯¹åº @WsAction(service="ProgressItemService", action="updateProgressStatus")
  Future<Object?> eventbusProgressProgressIdStatusPut({
    required int progressId,
    required String newStatus,
  }) async {
    final msg = {
      "service": "ProgressItemService",
      "action": "updateProgressStatus",
      "args": [progressId, newStatus]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// åå»ºæ°çè¿åº¦è®°å½ (WebSocket)
  /// å¯¹åº @WsAction(service="ProgressItemService", action="createProgress")
  Future<Object?> eventbusProgressPost({
    required ProgressItem progressItem,
  }) async {
    final msg = {
      "service": "ProgressItemService",
      "action": "createProgress",
      "args": [progressItem.toJson()]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }
}
