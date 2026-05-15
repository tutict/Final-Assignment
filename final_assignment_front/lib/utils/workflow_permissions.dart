import 'package:final_assignment_front/utils/helpers/app_helpers.dart';

bool canApprove(String? status) {
  final state = AppealProcessStatus.fromCode(status);
  final normalized =
      status?.replaceAll('-', '_').replaceAll(' ', '_').toLowerCase();
  return state == AppealProcessStatus.underReview ||
      normalized == 'under_review' ||
      normalized == 'underreview';
}

bool canReject(String? status) => canApprove(status);

bool canStartReview(String? status) {
  final state = AppealProcessStatus.fromCode(status);
  if (state == AppealProcessStatus.unprocessed) {
    return true;
  }
  final normalized =
      status?.replaceAll('-', '_').replaceAll(' ', '_').toLowerCase();
  return normalized == 'pending' ||
      normalized == 'unprocessed' ||
      normalized == 'under_review_pending';
}

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
