/**
 * @hook useAppealManagement
 * @description 管理端申诉审批页专用 Hook，聚合违法记录与其申诉记录并提供审批/驳回工作流操作。
 *
 * @param {{
 *   offenseLimit?: number,
 *   appealParams?: { page?: number, size?: number },
 * }} [options] - 查询选项；offenseLimit 限制参与聚合的违法记录数量，appealParams 透传给申诉列表查询。
 *
 * @returns {{
 *   data: Array<Object & { offense: Object }>,  // 申诉列表；每条为 AppealRecord 字段并附加 offense，offense 是对应 OffenseInformation 对象
 *   isLoading: boolean,  // 首次加载状态
 *   isFetching: boolean,  // 后台刷新状态
 *   isError: boolean,  // 查询是否失败
 *   error: unknown,  // React Query 暴露的查询错误
 *   approve: (appealOrId: number|string|{ appealId: number|string, offenseId?: number|string }) => Promise<unknown>,  // 触发 APPROVE workflow 事件
 *   reject: (appealOrId: number|string|{ appealId: number|string, offenseId?: number|string }) => Promise<unknown>,  // 触发 REJECT workflow 事件
 *   isUpdating: boolean,  // approve/reject mutation 进行中
 *   refetch: () => Promise<unknown>,  // 重新拉取聚合列表
 * }}
 *
 * @example
 * const { data, isLoading, approve, reject, isUpdating } = useAppealManagement();
 * await approve(data[0]);
 *
 * @notes
 * - 仅用于管理端申诉审批页面；用户端申诉列表请使用 useUserAppeals。
 * - data 是 appeal + offense 的聚合结构，来源为 offenses 列表与每条 offense 的 appeals 查询结果。
 * - React Query queryKey 以 appealManagementKeys 管理：offenses 单独缓存，appeals/list 使用规范化参数缓存，byOffense 按 offenseId 和分页参数缓存。
 * - approve/reject 不做提交前乐观更新；mutation 成功后写入 detail cache，并失效 listPrefix、legacy ['appeals'] 和对应 byOffense cache。
 * - 默认只处理前 20 条有 offenseId 的违法记录，每条违法记录默认查询第 1 页、50 条申诉。
 */
import { useCallback } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { listEntities, postWithIdempotency } from '../api/entities.js';
import { entityConfigs } from '../config/entities.js';
import { API_PATHS } from '../constants/apiPaths.js';
import { APPEAL_PROCESS_EVENT } from '../utils/workflowPermissions.js';

const DEFAULT_OFFENSE_LIMIT = 20;
const DEFAULT_APPEAL_PARAMS = { page: 1, size: 50 };

const normalizeId = (id) => (id === undefined || id === null ? id : String(id));

const normalizeAppealParams = (params = {}) => ({
  page: params.page ?? DEFAULT_APPEAL_PARAMS.page,
  size: params.size ?? DEFAULT_APPEAL_PARAMS.size,
});

const normalizeListParams = ({ offenseLimit = DEFAULT_OFFENSE_LIMIT, appealParams } = {}) => ({
  offenseLimit,
  appealParams: normalizeAppealParams(appealParams),
});

export const appealManagementKeys = {
  all: ['appealManagement'],
  offenses: () => [...appealManagementKeys.all, 'offenses'],
  appeals: () => [...appealManagementKeys.all, 'appeals'],
  listPrefix: () => [...appealManagementKeys.appeals(), 'list'],
  list: (params) => [...appealManagementKeys.listPrefix(), normalizeListParams(params)],
  byOffensePrefix: (offenseId) => [
    ...appealManagementKeys.appeals(),
    'byOffense',
    normalizeId(offenseId),
  ],
  byOffense: (offenseId, params) => [
    ...appealManagementKeys.byOffensePrefix(offenseId),
    normalizeAppealParams(params),
  ],
  detail: (appealId) => [...appealManagementKeys.appeals(), 'detail', normalizeId(appealId)],
  workflow: () => [...appealManagementKeys.appeals(), 'workflow'],
};

async function fetchOffenses(queryClient) {
  const offenses = await queryClient.fetchQuery({
    queryKey: appealManagementKeys.offenses(),
    queryFn: () => listEntities(entityConfigs.offenses.basePath),
  });

  return Array.isArray(offenses) ? offenses : [];
}

