import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManagerPredefinedQuestions extends StatefulWidget {
  const ManagerPredefinedQuestions({
    super.key,
    required this.onQuestionTap,
  });

  final VoidCallback onQuestionTap;

  @override
  State<ManagerPredefinedQuestions> createState() =>
      _ManagerPredefinedQuestionsState();
}

class _ManagerPredefinedQuestionsState
    extends State<ManagerPredefinedQuestions> {
  bool isExpanded = false;

  static const questions = [
    '如何查看所有未处理违法记录？',
    '如何统计本月罚款缴纳总额？',
    '有哪些待审核的交通违法申诉？',
    '如何批量更新罚款到期状态？',
    '超速违法的处理流程是什么？',
  ];

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();

    return _PredefinedQuestionPanel(
      title: '管理员常问',
      expanded: isExpanded,
      onToggle: () => setState(() => isExpanded = !isExpanded),
      questions: questions,
      onSelect: (question) {
        chatController.textController.text = question;
        chatController.sendMessage();
        widget.onQuestionTap();
      },
    );
  }
}

class _PredefinedQuestionPanel extends StatelessWidget {
  const _PredefinedQuestionPanel({
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.questions,
    required this.onSelect,
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final List<String> questions;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(
          alpha: dark ? 0.32 : 0.68,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: dark ? 0.34 : 0.52),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline,
                      size: 17, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState:
                expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: questions
                    .map(
                      (question) => _QuestionChip(
                        question: question,
                        onTap: () => onSelect(question),
                      ),
                    )
                    .toList(),
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _QuestionChip extends StatelessWidget {
  const _QuestionChip({
    required this.question,
    required this.onTap,
  });

  final String question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 136, maxWidth: 230),
      child: Material(
        color: scheme.surface.withValues(alpha: dark ? 0.44 : 0.82),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Text(
                    question,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                      height: 1.22,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 15,
                  color: scheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
