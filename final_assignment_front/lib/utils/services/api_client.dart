import 'dart:convert';

import 'package:final_assignment_front/features/model/appeal_management.dart';
import 'package:final_assignment_front/features/model/backup_restore.dart';
import 'package:final_assignment_front/features/model/category.dart';
import 'package:final_assignment_front/features/model/deduction_information.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/features/model/fine_information.dart';
import 'package:final_assignment_front/features/model/int.dart';
import 'package:final_assignment_front/features/model/integer.dart';
import 'package:final_assignment_front/features/model/login_log.dart';
import 'package:final_assignment_front/features/model/login_request.dart';
import 'package:final_assignment_front/features/model/offense_information.dart';
import 'package:final_assignment_front/features/model/operation_log.dart';
import 'package:final_assignment_front/features/model/permission_management.dart';
import 'package:final_assignment_front/features/model/register_request.dart';
import 'package:final_assignment_front/features/model/role_management.dart';
import 'package:final_assignment_front/features/model/security_context.dart';
import 'package:final_assignment_front/features/model/system_logs.dart';
import 'package:final_assignment_front/features/model/system_settings.dart';
import 'package:final_assignment_front/features/model/tag.dart';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:final_assignment_front/utils/auth/authentication.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:http/http.dart';

class QueryParam {
  String name;
  String value;

  QueryParam(this.name, this.value);
}

class ApiClient {
  String basePath;
  Client client;

  final Map<String, String> _defaultHeaderMap = {};
  final Map<String, Authentication> _authentications = {};

  final RegExp _regList = RegExp(r'^List<(.*)>$');
  final RegExp _regMap = RegExp(r'^Map<String,(.*)>$');

  ApiClient({this.basePath = "http://localhost"}) : client = Client();

  void addDefaultHeader(String key, String value) {
    _defaultHeaderMap[key] = value;
  }

  dynamic _deserialize(dynamic value, String targetType) {
    try {
      switch (targetType) {
        case 'String':
          return '$value';
        case 'int':
          return value is int ? value : int.parse('$value');
        case 'bool':
          return value is bool ? value : '$value'.toLowerCase() == 'true';
        case 'double':
          return value is double ? value : double.parse('$value');
        case 'AppealManagement':
          return AppealManagement.fromJson(value);
        case 'BackupRestore':
          return BackupRestore.fromJson(value);
        case 'Category':
          return Category.fromJson(value);
        case 'DeductionInformation':
          return DeductionInformation.fromJson(value);
        case 'DriverInformation':
          return DriverInformation.fromJson(value);
        case 'FineInformation':
          return FineInformation.fromJson(value);
        case 'Int':
          return Int.fromJson(value);
        case 'Integer':
          return Integer.fromJson(value);
        case 'LoginLog':
          return LoginLog.fromJson(value);
        case 'LoginRequest':
          return LoginRequest.fromJson(value);
        case 'OffenseInformation':
          return OffenseInformation.fromJson(value);
        case 'OperationLog':
          return OperationLog.fromJson(value);
        case 'PermissionManagement':
          return PermissionManagement.fromJson(value);
        case 'RegisterRequest':
          return RegisterRequest.fromJson(value);
        case 'RoleManagement':
          return RoleManagement.fromJson(value);
        case 'SecurityContext':
          return SecurityContext.fromJson(value);
        case 'SystemLogs':
          return SystemLogs.fromJson(value);
        case 'SystemSettings':
          return SystemSettings.fromJson(value);
        case 'Tag':
          return Tag.fromJson(value);
        case 'UserManagement':
          return UserManagement.fromJson(value);
        case 'VehicleInformation':
          return VehicleInformation.fromJson(value);
        default:
          {
            RegExpMatch? match;
            if (value is List &&
                (match = _regList.firstMatch(targetType)) != null) {
              var newTargetType =
                  match!.group(1)!; // Safe because match != null
              return value.map((v) => _deserialize(v, newTargetType)).toList();
            } else if (value is Map &&
                (match = _regMap.firstMatch(targetType)) != null) {
              var newTargetType =
                  match!.group(1)!; // Safe because match != null
              return Map<String, dynamic>.fromIterables(
                value.keys.cast<String>(),
                value.values.map((v) => _deserialize(v, newTargetType)),
              );
            }
          }
      }
    } on Exception catch (e, stack) {
      throw ApiException.withInner(
          500, 'Exception during deserialization.', e, stack);
    }
    throw ApiException(
        500, 'Could not find a suitable class for deserialization');
  }

