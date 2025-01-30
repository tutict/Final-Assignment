import 'package:final_assignment_front/features/model/security_context.dart';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:http/http.dart'; // 用于 Response 和 MultipartRequest

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class UserManagementControllerApi {
  final ApiClient apiClient;

  // 更新后的构造函数，apiClient 参数可为空
  UserManagementControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  // 解码响应体的辅助方法
  String _decodeBodyBytes(Response response) {
    return response.body;
  }

  /// getAllUsers with HTTP info returned
  ///
  ///
  Future<Response> apiUsersGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/users".replaceAll("{format}", "json");

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

  /// getAllUsers
  ///
  ///
  Future<List<Object>?> apiUsersGet() async {
    Response response = await apiUsersGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }

  /// 获取当前用户的违规详情 with HTTP info returned
  ///
  ///
  Future<Response> apiUsersMeGetWithHttpInfo(
      {required SecurityContext securityContext}) async {
    Object postBody = securityContext;

    // 创建路径和映射变量
    String path = "/api/users/me".replaceAll("{format}", "json");

    // 查询参数
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = ["application/json"];

    String? nullableContentType =
        contentTypes.isNotEmpty ? contentTypes[0] : null;
    List<String> authNames = [];

    // 已移除与 MultipartRequest 相关的死代码

    var response = await apiClient.invokeAPI(path, 'GET', queryParams, postBody,
        headerParams, formParams, nullableContentType, authNames);
    return response;
  }

  /// 获取当前用户的违规详情
  ///
  ///
  Future<Object?> apiUsersMeGet(
      {required SecurityContext securityContext}) async {
    Response response =
        await apiUsersMeGetWithHttpInfo(securityContext: securityContext);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// 更新当前用户信息 with HTTP info returned
  ///
  ///
  Future<Response> apiUsersMePutWithHttpInfo(
      {required SecurityContext securityContext}) async {
    Object postBody = securityContext;

    // 创建路径和映射变量
    String path = "/api/users/me".replaceAll("{format}", "json");

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

  /// 更新当前用户信息
  ///
  ///
  Future<Object?> apiUsersMePut(
      {required SecurityContext securityContext}) async {
    Response response =
        await apiUsersMePutWithHttpInfo(securityContext: securityContext);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// createUser with HTTP info returned
  ///
  ///
  Future<Response> apiUsersPostWithHttpInfo(
      {required UserManagement userManagement}) async {
    Object postBody = userManagement;

    // 创建路径和映射变量
    String path = "/api/users".replaceAll("{format}", "json");

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

  /// createUser
  ///
  ///
  Future<Object?> apiUsersPost({required UserManagement userManagement}) async {
    Response response =
        await apiUsersPostWithHttpInfo(userManagement: userManagement);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getUsersByStatus with HTTP info returned
  ///
  ///
  Future<Response> apiUsersStatusStatusGetWithHttpInfo(
      {required String status}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/users/status/{status}"
        .replaceAll("{format}", "json")
        .replaceAll("{" "status" "}", status.toString());

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

  /// getUsersByStatus
  ///
  ///
  Future<List<Object>?> apiUsersStatusStatusGet(
      {required String status}) async {
    Response response =
        await apiUsersStatusStatusGetWithHttpInfo(status: status);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }

  /// getUsersByType with HTTP info returned
  ///
  ///
  Future<Response> apiUsersTypeUserTypeGetWithHttpInfo(
      {required String userType}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/users/type/{userType}"
        .replaceAll("{format}", "json")
        .replaceAll("{" "userType" "}", userType.toString());

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

  /// getUsersByType
  ///
  ///
  Future<List<Object>?> apiUsersTypeUserTypeGet(
      {required String userType}) async {
    Response response =
        await apiUsersTypeUserTypeGetWithHttpInfo(userType: userType);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'List<Object>')
          as List<Object>;
    } else {
      return null;
    }
  }

  /// deleteUser with HTTP info returned
  ///
  ///
  Future<Response> apiUsersUserIdDeleteWithHttpInfo(
      {required String userId}) async {
    Object postBody = ''; // DELETE 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/users/{userId}"
        .replaceAll("{format}", "json")
        .replaceAll("{" "userId" "}", userId.toString());

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

  /// deleteUser
  ///
  ///
  Future<bool> apiUsersUserIdDelete({required String userId}) async {
    Response response = await apiUsersUserIdDeleteWithHttpInfo(userId: userId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else {
      // 假设 DELETE 请求成功时不返回内容，返回 true
      return true;
    }
  }

  /// getUserById with HTTP info returned
  ///
  ///
  Future<Response> apiUsersUserIdGetWithHttpInfo(
      {required String userId}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/users/{userId}"
        .replaceAll("{format}", "json")
        .replaceAll("{" "userId" "}", userId.toString());

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

  /// getUserById
  ///
  ///
  Future<Object?> apiUsersUserIdGet({required String userId}) async {
    Response response = await apiUsersUserIdGetWithHttpInfo(userId: userId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// updateUser with HTTP info returned
  ///
  ///
  Future<Response> apiUsersUserIdPutWithHttpInfo(
      {required String userId, required UserManagement userManagement}) async {
    Object postBody = userManagement;

    // 创建路径和映射变量
    String path = "/api/users/{userId}"
        .replaceAll("{format}", "json")
        .replaceAll("{" "userId" "}", userId.toString());

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

  /// updateUser
  ///
  ///
  Future<Object?> apiUsersUserIdPut(
      {required String userId, required UserManagement userManagement}) async {
    Response response = await apiUsersUserIdPutWithHttpInfo(
        userId: userId, userManagement: userManagement);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// deleteUserByUsername with HTTP info returned
  ///
  ///
  Future<Response> apiUsersUsernameUsernameDeleteWithHttpInfo(
      {required String username}) async {
    Object postBody = ''; // DELETE 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/users/username/{username}"
        .replaceAll("{format}", "json")
        .replaceAll("{" "username" "}", username.toString());

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

  /// deleteUserByUsername
  ///
  ///
  Future<bool> apiUsersUsernameUsernameDelete(
      {required String username}) async {
    Response response =
        await apiUsersUsernameUsernameDeleteWithHttpInfo(username: username);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else {
      // 假设 DELETE 请求成功时不返回内容，返回 true
      return true;
    }
  }

  /// getUserByUsername with HTTP info returned
  ///
  ///
  Future<Response> apiUsersUsernameUsernameGetWithHttpInfo(
      {required String username}) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 创建路径和映射变量
    String path = "/api/users/username/{username}"
        .replaceAll("{format}", "json")
        .replaceAll("{" "username" "}", username.toString());

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

  /// getUserByUsername
  ///
  ///
  Future<Object?> apiUsersUsernameUsernameGet(
      {required String username}) async {
    Response response =
        await apiUsersUsernameUsernameGetWithHttpInfo(username: username);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getAllUsers (WebSocket)
  /// 对应后端: @WsAction(service="UserManagementService", action="getAllUsers")
  Future<List<Object>?> eventbusUsersGet() async {
    final msg = {
      "service": "UserManagementService",
      "action": "getAllUsers",
      "args": [] // 无参数
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

  /// getCurrentUser (WebSocket)
  /// 如果后端是 @WsAction(service="UserManagementService", action="getCurrentUser")
  /// 并需要 1 个参数(用户名)
  Future<Object?> eventbusUsersMeGet({required String username}) async {
    final msg = {
      "service": "UserManagementService",
      "action": "getCurrentUser",
      "args": [username]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// updateCurrentUser (WebSocket)
  /// 若后端 @WsAction(service="UserManagementService", action="updateCurrentUser")
  /// 并签名: updateCurrentUser(String username, UserManagement updated)
  Future<Object?> eventbusUsersMePut(
      {required String username, required UserManagement updated}) async {
    final updatedMap = updated.toJson();
    final msg = {
      "service": "UserManagementService",
      "action": "updateCurrentUser",
      "args": [username, updatedMap]
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// createUser (WebSocket)
  /// 对应后端: @WsAction(service="UserManagementService", action="createUser")
  Future<Object?> eventbusUsersPost(
      {required UserManagement userManagement}) async {
    final userMap = userManagement.toJson();
    final msg = {
      "service": "UserManagementService",
      "action": "createUser",
      "args": [userMap]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// getUsersByStatus (WebSocket)
  /// 对应后端: @WsAction(service="UserManagementService", action="getUsersByStatus")
  Future<List<Object>?> eventbusUsersStatusStatusGet(
      {required String status}) async {
    final msg = {
      "service": "UserManagementService",
      "action": "getUsersByStatus",
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

  /// getUsersByType (WebSocket)
  /// 对应后端: @WsAction(service="UserManagementService", action="getUsersByType")
  Future<List<Object>?> eventbusUsersTypeUserTypeGet(
      {required String userType}) async {
    final msg = {
      "service": "UserManagementService",
      "action": "getUsersByType",
      "args": [userType]
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

  /// deleteUser (WebSocket)
  /// 对应后端: @WsAction(service="UserManagementService", action="deleteUser")
  Future<bool> eventbusUsersUserIdDelete({required String userId}) async {
    // 假设后端是 deleteUser(int userId)
    final msg = {
      "service": "UserManagementService",
      "action": "deleteUser",
      "args": [int.parse(userId)]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    // 如果后端无返回(或返回true/false), 这里假设成功
    return true;
  }

  /// getUserById (WebSocket)
  /// 对应后端: @WsAction(service="UserManagementService", action="getUserById")
  Future<Object?> eventbusUsersUserIdGet({required String userId}) async {
    final msg = {
      "service": "UserManagementService",
      "action": "getUserById",
      "args": [int.parse(userId)]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// updateUser (WebSocket)
  /// 对应后端: @WsAction(service="UserManagementService", action="updateUser")
  Future<Object?> eventbusUsersUserIdPut(
      {required String userId, required UserManagement userManagement}) async {
    final userMap = userManagement.toJson();
    final msg = {
      "service": "UserManagementService",
      "action": "updateUser",
      "args": [int.parse(userId), userMap]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }

  /// deleteUserByUsername (WebSocket)
  /// 对应后端: @WsAction(service="UserManagementService", action="deleteUserByUsername")
  Future<bool> eventbusUsersUsernameUsernameDelete(
      {required String username}) async {
    // e.g. deleteUserByUsername(String username)
    final msg = {
      "service": "UserManagementService",
      "action": "deleteUserByUsername",
      "args": [username]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return true;
  }

  /// getUserByUsername (WebSocket)
  /// 对应后端: @WsAction(service="UserManagementService", action="getUserByUsername")
  Future<Object?> eventbusUsersUsernameUsernameGet(
      {required String username}) async {
    final msg = {
      "service": "UserManagementService",
      "action": "getUserByUsername",
      "args": [username]
    };

    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    return respMap["result"];
  }
}
