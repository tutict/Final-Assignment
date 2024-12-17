import 'package:final_assignment_front/utils/auth/authentication.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';

class OAuth implements Authentication {
  String _accessToken;

  OAuth({required String accessToken}) : _accessToken = accessToken;

  @override
  void applyToParams(
      List<QueryParam> queryParams, Map<String, String> headerParams) {
    headerParams["Authorization"] = "Bearer $_accessToken";
  }

  set accessToken(String accessToken) => _accessToken = accessToken;
}
