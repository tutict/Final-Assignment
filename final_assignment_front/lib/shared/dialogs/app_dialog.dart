import 'package:flutter/material.dart';

class AppDialog {
  static Future<bool?> showConfirmDelete(
    BuildContext context, {
    required String itemName,
    String? extraWarning,
    String confirmLabel = '删除',
    String cancelLabel = '取消',
  }) {
    final warning = extraWarning ?? '';
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 $itemName 吗？$warning'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              confirmLabel,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
