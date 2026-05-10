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

  Future<http.Response> apiAiChatGetWithHttpInfo(String message) async {
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

  Future<String?> apiAiChatGet(String message) async {
    try {
      final response = await apiAiChatGetWithHttpInfo(message);
      final decodedBody = utf8.decode(response.bodyBytes, allowMalformed: true);
      if (response.statusCode >= 400) {
        throw Exception('API request failed: $decodedBody');
      }
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
      developer.log('Error in apiAiChatGet: $error', name: 'ChatControllerApi');
      throw Exception('Failed to process AI response: $error');
    }
  }

  Future<http.Response> apiAiChatActionsGetWithHttpInfo(
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

  Future<ChatActionResponse?> apiAiChatActionsGet(
    String message,
    bool webSearch,
  ) async {
    try {
      final response = await apiAiChatActionsGetWithHttpInfo(
        message,
        webSearch,
      );
      final decodedBody = utf8.decode(response.bodyBytes, allowMalformed: true);
      if (response.statusCode >= 400) {
        throw Exception('API request failed: $decodedBody');
      }
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
        'Error in apiAiChatActionsGet: $error',
        name: 'ChatControllerApi',
      );
      throw Exception('Failed to process AI actions response: $error');
    }
  }

  Stream<String> apiAiChatStream(
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
