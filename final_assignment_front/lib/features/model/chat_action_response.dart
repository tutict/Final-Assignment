import 'package:final_assignment_front/features/model/chat_action.dart';

class ChatActionResponse {
  final String? answer;
  final List<ChatAction> actions;
  final bool needConfirm;

  ChatActionResponse({
    this.answer,
    List<ChatAction>? actions,
    this.needConfirm = false,
  }) : actions = actions ?? const [];

  factory ChatActionResponse.fromJson(Map<String, dynamic> json) {
    final rawActions = json['actions'];
    final actions = rawActions is List
        ? rawActions
            .whereType<Map<String, dynamic>>()
            .map(ChatAction.fromJson)
            .toList()
        : <ChatAction>[];

    return ChatActionResponse(
      answer: json['answer'] as String?,
      actions: actions,
      needConfirm: json['needConfirm'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'answer': answer,
      'actions': actions.map((action) => action.toJson()).toList(),
      'needConfirm': needConfirm,
    };
  }

  @override
  String toString() {
    return 'ChatActionResponse{ answer: $answer, actions: $actions, needConfirm: $needConfirm }';
  }
}
