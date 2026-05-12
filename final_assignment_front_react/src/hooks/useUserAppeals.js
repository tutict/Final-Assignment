/**
 * @hook useUserAppeals
 * @description 用户端查看本人申诉记录专用 Hook，按驾驶员 ID 筛选违法记录并拉取关联申诉。
 *
 * @param {number|string|null|undefined} userId - 当前用户/驾驶员 ID；为空时不筛选，返回全部违法记录关联的申诉。
 *
 * @returns {import('@tanstack/react-query').UseQueryResult<Array<Object>, unknown>} React Query 查询结果；data 是 AppealRecord 列表，不包含 offense 聚合对象。
 *
 * @example
 * const { data: appeals = [], isLoading } = useUserAppeals(currentUser?.userId);
 *
 * @notes
 * - 仅用于用户端查看自己的申诉，不用于管理端审批。
 * - 返回数据是 appeal 列表；offense 只用于筛选和查询关联申诉，不会附加到返回项上。
 * - queryKey 为 ['userAppeals', userId ?? 'all']，不同用户的缓存互相隔离。
 * - @hardcoded slice(0,20)：前端展示上限；size:50：后端查询条数，确保覆盖展示量。
 */
import { useQuery } from '@tanstack/react-query';
import { listEntities } from '../api/entities.js';
import { entityConfigs } from '../config/entities.js';

async function fetchUserAppeals(userId) {
  const offenses = await listEntities(entityConfigs.offenses.basePath);
  const mine = userId
    ? offenses.filter((item) => String(item.driverId || '') === String(userId))
    : offenses;

  const appealGroups = await Promise.all(
    // @hardcoded slice(0,20)：前端展示上限；size:50：后端查询条数，确保覆盖展示量
    mine.slice(0, 20).map(async (offense) => {
      if (!offense.offenseId) return [];
      try {
        const appealList = await listEntities(entityConfigs.appeals.basePath, {
          offenseId: offense.offenseId,
          page: 1,
          // @hardcoded slice(0,20)：前端展示上限；size:50：后端查询条数，确保覆盖展示量
          size: 50,
        });
        return Array.isArray(appealList) ? appealList : [];
      } catch (error) {
        return [];
      }
    })
  );

  return appealGroups.flat();
}

export function useUserAppeals(userId) {
  return useQuery({
    queryKey: ['userAppeals', userId ?? 'all'],
    queryFn: () => fetchUserAppeals(userId),
  });
}
