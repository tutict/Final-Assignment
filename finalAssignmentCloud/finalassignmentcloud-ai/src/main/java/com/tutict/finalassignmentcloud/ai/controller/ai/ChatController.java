package com.tutict.finalassignmentcloud.ai.controller.ai;

import com.tutict.finalassignmentcloud.ai.service.ChatAgent;
import com.tutict.finalassignmentcloud.model.ai.ChatActionResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.http.MediaType;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/ai")
@Tag(name = "AI Chat", description = "Cloud AI chat endpoints")
public class ChatController {

    private final ChatAgent chatAgent;

    public ChatController(ChatAgent chatAgent) {
        this.chatAgent = chatAgent;
    }

    @GetMapping(value = "/chat", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    @Operation(
            summary = "Legacy streaming AI chat",
            description = "Legacy GET endpoint. New clients should use POST /api/ai/chat/stream."
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Streaming response"),
            @ApiResponse(responseCode = "400", description = "Missing message/massage parameter"),
            @ApiResponse(responseCode = "500", description = "Internal server error")
    })
    public Flux<ChatResponse> chat(
            @RequestParam(value = "message", required = false)
            @Parameter(description = "User message")
            String message,
            @RequestParam(value = "massage", required = false)
            @Parameter(description = "Deprecated legacy parameter", deprecated = true)
            String massage,
            @RequestParam(value = "webSearch", defaultValue = "false")
            @Parameter(description = "Enable web search")
            boolean webSearch
    ) {
        return chatAgent.streamChat(message, massage, webSearch);
    }

    @PostMapping(
            value = "/chat/stream",
            consumes = MediaType.APPLICATION_JSON_VALUE,
            produces = MediaType.TEXT_EVENT_STREAM_VALUE
    )
    @Operation(
            summary = "Compatible streaming AI chat",
            description = "POST endpoint compatible with the main backend SSE contract."
    )
    public Flux<ServerSentEvent<ChatStreamEvent>> streamChat(
            @RequestBody AiChatStreamRequest request
    ) {
        String sessionKey = request == null || request.sessionKey() == null || request.sessionKey().isBlank()
                ? UUID.randomUUID().toString()
                : request.sessionKey().trim();
        String messageId = UUID.randomUUID().toString();
        if (request == null || request.normalizedMessage().isBlank()) {
            return Flux.just(toSse(ChatStreamEvent.error(sessionKey, messageId, "message is required")));
        }
        String message = messageWithConversationWindow(request);

        return chatAgent.streamChat(message, null, request.isWebSearchEnabled(), metadataWithRagQuery(request))
                .map(ChatController::extractResponseText)
                .filter(token -> token != null && !token.isBlank())
                .map(token -> toSse(ChatStreamEvent.token(sessionKey, messageId, token)))
                .concatWithValues(toSse(ChatStreamEvent.done(sessionKey, messageId)))
                .onErrorResume(error -> Flux.just(toSse(ChatStreamEvent.error(
                        sessionKey,
                        messageId,
                        error.getMessage()
                ))));
    }

