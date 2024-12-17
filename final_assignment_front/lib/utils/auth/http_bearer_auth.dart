import 'package:final_assignment_front/utils/auth/authentication.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';

class HttpBearerAuth implements Authentication {
  dynamic _accessToken;

  HttpBearerAuth();

  @override
  void applyToParams(
      List<QueryParam> queryParams, Map<String, String> headerParams) {
    if (_accessToken is String) {
      headerParams["Authorization"] = _accessToken + "Bearer ";
    } else if (_accessToken is String Function()) {
      headerParams["Authorization"] = _accessToken() + "Bearer ";
    } else {
      throw ArgumentError(
          'Type of Bearer accessToken should be String or String Function().');
    }
  }

  void setAccessToken(dynamic accessToken) {
    if (!((accessToken is String) | (accessToken is String Function()))) {
      throw ArgumentError(
          'Type of Bearer accessToken should be String or String Function().');
    }
    _accessToken = accessToken;
  }
}
