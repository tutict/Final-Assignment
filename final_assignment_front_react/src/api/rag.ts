/**
 * RAG 知识资料管理 API，对齐后端 RagManagementController（/api/rag/admin，仅 SUPER_ADMIN）。
 * 对齐 Flutter RagManagementControllerApi。所有写入操作附带 Idempotency-Key。
 */
import { api, generateIdempotencyKey } from "./client";
import { API_PATHS } from "../constants/apiPaths";

export interface RagOverview {
  ragEnabled: boolean;
  indexingEnabled: boolean;
  documentCount: number;
  readyDocumentCount: number;
  chunkCount: number;
  pendingEmbeddingTaskCount: number;
  failedEmbeddingTaskCount: number;
  succeededEmbeddingTaskCount?: number;
  poisonedEmbeddingTaskCount?: number;
}

export interface RagDocument {
  id: string;
  sourceType: string;
  sourceTable: string;
  sourceId: string;
  sourceVersion: string;
  title: string;
  status: string;
  aclScope: string;
  route: string;
  metadataJson: string;
  contentHash: string;
  updatedAt: string;
  indexedAt: string;
}

export interface RagIndexResult {
  document: RagDocument;
  chunkCount: number;
  embeddingTaskCount: number;
}

export interface RagBackfillResult {
  processedDocuments: number;
  failedDocuments: number;
  hasMore: boolean;
  enabled: boolean;
}

export interface RagBackfillRunResult {
  processedDocuments: number;
  failedDocuments: number;
  processedPages: number;
  hasMore: boolean;
  enabled: boolean;
}

export interface RagEmbeddingBatchResult {
  selectedTasks: number;
  succeededTasks: number;
  failedTasks: number;
  enabled: boolean;
  alreadyRunning: boolean;
}

export interface RagRequeueResult {
  requeuedChunks: number;
  requeuedTasks: number;
  createdTasks: number;
}

export interface RagIndexMigrationResult {
  enabled: boolean;
  createdIndex: boolean;
  aliasSwitched: boolean;
  targetIndexName: string;
  aliasName: string;
  requeuedChunks: number;
  requeuedTasks: number;
  createdTasks: number;
  message: string;
}

function asInt(value: unknown): number {
  if (value === null || value === undefined) return 0;
  if (typeof value === "number") return Math.trunc(value);
  const parsed = Number.parseInt(String(value), 10);
  return Number.isNaN(parsed) ? 0 : parsed;
}

function normalizeOverview(data: Record<string, unknown>): RagOverview {
  return {
    ragEnabled: Boolean(data.ragEnabled),
    indexingEnabled: Boolean(data.indexingEnabled),
    documentCount: asInt(data.documentCount),
    readyDocumentCount: asInt(data.readyDocumentCount),
    chunkCount: asInt(data.chunkCount),
    pendingEmbeddingTaskCount: asInt(data.pendingEmbeddingTaskCount),
    failedEmbeddingTaskCount: asInt(data.failedEmbeddingTaskCount),
    succeededEmbeddingTaskCount: asInt(data.succeededEmbeddingTaskCount),
    poisonedEmbeddingTaskCount: asInt(data.poisonedEmbeddingTaskCount),
  };
}

function normalizeDocument(data: Record<string, unknown>): RagDocument {
  return {
    id: String(data.id ?? ""),
    sourceType: String(data.sourceType ?? ""),
    sourceTable: String(data.sourceTable ?? ""),
    sourceId: String(data.sourceId ?? ""),
    sourceVersion: String(data.sourceVersion ?? ""),
    title: String(data.title ?? ""),
    status: String(data.status ?? ""),
    aclScope: String(data.aclScope ?? ""),
    route: String(data.route ?? ""),
    metadataJson: String(data.metadataJson ?? ""),
    contentHash: String(data.contentHash ?? ""),
    updatedAt: String(data.updatedAt ?? ""),
    indexedAt: String(data.indexedAt ?? ""),
  };
}

function normalizeIndexResult(data: Record<string, unknown>): RagIndexResult {
  const document = normalizeDocument(
    (data.document as Record<string, unknown>) || {}
  );
  return {
    document,
    chunkCount: asInt(data.chunkCount),
    embeddingTaskCount: asInt(data.embeddingTaskCount),
  };
}

/** GET /api/rag/admin/overview */
export async function getRagOverview(): Promise<RagOverview> {
  const response = await api.get<Record<string, unknown>>(
    API_PATHS.RAG_OVERVIEW
  );
  return normalizeOverview(response.data || {});
}

/** GET /api/rag/admin/documents?query=&limit= */
export async function listRagDocuments(
  query?: string,
  limit = 50
): Promise<RagDocument[]> {
  const trimmed = query?.trim();
  const response = await api.get<unknown[]>(API_PATHS.RAG_DOCUMENTS, {
    params: {
      ...(trimmed ? { query: trimmed } : {}),
      limit,
    },
  });
  const list = Array.isArray(response.data) ? response.data : [];
  return list.map((item) =>
    normalizeDocument((item as Record<string, unknown>) || {})
  );
}

/** POST /api/rag/admin/documents/manual —— 手动录入文档 */
export async function createManualRagDocument(payload: {
  sourceId?: string;
  sourceVersion?: string;
  title: string;
  content: string;
  aclScope?: string;
  route?: string;
  metadataJson?: string;
}): Promise<RagIndexResult> {
  const response = await api.post<Record<string, unknown>>(
    API_PATHS.RAG_DOCUMENTS_MANUAL,
    {
      ...(payload.sourceId?.trim() ? { sourceId: payload.sourceId.trim() } : {}),
      ...(payload.sourceVersion?.trim()
        ? { sourceVersion: payload.sourceVersion.trim() }
        : {}),
      title: payload.title.trim(),
      content: payload.content.trim(),
      aclScope: payload.aclScope || "PUBLIC",
      route: (payload.route || "").trim(),
      metadataJson:
        payload.metadataJson?.trim() || "{}",
    },
    { headers: { "Idempotency-Key": generateIdempotencyKey() } }
  );
  return normalizeIndexResult(response.data || {});
}