    @GetMapping(value = "/chat/actions", produces = MediaType.APPLICATION_JSON_VALUE)
    @Operation(
            summary = "Get structured AI actions",
            description = "Returns JSON page-action suggestions for the frontend."
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Action response"),
            @ApiResponse(responseCode = "400", description = "Missing message/massage parameter"),
            @ApiResponse(responseCode = "500", description = "Internal server error")
    })
    public ChatActionResponse chatActions(
            @RequestParam(value = "message", required = false)
            @Parameter(description = "User message")
            String message,
            @RequestParam(value = "massage", required = false)
            @Parameter(description = "Deprecated legacy parameter", deprecated = true)
            String massage,
            @RequestParam(value = "webSearch", defaultValue = "false")
            @Parameter(description = "Enable web search")
            boolean webSearch
    ) {
        return chatAgent.chatWithActions(message, massage, webSearch);
    }

    private static ServerSentEvent<ChatStreamEvent> toSse(ChatStreamEvent event) {
        return ServerSentEvent.<ChatStreamEvent>builder(event)
                .event(event.type())
                .build();
    }

    private static String extractResponseText(ChatResponse response) {
        if (response == null || response.getResult() == null || response.getResult().getOutput() == null) {
            return "";
        }
        String text = response.getResult().getOutput().getText();
        return text == null ? "" : text;
    }

    private static String messageWithConversationWindow(AiChatStreamRequest request) {
        String message = request.normalizedMessage();
        List<String> window = request.conversationWindow();
        if (window.isEmpty()) {
            return message;
        }
        StringBuilder builder = new StringBuilder("Recent conversation:\n");
        int index = 1;
        for (String turn : window) {
            builder.append(index++)
                    .append(". ")
                    .append(turn)
                    .append("\n");
        }
        builder.append("\nCurrent user message:\n")
                .append(message);
        return builder.toString();
    }

    private static Map<String, Object> metadataWithRagQuery(AiChatStreamRequest request) {
        if (request == null) {
            return Map.of();
        }
        Map<String, Object> metadata = request.metadata();
        if (metadata.containsKey("ragQuery") || metadata.containsKey("rag_query")) {
            return metadata;
        }
        Map<String, Object> enriched = new LinkedHashMap<>(metadata);
        enriched.put("ragQuery", request.normalizedMessage());
        return Map.copyOf(enriched);
    }

    public record AiChatStreamRequest(
            String message,
            String sessionKey,
            Map<String, Object> metadata
    ) {
        public AiChatStreamRequest {
            if (metadata == null) {
                metadata = Map.of();
            }
        }

        public String normalizedMessage() {
            return message == null ? "" : message.trim();
        }

        public boolean isWebSearchEnabled() {
            Object val = metadata.get("webSearchRequested");
            if (val == null) {
                val = metadata.get("webSearch");
            }
            if (val == null) {
                val = metadata.get("web_search");
            }
            if (val instanceof Boolean enabled) {
                return enabled;
            }
            if (val instanceof String text) {
                return Boolean.parseBoolean(text);
            }
            return false;
        }

        public List<String> conversationWindow() {
            Object value = metadata.get("conversationWindow");
            if (value == null) {
                value = metadata.get("conversation_window");
            }
            if (value == null) {
                return List.of();
            }
            if (value instanceof Collection<?> collection) {
                List<String> turns = new ArrayList<>();
                for (Object item : collection) {
                    String turn = conversationTurn(item);
                    if (!turn.isBlank()) {
                        turns.add(turn);
                    }
                }
                return List.copyOf(turns);
            }
            String turn = value.toString().trim();
            return turn.isBlank() ? List.of() : List.of(turn);
        }

        private static String conversationTurn(Object item) {
            if (item == null) {
                return "";
            }
            if (item instanceof Map<?, ?> map) {
                Object role = map.get("role");
                Object content = map.get("content");
                if (content != null && !content.toString().isBlank()) {
                    String roleText = role == null || role.toString().isBlank()
                            ? "message"
                            : role.toString().trim();
                    return roleText + ": " + content.toString().trim();
                }
            }
            return item.toString().trim();
        }
    }

    public record ChatStreamEvent(
            String type,
            String sessionKey,
            String messageId,
            String token,
            Object payload,
            Instant timestamp
    ) {
        public static ChatStreamEvent token(String sessionKey, String messageId, String token) {
            return new ChatStreamEvent("token", sessionKey, messageId, token, null, Instant.now());
        }

        public static ChatStreamEvent done(String sessionKey, String messageId) {
            return new ChatStreamEvent("done", sessionKey, messageId, null, null, Instant.now());
        }

        public static ChatStreamEvent error(String sessionKey, String messageId, String message) {
            String errorMessage = message == null || message.isBlank() ? "AI stream failed" : message;
            return new ChatStreamEvent(
                    "error",
                    sessionKey,
                    messageId,
                    null,
                    Map.of("message", errorMessage),
                    Instant.now()
            );
        }
    }
}
