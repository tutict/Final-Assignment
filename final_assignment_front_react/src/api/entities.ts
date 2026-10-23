import { api, generateIdempotencyKey } from './client';

type Params = Record<string, unknown>;

export function unwrapPayload<T>(payload: unknown): T {
  if (payload && typeof payload === 'object' && 'data' in payload) {
    const data = (payload as { data?: unknown }).data;
    if (data && typeof data === 'object' && 'content' in data && Array.isArray((data as { content?: unknown }).content)) {
      return (data as { content: T }).content;
    }
    return data as T;
  }
  return payload as T;
}
export function unwrapList<T = Record<string, unknown>>(payload: unknown): T[] {
  const value = unwrapPayload<unknown>(payload);
  if (Array.isArray(value)) return value as T[];
  if (value && typeof value === "object" && Array.isArray((value as { content?: unknown }).content)) {
    return (value as { content: T[] }).content;
  }
  return [];
}

interface PageBody {
  content: unknown[];
  total: number;
  page: number;
  size: number;
}

function readPage(payload: unknown): PageBody | null {
  if (!payload || typeof payload !== "object") return null;
  const root = payload as { data?: unknown };
  const data = root.data && typeof root.data === "object" && !Array.isArray(root.data) ? root.data : payload;
  if (!data || typeof data !== "object" || Array.isArray(data) || !("content" in data)) return null;
  const page = data as { content?: unknown; total?: unknown; page?: unknown; size?: unknown };
  if (!Array.isArray(page.content) || typeof page.total !== "number") return null;
  return {
    content: page.content,
    total: page.total,
    page: typeof page.page === "number" ? page.page : 0,
    size: typeof page.size === "number" ? page.size : page.content.length,
  };
}

const MAX_PAGE_SIZE = 100;
const MAX_LIST_ROWS = 500;

/**
 * 按服务端分页取全量列表。列表/仪表盘只取第一页会静默截断为 20 条，
 * 这里从服务端回报的起始页开始按 100/页翻页，直到取满 total 或触达行数上限。
 * 非分页端点（裸数组）原样返回。
 */
export async function listAllPages<T = Record<string, unknown>>(
  basePath: string,
  params: Params = {},
  options: { pageSize?: number; maxRows?: number } = {}
): Promise<T[]> {
  const pageSize = options.pageSize ?? MAX_PAGE_SIZE;
  const maxRows = options.maxRows ?? MAX_LIST_ROWS;

  const response = await api.get<unknown>(basePath, { params });
  const first = readPage(response.data);
  if (!first) return unwrapList<T>(response.data);
  if (first.content.length >= first.total) return first.content as T[];

  const collected: T[] = [];
  let page = first.page;
  if (first.size === pageSize) {
    collected.push(...(first.content as T[]));
    if (collected.length >= first.total) return collected.slice(0, maxRows);
    page += 1;
  }

  for (let guard = 0; guard < 10 && collected.length < maxRows; guard += 1) {
    const body = readPage(
      (await api.get<unknown>(basePath, { params: { ...params, page, size: pageSize } })).data
    );
    if (!body || body.content.length === 0) break;
    collected.push(...(body.content as T[]));
    const effectiveSize = body.size > 0 ? body.size : body.content.length;
    if (collected.length >= body.total || body.content.length < effectiveSize) break;
    page += 1;
  }
  return collected.slice(0, maxRows);
}

export async function listEntities<T = unknown[]>(basePath: string, params?: Params): Promise<T> {
  const response = await api.get<unknown>(basePath, { params });
  const explicitWindow = Boolean(params && ("page" in params || "size" in params));
  const first = readPage(response.data);
  if (!first || explicitWindow || first.total <= first.content.length) {
    return unwrapPayload<T>(response.data);
  }

  const size = Math.min(MAX_PAGE_SIZE, Math.max(first.total, 1));
  const collected: unknown[] = [];
  let page = first.page;
  for (let guard = 0; collected.length < first.total && collected.length < MAX_LIST_ROWS && guard < 8; guard += 1) {
    const next = await api.get<unknown>(basePath, { params: { ...(params || {}), page, size } });
    const body = readPage(next.data);
    if (!body || body.content.length === 0) break;
    collected.push(...body.content);
    if (collected.length >= body.total || body.content.length < size) break;
    page += 1;
  }
  return collected as T;
}

export async function getEntity<T = unknown>(basePath: string, id: string | number): Promise<T> {
  const response = await api.get<T>(`${basePath}/${id}`);
  return unwrapPayload<T>(response.data);
}

export async function createEntity<T = unknown>(basePath: string, payload: unknown): Promise<T> {
  const response = await api.post<T>(basePath, payload, {
    headers: {
      'Idempotency-Key': generateIdempotencyKey(),
    },
  });
  return unwrapPayload<T>(response.data);
}

export async function updateEntity<T = unknown>(
  basePath: string,
  id: string | number,
  payload: unknown
): Promise<T> {
  const response = await api.put<T>(`${basePath}/${id}`, payload, {
    headers: {
      'Idempotency-Key': generateIdempotencyKey(),
    },
  });
  return unwrapPayload<T>(response.data);
}

export async function deleteEntity<T = unknown>(basePath: string, id: string | number): Promise<T> {
  const response = await api.delete<T>(`${basePath}/${id}`);
  return unwrapPayload<T>(response.data);
}

export async function postWithIdempotency<T = unknown>(url: string, payload: unknown): Promise<T> {
  const response = await api.post<T>(url, payload, {
    headers: {
      'Idempotency-Key': generateIdempotencyKey(),
    },
  });
  return unwrapPayload<T>(response.data);
}

export async function putWithIdempotency<T = unknown>(url: string, payload: unknown): Promise<T> {
  const response = await api.put<T>(url, payload, {
    headers: {
      'Idempotency-Key': generateIdempotencyKey(),
    },
  });
  return unwrapPayload<T>(response.data);
}
