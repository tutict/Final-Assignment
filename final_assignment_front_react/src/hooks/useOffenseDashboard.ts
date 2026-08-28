/**
 * 违法数据聚合 hooks，对齐 Flutter OffenseController._rebuildDashboardMetrics。
 * 数据源：GET /api/offenses（全量违法记录），客户端聚合为图表数据。
 */
import { useQuery, keepPreviousData } from '@tanstack/react-query';
import { useMemo } from 'react';
import { api } from '../api/client';
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
const PAID_RE = /paid|complete|closed|processed/i;

function dayKey(value: string): string {
  return value.slice(0, 10);
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

function buildTimeSeries(data: OffenseRecord[], windowStart: Date): TimeSeriesPoint[] {
  const buckets = new Map<string, TimeSeriesPoint>();
  const today = new Date();
  // 预填 30 天空桶，保证 x 轴连续
  for (let i = WINDOW_DAYS - 1; i >= 0; i -= 1) {
    const d = new Date(today);
    d.setDate(today.getDate() - i);
    const key = d.toISOString().slice(0, 10);
    buckets.set(key, { day: key, label: dayLabel(key), fines: 0, points: 0 });
  }
  for (const item of data) {
    const time = item.offenseTime;
    if (!time) continue;
    const key = dayKey(time);
    const bucket = buckets.get(key);
    if (!bucket) continue;
    if (new Date(time) < windowStart) continue;
    bucket.fines += Number(item.fineAmount ?? 0);
    bucket.points += Number(item.deductedPoints ?? 0);
  }
  return Array.from(buckets.values());
}

function buildPaymentStatus(data: OffenseRecord[]): PaymentSlice[] {
  let paid = 0;
  let pending = 0;
  for (const item of data) {
    if (item.processStatus && PAID_RE.test(item.processStatus)) {
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
  const now = new Date();
  const windowStart = new Date(now);
  windowStart.setDate(now.getDate() - WINDOW_DAYS);
  const windowStartIso = windowStart.toISOString();

  const todayKey = now.toISOString().slice(0, 10);
  let todayAdded = 0;
  let pending = 0;
  let processed = 0;
  let finesTotal = 0;
  for (const item of data) {
    if (item.offenseTime && dayKey(item.offenseTime) === todayKey) todayAdded += 1;
    if (item.processStatus && PAID_RE.test(item.processStatus)) {
      processed += 1;
    } else {
      pending += 1;
    }
    finesTotal += Number(item.fineAmount ?? 0);
  }

  return {
    offenseTypes: countBy(data, (item) => item.offenseType || item.offenseDescription, '未知类型'),
    timeSeries: buildTimeSeries(data, windowStart),
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

/** 拉取全量违法记录并对齐 Flutter 聚合。 */
export function useOffenseDashboard() {
  const query = useQuery<OffenseRecord[]>({
    queryKey: ['offenses', 'dashboard'],
    queryFn: async () => {
      const response = await api.get<unknown>(API_PATHS.OFFENSES);
      const data = response.data;
      return Array.isArray(data) ? (data as OffenseRecord[]) : [];
    },
    staleTime: 60_000,
    placeholderData: keepPreviousData,
  });

  const metrics = useMemo(
    () => buildOffenseMetrics(query.data || []),
    [query.data]
  );

  return {
    ...query,
    metrics,
    refresh: () => query.refetch(),
  };
}
