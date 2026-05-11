import { useQuery } from '@tanstack/react-query';
import { listEntities } from '../api/entities.js';
import { entityConfigs } from '../config/entities.js';

async function fetchUserAppeals(userId) {
  const offenses = await listEntities(entityConfigs.offenses.basePath);
  const mine = userId
    ? offenses.filter((item) => String(item.driverId || '') === String(userId))
    : offenses;

  const appealGroups = await Promise.all(
    mine.slice(0, 20).map(async (offense) => {
      if (!offense.offenseId) return [];
      try {
        const appealList = await listEntities(entityConfigs.appeals.basePath, {
          offenseId: offense.offenseId,
          page: 1,
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
