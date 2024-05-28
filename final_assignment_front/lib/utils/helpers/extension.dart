part of app_helpers;


extension TaskTypeExtension on TaskType {
  String toStringValue() {
    switch (this) {
      case TaskType.todo:
        return "To Do";
      case TaskType.inProgress:
        return "In Progress";
      case TaskType.done:
        return "Done";
    }
  }

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

