import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'dart:convert';
import 'package:final_assignment_front/features/model/login_request.dart';
import 'package:final_assignment_front/features/model/register_request.dart';
import 'package:final_assignment_front/features/model/user_response.dart';
import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:http/http.dart' as http; // ç¨äº Response å?MultipartRequest
import 'package:final_assignment_front/utils/services/api_client.dart';

// å®ä¹ä¸ä¸ªå
// ¨å±ç?defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class AuthControllerApi with BaseApiClient {
  @override
  final ApiClient apiClient;

  // æ´æ°åçæé å½æ°ï¼apiClient åæ°å¯ä¸ºç©?
  AuthControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  // è·åéç¨è¯·æ±å¤´ï¼å
// å« JWT
  Future<Map<String, String>> _getHeaders() async {
    return getHeaders();
  }

  Map<String, String> _getPublicHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// ä½¿ç¨ HTTP ä¿¡æ¯è¿è¡ç»å½
  Future<http.Response> _loginWithHttpInfo(
      {required LoginRequest loginRequest}) async {
    Object postBody = loginRequest;

    String path = "/api/auth/login".replaceAll("{format}", "json");

    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = _getPublicHeaders();
    Map<String, String> formParams = {};

    List<String> contentTypes = ["application/json"];
    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'POST', queryParams,
        postBody, headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// ç»å½
  Future<Map<String, dynamic>> login(
      {required LoginRequest loginRequest}) async {
    try {
      http.Response response =
          await _loginWithHttpInfo(loginRequest: loginRequest);
      AppLogger.debug('Login response status: ${response.statusCode}');
      AppLogger.debug('Login response body: ${response.body}');

      if (response.body.isNotEmpty) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {};
      }
    } catch (e) {
      AppLogger.error('Login error: $e');
      rethrow;
    }
  }

  /// ä½¿ç¨ HTTP ä¿¡æ¯è¿è¡ç¨æ·æ³¨å
  Future<http.Response> _registerWithHttpInfo(
      {required RegisterRequest registerRequest}) async {
    Object postBody = registerRequest;

    String path = "/api/auth/register".replaceAll("{format}", "json");

    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = _getPublicHeaders();
    Map<String, String> formParams = {};

    List<String> contentTypes = ["application/json"];
    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'POST', queryParams,
        postBody, headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// ç¨æ·æ³¨å
  Future<Map<String, dynamic>> register(
      {required RegisterRequest registerRequest}) async {
    try {
      http.Response response =
          await _registerWithHttpInfo(registerRequest: registerRequest);
      AppLogger.debug('Register response status: ${response.statusCode}');
      AppLogger.debug('Register response body: ${response.body}');

      if (response.body.isNotEmpty) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 201) {
        return {'status': 'CREATED'};
      } else {
        throw AppException.http(response.statusCode, 'Empty response body');
      }
    } catch (e) {
      AppLogger.error('Register error: $e');
      rethrow;
    }
  }

  /// ä½¿ç¨ HTTP ä¿¡æ¯è·åææç¨æ?
  Future<http.Response> _listAuthUsersWithHttpInfo() async {
    String path = "/api/auth/users".replaceAll("{format}", "json");

    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = await _getHeaders();
    Map<String, String> formParams = {};

    List<String> contentTypes = [];
    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, null,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// è·åææç¨æ?
  Future<List<UserResponse>> listAuthUsers() async {
    try {
      http.Response response = await _listAuthUsersWithHttpInfo();
      AppLogger.debug('Users get response status: ${response.statusCode}');
      AppLogger.debug('Users get response body: ${response.body}');

      if (response.body.isNotEmpty) {
        return unwrapApiResponse(
          jsonDecode(decodeBodyBytes(response)) as Map<String, dynamic>,
          (data) => (data as List)
              .map((e) => UserResponse.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      } else {
        return [];
      }
    } catch (e) {
      AppLogger.error('Users get error: $e');
      rethrow;
    }
  }

  /// è·åè§è²åè¡¨ï¼æ°å¢ï¼
  Future<http.Response> _listRolesWithHttpInfo() async {
    String path = "/api/roles".replaceAll("{format}", "json");

    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = await _getHeaders();
    Map<String, String> formParams = {};

    List<String> contentTypes = [];
    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, null,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// è·åè§è²åè¡¨
  Future<Map<String, dynamic>> listRoles() async {
    try {
      http.Response response = await _listRolesWithHttpInfo();
      AppLogger.debug('Roles get response status: ${response.statusCode}');
      AppLogger.debug('Roles get response body: ${response.body}');

      if (response.body.isNotEmpty) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {};
      }
    } catch (e) {
      AppLogger.error('Roles get error: $e');
      rethrow;
    }
  }

  /// ç»å½ï¼WebSocketï¼?
  Future<Object?> eventbusAuthLoginPost(
      {required LoginRequest loginRequest}) async {
    final msg = <String, dynamic>{
      "service": "AuthWsService",
      "action": "login",
      "args": [
        {"username": loginRequest.username, "password": loginRequest.password}
      ],
    };

    final respMap = await apiClient.sendWsMessage(msg);

    if (respMap.containsKey("error")) {
      throw AppException.http(400, respMap["error"]);
    }
    if (respMap.containsKey("result")) {
      return respMap["result"];
    }
    return null;
  }

  /// ç¨æ·æ³¨åï¼WebSocketï¼?
  Future<Object?> eventbusAuthRegisterPost(
      {required RegisterRequest registerRequest}) async {
    final msg = <String, dynamic>{
      "service": "AuthWsService",
      "action": "registerUser",
      "args": [
        {
          "username": registerRequest.username,
          "password": registerRequest.password,
          "role": registerRequest.role,
          "idempotencyKey": registerRequest.idempotencyKey
        }
      ],
    };

    final respMap = await apiClient.sendWsMessage(msg);

    if (respMap.containsKey("error")) {
      throw AppException.http(400, respMap["error"]);
    }
    if (respMap.containsKey("result")) {
      return respMap["result"];
    }
    return null;
  }

  /// è·åææç¨æ·ï¼WebSocketï¼?
  Future<Object?> eventbusAuthUsersGet() async {
    final msg = <String, dynamic>{
      "service": "AuthWsService",
      "action": "getAllUsers",
      "args": []
    };

    final respMap = await apiClient.sendWsMessage(msg);

    if (respMap.containsKey("error")) {
      throw AppException.http(400, respMap["error"]);
    }
    if (respMap.containsKey("result")) {
      return respMap["result"];
    }
    return null;
  }
}
