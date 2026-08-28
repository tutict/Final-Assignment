/**
 * 用户仪表盘聚合 hook，对齐 Flutter user_dashboard。
 * 基于当前用户筛选其违法/申诉数据，聚合成仪表盘 KPI。
 */
import { useQuery, keepPreviousData } from '@tanstack/react-query';
import { useMemo } from 'react';
import { api } from '../api/client';
import { API_PATHS } from '../constants/apiPaths';

export interface UserOffenseRecord {
  offenseId?: number;
  offenseTime?: string;
  processStatus?: string;
  fineAmount?: number;
  [key: string]: unknown;
}

export interface UserDashboardMetrics {
  totalOffenses: number;
  pendingOffenses: number;
  unpaidFines: number;
  activeAppeals: number;
  vehicleCount: number;
}

const PAID_RE = /paid|complete|closed|processed/i;

/** 拉取当前用户的违法记录（按 driverId 关联）。 */
export function useUserOffenses(driverId?: string | number) {
  return useQuery<UserOffenseRecord[]>({
    queryKey: ['userOffenses', driverId ?? 'me'],
    queryFn: async () => {
      const response = await api.get<unknown>(API_PATHS.OFFENSES);
      const data = response.data;
      if (!Array.isArray(data)) return [];
      const all = data as UserOffenseRecord[];
      if (!driverId) return all;
      return all.filter((item) => String(item.driverId || '') === String(driverId));
    },
    staleTime: 60_000,
    placeholderData: keepPreviousData,
  });
}

/** 聚合用户仪表盘 KPI。 */
export function useUserDashboardMetrics(driverId?: string | number): {
  metrics: UserDashboardMetrics;
  isLoading: boolean;
  isError: boolean;
  refresh: () => void;
} {
  const offensesQuery = useUserOffenses(driverId);

  const metrics = useMemo<UserDashboardMetrics>(() => {
    const list = offensesQuery.data || [];
    let pending = 0;
    let unpaid = 0;
    for (const item of list) {
      if (item.processStatus && PAID_RE.test(item.processStatus)) {
        // 已结
      } else {
        pending += 1;
        unpaid += Number(item.fineAmount ?? 0) > 0 ? 1 : 0;
      }
    }
    return {
      totalOffenses: list.length,
      pendingOffenses: pending,
      unpaidFines: unpaid,
      activeAppeals: 0,
      vehicleCount: 0,
    };
  }, [offensesQuery.data]);

  return {
    metrics,
    isLoading: offensesQuery.isLoading,
    isError: Boolean(offensesQuery.isError),
    refresh: () => offensesQuery.refetch(),
  };
}
