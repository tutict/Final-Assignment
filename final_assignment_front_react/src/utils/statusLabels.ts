import { STATUSES } from '../constants/statuses';

export const STATUS = {
  PENDING: STATUSES.PENDING,
  ACCEPTED: 'Accepted',
  NEED_SUPPLEMENT: 'Need_Supplement',
  UNPROCESSED: 'Unprocessed',
  UNDER_REVIEW: 'Under_Review',
  APPROVED: STATUSES.APPROVED,
  REJECTED: STATUSES.REJECTED,
  WITHDRAWN: 'Withdrawn',
  UNPAID: 'Unpaid',
  PARTIAL: 'Partial',
  PAID: 'Paid',
  OVERDUE: 'Overdue',
  WAIVED: 'Waived',
  SUCCESS: 'Success',
  PROCESSING: 'Processing',
  FAILED: 'Failed',
} as const;

export type StatusCode = (typeof STATUS)[keyof typeof STATUS];

export const STATUS_LABELS: Readonly<Record<string, string>> = Object.freeze({
  [STATUS.PENDING]: '待受理',
  [STATUS.ACCEPTED]: '已受理',
  [STATUS.NEED_SUPPLEMENT]: '需补充材料',
  [STATUS.UNPROCESSED]: '未处理',
  [STATUS.UNDER_REVIEW]: '审核中',
  [STATUS.APPROVED]: '已通过',
  [STATUS.REJECTED]: '已驳回',
  [STATUS.WITHDRAWN]: '已撤回',
  [STATUS.UNPAID]: '未支付',
  [STATUS.PARTIAL]: '部分支付',
  [STATUS.PAID]: '已支付',
  [STATUS.OVERDUE]: '已逾期',
  [STATUS.WAIVED]: '已减免',
});

export const getStatusLabel = (status: unknown): string => {
  if (!status) return '未知';
  return STATUS_LABELS[String(status)] || String(status);
};
