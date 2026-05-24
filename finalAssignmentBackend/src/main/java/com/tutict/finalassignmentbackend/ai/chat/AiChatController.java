package com.tutict.finalassignmentbackend.ai.chat;

import com.tutict.finalassignmentbackend.dto.response.ApiResponse;
import com.tutict.finalassignmentbackend.model.ai.ChatActionResponse;
import com.tutict.finalassignmentbackend.service.ai.ChatAgent;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;

@RestController
@RequestMapping("/api/ai/chat")
public class AiChatController {

    private final AiChatService aiChatService;
    private final StreamEventWriter streamEventWriter;
    private final ChatAgent chatAgent;
    private final boolean streamingEnabled;

    public AiChatController(
            AiChatService aiChatService,
            StreamEventWriter streamEventWriter,
            ChatAgent chatAgent,
            @Value("${ai.chat.streaming.enabled:true}") boolean streamingEnabled
    ) {
        this.aiChatService = aiChatService;
        this.streamEventWriter = streamEventWriter;
        this.chatAgent = chatAgent;
        this.streamingEnabled = streamingEnabled;
    }

    @PostMapping(
            value = "/stream",
            consumes = MediaType.APPLICATION_JSON_VALUE,
            produces = MediaType.TEXT_EVENT_STREAM_VALUE
    )
    public ResponseEntity<?> stream(@RequestBody AiChatStreamRequest request) {
        if (!streamingEnabled) {
            return ResponseEntity.status(503)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(ApiResponse.error("SERVICE_UNAVAILABLE", "AI \u6d41\u5f0f\u670d\u52a1\u6682\u672a\u542f\u7528"));
        }
        Flux<ServerSentEvent<String>> stream = streamEventWriter.write(aiChatService.stream(request));
        return ResponseEntity.ok()
                .contentType(MediaType.TEXT_EVENT_STREAM)
                .body(stream);
    }

    @Deprecated
    @GetMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<Void>> chatLegacy(
            @RequestParam(value = "message", required = false) String message
    ) {
        return ResponseEntity.status(410)
                .body(ApiResponse.error("GONE", "This endpoint is deprecated. Use POST /api/ai/chat/stream."));
    }

    @GetMapping(value = "/actions", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<ChatActionResponse>> getChatActions(
            @RequestParam(value = "message", required = false) String message,
            @RequestParam(value = "massage", required = false) String massage,
            @RequestParam(value = "webSearch", defaultValue = "false") boolean webSearch
    ) {
        return ResponseEntity.ok(ApiResponse.ok(chatAgent.chatWithActions(message, massage, webSearch)));
    }
}
