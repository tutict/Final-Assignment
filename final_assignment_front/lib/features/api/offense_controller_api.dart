import 'package:final_assignment_front/features/model/offense_information.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';

final ApiClient defaultApiClient = ApiClient();

class OffenseControllerApi with BaseApiClient {
  @override
  final ApiClient apiClient;

  OffenseControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  Future<void> initializeWithJwt() => initializeClientWithJwt();

  Future<List<OffenseInformation>> listOffenses() {
    return requestList(
      'GET',
      '/api/violations',
      OffenseInformation.fromJson,
    );
  }

  Future<Map<String, dynamic>> getOffenseDetails({
    required int offenseId,
  }) {
    return requestMap('GET', '/api/violations/$offenseId');
  }

  Future<List<OffenseInformation>> listOffensesByStatus({
    required String processStatus,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(processStatus, 'processStatus');
    return requestList(
      'GET',
      '/api/violations/status',
      OffenseInformation.fromJson,
      queryParams: queryParamsFromMap({
        'processStatus': processStatus,
        'page': page,
        'size': size,
      }),
    );
  }
}
