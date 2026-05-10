import 'package:final_assignment_front/utils/helpers/app_helpers.dart';

bool canApprove(String? status) {
  final state = AppealProcessStatus.fromCode(status);
  return state == AppealProcessStatus.unprocessed ||
      state == AppealProcessStatus.underReview;
}

bool canReject(String? status) => canApprove(status);

bool canEdit(String? status) {
  final appealState = AppealProcessStatus.fromCode(status);
  if (appealState != null) {
    return appealState != AppealProcessStatus.approved &&
        appealState != AppealProcessStatus.rejected &&
        appealState != AppealProcessStatus.withdrawn;
  }

  final offenseState = OffenseProcessStatus.fromCode(status);
  if (offenseState != null) {
    return offenseState == OffenseProcessStatus.unprocessed ||
        offenseState == OffenseProcessStatus.processing;
  }

  final paymentState = PaymentStatus.fromCode(status);
  if (paymentState != null) {
    return paymentState == PaymentStatus.unpaid ||
        paymentState == PaymentStatus.partial ||
        paymentState == PaymentStatus.overdue;
  }

  return false;
}

bool canPay(String? status) {
  final state = PaymentStatus.fromCode(status);
  return state == PaymentStatus.unpaid ||
      state == PaymentStatus.partial ||
      state == PaymentStatus.overdue;
}
