package com.tutict.finalassignmentbackend.ai.chat;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
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
            @Value("${ai.chat.streaming.enabled:false}") boolean streamingEnabled
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
    public Flux<ServerSentEvent<String>> stream(@RequestBody AiChatStreamRequest request) {
        if (!streamingEnabled) {
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "AI chat streaming is disabled"
            );
        }
        return streamEventWriter.write(aiChatService.stream(request));
    }
}
