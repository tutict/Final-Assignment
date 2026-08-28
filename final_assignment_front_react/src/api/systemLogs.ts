/**
 * 系统日志与请求历史 API，对齐后端 SystemLogsController（/api/system/logs）。
 * 对齐 Flutter SystemLogsControllerApi：概览 + 近期日志 + 请求历史搜索。
 */
import { api } from "./client";
import { API_PATHS, type RequestHistorySearchField } from "../constants/apiPaths";

export interface SystemLogsOverview {
  loginLogCount?: number;
  operationLogCount?: number;
  requestHistoryCount?: number;
  recentLoginLogs?: unknown[];
  recentOperationLogs?: unknown[];
  recentRequestHistories?: unknown[];
  [key: string]: unknown;
}

export interface SysRequestHistory {
  id?: number;
  idempotencyKey?: string;
  requestMethod?: string;
  requestUrl?: string;
  requestParams?: string;
  businessType?: string;
  businessId?: number;
  businessStatus?: string;
  userId?: number;
  requestIp?: string;
  createdTime?: string;
  modifiedTime?: string;
  deletedAt?: string;
  [key: string]: unknown;
}

/** GET /api/system/logs/overview */
export async function getSystemLogsOverview(): Promise<SystemLogsOverview> {
  const response = await api.get<SystemLogsOverview>(API_PATHS.SYSTEM_LOGS_OVERVIEW);
  return response.data || {};
}

/** GET /api/system/logs/login/recent?limit= */
export async function listRecentLoginLogs(limit = 10): Promise<unknown[]> {
  const response = await api.get<unknown[]>(API_PATHS.LOGIN_LOGS_RECENT, {
    params: { limit },
  });
  return Array.isArray(response.data) ? response.data : [];
}

/** GET /api/system/logs/operation/recent?limit= */
export async function listRecentOperationLogs(limit = 10): Promise<unknown[]> {
  const response = await api.get<unknown[]>(API_PATHS.OPERATION_LOGS_RECENT, {
    params: { limit },
  });
  return Array.isArray(response.data) ? response.data : [];
}

/** GET /api/system/logs/requests/{historyId} */
export async function getRequestHistory(
  historyId: string | number
): Promise<SysRequestHistory | null> {
  try {
    const response = await api.get<SysRequestHistory>(
      API_PATHS.REQUEST_HISTORY_BY_ID(historyId)
    );
    return response.data || null;
  } catch {
    return null;
  }
}

const FIELD_PARAMS: Record<
  RequestHistorySearchField,
  (value: string) => Record<string, unknown>
> = {
  idempotency: (value) => ({ key: value }),
  method: (value) => ({ requestMethod: value }),
  url: (value) => ({ requestUrl: value }),
  "business-type": (value) => ({ businessType: value }),
  "business-id": (value) => ({ businessId: value }),
  status: (value) => ({ status: value }),
  user: (value) => ({ userId: value }),
  ip: (value) => ({ requestIp: value }),
  "time-range": (value) => {
    // value 形如 "startTime~endTime"，留空侧表示开放区间
    const [start, end] = value.split("~");
    return {
      startTime: (start || "").trim(),
      endTime: (end || "").trim(),
    };
  },
};

export async function searchRequestHistory(
  field: RequestHistorySearchField,
  value: string,
  page = 1,
  size = 20
): Promise<SysRequestHistory[]> {
  const params = { ...FIELD_PARAMS[field](value), page, size };
  const response = await api.get<unknown[]>(
    API_PATHS.REQUEST_HISTORY_SEARCH(field),
    { params }
  );
  const list = Array.isArray(response.data) ? response.data : [];
  return list.map((item) => (item as SysRequestHistory) || {});
}
