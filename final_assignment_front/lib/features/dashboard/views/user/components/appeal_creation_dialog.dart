import 'package:final_assignment_front/features/api/appeal_management_controller_api.dart';
import 'package:flutter/material.dart';

Future<T?> showAppealCreationDialog<T>({
  required BuildContext context,
  required AppealCreationOperation operation,
  required WidgetBuilder builder,
}) async {
  try {
    return await showDialog<T>(context: context, builder: builder);
  } finally {
    operation.cancel();
  }
}
