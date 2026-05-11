import { useQuery } from '@tanstack/react-query';
import { api } from '../api/client.js';

async function fetchOverview() {
  const response = await api.get('/api/system/logs/overview');
  return response.data;
}

async function fetchRecentLogin() {
  const response = await api.get('/api/system/logs/login/recent', {
    params: { limit: 10 },
  });
  return response.data;
}

async function fetchRecentOperation() {
  const response = await api.get('/api/system/logs/operation/recent', {
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
