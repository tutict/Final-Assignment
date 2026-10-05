/**
 * 用户仪表盘聚合 hook，对齐 Flutter DriverHomeCounts。
 * 违法和罚款按驾驶员接口取，避免 USER 访问全量列表被拒绝，也避免把用户号当成驾驶员号。
 */
import { useQuery, keepPreviousData } from '@tanstack/react-query';
import { useMemo } from 'react';
import { api } from '../api/client';
import { unwrapList } from '../api/entities';
import { API_PATHS } from '../constants/apiPaths';

export interface UserOffenseRecord {
  offenseId?: number;
  offenseTime?: string;
  processStatus?: string;
  fineAmount?: number;
  driverId?: number | string;
  [key: string]: unknown;
}

export interface UserFineRecord {
  fineId?: number;
  paymentStatus?: string;
  fineAmount?: number;
  unpaidAmount?: number;
  [key: string]: unknown;
}

export interface UserDashboardMetrics {
  totalOffenses: number;
  pendingOffenses: number;
  unpaidFines: number;
  activeAppeals: number;
  vehicleCount: number;
}

function isSettledOffense(status?: string): boolean {
  const raw = (status || "").trim();
  const upper = raw.toUpperCase();
  if (!upper) return false;
  if (upper.includes("UNPROCESSED") || upper.includes("UNPAID") || upper.includes("PENDING")) return false;
  return (
    upper.includes("PAID") ||
    upper.includes("PROCESSED") ||
    upper.includes("COMPLETE") ||
    upper.includes("CLOSED") ||
    raw.includes("已缴") ||
    raw.includes("已结") ||
    raw.includes("已处理")
  );
}


function isUnpaidFine(item: UserFineRecord): boolean {
  const raw = String(item.paymentStatus || '');
  const status = raw.toUpperCase();
  if (!status && Number(item.unpaidAmount ?? item.fineAmount ?? 0) > 0) return true;
  return !(
    status.includes('PAID') ||
    status.includes('WAIVED') ||
    status.includes('SUCCESS') ||
    raw.includes('已缴') ||
    raw.includes('已支付')
  );
}

export function useUserOffenses(driverId?: string | number) {
  return useQuery<UserOffenseRecord[]>({
    queryKey: ['userOffenses', driverId ?? 'none'],
    enabled: driverId !== undefined && driverId !== null && String(driverId) !== '',
    queryFn: async () => {
      const response = await api.get<unknown>(API_PATHS.OFFENSES_BY_DRIVER(driverId as string | number), {
        params: { page: 1, size: 100 },
      });
      return unwrapList<UserOffenseRecord>(response.data);
    },
    staleTime: 60_000,
    placeholderData: keepPreviousData,
  });
}

export function useUserFines(driverId?: string | number) {
  return useQuery<UserFineRecord[]>({
    queryKey: ['userFines', driverId ?? 'none'],
    enabled: driverId !== undefined && driverId !== null && String(driverId) !== '',
    queryFn: async () => {
      const response = await api.get<unknown>(API_PATHS.FINES_BY_DRIVER(driverId as string | number), {
        params: { page: 1, size: 100 },
      });
      return unwrapList<UserFineRecord>(response.data);
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
  error: unknown;
  refresh: () => void;
} {
  const offensesQuery = useUserOffenses(driverId);
  const finesQuery = useUserFines(driverId);

  const metrics = useMemo<UserDashboardMetrics>(() => {
    const offenses = offensesQuery.data || [];
    const fines = finesQuery.data || [];
    const pending = offenses.filter((item) => !isSettledOffense(item.processStatus)).length;
    return {
      totalOffenses: offenses.length,
      pendingOffenses: pending,
      unpaidFines: fines.filter(isUnpaidFine).length,
      activeAppeals: 0,
      vehicleCount: 0,
    };
  }, [offensesQuery.data, finesQuery.data]);

  return {
    metrics,
    isLoading: offensesQuery.isLoading || finesQuery.isLoading,
    isError: Boolean(offensesQuery.isError || finesQuery.isError),
    error: offensesQuery.error || finesQuery.error,
    refresh: () => {
      void offensesQuery.refetch();
      void finesQuery.refetch();
    },
  };
}
