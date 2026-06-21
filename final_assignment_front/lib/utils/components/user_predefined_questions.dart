import 'package:final_assignment_front/features/dashboard/controllers/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserPredefinedQuestions extends StatefulWidget {
  const UserPredefinedQuestions({
    super.key,
    required this.onQuestionTap,
  });

  final VoidCallback onQuestionTap;

  @override
  State<UserPredefinedQuestions> createState() =>
      _UserPredefinedQuestionsState();
}

class _UserPredefinedQuestionsState extends State<UserPredefinedQuestions> {
  bool isExpanded = false;

  static const questions = [
    '如何查询我的交通违法记录？',
    '罚款缴纳流程是什么？',
    '交通违法申诉需要哪些材料？',
    '我的罚款什么时候到期？',
    '如何处理超速违法？',
  ];

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();

    return _PredefinedQuestionPanel(
      title: '驾驶员常问',
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
