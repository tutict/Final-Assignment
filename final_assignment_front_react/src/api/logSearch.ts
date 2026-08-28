/**
 * 登录/操作日志检索 API，对齐后端 Quarkus LoginLogController / OperationLogController。
 * 端点契约：
 * - 登录：GET /api/logs/login/search/{username|result|time-range}?page=&size=
 * - 操作：GET /api/logs/operation/search/{user/{userId}|result|time-range}?page=&size=
 * 响应均为裸 JSON 数组（无分页包装），page 1-based，size 默认 20。
 * GET 不需要 Idempotency-Key。
 */
import { api } from './client';
import { API_PATHS } from '../constants/apiPaths';

export interface LoginLog {
  logId?: number;
  username?: string;
  loginTime?: string;
  logoutTime?: string;
  loginResult?: string;
  failureReason?: string;
  loginIp?: string;
  loginLocation?: string;
  browserType?: string;
  browserVersion?: string;
  osType?: string;
  osVersion?: string;
  deviceType?: string;
  userAgent?: string;
  sessionId?: string;
  token?: string;
  createdAt?: string;
  deletedAt?: string;
  remarks?: string;
  [key: string]: unknown;
}

export interface OperationLog {
  logId?: number;
  operationType?: string;
  operationModule?: string;
  operationFunction?: string;
  operationContent?: string;
  operationTime?: string;
  userId?: number;
  username?: string;
  realName?: string;
  requestMethod?: string;
  requestUrl?: string;
  requestParams?: string;
  requestIp?: string;
  operationResult?: string;
  responseData?: string;
  errorMessage?: string;
  executionTime?: number;
  oldValue?: string;
  newValue?: string;
  createdAt?: string;
  deletedAt?: string;
  remarks?: string;
  [key: string]: unknown;
}

const DEFAULT_PAGE = 1;
const DEFAULT_SIZE = 20;

function asArray(data: unknown): unknown[] {
  return Array.isArray(data) ? data : [];
}

/** GET /api/logs/login —— 全量登录日志（无分页）。 */
export async function listLoginLogs(): Promise<LoginLog[]> {
  const response = await api.get<unknown>(API_PATHS.LOGIN_LOGS);
  return asArray(response.data) as LoginLog[];
}

/** GET /api/logs/login/search/username?username=&page=&size= —— 前缀匹配。 */
export async function searchLoginLogsByUsername(
  username: string,
  page = DEFAULT_PAGE,
  size = DEFAULT_SIZE
): Promise<LoginLog[]> {
  const response = await api.get<unknown>(API_PATHS.LOGIN_LOGS_SEARCH_USERNAME, {
    params: { username, page, size },
  });
  return asArray(response.data) as LoginLog[];
}

/** GET /api/logs/login/search/result?result=&page=&size= —— 精确匹配登录结果。 */
export async function searchLoginLogsByResult(
  result: string,
  page = DEFAULT_PAGE,
  size = DEFAULT_SIZE
): Promise<LoginLog[]> {
  const response = await api.get<unknown>(API_PATHS.LOGIN_LOGS_SEARCH_RESULT, {
    params: { result, page, size },
  });
  return asArray(response.data) as LoginLog[];
}

/** GET /api/logs/login/search/time-range?startTime=&endTime=&page=&size= —— 闭区间。 */
export async function searchLoginLogsByTimeRange(
  startTime: string,
  endTime: string,
  page = DEFAULT_PAGE,
  size = DEFAULT_SIZE
): Promise<LoginLog[]> {
  const response = await api.get<unknown>(API_PATHS.LOGIN_LOGS_SEARCH_TIME_RANGE, {
    params: { startTime, endTime, page, size },
  });
  return asArray(response.data) as LoginLog[];
}

/** GET /api/logs/operation —— 全量操作日志（无分页）。 */
export async function listOperationLogs(): Promise<OperationLog[]> {
  const response = await api.get<unknown>(API_PATHS.OPERATION_LOGS);
  return asArray(response.data) as OperationLog[];
}

/** GET /api/logs/operation/search/user/{userId}?page=&size= —— userId 在路径中。 */
export async function searchOperationLogsByUser(
  userId: string | number,
  page = DEFAULT_PAGE,
  size = DEFAULT_SIZE
): Promise<OperationLog[]> {
  const response = await api.get<unknown>(API_PATHS.OPERATION_LOGS_SEARCH_USER(userId), {
    params: { page, size },
  });
  return asArray(response.data) as OperationLog[];
}

/** GET /api/logs/operation/search/result?operationResult=&page=&size= —— 精确匹配。 */
export async function searchOperationLogsByResult(
  operationResult: string,
  page = DEFAULT_PAGE,
  size = DEFAULT_SIZE
): Promise<OperationLog[]> {
  const response = await api.get<unknown>(API_PATHS.OPERATION_LOGS_SEARCH_RESULT, {
    params: { operationResult, page, size },
  });
  return asArray(response.data) as OperationLog[];
}

/** GET /api/logs/operation/search/time-range?startTime=&endTime=&page=&size= —— 闭区间。 */
export async function searchOperationLogsByTimeRange(
  startTime: string,
  endTime: string,
  page = DEFAULT_PAGE,
  size = DEFAULT_SIZE
): Promise<OperationLog[]> {
  const response = await api.get<unknown>(API_PATHS.OPERATION_LOGS_SEARCH_TIME_RANGE, {
    params: { startTime, endTime, page, size },
  });
  return asArray(response.data) as OperationLog[];
}
