/**
 * 业务进度数据 hook，对齐 Flutter ProgressController。
 * 提供状态分类筛选、时间范围筛选、新建/删除/状态更新（管理员）、关联业务上下文。
 */
import { useCallback, useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import dayjs from 'dayjs';
import {
  createProgress,
  deleteProgress,
  getBusinessContext,
  listProgress,
  searchProgressByTimeRange,
  updateProgressStatus,
  type ProgressItem,
} from '../api/progress';

export const PROGRESS_STATUS_CATEGORIES = ['Pending', 'Processing', 'Completed', 'Archived'] as const;
export type ProgressStatus = (typeof PROGRESS_STATUS_CATEGORIES)[number];

export const PROGRESS_STATUS_LABELS: Record<string, string> = {
  Pending: '待处理',
  Processing: '处理中',
  Completed: '已完成',
  Archived: '已归档',
};

export function progressStatusLabel(status?: string): string {
  if (!status) return '未知';
  return PROGRESS_STATUS_LABELS[status] ?? status;
}

interface UseProgressOptions {
  /** 管理员可创建/删除/变更状态；用户端只读 + 筛选 */
  canManage?: boolean;
}

export function useProgress({ canManage = false }: UseProgressOptions = {}) {
  const queryClient = useQueryClient();
  const [selectedStatus, setSelectedStatus] = useState<string | null>(null);
  const [startDate, setStartDate] = useState<string | null>(null);
  const [endDate, setEndDate] = useState<string | null>(null);

  const hasDateFilter = Boolean(startDate && endDate);
  const hasActiveFilter = Boolean(selectedStatus) || hasDateFilter;

  // 时间范围筛选走独立后端端点（对齐 Flutter fetchProgressByTimeRange）
  const timeRangeQuery = useQuery({
    queryKey: ['progress', 'timeRange', startDate, endDate],
    queryFn: () => searchProgressByTimeRange(startDate as string, endDate as string),
    enabled: hasDateFilter,
  });

  const allQuery = useQuery({
    queryKey: ['progress', 'all'],
    queryFn: listProgress,
    enabled: !hasDateFilter,
  });

  const baseItems: ProgressItem[] = hasDateFilter
    ? (Array.isArray(timeRangeQuery.data) ? timeRangeQuery.data : [])
    : (Array.isArray(allQuery.data) ? allQuery.data : []);

  const isLoading = hasDateFilter ? timeRangeQuery.isLoading : allQuery.isLoading;
  const isError = hasDateFilter ? timeRangeQuery.isError : allQuery.isError;
  const error = hasDateFilter ? timeRangeQuery.error : allQuery.error;

  const filteredItems = useMemo(() => {
    if (!selectedStatus) return baseItems;
    return baseItems.filter((item) => item.status === selectedStatus);
  }, [baseItems, selectedStatus]);

  const refresh = useCallback(() => {
    if (hasDateFilter) {
      void timeRangeQuery.refetch();
    } else {
      void allQuery.refetch();
    }
  }, [hasDateFilter, timeRangeQuery, allQuery]);

  const filterByStatus = useCallback((status: string | null) => {
    setSelectedStatus(status);
    setStartDate(null);
    setEndDate(null);
  }, []);

  const filterByTimeRange = useCallback((start: string, end: string) => {
    setSelectedStatus(null);
    setStartDate(start);
    setEndDate(end);
  }, []);

  const clearFilters = useCallback(() => {
    setSelectedStatus(null);
    setStartDate(null);
    setEndDate(null);
  }, []);

  const invalidateAll = useCallback(async () => {
    await Promise.all([
      queryClient.invalidateQueries({ queryKey: ['progress'] }),
    ]);
  }, [queryClient]);

  const createMutation = useMutation({
    mutationFn: (payload: { title: string; details?: string; appealId?: number }) =>
      createProgress({
        title: payload.title,
        details: payload.details,
        appealId: payload.appealId,
        status: 'Pending',
        submitTime: new Date().toISOString(),
        username: '',
      }),
    onSuccess: () => invalidateAll(),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: number) => deleteProgress(id),
    onSuccess: () => invalidateAll(),
  });

  const statusMutation = useMutation({
    mutationFn: ({ id, status }: { id: number; status: string }) =>
      updateProgressStatus(id, status),
    onSuccess: () => invalidateAll(),
  });

  return {
    items: filteredItems,
    totalCount: baseItems.length,
    statusCategories: [...PROGRESS_STATUS_CATEGORIES] as string[],
    selectedStatus,
    startDate,
    endDate,
    hasActiveFilter,
    isLoading,
    isError,
    error,
    businessContext: getBusinessContext,
    refresh,
    filterByStatus,
    filterByTimeRange,
    clearFilters,
    // 管理员操作
    createProgress: canManage ? (payload: { title: string; details?: string; appealId?: number }) =>
      createMutation.mutateAsync(payload) : undefined,
    deleteProgress: canManage ? (id: number) => deleteMutation.mutateAsync(id) : undefined,
    updateStatus: canManage
      ? (id: number, status: string) => statusMutation.mutateAsync({ id, status })
      : undefined,
    isMutating: createMutation.isPending || deleteMutation.isPending || statusMutation.isPending,
  };
}

/** 格式化时间范围为短日期标签（对齐 Flutter _shortDate MM-dd）。 */
export function formatProgressDateRange(start: string | null, end: string | null): string {
  if (!start || !end) return '时间范围';
  return `${dayjs(start).format('MM-DD')} - ${dayjs(end).format('MM-DD')}`;
}
