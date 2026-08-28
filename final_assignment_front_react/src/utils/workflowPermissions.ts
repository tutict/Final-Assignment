import { STATUSES } from '../constants/statuses';
import { STATUS } from './statusLabels';

export const APPEAL_PROCESS_STATUS = {
  unprocessed: STATUS.UNPROCESSED,
  underReview: STATUS.UNDER_REVIEW,
  approved: STATUSES.APPROVED,
  rejected: STATUSES.REJECTED,
  withdrawn: STATUS.WITHDRAWN,
} as const;

export const APPEAL_PROCESS_EVENT = {
  approve: 'APPROVE',
  reject: 'REJECT',
} as const;

const REVIEWABLE_APPEAL_STATUSES = new Set<string>([
  APPEAL_PROCESS_STATUS.unprocessed,
  APPEAL_PROCESS_STATUS.underReview,
]);

const TERMINAL_APPEAL_STATUSES = new Set<string>([
  APPEAL_PROCESS_STATUS.approved,
  APPEAL_PROCESS_STATUS.rejected,
  APPEAL_PROCESS_STATUS.withdrawn,
]);

export const canApprove = (status: unknown): boolean =>
  REVIEWABLE_APPEAL_STATUSES.has(String(status));

export const canReject = (status: unknown): boolean => canApprove(status);

export const canEdit = (status: unknown): boolean =>
  Boolean(status) && !TERMINAL_APPEAL_STATUSES.has(String(status));
