export const STATUS_LABELS = Object.freeze({
  Pending: '待受理',
  Accepted: '已受理',
  Need_Supplement: '需补充材料',
  Unprocessed: '未处理',
  Under_Review: '审核中',
  Approved: '已通过',
  Rejected: '已驳回',
  Withdrawn: '已撤回',
  Unpaid: '未支付',
  Partial: '部分支付',
  Paid: '已支付',
  Overdue: '已逾期',
  Waived: '已减免',
});

export const getStatusLabel = (status) => {
  if (!status) return '未知';
  return STATUS_LABELS[status] || status;
};
