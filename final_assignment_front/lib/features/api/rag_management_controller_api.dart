import 'package:final_assignment_front/utils/services/api_client.dart';

class RagManagementControllerApi with BaseApiClient {
  RagManagementControllerApi() : _apiClient = ApiClient();

  final ApiClient _apiClient;

  @override
  ApiClient get apiClient => _apiClient;

  Future<void> initializeWithJwt() => initializeClientWithJwt();

  Future<RagOverview> getOverview() {
    return requestObject(
      'GET',
      '/api/rag/admin/overview',
      RagOverview.fromJson,
    );
  }

  Future<List<RagDocumentDto>> listDocuments({
    String? query,
    int limit = 50,
  }) {
    return requestList(
      'GET',
      '/api/rag/admin/documents',
      RagDocumentDto.fromJson,
      queryParams: queryParamsFromMap({
        'query': query?.trim().isEmpty == true ? null : query?.trim(),
        'limit': limit,
      }),
    );
  }

  Future<RagIndexResult> createManualDocument({
    String? sourceId,
    String? sourceVersion,
    required String title,
    required String content,
    String aclScope = 'PUBLIC',
    String route = '',
    String metadataJson = '{}',
  }) {
    return requestObject(
      'POST',
      '/api/rag/admin/documents/manual',
      RagIndexResult.fromJson,
      body: {
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
      contentType: BaseApiClient.defaultContentType,
    );
  }

  Future<void> runBackfill({int page = 1, int size = 200}) {
    return requestVoid(
      'POST',
      '/api/rag/admin/backfill',
      queryParams: pageParams(page, size),
    );
  }

  Future<void> deleteDocument(String documentId) {
    return requestVoid(
      'DELETE',
      '/api/rag/admin/documents/$documentId',
    );
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
