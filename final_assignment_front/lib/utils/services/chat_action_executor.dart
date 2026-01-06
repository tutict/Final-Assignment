import 'package:final_assignment_front/features/model/chat_action.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:final_assignment_front/utils/ui/ui_utils.dart';
import 'package:flutter/material.dart';

typedef ChatActionHandler = Future<void> Function(ChatAction action);
typedef ChatConfirmHandler = Future<bool> Function();

class ChatActionExecutor {
  final BuildContext? context;
  final ApiClient? apiClient;
  final ChatActionHandler? onNavigate;
  final ChatActionHandler? onFillForm;
  final ChatActionHandler? onCallApi;
  final ChatActionHandler? onShowModal;
  final ChatConfirmHandler? onConfirm;

  ChatActionExecutor({
    this.context,
    this.apiClient,
    this.onNavigate,
    this.onFillForm,
    this.onCallApi,
    this.onShowModal,
    this.onConfirm,
  });

  Future<void> executeActions(List<ChatAction> actions,
      {bool needConfirm = true}) async {
    if (actions.isEmpty) return;
    final confirmed = await _confirmIfNeeded(needConfirm);
    if (!confirmed) return;

    for (final action in actions) {
      await _executeAction(action);
    }
  }

  Future<void> _executeAction(ChatAction action) async {
    final type = action.type?.toUpperCase();
    switch (type) {
      case 'NAVIGATE':
        if (onNavigate != null) {
          await onNavigate!(action);
        } else if (context != null && action.target != null) {
          Navigator.of(context!).pushNamed(action.target!);
        } else {
          debugPrint('NAVIGATE handler missing for action: $action');
        }
        break;
      case 'FILL_FORM':
        if (onFillForm != null) {
          await onFillForm!(action);
        } else {
          debugPrint('FILL_FORM handler missing for action: $action');
        }
        break;
      case 'CALL_API':
        if (onCallApi != null) {
          await onCallApi!(action);
        } else {
          await _callApiFallback(action);
        }
        break;
      case 'SHOW_MODAL':
        if (onShowModal != null) {
          await onShowModal!(action);
        } else {
          await _showModalFallback(action);
        }
        break;
      default:
        debugPrint('Unknown action type: $action');
    }
  }

  Future<void> _callApiFallback(ChatAction action) async {
    if (apiClient == null || action.target == null) {
      debugPrint('CALL_API fallback missing apiClient/target: $action');
      return;
    }
    await apiClient!.invokeAPI(
        action.target!, 'GET', [], null, {}, {}, null, []);
  }

  Future<void> _showModalFallback(ChatAction action) async {
    if (context == null) {
      debugPrint('SHOW_MODAL fallback missing context: $action');
      return;
    }
    await AppDialog.showCustomDialog(
      context: context!,
      title: action.label ?? '提示',
      content: Text(action.value ?? ''),
    );
  }

  Future<bool> _confirmIfNeeded(bool needConfirm) async {
    if (!needConfirm) return true;
    if (onConfirm != null) {
      return await onConfirm!();
    }
    if (context == null) return true;
    bool confirmed = false;
    await AppDialog.showConfirmDialog(
      context: context!,
      title: '确认执行',
      message: 'AI 给出了可执行动作，是否继续？',
      onConfirmed: () => confirmed = true,
    );
    return confirmed;
  }
}
