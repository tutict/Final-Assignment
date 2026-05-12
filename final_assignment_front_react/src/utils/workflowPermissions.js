import { STATUSES } from '../constants/statuses.js';
import { STATUS } from './statusLabels.js';

export const APPEAL_PROCESS_STATUS = Object.freeze({
  unprocessed: STATUS.UNPROCESSED,
  underReview: STATUS.UNDER_REVIEW,
  approved: STATUSES.APPROVED,
  rejected: STATUSES.REJECTED,
  withdrawn: STATUS.WITHDRAWN,
});

export const APPEAL_PROCESS_EVENT = Object.freeze({
  approve: 'APPROVE',
  reject: 'REJECT',
});

const REVIEWABLE_APPEAL_STATUSES = new Set([
  APPEAL_PROCESS_STATUS.unprocessed,
  APPEAL_PROCESS_STATUS.underReview,
]);

const TERMINAL_APPEAL_STATUSES = new Set([
  APPEAL_PROCESS_STATUS.approved,
  APPEAL_PROCESS_STATUS.rejected,
  APPEAL_PROCESS_STATUS.withdrawn,
]);

export const canApprove = (status) => REVIEWABLE_APPEAL_STATUSES.has(status);

export const canReject = (status) => canApprove(status);

export const canEdit = (status) =>
  Boolean(status) && !TERMINAL_APPEAL_STATUSES.has(status);
