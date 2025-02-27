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
          return noMarkdownMessage; // 返回去掉了 Markdown 的纯文本
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

  // 移除 Markdown 语法的函数
  String removeMarkdown(String text) {
    // 移除粗体：**text**
    text = text.replaceAllMapped(
        RegExp(r'\*\*(.*?)\*\*'), (match) => match.group(1)!);
    // 如果有斜体 *text*，也可以移除
    text =
        text.replaceAllMapped(RegExp(r'\*(.*?)\*'), (match) => match.group(1)!);
    return text;
  }

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
