// 扩展TaskType枚举，增加额外的功能方法
part of 'app_helpers.dart';

extension TaskTypeExtension on TaskType {
  /// 返回任务类型的字符串表示
  ///
  ///   - "To Do"，如果任务类型是TaskType.todo
  ///   - "In Progress"，如果任务类型是TaskType.inProgress
  ///   - "Done"，如果任务类型是TaskType.done
  String toStringValue() {
    switch (this) {
      case TaskType.todo:
        return "待做";
      case TaskType.inProgress:
        return "正在处理";
      case TaskType.done:
        return "完成";
    }
  }

  /// 根据任务类型返回相应的颜色
  ///
  ///   - Colors.blue，如果任务类型是TaskType.todo
  ///   - Colors.orange，如果任务类型是TaskType.inProgress
  ///   - Colors.green，如果任务类型是TaskType.done
  Color getColor() {
    switch (this) {
      case TaskType.todo:
        return Colors.blue;
      case TaskType.inProgress:
        return Colors.orange;
      case TaskType.done:
        return Colors.green;
    }
  }
}

extension PaymentStatusExtension on PaymentStatus {
  Color get color {
    switch (this) {
      case PaymentStatus.unpaid:
        return Colors.redAccent;
      case PaymentStatus.partial:
        return Colors.deepOrange;
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.overdue:
        return Colors.purple;
      case PaymentStatus.waived:
        return Colors.blueGrey;
    }
  }

  Color get backgroundColor => color.withOpacity(0.12);
}

extension OffenseProcessStatusExtension on OffenseProcessStatus {
  Color get color {
    switch (this) {
      case OffenseProcessStatus.unprocessed:
        return Colors.blueGrey;
      case OffenseProcessStatus.processing:
        return Colors.orange;
      case OffenseProcessStatus.processed:
        return Colors.green;
      case OffenseProcessStatus.appealing:
        return Colors.indigo;
      case OffenseProcessStatus.appealApproved:
        return Colors.teal;
      case OffenseProcessStatus.appealRejected:
        return Colors.redAccent;
      case OffenseProcessStatus.cancelled:
        return Colors.grey;
    }
  }

  Color get backgroundColor => color.withOpacity(0.12);
}

extension DeductionStatusExtension on DeductionStatus {
  Color get color {
    switch (this) {
      case DeductionStatus.effective:
        return Colors.deepPurple;
      case DeductionStatus.cancelled:
        return Colors.redAccent;
      case DeductionStatus.restored:
        return Colors.green;
    }
  }

  Color get backgroundColor => color.withOpacity(0.12);
}

extension AppealAcceptanceStatusExtension on AppealAcceptanceStatus {
  Color get color {
    switch (this) {
      case AppealAcceptanceStatus.pending:
        return Colors.amber;
      case AppealAcceptanceStatus.accepted:
        return Colors.green;
      case AppealAcceptanceStatus.rejected:
        return Colors.redAccent;
      case AppealAcceptanceStatus.needSupplement:
        return Colors.blueGrey;
    }
  }

  Color get backgroundColor => color.withOpacity(0.12);
}

extension AppealProcessStatusExtension on AppealProcessStatus {
  Color get color {
    switch (this) {
      case AppealProcessStatus.unprocessed:
        return Colors.blueGrey;
      case AppealProcessStatus.underReview:
        return Colors.blue;
      case AppealProcessStatus.approved:
        return Colors.green;
      case AppealProcessStatus.rejected:
        return Colors.redAccent;
      case AppealProcessStatus.withdrawn:
        return Colors.deepOrange;
    }
  }

  Color get backgroundColor => color.withOpacity(0.12);
}
