import { useQuery, type UseQueryResult } from '@tanstack/react-query';
import { listEntities } from '../api/entities';
import { entityConfigs } from '../config/entities';

interface OffenseLike {
  offenseId?: number | string;
  driverId?: number | string;
  [key: string]: unknown;
}

export function useUserAppeals(
  userId: number | string | null | undefined
): UseQueryResult<unknown[], unknown> {
  return useQuery({
    queryKey: ['userAppeals', userId ?? 'all'],
    queryFn: async (): Promise<unknown[]> => {
      const offenses = await listEntities<OffenseLike[]>(entityConfigs.offenses.basePath);
      const mine = userId
        ? offenses.filter((item) => String(item.driverId || '') === String(userId))
        : offenses;

      const appealGroups = await Promise.all(
        // @hardcoded slice(0,20)：前端展示上限；size:50：后端查询条数，确保覆盖展示量
        mine.slice(0, 20).map(async (offense) => {
          if (!offense.offenseId) return [];
          try {
            const appealList = await listEntities<unknown[]>(
              entityConfigs.appeals.basePath,
              {
                offenseId: offense.offenseId,
                page: 1,
                size: 50,
              }
            );
            return Array.isArray(appealList) ? appealList : [];
          } catch (error) {
            console.warn(
              `[useUserAppeals] 获取申诉失败 offenseId=${offense.offenseId}:`,
              (error as { message?: string })?.message
            );
            return { __fetchError: true, offenseId: offense.offenseId };
          }
        })
      );

      return appealGroups.flat();
    },
  });
}
