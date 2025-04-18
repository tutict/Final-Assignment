import 'package:final_assignment_front/utils/services/api_client.dart';

abstract class Authentication {
  /// Apply authentication settings to header and query params.
  void applyToParams(
      List<QueryParam> queryParams, Map<String, String> headerParams);
}
