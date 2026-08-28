import { useQuery, type UseQueryResult } from '@tanstack/react-query';
import { api } from '../api/client';
import { API_PATHS } from '../constants/apiPaths';

export interface SystemLogsOverview {
  loginLogCount?: number;
  operationLogCount?: number;
  requestHistoryCount?: number;
  [key: string]: unknown;
}

export interface UseSystemLogsResult {
  overview: UseQueryResult<SystemLogsOverview, unknown>;
  loginLogs: UseQueryResult<unknown[], unknown>;
  operationLogs: UseQueryResult<unknown[], unknown>;
}

async function fetchOverview(): Promise<SystemLogsOverview> {
  const response = await api.get<SystemLogsOverview>(API_PATHS.SYSTEM_LOGS_OVERVIEW);
  return response.data;
}

async function fetchRecentLogin(): Promise<unknown[]> {
  const response = await api.get<unknown[]>(API_PATHS.LOGIN_LOGS_RECENT, {
    // 对齐 Flutter SystemLogPage：每次拉取 20 条
    params: { limit: 20 },
  });
  return response.data;
}

async function fetchRecentOperation(): Promise<unknown[]> {
  const response = await api.get<unknown[]>(API_PATHS.OPERATION_LOGS_RECENT, {
    // 对齐 Flutter SystemLogPage：每次拉取 20 条
    params: { limit: 20 },
  });
  return response.data;
}

export function useSystemLogs(): UseSystemLogsResult {
  const overview = useQuery({
    queryKey: ['systemLogs', 'overview'],
    queryFn: fetchOverview,
  });

  const loginLogs = useQuery({
    queryKey: ['systemLogs', 'loginRecent'],
    queryFn: fetchRecentLogin,
  });

  const operationLogs = useQuery({
    queryKey: ['systemLogs', 'operationRecent'],
    queryFn: fetchRecentOperation,
  });

  return { overview, loginLogs, operationLogs };
}