  dynamic deserialize(String jsonStr, String targetType) {
    // Remove all spaces. Necessary for regex patterns as well.
    targetType = targetType.replaceAll(' ', '');

    if (targetType == 'String') return jsonStr;

    var decodedJson = jsonDecode(jsonStr);
    return _deserialize(decodedJson, targetType);
  }

  String serialize(Object obj) {
    return json.encode(obj);
  }

  /// We don't use a Map<String, String> for queryParams.
  /// If collectionFormat is 'multi' a key might appear multiple times.
  Future<Response> invokeAPI(
      String path,
      String method,
      Iterable<QueryParam> queryParams,
      Object? body,
      Map<String, String> headerParams,
      Map<String, String> formParams,
      String? nullableContentType,
      List<String> authNames) async {
    // Convert Iterable<QueryParam> to List<QueryParam>
    List<QueryParam> queryParamsList = queryParams.toList();

    // Update queryParams and headerParams based on authentication
    _updateParamsForAuth(authNames, queryParamsList, headerParams);

    // Build query string
    var ps = queryParamsList
        .where((p) => p.value.isNotEmpty) // Assuming value is non-nullable
        .map((p) =>
            '${Uri.encodeQueryComponent(p.name)}=${Uri.encodeQueryComponent(p.value)}');

    String queryString = ps.isNotEmpty ? '?${ps.join('&')}' : '';

    String url = basePath + path + queryString;

    // Merge default headers with headerParams
    headerParams.addAll(_defaultHeaderMap);
    final contentType =
        nullableContentType ?? 'application/json'; // Provide a default

    headerParams['Content-Type'] = contentType;

    Uri uri;
    try {
      uri = Uri.parse(url);
    } catch (e) {
      throw ApiException(500, 'Invalid URL: $url');
    }

    // Determine headers to pass
    if (body is MultipartRequest) {
      var request = MultipartRequest(method, uri);
      request.fields.addAll(body.fields);
      request.files.addAll(body.files);
      request.headers.addAll(body.headers);
      request.headers.addAll(headerParams);
      var streamedResponse = await client.send(request);
      return Response.fromStream(streamedResponse);
    } else {
      var msgBody = nullableContentType == "application/x-www-form-urlencoded"
          ? formParams
          : serialize(body ?? {});

      // Ensure headers are non-null
      final Map<String, String>? finalHeaderParams =
          headerParams.isEmpty ? null : headerParams;

      switch (method.toUpperCase()) {
        case "POST":
          return client.post(uri, headers: finalHeaderParams, body: msgBody);
        case "PUT":
          return client.put(uri, headers: finalHeaderParams, body: msgBody);
        case "DELETE":
          return client.delete(uri, headers: finalHeaderParams);
        case "PATCH":
          return client.patch(uri, headers: finalHeaderParams, body: msgBody);
        case "HEAD":
          return client.head(uri, headers: finalHeaderParams);
        case "GET":
        default:
          return client.get(uri, headers: finalHeaderParams);
      }
    }
  }

  /// Update query and header parameters based on authentication settings.
  /// @param authNames The authentications to apply
  void _updateParamsForAuth(List<String> authNames,
      List<QueryParam> queryParams, Map<String, String> headerParams) {
    for (var authName in authNames) {
      Authentication? auth = _authentications[authName];
      if (auth == null) {
        throw ArgumentError("Authentication undefined: $authName");
      }
      auth.applyToParams(queryParams, headerParams);
    }
  }

  T? getAuthentication<T extends Authentication>(String name) {
    var authentication = _authentications[name];

    return authentication is T ? authentication : null;
  }
}
