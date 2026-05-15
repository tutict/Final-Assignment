package com.tutict.finalassignmentbackend.ai.chat;

import com.tutict.finalassignmentbackend.dto.response.ApiResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;

@RestController
@RequestMapping("/api/ai/chat")
public class AiChatController {

    private final AiChatService aiChatService;
    private final StreamEventWriter streamEventWriter;
    private final boolean streamingEnabled;

    public AiChatController(
            AiChatService aiChatService,
            StreamEventWriter streamEventWriter,
            @Value("${ai.chat.streaming.enabled:true}") boolean streamingEnabled
    ) {
        this.aiChatService = aiChatService;
        this.streamEventWriter = streamEventWriter;
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
}
