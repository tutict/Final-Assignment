import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';

/// AI 预制问题选项栏组件
/// 展示两层与交通违法相关的预定义问题，用户点击后发送到 AI 聊天界面，添加折叠按钮
class ManagerPredefinedQuestions extends StatelessWidget {
  const ManagerPredefinedQuestions({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatController chatController = Get.find<ChatController>();

    // 使用 GetX 的 RxBool 控制折叠状态
    final RxBool isExpanded = true.obs; // 默认展开

    // 交通违法相关的预定义问题列表
    final List<String> adminQuestions = [
      '如何查看所有未处理的交通违法记录？',
      '如何统计本月罚款缴纳总额？',
      '有哪些待审核的交通违法申诉？',
      '如何批量更新罚款到期状态？',
      '超速违章的处理流程是什么？',
    ];

    // 将问题分为两行
    final int halfLength = (adminQuestions.length / 2).ceil();
    final List<String> firstRow = adminQuestions.sublist(0, halfLength);
    final List<String> secondRow = adminQuestions.sublist(halfLength);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 折叠按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  '管理员预定义问题',
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
                : const SizedBox.shrink(), // 折叠时显示空占位符
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
