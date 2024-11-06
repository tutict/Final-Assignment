import 'dart:async';
import 'package:final_assignment_front/utils/services/rest_api_services.dart';
import 'package:flutter/material.dart';

class MessageProvider with ChangeNotifier {
  MessageModel? _message;

  MessageModel? get message => _message;

  void updateMessage(MessageModel message) {
    _message = message;
    notifyListeners();
  }

  /// 等待指定 action 的消息
  Future<Map<String, dynamic>?> waitForMessage(String action) async {
    // 创建一个 Completer，用于等待特定的消息
    Completer<Map<String, dynamic>?> completer = Completer();

    // 定义一个监听器，当消息更新时检查 action 是否匹配
    void listener() {
      if (_message != null && _message!.action == action) {
        completer.complete(_message!.data);
        removeListener(listener); // 移除监听器
      }
    }

    addListener(listener); // 添加监听器

    // 超时处理，防止无限等待
    Future.delayed(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        completer.complete(null);
        removeListener(listener); // 超时后移除监听器
      }
    });

    return completer.future;
  }
}
