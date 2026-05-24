import 'package:final_assignment_front/features/model/offense_type_dict.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';

final ApiClient defaultApiClient = ApiClient();

class OffenseTypeControllerApi with BaseApiClient {
  @override
  final ApiClient apiClient;

  OffenseTypeControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  Future<void> initializeWithJwt() => initializeClientWithJwt();

  Future<OffenseTypeDictModel> createOffenseType({
    required OffenseTypeDictModel offenseType,
    String? idempotencyKey,
  }) {
    return requestObject(
      'POST',
      '/api/offense-types',
      OffenseTypeDictModel.fromJson,
      body: offenseType.toJson(),
      contentType: 'application/json',
      idempotencyKey: idempotencyKey,
    );
  }

  Future<OffenseTypeDictModel> updateOffenseType({
    required int typeId,
    required OffenseTypeDictModel offenseType,
    String? idempotencyKey,
  }) {
    return requestObject(
      'PUT',
      '/api/offense-types/$typeId',
      OffenseTypeDictModel.fromJson,
      body: offenseType.toJson(),
      contentType: 'application/json',
      idempotencyKey: idempotencyKey,
    );
  }

  Future<void> deleteOffenseType({required int typeId}) {
    return requestVoid('DELETE', '/api/offense-types/$typeId');
  }

  Future<OffenseTypeDictModel?> getOffenseType({
    required int typeId,
  }) {
    return requestNullableObject(
      'GET',
      '/api/offense-types/$typeId',
      OffenseTypeDictModel.fromJson,
    );
  }

  Future<List<OffenseTypeDictModel>> listOffenseTypes() {
    return requestList(
      'GET',
      '/api/offense-types',
      OffenseTypeDictModel.fromJson,
    );
  }

  Future<List<OffenseTypeDictModel>> searchOffenseTypesByCodePrefix({
    required String offenseCode,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(offenseCode, 'offenseCode');
    return _search('/api/offense-types/search/code/prefix', {
      'offenseCode': offenseCode,
      'page': page,
      'size': size,
    });
  }

  Future<List<OffenseTypeDictModel>> searchOffenseTypesByCodeFuzzy({
    required String offenseCode,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(offenseCode, 'offenseCode');
    return _search('/api/offense-types/search/code/fuzzy', {
      'offenseCode': offenseCode,
      'page': page,
      'size': size,
    });
  }

  Future<List<OffenseTypeDictModel>> searchOffenseTypesByNamePrefix({
    required String offenseName,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(offenseName, 'offenseName');
    return _search('/api/offense-types/search/name/prefix', {
      'offenseName': offenseName,
      'page': page,
      'size': size,
    });
  }

  Future<List<OffenseTypeDictModel>> searchOffenseTypesByNameFuzzy({
    required String offenseName,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(offenseName, 'offenseName');
    return _search('/api/offense-types/search/name/fuzzy', {
      'offenseName': offenseName,
      'page': page,
      'size': size,
    });
  }

  Future<List<OffenseTypeDictModel>> searchOffenseTypesByCategory({
    required String category,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(category, 'category');
    return _search('/api/offense-types/search/category', {
      'category': category,
      'page': page,
      'size': size,
    });
  }

  Future<List<OffenseTypeDictModel>> searchOffenseTypesBySeverity({
    required String severityLevel,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(severityLevel, 'severityLevel');
    return _search('/api/offense-types/search/severity', {
      'severityLevel': severityLevel,
      'page': page,
      'size': size,
    });
  }

  Future<List<OffenseTypeDictModel>> searchOffenseTypesByStatus({
    required String status,
    int page = 1,
    int size = 20,
  }) {
    requireNotBlank(status, 'status');
    return _search('/api/offense-types/search/status', {
      'status': status,
      'page': page,
      'size': size,
    });
  }

  Future<List<OffenseTypeDictModel>> searchOffenseTypesByFineRange({
    required double minAmount,
    required double maxAmount,
    int page = 1,
    int size = 20,
  }) {
    return _search('/api/offense-types/search/fine-range', {
      'minAmount': minAmount,
      'maxAmount': maxAmount,
      'page': page,
      'size': size,
    });
  }

  Future<List<OffenseTypeDictModel>> searchOffenseTypesByPointsRange({
    required int minPoints,
    required int maxPoints,
    int page = 1,
    int size = 20,
  }) {
    return _search('/api/offense-types/search/points-range', {
      'minPoints': minPoints,
      'maxPoints': maxPoints,
      'page': page,
      'size': size,
    });
  }

  Future<List<OffenseTypeDictModel>> _search(
    String path,
    Map<String, Object?> params,
  ) {
    return requestList(
      'GET',
      path,
      OffenseTypeDictModel.fromJson,
      queryParams: queryParamsFromMap(params),
    );
  }
}
