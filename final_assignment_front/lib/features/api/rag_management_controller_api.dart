import 'dart:convert';

import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';
import 'package:http/http.dart' as http;

class RagManagementControllerApi with BaseApiClient {
  RagManagementControllerApi() : _apiClient = ApiClient();

  final ApiClient _apiClient;

  @override
  ApiClient get apiClient => _apiClient;

  Future<void> initializeWithJwt() async {
    final jwtToken = await AuthTokenStore.instance.getJwtToken();
    if (jwtToken == null) {
      throw Exception('JWT token not found in SharedPreferences');
    }
    _apiClient.setJwtToken(jwtToken);
  }

  Future<RagOverview> getOverview() async {
    final response = await _apiClient.invokeAPI(
      '/api/rag/admin/overview',
      'GET',
      const [],
      null,
      {},
      {},
      null,
      const ['bearerAuth'],
    );
    final data = _decodeEnvelope(response);
    return RagOverview.fromJson(data as Map<String, dynamic>);
  }

  Future<List<RagDocumentDto>> listDocuments({
    String? query,
    int limit = 50,
  }) async {
    final response = await _apiClient.invokeAPI(
      '/api/rag/admin/documents',
      'GET',
      [
        if (query != null && query.trim().isNotEmpty)
          QueryParam('query', query.trim()),
        QueryParam('limit', '$limit'),
      ],
      null,
      {},
      {},
      null,
      const ['bearerAuth'],
    );
    final data = _decodeEnvelope(response);
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(RagDocumentDto.fromJson)
        .toList(growable: false);
  }

  Future<RagIndexResult> createManualDocument({
    String? sourceId,
    String? sourceVersion,
    required String title,
    required String content,
    String aclScope = 'PUBLIC',
    String route = '',
    String metadataJson = '{}',
  }) async {
    final response = await _apiClient.invokeAPI(
      '/api/rag/admin/documents/manual',
      'POST',
      const [],
      {
        if (sourceId != null && sourceId.trim().isNotEmpty)
          'sourceId': sourceId.trim(),
        if (sourceVersion != null && sourceVersion.trim().isNotEmpty)
          'sourceVersion': sourceVersion.trim(),
        'title': title.trim(),
        'content': content.trim(),
        'aclScope': aclScope,
        'route': route.trim(),
        'metadataJson':
            metadataJson.trim().isEmpty ? '{}' : metadataJson.trim(),
      },
      {},
      {},
      'application/json',
      const ['bearerAuth'],
    );
    final data = _decodeEnvelope(response);
    return RagIndexResult.fromJson(data as Map<String, dynamic>);
  }

  Future<void> runBackfill({int page = 1, int size = 200}) async {
    final response = await _apiClient.invokeAPI(
      '/api/rag/admin/backfill',
      'POST',
      [
        QueryParam('page', '$page'),
        QueryParam('size', '$size'),
      ],
      null,
      {},
      {},
      null,
      const ['bearerAuth'],
    );
    _decodeEnvelope(response);
  }

  Future<void> deleteDocument(String documentId) async {
    final response = await _apiClient.invokeAPI(
      '/api/rag/admin/documents/$documentId',
      'DELETE',
      const [],
      null,
      {},
      {},
      null,
      const ['bearerAuth'],
    );
    _decodeEnvelope(response);
  }

  String _decode(http.Response response) => decodeBodyBytes(response);

  dynamic _decodeEnvelope(http.Response response) {
    if (response.statusCode >= 400) {
      throw AppException.http(response.statusCode, _decode(response));
    }
    if (response.body.isEmpty) return null;
    final decoded = jsonDecode(_decode(response));
    if (decoded is Map<String, dynamic> && decoded.containsKey('success')) {
      if (decoded['success'] == false) {
        throw AppException.http(
          response.statusCode,
          (decoded['message'] ?? decoded['errorCode'] ?? 'Request failed')
              .toString(),
        );
      }
      return decoded['data'];
    }
    return decoded;
  }
}

class RagOverview {
  const RagOverview({
    required this.ragEnabled,
    required this.indexingEnabled,
    required this.documentCount,
    required this.readyDocumentCount,
    required this.chunkCount,
    required this.pendingEmbeddingTaskCount,
    required this.failedEmbeddingTaskCount,
  });

  factory RagOverview.fromJson(Map<String, dynamic> json) {
    return RagOverview(
      ragEnabled: json['ragEnabled'] == true,
      indexingEnabled: json['indexingEnabled'] == true,
      documentCount: _asInt(json['documentCount']),
      readyDocumentCount: _asInt(json['readyDocumentCount']),
      chunkCount: _asInt(json['chunkCount']),
      pendingEmbeddingTaskCount: _asInt(json['pendingEmbeddingTaskCount']),
      failedEmbeddingTaskCount: _asInt(json['failedEmbeddingTaskCount']),
    );
  }

  final bool ragEnabled;
  final bool indexingEnabled;
  final int documentCount;
  final int readyDocumentCount;
  final int chunkCount;
  final int pendingEmbeddingTaskCount;
  final int failedEmbeddingTaskCount;
}

class RagDocumentDto {
  const RagDocumentDto({
    required this.id,
    required this.sourceType,
    required this.sourceTable,
    required this.sourceId,
    required this.sourceVersion,
    required this.title,
    required this.status,
    required this.aclScope,
    required this.route,
    required this.updatedAt,
  });

  factory RagDocumentDto.fromJson(Map<String, dynamic> json) {
    return RagDocumentDto(
      id: (json['id'] ?? '').toString(),
      sourceType: (json['sourceType'] ?? '').toString(),
      sourceTable: (json['sourceTable'] ?? '').toString(),
      sourceId: (json['sourceId'] ?? '').toString(),
      sourceVersion: (json['sourceVersion'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      aclScope: (json['aclScope'] ?? '').toString(),
      route: (json['route'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
    );
  }

  final String id;
  final String sourceType;
  final String sourceTable;
  final String sourceId;
  final String sourceVersion;
  final String title;
  final String status;
  final String aclScope;
  final String route;
  final String updatedAt;
}

class RagIndexResult {
  const RagIndexResult({
    required this.document,
    required this.chunkCount,
    required this.embeddingTaskCount,
  });

  factory RagIndexResult.fromJson(Map<String, dynamic> json) {
    return RagIndexResult(
      document:
          RagDocumentDto.fromJson(json['document'] as Map<String, dynamic>),
      chunkCount: _asInt(json['chunkCount']),
      embeddingTaskCount: _asInt(json['embeddingTaskCount']),
    );
  }

  final RagDocumentDto document;
  final int chunkCount;
  final int embeddingTaskCount;
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
