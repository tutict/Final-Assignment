package com.tutict.finalassignmentbackend.controller.ai;

import com.tutict.finalassignmentbackend.service.AIChatSearchService;
import org.json.JSONObject;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;
import reactor.core.publisher.Flux;

import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/ai")
public class ChatController {

    private static final Logger LOG = Logger.getLogger(ChatController.class.getName());
    private final ChatClient chatClient;

//    private final AIChatSearchService aiChatSearchService;
//    public ChatController(ChatClient.Builder chatClient, AIChatSearchService aiChatSearchService) {
//        this.chatClient = chatClient.build();
//        this.aiChatSearchService = aiChatSearchService;
//    }

    public ChatController(ChatClient.Builder chatClient) {
        this.chatClient = chatClient.build();
    }

    @RequestMapping(
            value = "/chat",
            produces = MediaType.TEXT_EVENT_STREAM_VALUE // 设置为 SSE 流式输出
    )
    public SseEmitter chat(@RequestParam(value = "massage") String message) {
        // 创建 SseEmitter 用于流式输出
        SseEmitter emitter = new SseEmitter(Long.MAX_VALUE); // 设置无超时

        try {
//            // Perform Baidu search using AIChatSearchService
//            String searchResult = aiChatSearchService.search(message).toString();
//
//            // Combine the original message with search results for the AI prompt
//            String prompt = message + "\n\nBaidu Search Results:\n" + (searchResult != null ? searchResult : "No search results found.");

            // 获取 AI 的流式响应
            Flux<String> responseFlux = chatClient.prompt(message)
                    .stream()
                    .content()
                    .map(response -> response.replaceAll("(?s)<think>.*?</think>", "").trim());

            // 订阅 Flux，逐步发送响应
            responseFlux.subscribe(
                    response -> {
                        try {
                            // 将每段响应包装为 JSON 并发送
                            String jsonResponse = "{\"message\": " + JSONObject.quote(response) + "}";
                            emitter.send(SseEmitter.event()
                                    .data(jsonResponse)
                                    .name("message"));
                        } catch (IOException e) {
                            LOG.log(Level.WARNING, "Failed to send SSE event: " + e.getMessage(), e);
                            emitter.completeWithError(e);
                        }
                    },
                    error -> {
                        // 处理错误
                        LOG.log(Level.WARNING, "Chat stream failed: " + error.getMessage(), error);
                        try {
                            String jsonError = "{\"error\": \"Chat failed: " + error.getMessage() + "\"}";
                            emitter.send(SseEmitter.event()
                                    .data(jsonError)
                                    .name("error"));
                        } catch (IOException e) {
                            LOG.log(Level.WARNING, "Failed to send error event: " + e.getMessage(), e);
                        } finally {
                            emitter.completeWithError(error);
                        }
                    },
                    () -> {
                        // 流完成
                        LOG.log(Level.INFO, "Chat stream completed for message: " + message);
                        emitter.complete();
                    }
            );
        } catch (Exception e) {
            LOG.log(Level.SEVERE, "Failed to initialize chat stream: " + e.getMessage(), e);
            try {
                String jsonError = "{\"error\": \"Chat initialization failed: " + e.getMessage() + "\"}";
                emitter.send(SseEmitter.event()
                        .data(jsonError)
                        .name("error"));
            } catch (IOException ex) {
                LOG.log(Level.WARNING, "Failed to send initial error: " + ex.getMessage(), ex);
            } finally {
                emitter.completeWithError(e);
            }
        }

        return emitter;
    }
}