/** POST /api/rag/admin/documents/upload —— multipart 上传文档 */
export async function uploadRagDocument(payload: {
  file: File;
  sourceId?: string;
  sourceVersion?: string;
  title?: string;
  aclScope?: string;
  route?: string;
  metadataJson?: string;
}): Promise<RagIndexResult> {
  const form = new FormData();
  form.append("file", payload.file);
  if (payload.sourceId?.trim()) form.append("sourceId", payload.sourceId.trim());
  if (payload.sourceVersion?.trim())
    form.append("sourceVersion", payload.sourceVersion.trim());
  if (payload.title?.trim()) form.append("title", payload.title.trim());
  form.append("aclScope", payload.aclScope || "PUBLIC");
  if (payload.route?.trim()) form.append("route", payload.route.trim());
  form.append("metadataJson", payload.metadataJson?.trim() || "{}");

  const response = await api.post<Record<string, unknown>>(
    API_PATHS.RAG_DOCUMENTS_UPLOAD,
    form,
    {
      headers: {
        "Idempotency-Key": generateIdempotencyKey(),
        "Content-Type": "multipart/form-data",
      },
      timeout: 60000,
    }
  );
  return normalizeIndexResult(response.data || {});
}

/** DELETE /api/rag/admin/documents/{documentId} */
export async function deleteRagDocument(documentId: string): Promise<void> {
  await api.delete(API_PATHS.RAG_DOCUMENTS_BY_ID(documentId));
}

/** POST /api/rag/admin/backfill —— 执行一批回填 */
export async function runRagBackfill(
  page = 1,
  size = 200
): Promise<RagBackfillResult> {
  const response = await api.post<Record<string, unknown>>(
    API_PATHS.RAG_BACKFILL,
    undefined,
    { params: { page, size } }
  );
  return {
    processedDocuments: asInt(response.data?.processedDocuments),
    failedDocuments: asInt(response.data?.failedDocuments),
    hasMore: Boolean(response.data?.hasMore),
    enabled: Boolean(response.data?.enabled),
  };
}

/** POST /api/rag/admin/backfill/run —— 执行多批回填 */
export async function runRagBackfillBatches(
  startPage = 1,
  size = 200,
  maxPages = 20
): Promise<RagBackfillRunResult> {
  const response = await api.post<Record<string, unknown>>(
    API_PATHS.RAG_BACKFILL_RUN,
    undefined,
    { params: { startPage, size, maxPages } }
  );
  return {
    processedDocuments: asInt(response.data?.processedDocuments),
    failedDocuments: asInt(response.data?.failedDocuments),
    processedPages: asInt(response.data?.processedPages),
    hasMore: Boolean(response.data?.hasMore),
    enabled: Boolean(response.data?.enabled),
  };
}

/** POST /api/rag/admin/embedding/run —— 执行一批向量任务 */
export async function runRagEmbeddingBatch(
  limit = 25
): Promise<RagEmbeddingBatchResult> {
  const response = await api.post<Record<string, unknown>>(
    API_PATHS.RAG_EMBEDDING_RUN,
    undefined,
    { params: { limit } }
  );
  return {
    selectedTasks: asInt(response.data?.selectedTasks),
    succeededTasks: asInt(response.data?.succeededTasks),
    failedTasks: asInt(response.data?.failedTasks),
    enabled: Boolean(response.data?.enabled),
    alreadyRunning: Boolean(response.data?.alreadyRunning),
  };
}

/** POST /api/rag/admin/embedding/requeue —— 重新入队向量任务 */
export async function requeueRagEmbeddingTasks(
  limit = 1000
): Promise<RagRequeueResult> {
  const response = await api.post<Record<string, unknown>>(
    API_PATHS.RAG_EMBEDDING_REQUEUE,
    undefined,
    { params: { limit } }
  );
  return {
    requeuedChunks: asInt(response.data?.requeuedChunks),
    requeuedTasks: asInt(response.data?.requeuedTasks),
    createdTasks: asInt(response.data?.createdTasks),
  };
}

/** POST /api/rag/admin/index/migrate —— 创建新索引并切换别名 */
export async function migrateRagIndex(payload: {
  indexName?: string;
  requeue?: boolean;
  requeueLimit?: number;
}): Promise<RagIndexMigrationResult> {
  const response = await api.post<Record<string, unknown>>(
    API_PATHS.RAG_INDEX_MIGRATE,
    undefined,
    {
      params: {
        ...(payload.indexName ? { indexName: payload.indexName } : {}),
        requeue: payload.requeue ?? true,
        requeueLimit: payload.requeueLimit ?? 1000,
      },
    }
  );
  const data = response.data || {};
  return {
    enabled: Boolean(data.enabled),
    createdIndex: Boolean(data.createdIndex),
    aliasSwitched: Boolean(data.aliasSwitched),
    targetIndexName: String(data.targetIndexName ?? ""),
    aliasName: String(data.aliasName ?? ""),
    requeuedChunks: asInt(data.requeuedChunks),
    requeuedTasks: asInt(data.requeuedTasks),
    createdTasks: asInt(data.createdTasks),
    message: String(data.message ?? ""),
  };
}
