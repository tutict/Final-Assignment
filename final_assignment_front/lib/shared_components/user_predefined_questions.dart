import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';

/// 用户预制问题选项栏组件
/// 展示两层与交通违法相关的预定义问题，用户点击后发送到 AI 聊天界面，支持折叠
class UserPredefinedQuestions extends StatelessWidget {
  const UserPredefinedQuestions({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatController chatController = Get.find<ChatController>();

    // 使用 GetX 的 RxBool 控制折叠状态
    final RxBool isExpanded = true.obs; // 默认展开

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
          // 折叠按钮和标题
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  '用户常见问题',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: Obx(() => Icon(
                      isExpanded.value ? Icons.expand_less : Icons.expand_more,
                      color: Theme.of(context).colorScheme.primary,
                    )),
                onPressed: () {
                  isExpanded.value = !isExpanded.value; // 切换折叠状态
                },
              ),
            ],
          ),
          // 问题列表，使用 Obx 监听折叠状态
          Obx(
            () => isExpanded.value
                ? Column(
                    children: [
                      // 第一行问题
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: firstRow
                            .map((question) =>
                                _buildButton(context, chatController, question))
                            .toList(),
                      ),
                      const SizedBox(height: 8.0),
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
                  )
                : const SizedBox.shrink(), // 折叠时隐藏
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
        chatController.textController.text = question;
        chatController.sendMessage();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
      child: Text(
        question,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 14.0,
            ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}
