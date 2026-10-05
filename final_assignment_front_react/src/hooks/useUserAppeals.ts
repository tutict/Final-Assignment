import { useQuery, type UseQueryResult } from '@tanstack/react-query';
import { listEntities } from '../api/entities';
import { API_PATHS } from '../constants/apiPaths';

/** 当前登录用户的申诉。走 /api/appeals/my，不拉全量违法再逐条查申诉。 */
export function useUserAppeals(): UseQueryResult<unknown[], unknown> {
  return useQuery({
    queryKey: ['userAppeals', 'my'],
    queryFn: async (): Promise<unknown[]> => {
      const rows = await listEntities<unknown[]>(API_PATHS.APPEALS_MY, { page: 1, size: 50 });
      return Array.isArray(rows) ? rows : [];
    },
  });
}
