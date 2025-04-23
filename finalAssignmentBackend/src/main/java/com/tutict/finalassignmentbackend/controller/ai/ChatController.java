package com.tutict.finalassignmentbackend.controller.ai;

import com.tutict.finalassignmentbackend.service.AIChatSearchService;
import org.json.JSONObject;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;
import org.springframework.ai.chat.client.ChatClient;
import reactor.core.publisher.Flux;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/ai")
public class ChatController {
    private static final Logger LOG = Logger.getLogger(ChatController.class.getName());
    private final ChatClient chatClient;
    private final AIChatSearchService aiChatSearchService;

    public ChatController(ChatClient.Builder chatClientBuilder,
                          AIChatSearchService aiChatSearchService) {
        this.chatClient = chatClientBuilder.build();
        this.aiChatSearchService = aiChatSearchService;
    }

    @RequestMapping(value = "/chat", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter chat(
            @RequestParam(value = "message", required = false) String message,
            @RequestParam(value = "massage", required = false) String massage,
            @RequestParam(value = "webSearch", defaultValue = "false") boolean webSearch) {

        // 优先使用新的 message 参数，其次兼容旧的 massage
        String userMessage = (message != null && !message.isBlank())
                ? message
                : (massage != null ? massage : "");

        if (userMessage.isBlank()) {
            throw new IllegalArgumentException("缺少请求参数：message 或 massage 必须提供其一");
        }

        SseEmitter emitter = new SseEmitter(Long.MAX_VALUE);
        LOG.log(Level.INFO, "Chat request received: message={0}, webSearch={1}",
                new Object[]{userMessage, webSearch});

        try {
            // 构造系统提示
            String systemPrompt = "你是一个专业的交通违法查询助手。请用简洁、准确的中文回答，" +
                    "仅提供结构化输出，如编号列表或要点。";
            StringBuilder promptBuilder = new StringBuilder(systemPrompt).append("\n\n");

            if (webSearch) {
                List<Map<String, String>> results = aiChatSearchService.search(userMessage);
                StringBuilder sb = new StringBuilder();
                if (results.isEmpty()) {
                    sb.append("没找到任何相关消息");
                } else {
                    for (int i = 0; i < results.size(); i++) {
                        Map<String, String> item = results.get(i);
                        sb.append(String.format("%d. %s\n   %s\n",
                                i + 1,
                                item.getOrDefault("title", "<无标题>"),
                                item.getOrDefault("abstract", "<无摘要>")));
                    }
                }
                promptBuilder.append("以下是搜索结果：\n")
                        .append(sb)
                        .append("\n");
            }

            // 一定要在拼完所有内容后，再取 String
            promptBuilder.append("用户问题：").append(userMessage).append("\n\n");
            String finalPrompt = promptBuilder.toString();

            // 2. 把 finalPrompt 直接给模型
            Flux<String> tokenFlux = chatClient.prompt(finalPrompt)
                    .stream()
                    .content();

            // 缓冲 token，按句发送
            StringBuilder buffer = new StringBuilder();
            tokenFlux.subscribe(
                    token -> {
                        buffer.append(token);
                        if (token.matches(".*[。！？.!?]$")) {
                            sendChunk(emitter, buffer.toString());
                            buffer.setLength(0);
                        }
                    },
                    error -> {
                        LOG.log(Level.SEVERE, "Stream error: {0}", error.getMessage());
                        sendError(emitter, "Chat failed: " + error.getMessage());
                    },
                    () -> {
                        if (!buffer.isEmpty()) {
                            sendChunk(emitter, buffer.toString());
                        }
                        emitter.complete();
                        LOG.log(Level.INFO, "Stream completed for: {0}", userMessage);
                    }
            );

        } catch (Exception e) {
            LOG.log(Level.SEVERE, "Initialization error: {0}", e.getMessage());
            sendError(emitter, "Chat initialization failed: " + e.getMessage());
        }

        return emitter;
    }

    private void sendChunk(SseEmitter emitter, String text) {
        try {
            String json = "{\"message\": " + JSONObject.quote(text) + "}";
            emitter.send(SseEmitter.event()
                    .name("message")
                    .data(json, MediaType.APPLICATION_JSON));
            emitter.send(SseEmitter.event().comment("flush"));
        } catch (IOException e) {
            LOG.log(Level.WARNING, "Failed to send chunk: {0}", e.getMessage());
            emitter.completeWithError(e);
        }
    }

    private void sendError(SseEmitter emitter, String errorMsg) {
        try {
            String json = "{\"error\": " + JSONObject.quote(errorMsg) + "}";
            emitter.send(SseEmitter.event()
                    .name("error")
                    .data(json, MediaType.APPLICATION_JSON));
            emitter.send(SseEmitter.event().comment("flush"));
        } catch (IOException ignored) {
        } finally {
            emitter.completeWithError(new RuntimeException(errorMsg));
        }
    }
}
