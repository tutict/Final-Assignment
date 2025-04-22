package com.tutict.finalassignmentbackend.controller.ai;

import com.tutict.finalassignmentbackend.service.AIChatSearchService;
import jakarta.annotation.PreDestroy;
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
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.logging.Level;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api/ai")
public class ChatController {
    private static final Logger LOG = Logger.getLogger(ChatController.class.getName());
    private final ChatClient chatClient;
    private final AIChatSearchService aiChatSearchService;
    private final ExecutorService executor = Executors.newCachedThreadPool();

    public ChatController(ChatClient.Builder chatClientBuilder,
                          AIChatSearchService aiChatSearchService) {
        this.chatClient = chatClientBuilder.build();
        this.aiChatSearchService = aiChatSearchService;
    }

    @RequestMapping(value = "/chat", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter chat(
            // 同时接收前端的 oldParam=massage 和 新Param=message
            @RequestParam(value = "message", required = false) String message,
            @RequestParam(value = "massage", required = false) String massage,
            @RequestParam(value = "webSearch", defaultValue = "false") boolean webSearch) {

        // 优先用新参数，没有再用旧的
        String userMessage = (message != null && !message.isBlank())
                ? message
                : (massage != null ? massage : "");

        if (userMessage.isBlank()) {
            throw new IllegalArgumentException("缺少请求参数：message 或 massage 必须提供其一");
        }

        SseEmitter emitter = new SseEmitter(Long.MAX_VALUE);

        try {
            // 异步启动 Web 搜索
            CompletableFuture<List<Map<String, String>>> searchFuture = webSearch
                    ? CompletableFuture.supplyAsync(() -> aiChatSearchService.search(userMessage), executor)
                    : CompletableFuture.completedFuture(List.of());

            // 构造 Prompt
            String systemPrompt = "你是一个专业的交通违法查询助手。请用简洁、准确的中文回答，" +
                    "包含适当的标点符号，确保句子通顺、完整。";
            String initialPrompt = systemPrompt + "\n\n用户问题: " + userMessage +
                    (webSearch ? "\n\n正在搜索相关资料，请稍候...\n" : "\n\n");

            // 获取模型的 token 流
            Flux<String> tokenFlux = chatClient.prompt(initialPrompt)
                    .stream()
                    .content();

            // 用 buffer 累积 token，按句发送
            StringBuilder buffer = new StringBuilder();
            tokenFlux.subscribe(
                    token -> {
                        buffer.append(token);
                        if (token.matches(".*[。！？\\.!?]$")) {
                            sendChunk(emitter, buffer.toString());
                            buffer.setLength(0);
                        }
                    },
                    error -> {
                        sendError(emitter, "Chat failed: " + error.getMessage());
                    },
                    () -> {
                        if (!buffer.isEmpty()) {
                            sendChunk(emitter, buffer.toString());
                        }
                        emitter.complete();
                        LOG.log(Level.INFO, "Chat stream completed for message: {0}", userMessage);
                    }
            );

            // 处理 Web 搜索结果
            if (webSearch) {
                searchFuture.thenAccept(results -> {
                    StringBuilder sb = new StringBuilder();
                    if (results.isEmpty()) {
                        sb.append("没找到任何相关消息");
                    } else {
                        for (int i = 0; i < results.size(); i++) {
                            Map<String, String> item = results.get(i);
                            String title = item.getOrDefault("title", "<无标题>");
                            String abs  = item.getOrDefault("abstract", "<无摘要>");
                            sb.append(String.format("%d. %s\n   %s\n", i + 1, title, abs));
                        }
                    }
                    sendSearch(emitter, sb.toString());
                }).exceptionally(ex -> {
                    sendError(emitter, "Search failed: " + ex.getMessage());
                    return null;
                });
            }

        } catch (Exception e) {
            LOG.log(Level.SEVERE, "Failed to initialize chat stream: " + e.getMessage(), e);
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
            LOG.log(Level.WARNING, "Failed to send SSE chunk: " + e.getMessage(), e);
            emitter.completeWithError(e);
        }
    }

    private void sendSearch(SseEmitter emitter, String text) {
        try {
            String json = "{\"searchResults\": " + JSONObject.quote(text) + "}";
            emitter.send(SseEmitter.event()
                    .name("search")
                    .data(json, MediaType.APPLICATION_JSON));
            emitter.send(SseEmitter.event().comment("flush"));
        } catch (IOException e) {
            LOG.log(Level.WARNING, "Failed to send search SSE: " + e.getMessage(), e);
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
        } catch (IOException e) {
            LOG.log(Level.WARNING, "Failed to send error SSE: " + e.getMessage(), e);
        } finally {
            emitter.completeWithError(new RuntimeException(errorMsg));
        }
    }

    @PreDestroy
    public void shutdown() {
        executor.shutdown();
        try {
            if (!executor.awaitTermination(10, java.util.concurrent.TimeUnit.SECONDS)) {
                executor.shutdownNow();
            }
        } catch (InterruptedException e) {
            executor.shutdownNow();
            Thread.currentThread().interrupt();
        }
    }
}
