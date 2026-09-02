import 'package:final_assignment_front/features/dashboard/views/shared/widgets/status_badge.dart';
import 'package:final_assignment_front/utils/helpers/app_helpers.dart';
import 'package:flutter/material.dart';

/// 罚款支付状态徽章：未支付 / 部分支付 / 已支付 / 逾期 / 减免。
///
/// 直接映射 [PaymentStatus] 到对应的语义色调，供罚款列表与管理端使用。
class PaymentStatusChip extends StatelessWidget {
  const PaymentStatusChip({super.key, required this.status, this.dense = false});

  final PaymentStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      label: status.label,
      tone: _tone,
      icon: _icon,
      dense: dense,
    );
  }

  StatusTone get _tone {
    switch (status) {
      case PaymentStatus.unpaid:
        return StatusTone.warning;
      case PaymentStatus.partial:
        return StatusTone.info;
      case PaymentStatus.paid:
        return StatusTone.success;
      case PaymentStatus.overdue:
        return StatusTone.danger;
      case PaymentStatus.waived:
      case PaymentStatus.unknown:
        return StatusTone.neutral;
    }
  }

  IconData? get _icon {
    switch (status) {
      case PaymentStatus.unpaid:
        return Icons.receipt_long;
      case PaymentStatus.paid:
        return Icons.task_alt;
      case PaymentStatus.overdue:
        return Icons.warning_amber;
      case PaymentStatus.partial:
      case PaymentStatus.waived:
      case PaymentStatus.unknown:
        return null;
    }
  }
}