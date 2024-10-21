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
