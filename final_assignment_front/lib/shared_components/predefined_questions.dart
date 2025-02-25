import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';

/// AI 预制问题选项栏组件
/// 展示两层与交通违法相关的预定义问题，用户点击后发送到 AI 聊天界面
class PredefinedQuestions extends StatelessWidget {
  const PredefinedQuestions({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatController chatController = Get.find<ChatController>();

    // 交通违法相关的预定义问题列表
    final List<String> questions = [
      '如何查询我的交通违法记录？',
      '罚款缴纳的流程是什么？',
      '交通违法申诉需要哪些材料？',
      '我的罚款什么时候到期？',
      '如何处理超速违章？',
    ];

    // 将问题分为两行
    final int halfLength = (questions.length / 2).ceil();
    final List<String> firstRow = questions.sublist(0, halfLength);
    final List<String> secondRow = questions.sublist(halfLength);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 第一行问题
          Wrap(
            spacing: 8.0, // 按钮间横向间距
            runSpacing: 8.0, // 行间距
            children: firstRow
                .map((question) =>
                    _buildButton(context, chatController, question))
                .toList(),
          ),
          const SizedBox(height: 8.0), // 两行间距
          // 第二行问题
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: secondRow
                .map((question) =>
                    _buildButton(context, chatController, question))
                .toList(),
          ),
        ],
      ),
    );
  }

  // 构建单个按钮
  Widget _buildButton(
      BuildContext context, ChatController chatController, String question) {
    return ElevatedButton(
      onPressed: () {
        // 点击时发送预制问题
        chatController.textController.text = question;
        chatController.sendMessage();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
        // 与 AppTheme.dart 一致
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0), // 与 AppTheme.dart 一致
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
      child: Text(
        question,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 14.0, // 调整字体大小以适应按钮
            ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}
