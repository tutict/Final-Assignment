import 'dart:convert';
import 'dart:developer' as developer;

import 'package:final_assignment_front/features/ai/ai_chat_api.dart';
import 'package:final_assignment_front/features/ai/ai_stream_event.dart';
import 'package:final_assignment_front/features/model/chat_action_response.dart';
import 'package:final_assignment_front/features/model/chat_response.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:http/http.dart' as http;

final ApiClient defaultApiClient = ApiClient();

class ChatControllerApi with BaseApiClient {
  ChatControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  @override
  final ApiClient apiClient;

  Future<http.Response> _sendChatMessageWithHttpInfo(String message) async {
    final queryParams = [QueryParam('message', message)];
    final headerParams = await getHeaders();

    return apiClient.invokeAPI(
      '/api/ai/chat',
      'GET',
      queryParams,
      '',
      headerParams,
      {},
      null,
      [],
    );
  }

  /// 发送单轮 AI 聊天消息并返回清洗后的文本回复。
  ///
  /// [message] 用户输入的自然语言消息。
  ///
  /// 返回后端 `message` 字段对应的文本；空响应会返回兜底提示。
  ///
  /// 抛出 [Exception]：当 HTTP 响应非 2xx、响应结构无效或解析失败时。
  ///
  /// 对应接口：GET /api/ai/chat
  Future<String?> sendChatMessage(String message) async {
    try {
      final response = await _sendChatMessageWithHttpInfo(message);
      final decodedBody = utf8.decode(response.bodyBytes, allowMalformed: true);
      if (decodedBody.isEmpty) {
        return 'AI returned an empty response.';
      }

      final jsonResponse = jsonDecode(decodedBody);
      if (jsonResponse is Map<String, dynamic> &&
          jsonResponse['message'] != null) {
        return removeMarkdown(jsonResponse['message'].toString());
      }
      return 'No valid response from AI.';
    } catch (error) {
      developer.log('Error in sendChatMessage: $error',
          name: 'ChatControllerApi');
      throw Exception('Failed to process AI response: $error');
    }
  }

  Future<http.Response> _getChatActionsWithHttpInfo(
    String message,
    bool webSearch,
  ) async {
    final queryParams = [
      QueryParam('message', message),
      QueryParam('webSearch', webSearch.toString()),
    ];
    final headerParams = await getHeaders();

    return apiClient.invokeAPI(
      '/api/ai/chat/actions',
      'GET',
      queryParams,
      '',
      headerParams,
      {},
      null,
      [],
    );
  }

  /// 获取 AI 对话的结构化动作建议。
  ///
  /// [message] 用户输入的自然语言消息。
  /// [webSearch] 是否允许后端执行联网搜索。
  ///
  /// 返回 [ChatActionResponse]；空响应或非对象响应时返回 `null`。
  ///
  /// 抛出 [Exception]：当 HTTP 响应非 2xx 或响应解析失败时。
  ///
  /// 对应接口：GET /api/ai/chat/actions
  Future<ChatActionResponse?> getChatActions(
    String message,
    bool webSearch,
  ) async {
    try {
      final response = await _getChatActionsWithHttpInfo(
        message,
        webSearch,
      );
      final decodedBody = utf8.decode(response.bodyBytes, allowMalformed: true);
      if (decodedBody.isEmpty) {
        return null;
      }

      final jsonResponse = jsonDecode(decodedBody);
      if (jsonResponse is Map<String, dynamic>) {
        return ChatActionResponse.fromJson(jsonResponse);
      }
      return null;
    } catch (error) {
      developer.log(
        'Error in getChatActions: $error',
        name: 'ChatControllerApi',
      );
      throw Exception('Failed to process AI actions response: $error');
    }
  }

