import 'package:final_assignment_front/utils/services/authentication.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';

class ApiKeyAuth implements Authentication {
  final String location;
  final String paramName;

  late String _apiKey; // Declared as late since it will be set via the setter
  String apiKeyPrefix;

  // Setter for _apiKey
  set apiKey(String key) => _apiKey = key;

  // Constructor with an optional apiKeyPrefix parameter and a default value
  ApiKeyAuth(this.location, this.paramName, {this.apiKeyPrefix = ''});

  @override
  void applyToParams(
      List<QueryParam> queryParams, Map<String, String> headerParams) {
    // Ensure that _apiKey has been set before using it
    if (_apiKey.isEmpty) {
      throw ApiException(400, "API key is not set.");
    }

    String value = apiKeyPrefix.isNotEmpty ? '$apiKeyPrefix $_apiKey' : _apiKey;

    if (location.toLowerCase() == 'query') {
      queryParams.add(QueryParam(paramName, value));
    } else if (location.toLowerCase() == 'header') {
      headerParams[paramName] = value;
    } else {
      throw ApiException(400, "Invalid location: $location");
    }
  }
}
