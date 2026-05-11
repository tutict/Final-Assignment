import { useCallback } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { listEntities, postWithIdempotency } from '../api/entities.js';
import { entityConfigs } from '../config/entities.js';
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
        return [];
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
      postWithIdempotency(`/api/workflow/appeals/${appealId}/events/${event}`, {}),
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
