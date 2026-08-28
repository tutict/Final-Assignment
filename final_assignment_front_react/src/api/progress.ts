/**
 * 业务进度 API，对齐 Flutter ProgressControllerApi。
 * 后端 /api/progress 实体为 SysRequestHistory（businessType/businessStatus/businessId 等），
 * 前端复用 Flutter ProgressItem 的本地归一化语义：status 取 businessStatus，submitTime 取 createdAt。
 */
import { api, generateIdempotencyKey } from './client';
import { API_PATHS } from '../constants/apiPaths';

/** 进度记录归一化字段（对齐 Flutter ProgressItem.fromJson 的字段映射）。 */
export interface ProgressItem {
  id?: number;
  /** 业务类型（后端 businessType） */
  title: string;
  /** 业务状态（Pending / Processing / Completed / Archived） */
  status: string;
  /** 提交时间（后端 createdAt） */
  submitTime: string;
  /** 详情（后端 requestParams） */
  details?: string;
  /** 提交用户（后端 userId） */
  username: string;
  appealId?: number;
  deductionId?: number;
  driverId?: number;
  fineId?: number;
  vehicleId?: number;
  offenseId?: number;
  [key: string]: unknown;
}

const VALID_STATUSES = new Set(['Pending', 'Processing', 'Completed', 'Archived']);

/** 将后端 SysRequestHistory JSON 归一化为前端 ProgressItem（对齐 Flutter ProgressItem.fromJson）。 */
export function normalizeProgress(raw: Record<string, unknown>): ProgressItem {
  const rawStatus = String(raw.businessStatus ?? raw.status ?? 'Pending');
  const status = VALID_STATUSES.has(rawStatus) ? rawStatus : 'Pending';
  return {
    id: asInt(raw.id),
    title: asString(raw.businessType ?? raw.title) ?? '',
    status,
    submitTime: asString(raw.createdAt ?? raw.submitTime) ?? new Date(0).toISOString(),
    details: asString(raw.requestParams ?? raw.details),
    username: asString(raw.userId ?? raw.username) ?? '',
    appealId: asInt(raw.appealId),
    deductionId: asInt(raw.deductionId),
    driverId: asInt(raw.driverId),
    fineId: asInt(raw.fineId),
    vehicleId: asInt(raw.vehicleId),
    offenseId: asInt(raw.offenseId),
  };
}

interface BackendProgress {
  id?: number;
  businessType?: string;
  businessStatus?: string;
  businessId?: number;
  userId?: number | string;
  requestParams?: string;
  createdAt?: string;
  [key: string]: unknown;
}

/** 构造用于写回后端的请求体（对齐 Flutter ProgressItem.toJson 的字段名映射）。 */
export function toBackendPayload(item: Partial<ProgressItem>): Record<string, unknown> {
  return {
    id: item.id,
    businessType: item.title,
    businessStatus: item.status,
    requestParams: item.details,
    userId: item.username,
    appealId: item.appealId,
    deductionId: item.deductionId,
    driverId: item.driverId,
    fineId: item.fineId,
    vehicleId: item.vehicleId,
    offenseId: item.offenseId,
  };
}

export async function listProgress(): Promise<ProgressItem[]> {
  const response = await api.get<BackendProgress[]>(API_PATHS.PROGRESS);
  const rows = Array.isArray(response.data) ? response.data : [];
  return rows.map((row) => normalizeProgress(row as Record<string, unknown>));
}

export async function createProgress(item: Partial<ProgressItem>): Promise<ProgressItem> {
  const response = await api.post<BackendProgress>(
    API_PATHS.PROGRESS,
    toBackendPayload(item),
    { headers: { 'Idempotency-Key': generateIdempotencyKey() } }
  );
  return normalizeProgress(response.data as Record<string, unknown>);
}

/** 更新进度（对齐 Flutter updateProgressItemStatus：先 GET 再整体 PUT）。 */
export async function updateProgressStatus(id: number, newStatus: string): Promise<ProgressItem> {
  const existing = await api.get<Record<string, unknown>>(`${API_PATHS.PROGRESS}/${id}`);
  const body = { ...(existing.data || {}), businessStatus: newStatus, status: newStatus };
  const response = await api.put<BackendProgress>(`${API_PATHS.PROGRESS}/${id}`, body, {
    headers: { 'Idempotency-Key': generateIdempotencyKey() },
  });
  return normalizeProgress(response.data as Record<string, unknown>);
}

export async function deleteProgress(id: number): Promise<void> {
  await api.delete(`${API_PATHS.PROGRESS}/${id}`);
}

export async function searchProgressByTimeRange(startTime: string, endTime: string): Promise<ProgressItem[]> {
  const response = await api.get<BackendProgress[]>(API_PATHS.PROGRESS_BY_TIME_RANGE, {
    params: { startTime, endTime },
  });
  const rows = Array.isArray(response.data) ? response.data : [];
  return rows.map((row) => normalizeProgress(row as Record<string, unknown>));
}

export async function getProgress(id: number): Promise<ProgressItem> {
  const response = await api.get<BackendProgress>(`${API_PATHS.PROGRESS}/${id}`);
  return normalizeProgress(response.data as Record<string, unknown>);
}

/** 关联业务上下文文案（对齐 Flutter ProgressController.getBusinessContext）。 */
export function getBusinessContext(item: ProgressItem): string {
  const contexts: string[] = [];
  if (item.appealId != null) contexts.push(`申诉ID: ${item.appealId}`);
  if (item.deductionId != null) contexts.push(`扣分ID: ${item.deductionId}`);
  if (item.driverId != null) contexts.push(`司机ID: ${item.driverId}`);
  if (item.fineId != null) contexts.push(`罚款ID: ${item.fineId}`);
  if (item.vehicleId != null) contexts.push(`车辆ID: ${item.vehicleId}`);
  if (item.offenseId != null) contexts.push(`违法ID: ${item.offenseId}`);
  return contexts.length > 0 ? contexts.join(', ') : '无关联业务';
}

function asInt(value: unknown): number | undefined {
  if (value === null || value === undefined || value === '') return undefined;
  const num = Number(value);
  return Number.isFinite(num) ? num : undefined;
}

function asString(value: unknown): string | undefined {
  if (value === null || value === undefined) return undefined;
  const str = String(value).trim();
  return str === '' ? undefined : str;
}
