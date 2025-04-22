package com.tutict.finalassignmentbackend.controller.ai;

import com.tutict.finalassignmentbackend.service.AIChatSearchService;
import org.jetbrains.annotations.NotNull;
import org.json.JSONObject;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;
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

    public ChatController(ChatClient.Builder chatClient, AIChatSearchService aiChatSearchService) {
        this.chatClient = chatClient.build();
        this.aiChatSearchService = aiChatSearchService;
    }

    @RequestMapping(
            value = "/chat",
            produces = MediaType.TEXT_EVENT_STREAM_VALUE
    )
    public SseEmitter chat(@RequestParam(value = "massage") String message) {
        SseEmitter emitter = new SseEmitter(Long.MAX_VALUE);

        try {
            // Fetch search results
            List<Map<String, String>> searchResults = aiChatSearchService.search(message);

            String prompt = getString(message, searchResults);

            // Stream AI response
            Flux<String> responseFlux = chatClient.prompt(prompt)
                    .stream()
                    .content()
                    .map(response -> response.replaceAll("(?s)<think>.*?</think>", "").trim());

            responseFlux.subscribe(
                    response -> {
                        try {
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

    private static @NotNull String getString(String message, List<Map<String, String>> searchResults) {
        StringBuilder searchResultBuilder = new StringBuilder();
        if (searchResults.isEmpty()) {
            searchResultBuilder.append("没找到任何相关消息");
        } else {
            for (int i = 0; i < searchResults.size(); i++) {
                Map<String, String> item = searchResults.get(i);
                String title = item.getOrDefault("title", "<无标题>");
                String abstractText = item.getOrDefault("abstract", "<无摘要>");
                searchResultBuilder.append(String.format("%d. %s\n   %s\n", i + 1, title, abstractText));
            }
        }

        String prompt = message + "\n\n在百度搜寻到的资料:\n" + searchResultBuilder.toString();
        return prompt;
    }
}