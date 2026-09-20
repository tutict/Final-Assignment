import 'dart:convert';
import 'dart:typed_data';

import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';
import 'package:http/http.dart' as http;

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

  Future<RagDocumentPage> listDocuments({
    String? query,
    int page = 1,
    int size = 20,
  }) {
    return requestObject(
      'GET',
      '/api/rag/admin/documents',
      RagDocumentPage.fromJson,
      queryParams: queryParamsFromMap({
        'query': query?.trim().isEmpty == true ? null : query?.trim(),
        'page': page,
        'size': size,
      }),
    );
  }

  Future<RagDocumentDetail> getDocument(String documentId) {
    return requestObject(
      'GET',
      '/api/rag/admin/documents/$documentId',
      RagDocumentDetail.fromJson,
    );
  }

  Future<RagIndexResult> updateDocument({
    required String documentId,
    required String title,
    required String content,
    String aclScope = 'PUBLIC',
    String route = '',
    String metadataJson = '{}',
  }) {
    return requestObject(
      'PUT',
      '/api/rag/admin/documents/$documentId',
      RagIndexResult.fromJson,
      body: {
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

  Future<List<RagPreviewHit>> preview({
    required String query,
    String asRole = 'USER',
    int topK = 8,
  }) {
    return requestList(
      'POST',
      '/api/rag/admin/preview',
      RagPreviewHit.fromJson,
      body: {
        'query': query.trim(),
        'asRole': asRole,
        'topK': topK,
      },
      contentType: BaseApiClient.defaultContentType,
    );
  }

  Future<void> runEmbeddingBatch({int limit = 25}) {
    return requestVoid(
      'POST',
      '/api/rag/admin/embedding/run',
      queryParams: queryParamsFromMap({'limit': limit}),
    );
  }

  Future<void> requeueEmbeddingTasks({int limit = 1000}) {
    return requestVoid(
      'POST',
      '/api/rag/admin/embedding/requeue',
      queryParams: queryParamsFromMap({'limit': limit}),
    );
  }

  Future<void> migrateIndex() {
    return requestVoid(
      'POST',
      '/api/rag/admin/index/migrate',
      queryParams: queryParamsFromMap({
        'requeue': true,
        'requeueLimit': 1000,
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

  Future<RagIndexResult> uploadDocument({
    required String fileName,
    required Uint8List bytes,
    String? sourceId,
    String? sourceVersion,
    String? title,
    String aclScope = 'PUBLIC',
    String route = '',
    String metadataJson = '{}',
  }) async {
    await initializeWithJwt();
    final token = await AuthTokenStore.instance.getJwtToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${_apiClient.basePath}/api/rag/admin/documents/upload'),
    );
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.fields.addAll({
      if (sourceId != null && sourceId.trim().isNotEmpty)
        'sourceId': sourceId.trim(),
      if (sourceVersion != null && sourceVersion.trim().isNotEmpty)
        'sourceVersion': sourceVersion.trim(),
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      'aclScope': aclScope,
      if (route.trim().isNotEmpty) 'route': route.trim(),
      'metadataJson': metadataJson.trim().isEmpty ? '{}' : metadataJson.trim(),
    });
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ),
    );

    final streamedResponse =
        await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamedResponse);
    if (AppException.isErrorStatus(response.statusCode)) {
      throw AppException.fromResponse(response);
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
    if (data is! Map<String, dynamic>) {
      throw const AppException(
        type: AppErrorType.serverError,
        message: 'Invalid RAG upload response',
        statusCode: 500,
      );
    }
    return RagIndexResult.fromJson(data);
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
    required this.metadataJson,
    required this.contentHash,
    required this.updatedAt,
    required this.indexedAt,
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
      metadataJson: (json['metadataJson'] ?? '').toString(),
      contentHash: (json['contentHash'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
      indexedAt: (json['indexedAt'] ?? '').toString(),
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
  final String metadataJson;
  final String contentHash;
  final String updatedAt;
  final String indexedAt;
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

class RagDocumentPage {
  const RagDocumentPage({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
  });

  factory RagDocumentPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['records'] ?? json['data'] ?? [];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((item) => RagDocumentDto.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : <RagDocumentDto>[];
    return RagDocumentPage(
      items: items,
      total: _asInt(json['total'] ?? items.length),
      page: _asInt(json['page'] == 0 ? 1 : json['page'] ?? 1),
      size: _asInt(json['size'] ?? items.length),
    );
  }

  final List<RagDocumentDto> items;
  final int total;
  final int page;
  final int size;
}

class RagDocumentDetail {
  const RagDocumentDetail({
    required this.document,
    required this.content,
    required this.chunks,
  });

  factory RagDocumentDetail.fromJson(Map<String, dynamic> json) {
    final document = json['document'];
    final chunks = json['chunks'];
    return RagDocumentDetail(
      document: RagDocumentDto.fromJson(
        document is Map ? Map<String, dynamic>.from(document) : const {},
      ),
      content: (json['content'] ?? '').toString(),
      chunks: chunks is List
          ? chunks
              .whereType<Map>()
              .map((item) => RagChunkView.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
    );
  }

  final RagDocumentDto document;
  final String content;
  final List<RagChunkView> chunks;
}

class RagChunkView {
  const RagChunkView({
    required this.id,
    required this.chunkNo,
    required this.content,
    required this.status,
    required this.embeddingStatus,
    required this.lastError,
  });

  factory RagChunkView.fromJson(Map<String, dynamic> json) {
    return RagChunkView(
      id: (json['id'] ?? '').toString(),
      chunkNo: _asInt(json['chunkNo']),
      content: (json['content'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      embeddingStatus: (json['embeddingStatus'] ?? '').toString(),
      lastError: (json['lastError'] ?? '').toString(),
    );
  }

  final String id;
  final int chunkNo;
  final String content;
  final String status;
  final String embeddingStatus;
  final String lastError;

  bool get failed =>
      embeddingStatus.toUpperCase() == 'FAILED' ||
      embeddingStatus.toUpperCase() == 'POISONED';
}

class RagPreviewHit {
  const RagPreviewHit({
    required this.documentId,
    required this.title,
    required this.snippet,
    required this.score,
    required this.route,
    required this.aclScope,
    required this.sourceType,
  });

  factory RagPreviewHit.fromJson(Map<String, dynamic> json) {
    return RagPreviewHit(
      documentId: (json['documentId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      snippet: (json['snippet'] ?? '').toString(),
      score: json['score'] is num ? (json['score'] as num).toDouble() : 0,
      route: (json['route'] ?? '').toString(),
      aclScope: (json['aclScope'] ?? '').toString(),
      sourceType: (json['sourceType'] ?? '').toString(),
    );
  }

  final String documentId;
  final String title;
  final String snippet;
  final double score;
  final String route;
  final String aclScope;
  final String sourceType;
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
