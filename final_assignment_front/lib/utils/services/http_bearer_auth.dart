import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'package:final_assignment_front/utils/services/authentication.dart';
import 'package:final_assignment_front/utils/services/query_param.dart';

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
      AppLogger.debug('Applied Authorization header');
    } else {
      AppLogger.debug('No access token set for HttpBearerAuth');
    }
  }

  void setAccessToken(dynamic accessToken) {
    if (!((accessToken is String) || (accessToken is String Function()))) {
      throw ArgumentError(
          'Type of Bearer accessToken should be String or String Function().');
    }
    _accessToken = accessToken;
    AppLogger.debug('Set access token');
  }

  /// Returns the resolved token string if available, otherwise null.
  String? getAccessTokenString() {
    if (_accessToken == null) return null;
    if (_accessToken is String) return _accessToken as String;
    if (_accessToken is String Function()) {
      return (_accessToken as String Function())();
    }
    return null;
  }
}
