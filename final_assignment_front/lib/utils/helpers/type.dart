part of 'app_helpers.dart';

// 这个文件主要处理枚举数据

enum TaskType {
  todo,
  inProgress,
  done,
}

enum CaseType {
  caseAppeal, // 添加案件申诉类型
  caseSearch, // 添加案件查询类型
  caseManagement, // 添加信息管理类型
}

enum PaymentStatus {
  unpaid(code: 'Unpaid', label: '未支付'),
  partial(code: 'Partial', label: '部分支付'),
  paid(code: 'Paid', label: '已支付'),
  overdue(code: 'Overdue', label: '逾期'),
  waived(code: 'Waived', label: '减免');

  final String code;
  final String label;

  const PaymentStatus({required this.code, required this.label});

  static PaymentStatus? fromCode(String? code) =>
      StringHelper.enumFromCode(values, code, (value) => value.code);
}

enum OffenseProcessStatus {
  unprocessed(code: 'Unprocessed', label: '未处理'),
  processing(code: 'Processing', label: '处理中'),
  processed(code: 'Processed', label: '已处理'),
  appealing(code: 'Appealing', label: '申诉中'),
  appealApproved(code: 'Appeal_Approved', label: '申诉通过'),
  appealRejected(code: 'Appeal_Rejected', label: '申诉驳回'),
  cancelled(code: 'Cancelled', label: '已取消');

  final String code;
  final String label;

  const OffenseProcessStatus({required this.code, required this.label});

  static OffenseProcessStatus? fromCode(String? code) =>
      StringHelper.enumFromCode(values, code, (value) => value.code);
}

enum DeductionStatus {
  effective(code: 'Effective', label: '生效中'),
  cancelled(code: 'Cancelled', label: '已取消'),
  restored(code: 'Restored', label: '已恢复');

  final String code;
  final String label;

  const DeductionStatus({required this.code, required this.label});

  static DeductionStatus? fromCode(String? code) =>
      StringHelper.enumFromCode(values, code, (value) => value.code);
}

enum AppealAcceptanceStatus {
  pending(code: 'Pending', label: '待受理'),
  accepted(code: 'Accepted', label: '已受理'),
  rejected(code: 'Rejected', label: '不予受理'),
  needSupplement(code: 'Need_Supplement', label: '需补充材料');

  final String code;
  final String label;

  const AppealAcceptanceStatus({required this.code, required this.label});

  static AppealAcceptanceStatus? fromCode(String? code) =>
      StringHelper.enumFromCode(values, code, (value) => value.code);
}

enum AppealProcessStatus {
  unprocessed(code: 'Unprocessed', label: '未处理'),
  underReview(code: 'Under_Review', label: '审核中'),
  approved(code: 'Approved', label: '已批准'),
  rejected(code: 'Rejected', label: '已驳回'),
  withdrawn(code: 'Withdrawn', label: '已撤回');

  final String code;
  final String label;

  const AppealProcessStatus({required this.code, required this.label});

  static AppealProcessStatus? fromCode(String? code) =>
      StringHelper.enumFromCode(values, code, (value) => value.code);
}

enum PaymentEventType {
  partialPay(code: 'PARTIAL_PAY', label: '部分支付'),
  completePayment(code: 'COMPLETE_PAYMENT', label: '完成支付'),
  markOverdue(code: 'MARK_OVERDUE', label: '标记逾期'),
  waiveFine(code: 'WAIVE_FINE', label: '减免罚款'),
  continuePayment(code: 'CONTINUE_PAYMENT', label: '继续支付');

  final String code;
  final String label;

  const PaymentEventType({required this.code, required this.label});

  static PaymentEventType? fromCode(String? code) =>
      StringHelper.enumFromCode(values, code, (value) => value.code);
}

enum DeductionEventType {
  cancel(code: 'CANCEL', label: '取消扣分'),
  restore(code: 'RESTORE', label: '恢复扣分'),
  reactivate(code: 'REACTIVATE', label: '重新生效');

  final String code;
  final String label;

  const DeductionEventType({required this.code, required this.label});

  static DeductionEventType? fromCode(String? code) =>
      StringHelper.enumFromCode(values, code, (value) => value.code);
}

enum OffenseProcessEventType {
  startProcessing(code: 'START_PROCESSING', label: '开始处理'),
  completeProcessing(code: 'COMPLETE_PROCESSING', label: '完成处理'),
  submitAppeal(code: 'SUBMIT_APPEAL', label: '提交申诉'),
  approveAppeal(code: 'APPROVE_APPEAL', label: '申诉通过'),
  rejectAppeal(code: 'REJECT_APPEAL', label: '申诉驳回'),
  cancel(code: 'CANCEL', label: '取消记录'),
  withdrawAppeal(code: 'WITHDRAW_APPEAL', label: '撤回申诉');

  final String code;
  final String label;

  const OffenseProcessEventType({required this.code, required this.label});

  static OffenseProcessEventType? fromCode(String? code) =>
      StringHelper.enumFromCode(values, code, (value) => value.code);
}

enum AppealAcceptanceEventType {
  accept(code: 'ACCEPT', label: '受理申诉'),
  reject(code: 'REJECT', label: '拒绝受理'),
  requestSupplement(code: 'REQUEST_SUPPLEMENT', label: '要求补充材料'),
  supplementComplete(code: 'SUPPLEMENT_COMPLETE', label: '补充完成'),
  resubmit(code: 'RESUBMIT', label: '重新提交');

  final String code;
  final String label;

  const AppealAcceptanceEventType({required this.code, required this.label});

  static AppealAcceptanceEventType? fromCode(String? code) =>
      StringHelper.enumFromCode(values, code, (value) => value.code);
}

enum AppealProcessEventType {
  startReview(code: 'START_REVIEW', label: '开始审核'),
  approve(code: 'APPROVE', label: '批准申诉'),
  reject(code: 'REJECT', label: '驳回申诉'),
  withdraw(code: 'WITHDRAW', label: '撤回申诉'),
  reopenReview(code: 'REOPEN_REVIEW', label: '重新审核');

  final String code;
  final String label;

  const AppealProcessEventType({required this.code, required this.label});

  static AppealProcessEventType? fromCode(String? code) =>
      StringHelper.enumFromCode(values, code, (value) => value.code);
}
