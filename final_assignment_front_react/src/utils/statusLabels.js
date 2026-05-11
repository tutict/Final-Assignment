export const STATUS = Object.freeze({
  PENDING: 'Pending',
  ACCEPTED: 'Accepted',
  NEED_SUPPLEMENT: 'Need_Supplement',
  UNPROCESSED: 'Unprocessed',
  UNDER_REVIEW: 'Under_Review',
  APPROVED: 'Approved',
  REJECTED: 'Rejected',
  WITHDRAWN: 'Withdrawn',
  UNPAID: 'Unpaid',
  PARTIAL: 'Partial',
  PAID: 'Paid',
  OVERDUE: 'Overdue',
  WAIVED: 'Waived',
  SUCCESS: 'Success',
  PROCESSING: 'Processing',
  FAILED: 'Failed',
});

export const STATUS_LABELS = Object.freeze({
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

export const getStatusLabel = (status) => {
  if (!status) return '未知';
  return STATUS_LABELS[status] || status;
};
