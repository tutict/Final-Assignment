import { useQuery } from '@tanstack/react-query';
import { api } from '../api/client.js';
import { API_PATHS } from '../constants/apiPaths.js';

async function fetchOverview() {
  const response = await api.get(API_PATHS.SYSTEM_LOGS_OVERVIEW);
  return response.data;
}

async function fetchRecentLogin() {
  const response = await api.get(API_PATHS.LOGIN_LOGS_RECENT, {
    params: { limit: 10 },
  });
  return response.data;
}

async function fetchRecentOperation() {
  const response = await api.get(API_PATHS.OPERATION_LOGS_RECENT, {
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
