import 'dart:convert';
import 'dart:developer' as developer;

import 'package:final_assignment_front/features/model/chat_response.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final ApiClient defaultApiClient = ApiClient();

class ChatControllerApi {
  final ApiClient apiClient;

  ChatControllerApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  // 非流式 GET 请求（保留原有方法）
  Future<http.Response> apiAiChatGetWithHttpInfo(String message) async {
    Object postBody = '';
    String path = "/api/ai/chat".replaceAll("{format}", "json");
    List<QueryParam> queryParams = [QueryParam("massage", message)];
    Map<String, String> headerParams = {};

    final prefs = await SharedPreferences.getInstance();
    String? jwtToken = prefs.getString('jwtToken');
    if (jwtToken != null) {
      headerParams['Authorization'] = 'Bearer $jwtToken';
      developer.log("JWT Token: $jwtToken", name: 'ChatControllerApi');
    } else {
      developer.log("No JWT token found in SharedPreferences",
          name: 'ChatControllerApi');
    }

    return await apiClient.invokeAPI(
        path, 'GET', queryParams, postBody, headerParams, {}, null, []);
  }

  Future<String?> apiAiChatGet(String message) async {
    try {
      http.Response response = await apiAiChatGetWithHttpInfo(message);
      String decodedBody =
          utf8.decode(response.bodyBytes, allowMalformed: true);
      developer.log("Decoded response body: $decodedBody",
          name: 'ChatControllerApi');

      if (response.statusCode >= 400) {
        throw Exception("API request failed: $decodedBody");
      }
      if (decodedBody.isNotEmpty) {
        final jsonResponse = jsonDecode(decodedBody);
        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse['message'] != null) {
          String rawMessage = jsonResponse['message'].toString();
          String noMarkdownMessage = removeMarkdown(rawMessage);
          developer.log("Processed AI response: $noMarkdownMessage",
              name: 'ChatControllerApi');
          return noMarkdownMessage;
        }
        developer.log("No valid 'message' field in response: $decodedBody",
            name: 'ChatControllerApi');
        return "No valid response from AI.";
      }
      developer.log("Empty response body", name: 'ChatControllerApi');
      return "AI returned an empty response.";
    } catch (e) {
      developer.log("Error in apiAiChatGet: $e", name: 'ChatControllerApi');
      throw Exception("Failed to process AI response: $e");
    }
  }

// 流式 GET 请求方法
  Stream<String> apiAiChatStream(String message) async* {
    final prefs = await SharedPreferences.getInstance();
    String? jwtToken = prefs.getString('jwtToken');
    Map<String, String> headers = {
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
    };

    if (jwtToken != null) {
      headers['Authorization'] = 'Bearer $jwtToken';
      developer.log("JWT Token for stream: $jwtToken",
          name: 'ChatControllerApi');
    } else {
      developer.log("No JWT token found for stream", name: 'ChatControllerApi');
    }

    final uri = Uri.parse('http://localhost:8080/api/ai/chat?massage=$message');
    final request = http.Request('GET', uri)..headers.addAll(headers);

    final client = http.Client();
    try {
      final response = await client.send(request);

      if (response.statusCode >= 400) {
        developer.log(
            "Stream request failed with status: ${response.statusCode}",
            name: 'ChatControllerApi');
        throw Exception('Stream request failed: ${response.statusCode}');
      }

      StringBuffer dataBuffer = StringBuffer();
      await for (final data in response.stream.transform(utf8.decoder)) {
        dataBuffer.write(data);

        String bufferedData = dataBuffer.toString();

        // 按行分割缓冲数据
        List<String> lines = bufferedData.split('\n');
        for (int i = 0; i < lines.length - 1; i++) {
          String line = lines[i].trim();
          if (line.startsWith('data:')) {
            int colonIndex = line.indexOf(':');
            if (colonIndex != -1) {
              String jsonString = line.substring(colonIndex + 1).trim();
              try {
                final jsonData = jsonDecode(jsonString);
                if (jsonData is Map<String, dynamic> &&
                    jsonData['message'] != null) {
                  String rawMessage = jsonData['message'].toString();
                  String noMarkdownMessage = removeMarkdown(rawMessage);
                  if (noMarkdownMessage.isNotEmpty) {
                    yield noMarkdownMessage;
                  }
                }
              } catch (e) {
                developer.log(
                    "Failed to parse SSE chunk: '$jsonString', error: $e",
                    name: 'ChatControllerApi');
              }
            }
          }
        }

        // 保留最后一行（可能不完整）
        if (lines.last.isNotEmpty) {
          dataBuffer = StringBuffer(lines.last);
        } else {
          dataBuffer.clear();
        }
      }
    } catch (e) {
      developer.log("Stream error: $e", name: 'ChatControllerApi');
      rethrow;
    } finally {
      client.close();
    }
  }

// 移除 Markdown 语法的函数
  String removeMarkdown(String text) {
    // 移除 <think>...</think> 标签，包括跨行情况
    text = text.replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '');
    // 移除单独的 <think> 或 </think>
    text = text.replaceAll(RegExp(r'</?think>'), '');
    // 其他 Markdown 处理
    text = text.replaceAllMapped(
        RegExp(r'\*\*(.*?)\*\*'), (match) => match.group(1)!);
    text =
        text.replaceAllMapped(RegExp(r'\*(.*?)\*'), (match) => match.group(1)!);
    text =
        text.replaceAllMapped(RegExp(r'##(.*?)##'), (match) => match.group(1)!);
    text =
        text.replaceAllMapped(RegExp(r'_(.*?)_'), (match) => match.group(1)!);
    return text;
  }

  // WebSocket 方法（保留）
  Future<ChatResponse?> eventbusAiChatGet() async {
    final msg = {
      "service": "AiService",
      "action": "getChatResponse",
      "args": []
    };
    final respMap = await apiClient.sendWsMessage(msg);
    if (respMap.containsKey("error")) {
      throw ApiException(400, respMap["error"]);
    }
    if (respMap["result"] != null) {
      final resultMap = respMap["result"] as Map<String, dynamic>;
      return ChatResponse.fromJson(resultMap);
    }
    return null;
  }
}