async function fetchAppealsByOffense(queryClient, offenseId, appealParams) {
  const appeals = await queryClient.fetchQuery({
    queryKey: appealManagementKeys.byOffense(offenseId, appealParams),
    queryFn: () =>
      listEntities(entityConfigs.appeals.basePath, {
        offenseId,
        ...normalizeAppealParams(appealParams),
      }),
  });

  return Array.isArray(appeals) ? appeals : [];
}

async function fetchAppealManagementData(queryClient, params) {
  const { offenseLimit, appealParams } = normalizeListParams(params);
  const offenses = await fetchOffenses(queryClient);
  const scopedOffenses = offenses
    .filter((offense) => offense?.offenseId)
    .slice(0, offenseLimit);

  const appealGroups = await Promise.all(
    scopedOffenses.map(async (offense) => {
      try {
        const appeals = await fetchAppealsByOffense(
          queryClient,
          offense.offenseId,
          appealParams
        );
        return appeals.map((appeal) => ({ ...appeal, offense }));
      } catch (error) {
        console.warn(
          `[useAppealManagement] 获取申诉失败 offenseId=${offense.offenseId}:`,
          error?.message
        );
        return { __fetchError: true, offenseId: offense.offenseId };
      }
    })
  );

  const appeals = appealGroups.flat();
  appeals.forEach((appeal) => {
    if (appeal?.appealId) {
      queryClient.setQueryData(appealManagementKeys.detail(appeal.appealId), appeal);
    }
  });

  return appeals;
}

function resolveAppealIdentity(appealOrId) {
  if (appealOrId && typeof appealOrId === 'object') {
    return {
      appealId: appealOrId.appealId,
      offenseId: appealOrId.offenseId,
    };
  }

  return {
    appealId: appealOrId,
    offenseId: undefined,
  };
}

function invalidateAppealCaches(queryClient, appeal) {
  const invalidations = [
    queryClient.invalidateQueries({ queryKey: appealManagementKeys.listPrefix() }),
    queryClient.invalidateQueries({ queryKey: ['appeals'] }),
  ];

  if (appeal?.appealId) {
    invalidations.push(
      queryClient.invalidateQueries({
        queryKey: appealManagementKeys.detail(appeal.appealId),
      })
    );
  }

  if (appeal?.offenseId) {
    invalidations.push(
      queryClient.invalidateQueries({
        queryKey: appealManagementKeys.byOffensePrefix(appeal.offenseId),
      })
    );
  }

  return Promise.all(invalidations);
}

export function useAppealManagement(options = {}) {
  const queryClient = useQueryClient();
  const listParams = normalizeListParams(options);

  const appealsQuery = useQuery({
    queryKey: appealManagementKeys.list(listParams),
    queryFn: () => fetchAppealManagementData(queryClient, listParams),
  });

  const workflowMutation = useMutation({
    mutationKey: appealManagementKeys.workflow(),
    mutationFn: ({ appealId, event }) =>
      postWithIdempotency(API_PATHS.APPEAL_WORKFLOW_EVENT(appealId, event), {}),
    onSuccess: async (updatedAppeal, variables) => {
      const changedAppeal = {
        appealId: variables.appealId,
        offenseId: variables.offenseId,
        ...(updatedAppeal || {}),
      };

      if (changedAppeal.appealId) {
        queryClient.setQueryData(
          appealManagementKeys.detail(changedAppeal.appealId),
          changedAppeal
        );
      }

      await invalidateAppealCaches(queryClient, changedAppeal);
    },
  });

  const triggerWorkflow = useCallback(
    (appealOrId, event) => {
      const { appealId, offenseId } = resolveAppealIdentity(appealOrId);
      if (!appealId) return Promise.resolve();
      return workflowMutation.mutateAsync({ appealId, offenseId, event });
    },
    [workflowMutation]
  );

  const approve = useCallback(
    (appealOrId) => triggerWorkflow(appealOrId, APPEAL_PROCESS_EVENT.approve),
    [triggerWorkflow]
  );

  const reject = useCallback(
    (appealOrId) => triggerWorkflow(appealOrId, APPEAL_PROCESS_EVENT.reject),
    [triggerWorkflow]
  );

  return {
    data: Array.isArray(appealsQuery.data) ? appealsQuery.data : [],
    isLoading: appealsQuery.isLoading,
    isFetching: appealsQuery.isFetching,
    isError: appealsQuery.isError,
    error: appealsQuery.error,
    approve,
    reject,
    isUpdating: workflowMutation.isPending,
    refetch: appealsQuery.refetch,
  };
}
