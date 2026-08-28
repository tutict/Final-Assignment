import { useCallback } from 'react';
import {
  useMutation,
  useQuery,
  useQueryClient,
  type UseQueryResult,
} from '@tanstack/react-query';
import { listEntities, postWithIdempotency } from '../api/entities';
import { entityConfigs } from '../config/entities';
import { API_PATHS } from '../constants/apiPaths';
import { APPEAL_PROCESS_EVENT } from '../utils/workflowPermissions';

const DEFAULT_OFFENSE_LIMIT = 20;
const DEFAULT_APPEAL_PARAMS = { page: 1, size: 50 };

type AppealId = number | string | undefined;
type Appealish = { appealId?: AppealId; offenseId?: AppealId; [key: string]: unknown };

export interface AppealManagementItem extends Appealish {
  offense: Record<string, unknown>;
}

interface ListParams {
  offenseLimit?: number;
  appealParams?: { page?: number; size?: number };
}

const normalizeId = (id: AppealId): AppealId =>
  id === undefined || id === null ? id : String(id);

const normalizeAppealParams = (params: { page?: number; size?: number } = {}) => ({
  page: params.page ?? DEFAULT_APPEAL_PARAMS.page,
  size: params.size ?? DEFAULT_APPEAL_PARAMS.size,
});

const normalizeListParams = ({
  offenseLimit = DEFAULT_OFFENSE_LIMIT,
  appealParams,
}: ListParams = {}): Required<ListParams> & { appealParams: ReturnType<typeof normalizeAppealParams> } => ({
  offenseLimit,
  appealParams: normalizeAppealParams(appealParams),
});

export const appealManagementKeys = {
  all: ['appealManagement'],
  offenses: () => [...appealManagementKeys.all, 'offenses'],
  appeals: () => [...appealManagementKeys.all, 'appeals'],
  listPrefix: () => [...appealManagementKeys.appeals(), 'list'],
  list: (params: ListParams) => [...appealManagementKeys.listPrefix(), normalizeListParams(params)],
  byOffensePrefix: (offenseId: AppealId) => [
    ...appealManagementKeys.appeals(),
    'byOffense',
    normalizeId(offenseId),
  ],
  byOffense: (offenseId: AppealId, params: { page?: number; size?: number }) => [
    ...appealManagementKeys.byOffensePrefix(offenseId),
    normalizeAppealParams(params),
  ],
  detail: (appealId: AppealId) => [...appealManagementKeys.appeals(), 'detail', normalizeId(appealId)],
  workflow: () => [...appealManagementKeys.appeals(), 'workflow'],
};

async function fetchOffenses(queryClient: ReturnType<typeof useQueryClient>): Promise<Record<string, unknown>[]> {
  const offenses = await queryClient.fetchQuery({
    queryKey: appealManagementKeys.offenses(),
    queryFn: () => listEntities<unknown[]>(entityConfigs.offenses.basePath),
  });
  return Array.isArray(offenses) ? (offenses as Record<string, unknown>[]) : [];
}

async function fetchAppealsByOffense(
  queryClient: ReturnType<typeof useQueryClient>,
  offenseId: AppealId,
  appealParams: { page?: number; size?: number }
): Promise<Record<string, unknown>[]> {
  const appeals = await queryClient.fetchQuery({
    queryKey: appealManagementKeys.byOffense(offenseId, appealParams),
    queryFn: () =>
      listEntities<unknown[]>(entityConfigs.appeals.basePath, {
        offenseId,
        ...normalizeAppealParams(appealParams),
      }),
  });
  return Array.isArray(appeals) ? (appeals as Record<string, unknown>[]) : [];
}

async function fetchAppealManagementData(
  queryClient: ReturnType<typeof useQueryClient>,
  params: ListParams
): Promise<AppealManagementItem[]> {
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
          offense.offenseId as AppealId,
          appealParams
        );
        return appeals.map((appeal) => ({ ...appeal, offense }));
      } catch (error) {
        console.warn(
          `[useAppealManagement] 获取申诉失败 offenseId=${offense.offenseId}:`,
          (error as { message?: string })?.message
        );
        return { __fetchError: true, offenseId: offense.offenseId };
      }
    })
  );

  const appeals = appealGroups.flat() as AppealManagementItem[];
  appeals.forEach((appeal) => {
    if (appeal?.appealId) {
      queryClient.setQueryData(appealManagementKeys.detail(appeal.appealId), appeal);
    }
  });

  return appeals;
}

function resolveAppealIdentity(appealOrId: AppealId | Appealish): Appealish {
  if (appealOrId && typeof appealOrId === 'object') {
    return {
      appealId: appealOrId.appealId,
      offenseId: appealOrId.offenseId,
    };
  }
  return { appealId: appealOrId as AppealId, offenseId: undefined };
}

function invalidateAppealCaches(
  queryClient: ReturnType<typeof useQueryClient>,
  appeal: Appealish
): Promise<unknown[]> {
  const invalidations: Promise<unknown>[] = [
    queryClient.invalidateQueries({ queryKey: appealManagementKeys.listPrefix() }),
    queryClient.invalidateQueries({ queryKey: ['appeals'] }),
  ];

  if (appeal?.appealId) {
    invalidations.push(
      queryClient.invalidateQueries({ queryKey: appealManagementKeys.detail(appeal.appealId) })
    );
  }

  if (appeal?.offenseId) {
    invalidations.push(
      queryClient.invalidateQueries({ queryKey: appealManagementKeys.byOffensePrefix(appeal.offenseId) })
    );
  }

  return Promise.all(invalidations);
}

interface WorkflowVariables extends Appealish {
  event: string;
}

export function useAppealManagement(options: ListParams = {}) {
  const queryClient = useQueryClient();
  const listParams = normalizeListParams(options);

  const appealsQuery: UseQueryResult<AppealManagementItem[], unknown> = useQuery({
    queryKey: appealManagementKeys.list(listParams),
    queryFn: () => fetchAppealManagementData(queryClient, listParams),
  });

  const workflowMutation = useMutation({
    mutationKey: appealManagementKeys.workflow(),
    mutationFn: ({ appealId, event }: WorkflowVariables) =>
      postWithIdempotency(API_PATHS.APPEAL_WORKFLOW_EVENT(appealId as string | number, event), {}),
    onSuccess: async (updatedAppeal, variables) => {
      const changedAppeal: Appealish = {
        appealId: variables.appealId,
        offenseId: variables.offenseId,
        ...((updatedAppeal as Appealish) || {}),
      };

      if (changedAppeal.appealId) {
        queryClient.setQueryData(appealManagementKeys.detail(changedAppeal.appealId), changedAppeal);
      }

      await invalidateAppealCaches(queryClient, changedAppeal);
    },
  });

  const triggerWorkflow = useCallback(
    (appealOrId: AppealId | Appealish, event: string): Promise<unknown> => {
      const { appealId, offenseId } = resolveAppealIdentity(appealOrId);
      if (!appealId) return Promise.resolve();
      return workflowMutation.mutateAsync({ appealId, offenseId, event });
    },
    [workflowMutation]
  );

  const approve = useCallback(
    (appealOrId: AppealId | Appealish) => triggerWorkflow(appealOrId, APPEAL_PROCESS_EVENT.approve),
    [triggerWorkflow]
  );

  const reject = useCallback(
    (appealOrId: AppealId | Appealish) => triggerWorkflow(appealOrId, APPEAL_PROCESS_EVENT.reject),
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
