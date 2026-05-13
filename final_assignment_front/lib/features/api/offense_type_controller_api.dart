import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'dart:convert';

import 'package:final_assignment_front/features/model/offense_type_dict.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

final ApiClient defaultApiClient = ApiClient();

class OffenseTypeControllerApi with BaseApiClient {
  @override
  final ApiClient apiClient;

  OffenseTypeControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  Future<void> initializeWithJwt() async {
    final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null || jwtToken.isEmpty) {
      throw Exception('JWT token not found in SharedPreferences');
    }
    apiClient.setJwtToken(jwtToken);
    AppLogger.debug(
        'Initialized OffenseTypeControllerApi with token: $jwtToken');
  }

  String _decodeBodyBytes(http.Response response) {
    return decodeBodyBytes(response);
  }

  Future<Map<String, String>> _getHeaders({String? idempotencyKey}) async {
    return getHeaders(idempotencyKey: idempotencyKey);
  }

  void _ensureSuccess(http.Response response) {
    ensureSuccess(response);
  }

  List<OffenseTypeDictModel> _parseList(String body) {
    if (body.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(body) as List<dynamic>;
    return jsonList
        .map((item) =>
            OffenseTypeDictModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/offense-types
  Future<OffenseTypeDictModel> createOffenseType({
    required OffenseTypeDictModel offenseType,
    String? idempotencyKey,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offense-types',
      'POST',
      const [],
      offenseType.toJson(),
      await _getHeaders(idempotencyKey: idempotencyKey),
      const {},
      'application/json',
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return OffenseTypeDictModel.fromJson(
        jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>);
  }

  /// PUT /api/offense-types/{typeId}
  Future<OffenseTypeDictModel> updateOffenseType({
    required int typeId,
    required OffenseTypeDictModel offenseType,
    String? idempotencyKey,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offense-types/$typeId',
      'PUT',
      const [],
      offenseType.toJson(),
      await _getHeaders(idempotencyKey: idempotencyKey),
      const {},
      'application/json',
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return OffenseTypeDictModel.fromJson(
        jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>);
  }

  /// DELETE /api/offense-types/{typeId}
  Future<void> deleteOffenseType({required int typeId}) async {
    final response = await apiClient.invokeAPI(
      '/api/offense-types/$typeId',
      'DELETE',
      const [],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      _ensureSuccess(response);
    }
  }

  /// GET /api/offense-types/{typeId}
  Future<OffenseTypeDictModel?> getOffenseType({
    required int typeId,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offense-types/$typeId',
      'GET',
      const [],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
      passThroughStatusCodes: const {404},
    );
    if (response.statusCode == 404) return null;
    _ensureSuccess(response);
    if (response.body.isEmpty) return null;
    return OffenseTypeDictModel.fromJson(
        jsonDecode(_decodeBodyBytes(response)) as Map<String, dynamic>);
  }

  /// GET /api/offense-types
  Future<List<OffenseTypeDictModel>> listOffenseTypes() async {
    final response = await apiClient.invokeAPI(
      '/api/offense-types',
      'GET',
      const [],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }

  /// GET /api/offense-types/search/code/prefix
  Future<List<OffenseTypeDictModel>> searchOffenseTypesByCodePrefix({
    required String offenseCode,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offense-types/search/code/prefix',
      'GET',
      [
        QueryParam('offenseCode', offenseCode),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }

  /// GET /api/offense-types/search/code/fuzzy
  Future<List<OffenseTypeDictModel>> searchOffenseTypesByCodeFuzzy({
    required String offenseCode,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offense-types/search/code/fuzzy',
      'GET',
      [
        QueryParam('offenseCode', offenseCode),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }

  /// GET /api/offense-types/search/name/prefix
  Future<List<OffenseTypeDictModel>> searchOffenseTypesByNamePrefix({
    required String offenseName,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offense-types/search/name/prefix',
      'GET',
      [
        QueryParam('offenseName', offenseName),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }

  /// GET /api/offense-types/search/name/fuzzy
  Future<List<OffenseTypeDictModel>> searchOffenseTypesByNameFuzzy({
    required String offenseName,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offense-types/search/name/fuzzy',
      'GET',
      [
        QueryParam('offenseName', offenseName),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }

  /// GET /api/offense-types/search/category
  Future<List<OffenseTypeDictModel>> searchOffenseTypesByCategory({
    required String category,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offense-types/search/category',
      'GET',
      [
        QueryParam('category', category),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }

  /// GET /api/offense-types/search/severity
  Future<List<OffenseTypeDictModel>> searchOffenseTypesBySeverity({
    required String severityLevel,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offense-types/search/severity',
      'GET',
      [
        QueryParam('severityLevel', severityLevel),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }

  /// GET /api/offense-types/search/status
  Future<List<OffenseTypeDictModel>> searchOffenseTypesByStatus({
    required String status,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offense-types/search/status',
      'GET',
      [
        QueryParam('status', status),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }

  /// GET /api/offense-types/search/fine-range
  Future<List<OffenseTypeDictModel>> searchOffenseTypesByFineRange({
    required double minAmount,
    required double maxAmount,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offense-types/search/fine-range',
      'GET',
      [
        QueryParam('minAmount', '$minAmount'),
        QueryParam('maxAmount', '$maxAmount'),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }

  /// GET /api/offense-types/search/points-range
  Future<List<OffenseTypeDictModel>> searchOffenseTypesByPointsRange({
    required int minPoints,
    required int maxPoints,
    int page = 1,
    int size = 20,
  }) async {
    final response = await apiClient.invokeAPI(
      '/api/offense-types/search/points-range',
      'GET',
      [
        QueryParam('minPoints', '$minPoints'),
        QueryParam('maxPoints', '$maxPoints'),
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      await _getHeaders(),
      const {},
      null,
      ['bearerAuth'],
    );
    _ensureSuccess(response);
    return _parseList(_decodeBodyBytes(response));
  }
}
