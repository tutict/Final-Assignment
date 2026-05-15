import 'dart:developer' as developer;

import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ErrorHandler {
  /// 操作失败时调用：显示 Snackbar + 记录日志
  static void showError(Object error, {String? fallbackMessage}) {
    final appException = AppException.fromError(
      error,
      fallbackMessage: fallbackMessage,
    );
    final msg = appException.message;

    Get.snackbar(
      '错误',
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      duration: const Duration(seconds: 3),
    );

    developer.log(
      msg,
      name: 'AppError',
      error: error,
    );
  }

  /// 页面加载失败时调用：只更新 Controller 状态，不弹 Snackbar
  static String extractMessage(Object error, {String? fallback}) {
    return AppException.fromError(
      error,
      fallbackMessage: fallback,
    ).message;
  }
}
