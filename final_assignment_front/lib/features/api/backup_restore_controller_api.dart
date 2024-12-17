import 'package:final_assignment_front/features/model/backup_restore.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:http/http.dart'; // 用于 Response 和 MultipartRequest
import 'package:final_assignment_front/utils/services/api_client.dart';

/// 定义一个全局的 defaultApiClient
final ApiClient defaultApiClient = ApiClient();

class BackupRestoreControllerApi {
  final ApiClient apiClient;

  // 更新后的构造函数，apiClient 参数可为空
  BackupRestoreControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  // 解码响应体的辅助方法
  String _decodeBodyBytes(Response response) {
    return response.body;
  }

  /// deleteBackup with HTTP info returned
  ///
  ///
  Future<Response> apiBackupsBackupIdDeleteWithHttpInfo(String backupId) async {
    Object postBody = ''; // DELETE 请求通常没有 body

    // 验证必需参数已设置
    if (backupId.isEmpty) {
      throw ApiException(400, "Missing required param: backupId");
    }

    // 创建路径和映射变量
    String path = "/api/backups/{backupId}"
        .replaceAll("{format}", "json")
        .replaceAll("{backupId}", backupId);

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

  /// deleteBackup
  ///
  ///
  Future<Object?> apiBackupsBackupIdDelete(String backupId) async {
    Response response = await apiBackupsBackupIdDeleteWithHttpInfo(backupId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getBackupById with HTTP info returned
  ///
  ///
  Future<Response> apiBackupsBackupIdGetWithHttpInfo(String backupId) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    if (backupId.isEmpty) {
      throw ApiException(400, "Missing required param: backupId");
    }

    // 创建路径和映射变量
    String path = "/api/backups/{backupId}"
        .replaceAll("{format}", "json")
        .replaceAll("{backupId}", backupId);

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

  /// getBackupById
  ///
  ///
  Future<Object?> apiBackupsBackupIdGet(String backupId) async {
    Response response = await apiBackupsBackupIdGetWithHttpInfo(backupId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// updateBackup with HTTP info returned
  ///
  ///
  Future<Response> apiBackupsBackupIdPutWithHttpInfo(String backupId,
      {int? backupNumber}) async {
    Object postBody = backupNumber ?? 0; // 根据实际需求设置默认值

    // 验证必需参数已设置
    if (backupId.isEmpty) {
      throw ApiException(400, "Missing required param: backupId");
    }

    // 创建路径和映射变量
    String path = "/api/backups/{backupId}"
        .replaceAll("{format}", "json")
        .replaceAll("{backupId}", backupId);

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

  /// updateBackup
  ///
  ///
  Future<Object?> apiBackupsBackupIdPut(String backupId,
      {int? backupNumber}) async {
    Response response = await apiBackupsBackupIdPutWithHttpInfo(backupId,
        backupNumber: backupNumber);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getBackupByFileName with HTTP info returned
  ///
  ///
  Future<Response> apiBackupsFilenameBackupFileNameGetWithHttpInfo(
      String backupFileName) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    if (backupFileName.isEmpty) {
      throw ApiException(400, "Missing required param: backupFileName");
    }

    // 创建路径和映射变量
    String path = "/api/backups/filename/{backupFileName}"
        .replaceAll("{format}", "json")
        .replaceAll("{backupFileName}", backupFileName);

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

  /// getBackupByFileName
  ///
  ///
  Future<Object?> apiBackupsFilenameBackupFileNameGet(
      String backupFileName) async {
    Response response =
        await apiBackupsFilenameBackupFileNameGetWithHttpInfo(backupFileName);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getAllBackups with HTTP info returned
  ///
  ///
  Future<Response> apiBackupsGetWithHttpInfo() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    // 假设此端点无需必需参数

    // 创建路径和映射变量
    String path = "/api/backups".replaceAll("{format}", "json");

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

  /// getAllBackups
  ///
  ///
  Future<Object?> apiBackupsGet() async {
    Response response = await apiBackupsGetWithHttpInfo();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// createBackup with HTTP info returned
  ///
  ///
  Future<Response> apiBackupsPostWithHttpInfo(
      {required BackupRestore backupRestore}) async {
    Object postBody = backupRestore;

    // 验证必需参数已设置
    // 因为使用了 'required'，无需检查是否为 null

    // 创建路径和映射变量
    String path = "/api/backups".replaceAll("{format}", "json");

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

  /// createBackup
  ///
  ///
  Future<Object?> apiBackupsPost({required BackupRestore backupRestore}) async {
    Response response =
        await apiBackupsPostWithHttpInfo(backupRestore: backupRestore);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getBackupsByTime with HTTP info returned
  ///
  ///
  Future<Response> apiBackupsTimeBackupTimeGetWithHttpInfo(
      String backupTime) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    if (backupTime.isEmpty) {
      throw ApiException(400, "Missing required param: backupTime");
    }

    // 创建路径和映射变量
    String path = "/api/backups/time/{backupTime}"
        .replaceAll("{format}", "json")
        .replaceAll("{backupTime}", backupTime);

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

  /// getBackupsByTime
  ///
  ///
  Future<Object?> apiBackupsTimeBackupTimeGet(String backupTime) async {
    Response response =
        await apiBackupsTimeBackupTimeGetWithHttpInfo(backupTime);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// deleteBackup with HTTP info returned (eventbus)
  ///
  ///
  Future<Response> eventbusBackupsBackupIdDeleteWithHttpInfo(
      String backupId) async {
    Object postBody = ''; // DELETE 请求通常没有 body

    // 验证必需参数已设置
    if (backupId.isEmpty) {
      throw ApiException(400, "Missing required param: backupId");
    }

    // 创建路径和映射变量
    String path = "/eventbus/backups/{backupId}"
        .replaceAll("{format}", "json")
        .replaceAll("{backupId}", backupId);

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

  /// deleteBackup
  ///
  ///
  Future<Object?> eventbusBackupsBackupIdDelete(String backupId) async {
    Response response =
        await eventbusBackupsBackupIdDeleteWithHttpInfo(backupId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getBackupById with HTTP info returned (eventbus)
  ///
  ///
  Future<Response> eventbusBackupsBackupIdGetWithHttpInfo(
      String backupId) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    if (backupId.isEmpty) {
      throw ApiException(400, "Missing required param: backupId");
    }

    // 创建路径和映射变量
    String path = "/eventbus/backups/{backupId}"
        .replaceAll("{format}", "json")
        .replaceAll("{backupId}", backupId);

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

  /// getBackupById (eventbus)
  ///
  ///
  Future<Object?> eventbusBackupsBackupIdGet(String backupId) async {
    Response response = await eventbusBackupsBackupIdGetWithHttpInfo(backupId);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// updateBackup with HTTP info returned (eventbus)
  ///
  ///
  Future<Response> eventbusBackupsBackupIdPutWithHttpInfo(String backupId,
      {int? backupNumber}) async {
    Object postBody = backupNumber ?? 0; // 根据实际需求设置默认值

    // 验证必需参数已设置
    if (backupId.isEmpty) {
      throw ApiException(400, "Missing required param: backupId");
    }

    // 创建路径和映射变量
    String path = "/eventbus/backups/{backupId}"
        .replaceAll("{format}", "json")
        .replaceAll("{backupId}", backupId);

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

  /// updateBackup (eventbus)
  ///
  ///
  Future<Object?> eventbusBackupsBackupIdPut(String backupId,
      {int? backupNumber}) async {
    Response response = await eventbusBackupsBackupIdPutWithHttpInfo(backupId,
        backupNumber: backupNumber);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getBackupByFileName with HTTP info returned (eventbus)
  ///
  ///
  Future<Response> apiBackupsEventbusFilenameBackupFileNameGetWithHttpInfo(
      String backupFileName) async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    if (backupFileName.isEmpty) {
      throw ApiException(400, "Missing required param: backupFileName");
    }

    // 创建路径和映射变量
    String path = "/eventbus/backups/filename/{backupFileName}"
        .replaceAll("{format}", "json")
        .replaceAll("{backupFileName}", backupFileName);

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

  /// getBackupByFileName (eventbus)
  ///
  ///
  Future<Object?> apiBackupsEventbusFilenameBackupFileNameGet(
      String backupFileName) async {
    Response response =
        await apiBackupsFilenameBackupFileNameGetWithHttpInfo(backupFileName);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if (response.body.isNotEmpty) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Object')
          as Object;
    } else {
      return null;
    }
  }

  /// getAllBackups with HTTP info returned (eventbus)
  ///
  ///
  Future<Response> apiBackupsGetWithHttpInfoEventbus() async {
    Object postBody = ''; // GET 请求通常没有 body

    // 验证必需参数已设置
    // 假设此端点无需必需参数

    // 创建路径和映射变量
    String path = "/eventbus/backups".replaceAll("{format}", "json");

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

  /// getAllBackups (eventbus)
  ///
  ///
  Future<Object?> apiBackupsGetEventbus() async {
    Response response = await apiBackupsGetWithHttpInfoEventbus();
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
