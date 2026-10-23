/**
 * 违法数据聚合 hooks，对齐 Flutter OffenseController._rebuildDashboardMetrics。
 * 数据源：GET /api/offenses（全量违法记录），客户端聚合为图表数据。
 */
import { useQuery, keepPreviousData } from '@tanstack/react-query';
import { useMemo } from 'react';
import dayjs from 'dayjs';
import { api } from '../api/client';
import { unwrapList } from '../api/entities';
import { API_PATHS } from '../constants/apiPaths';

export interface OffenseRecord {
  offenseId?: number;
  offenseType?: string;
  offenseDescription?: string;
  offenseTime?: string;
  fineAmount?: number;
  deductedPoints?: number;
  processStatus?: string;
  processResult?: string;
  remarks?: string;
  [key: string]: unknown;
}

export interface OffenseTypeSlice {
  label: string;
  value: number;
}

export interface TimeSeriesPoint {
  day: string; // ISO date (yyyy-MM-dd)
  label: string; // MM-dd
  fines: number;
  points: number;
}

export interface PaymentSlice {
  label: string;
  value: number;
}

export interface OffenseDashboardMetrics {
  offenseTypes: OffenseTypeSlice[];
  timeSeries: TimeSeriesPoint[];
  paymentStatus: PaymentSlice[];
  appealReasons: OffenseTypeSlice[];
  total: number;
  pending: number;
  processed: number;
  finesTotal: number;
  todayAdded: number;
  windowStart: string;
}