  /// @streamApi
  /// 建立 AI 聊天 SSE 流并逐段产出文本 token。
  ///
  /// [message] 用户输入的自然语言消息。
  /// [webSearch] 是否将联网搜索意图写入流式请求 metadata。
  /// [cancelToken] 调用方用于主动取消底层 SSE/流式连接的令牌。
  ///
  /// 返回一个 [Stream]，每个事件产出清洗后的文本片段；`done` 事件会结束流，
  /// `keepalive`、`session`、`usage` 和未知事件不会向 UI 产出文本。
  ///
  /// 调用方应通过 `await for`、`listen` 或订阅取消来监听和关闭连接；传入
  /// [cancelToken] 时，可由调用方在页面销毁或用户停止生成时取消底层请求。
  ///
  /// 抛出 [Exception]：当后端返回 error 事件或底层流式请求失败时。
  ///
  /// 对应接口：POST /api/ai/chat/stream
  Stream<String> streamChat(
    String message,
    bool webSearch, {
    CancelToken? cancelToken,
  }) async* {
    final typedApi = AiChatApi(apiClient: apiClient);

    await for (final event in typedApi.streamChat(
      message: message,
      metadata: {'webSearchRequested': webSearch},
      cancelToken: cancelToken,
    )) {
      switch (event.type) {
        case AiStreamEventType.token:
          final token = removeMarkdown(event.token ?? '');
          if (token.isNotEmpty) {
            yield token;
          }
          break;
        case AiStreamEventType.done:
          return;
        case AiStreamEventType.error:
          throw Exception(event.message ?? 'AI stream failed');
        case AiStreamEventType.keepalive:
          break;
        case AiStreamEventType.session:
        case AiStreamEventType.usage:
        case AiStreamEventType.unknown:
          break;
      }
    }
  }

  /// 清洗 AI 回复中的 Markdown 标记并保留 `<think>` 语义占位。
  ///
  /// [text] 后端返回的原始 AI 文本，可能包含 Markdown 加粗、标题、斜体、
  /// 删除线或 `<think>` 推理片段。
  ///
  /// 返回去除常见 Markdown 标记后的纯文本；该方法只处理入参字符串，
  /// 不访问网络、不修改对象状态，也不会产生 UI 副作用。
  ///
  /// 该清洗逻辑放在 API 层，是为了让普通请求和 [streamChat] 的流式 token
  /// 使用同一套文本规范，避免多个 UI 页面重复实现不一致的 Markdown 处理。
  String removeMarkdown(String text) {
    text = text.replaceAllMapped(
      RegExp(r'<think>([\s\S]*?)</think>'),
      (match) => '[THINK]${match.group(1)}[/THINK]',
    );
    text = text.replaceAll(RegExp(r'</?think>'), '');
    text = text.replaceAllMapped(
      RegExp(r'\*\*(.*?)\*\*'),
      (match) => match.group(1)!,
    );
    text = text.replaceAllMapped(
      RegExp(r'\*(.*?)\*'),
      (match) => match.group(1)!,
    );
    text = text.replaceAllMapped(
      RegExp(r'##(.*?)##'),
      (match) => match.group(1)!,
    );
    text = text.replaceAllMapped(
      RegExp(r'_(.*?)_'),
      (match) => match.group(1)!,
    );
    text = text.replaceAllMapped(
      RegExp(r'-(.*?)-'),
      (match) => match.group(1)!,
    );
    text = text.replaceAllMapped(
      RegExp(r'###(.*?)###'),
      (match) => match.group(1)!,
    );
    return text.trim();
  }

  /// @realtimeApi
  /// 通过 WebSocket eventbus 获取 AI 聊天响应示例数据。
  ///
  /// 返回 [ChatResponse]；当 eventbus result 为空时返回 `null`。
  ///
  /// 抛出 [ApiException]：当 WebSocket 响应包含 `error` 字段时。
  ///
  /// 对应实时动作：AiService.getChatResponse
  Future<ChatResponse?> eventbusAiChatGet() async {
    final msg = {
      'service': 'AiService',
      'action': 'getChatResponse',
      'args': [],
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey('error')) {
      throw ApiException(400, respMap['error']);
    }
    if (respMap['result'] != null) {
      final resultMap = respMap['result'] as Map<String, dynamic>;
      return ChatResponse.fromJson(resultMap);
    }
    return null;
  }
}
