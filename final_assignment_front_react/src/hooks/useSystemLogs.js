/**
 * @hook useSystemLogs
 * @description 管理系统日志页数据源，分别查询日志概览、最近登录日志和最近操作日志。
 *
 * @returns {{
 *   overview: import('@tanstack/react-query').UseQueryResult<Object, unknown>,  // 系统日志概览，通常包含 loginLogCount、operationLogCount、requestHistoryCount
 *   loginLogs: import('@tanstack/react-query').UseQueryResult<Array<Object>, unknown>,  // 最近登录日志列表，元素对应 AuditLoginLog
 *   operationLogs: import('@tanstack/react-query').UseQueryResult<Array<Object>, unknown>,  // 最近操作日志列表，元素对应 AuditOperationLog
 * }}
 *
 * @example
 * const { overview, loginLogs, operationLogs } = useSystemLogs();
 *
 * @notes
 * - overview 使用 queryKey ['systemLogs', 'overview']。
 * - loginLogs 使用 queryKey ['systemLogs', 'loginRecent']，请求最近登录日志。
 * - operationLogs 使用 queryKey ['systemLogs', 'operationRecent']，请求最近操作日志。
 * - 当前 Hook 不接收分页参数；limit: 10 是每次查询的固定最大条数。
 */
import { useQuery } from '@tanstack/react-query';
import { api } from '../api/client.js';
import { API_PATHS } from '../constants/apiPaths.js';

async function fetchOverview() {
  const response = await api.get(API_PATHS.SYSTEM_LOGS_OVERVIEW);
  return response.data;
}

async function fetchRecentLogin() {
  const response = await api.get(API_PATHS.LOGIN_LOGS_RECENT, {
    // @hardcoded 每次拉取日志条数，待确认是否需要分页
    params: { limit: 10 },
  });
  return response.data;
}

async function fetchRecentOperation() {
  const response = await api.get(API_PATHS.OPERATION_LOGS_RECENT, {
    // @hardcoded 每次拉取日志条数，待确认是否需要分页
    params: { limit: 10 },
  });
  return response.data;
}

export function useSystemLogs() {
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