const WINDOW_DAYS = 30;
function isSettledStatus(status?: string): boolean {
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


// 违法时间是后端 LocalDateTime（本地墙钟、无时区），按本地日期切桶；
// 直接 slice(0,10) 会把带 Z 的 UTC 时间算到错误的日期。
function dayKey(value: string): string {
  const parsed = dayjs(value);
  return parsed.isValid() ? parsed.format('YYYY-MM-DD') : value.slice(0, 10);
}

function dayLabel(value: string): string {
  return value.slice(5, 10);
}

function countBy<T>(
  data: T[],
  selector: (item: T) => string | undefined,
  fallback = '未知'
): OffenseTypeSlice[] {
  const counts = new Map<string, number>();
  for (const item of data) {
    const key = (selector(item) || fallback).trim() || fallback;
    counts.set(key, (counts.get(key) || 0) + 1);
  }
  return Array.from(counts, ([label, value]) => ({ label, value })).sort(
    (a, b) => b.value - a.value
  );
}

function buildTimeSeries(data: OffenseRecord[], windowStartMs: number): TimeSeriesPoint[] {
  const buckets = new Map<string, TimeSeriesPoint>();
  const today = dayjs();
  // 预填 30 天空桶，保证 x 轴连续
  for (let i = WINDOW_DAYS - 1; i >= 0; i -= 1) {
    const d = today.subtract(i, 'day');
    const key = d.format('YYYY-MM-DD');
    buckets.set(key, { day: key, label: dayLabel(key), fines: 0, points: 0 });
  }
  for (const item of data) {
    const time = item.offenseTime;
    if (!time) continue;
    const key = dayKey(time);
    const bucket = buckets.get(key);
    if (!bucket) continue;
    const timestamp = dayjs(time).valueOf();
    if (!Number.isNaN(timestamp) && timestamp < windowStartMs) continue;
    bucket.fines += Number(item.fineAmount ?? 0);
    bucket.points += Number(item.deductedPoints ?? 0);
  }
  return Array.from(buckets.values());
}

function buildPaymentStatus(data: OffenseRecord[]): PaymentSlice[] {
  let paid = 0;
  let pending = 0;
  for (const item of data) {
    if (isSettledStatus(item.processStatus)) {
      paid += 1;
    } else {
      pending += 1;
    }
  }
  return [
    { label: '已缴/已结', value: paid },
    { label: '未缴/待办', value: pending },
  ];
}

export function buildOffenseMetrics(data: OffenseRecord[]): OffenseDashboardMetrics {
  const now = dayjs();
  const windowStart = now.subtract(WINDOW_DAYS, 'day');
  const windowStartIso = windowStart.format('YYYY-MM-DDTHH:mm:ss');

  const todayKey = now.format('YYYY-MM-DD');
  let todayAdded = 0;
  let pending = 0;
  let processed = 0;
  let finesTotal = 0;
  for (const item of data) {
    if (item.offenseTime && dayKey(item.offenseTime) === todayKey) todayAdded += 1;
    if (isSettledStatus(item.processStatus)) {
      processed += 1;
    } else {
      pending += 1;
    }
    finesTotal += Number(item.fineAmount ?? 0);
  }

  return {
    offenseTypes: countBy(data, (item) => item.offenseType || item.offenseDescription, '未知类型'),
    timeSeries: buildTimeSeries(data, windowStart.valueOf()),
    paymentStatus: buildPaymentStatus(data),
    appealReasons: countBy(data, (item) => item.processResult || item.remarks, '无'),
    total: data.length,
    pending,
    processed,
    finesTotal,
    todayAdded,
    windowStart: windowStartIso,
  };
}

function isFineSettled(status?: string): boolean {
  const raw = (status || "").trim();
  const upper = raw.toUpperCase();
  if (!upper) return false;
  if (upper.includes("UNPAID") || upper.includes("PARTIAL") || upper.includes("OVERDUE")) return false;
  return upper.includes("PAID") || upper.includes("WAIVED") || upper.includes("SUCCESS") || raw.includes("已缴") || raw.includes("已支付");
}

function buildFinePaymentStatus(fines: Array<{ paymentStatus?: string }>): PaymentSlice[] {
  let paid = 0;
  let pending = 0;
  for (const item of fines) {
    if (isFineSettled(item.paymentStatus)) paid += 1;
    else pending += 1;
  }
  return [
    { label: "已缴/已结", value: paid },
    { label: "未缴/待办", value: pending },
  ];
}

/** 违法状态来自违法记录；支付状态来自罚款单；申诉理由来自申诉单。 */
export function useOffenseDashboard() {
  const offenses = useQuery<OffenseRecord[]>({
    queryKey: ['offenses', 'dashboard'],
    queryFn: async () => {
      const response = await api.get<unknown>(API_PATHS.OFFENSES, { params: { page: 0, size: 100 } });
      return unwrapList<OffenseRecord>(response.data);
    },
    staleTime: 60_000,
    placeholderData: keepPreviousData,
  });
  const fines = useQuery<Array<{ paymentStatus?: string }>>({
    queryKey: ['fines', 'dashboard'],
    queryFn: async () => {
      const response = await api.get<unknown>(API_PATHS.FINES);
      return unwrapList<{ paymentStatus?: string }>(response.data);
    },
    staleTime: 60_000,
  });
  const appeals = useQuery<Array<{ appealReason?: string }>>({
    queryKey: ['appeals', 'dashboard'],
    queryFn: async () => {
      const response = await api.get<unknown>(API_PATHS.APPEAL_LIST, { params: { page: 1, size: 100 } });
      return unwrapList<{ appealReason?: string }>(response.data);
    },
    staleTime: 60_000,
  });

  const metrics = useMemo(() => {
    const base = buildOffenseMetrics(offenses.data || []);
    const appealRows = appeals.data || [];
    return {
      ...base,
      paymentStatus: buildFinePaymentStatus(fines.data || []),
      appealReasons: appealRows.length
        ? countBy(appealRows, (item) => item.appealReason, "未填写")
        : base.appealReasons,
    };
  }, [offenses.data, fines.data, appeals.data]);

  return {
    ...offenses,
    isLoading: offenses.isLoading || fines.isLoading || appeals.isLoading,
    isError: Boolean(offenses.isError || fines.isError),
    metrics,
    refresh: () => {
      void offenses.refetch();
      void fines.refetch();
      void appeals.refetch();
    },
  };
}
