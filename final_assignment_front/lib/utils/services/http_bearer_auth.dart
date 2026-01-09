import 'package:final_assignment_front/utils/services/authentication.dart';
import 'package:final_assignment_front/utils/services/query_param.dart';
import 'package:flutter/material.dart';

class HttpBearerAuth implements Authentication {
  dynamic _accessToken;

  HttpBearerAuth();

  @override
  void applyToParams(
      List<QueryParam> queryParams, Map<String, String> headerParams) {
    if (_accessToken != null) {
      String token;
      if (_accessToken is String) {
        token = _accessToken;
      } else if (_accessToken is String Function()) {
        token = _accessToken();
      } else {
        throw ArgumentError(
            'Type of Bearer accessToken should be String or String Function().');
      }
      headerParams["Authorization"] = "Bearer $token";
      debugPrint('Applied Authorization header: Bearer $token');
    } else {
      debugPrint('No access token set for HttpBearerAuth');
    }
  }

  void setAccessToken(dynamic accessToken) {
    if (!((accessToken is String) || (accessToken is String Function()))) {
      throw ArgumentError(
          'Type of Bearer accessToken should be String or String Function().');
    }
    _accessToken = accessToken;
    debugPrint('Set access token: $_accessToken');
  }

  /// Returns the resolved token string if available, otherwise null.
  String? getAccessTokenString() {
    if (_accessToken == null) return null;
    if (_accessToken is String) return _accessToken as String;
    if (_accessToken is String Function()) return (_accessToken as String Function())();
    return null;
  }
}
