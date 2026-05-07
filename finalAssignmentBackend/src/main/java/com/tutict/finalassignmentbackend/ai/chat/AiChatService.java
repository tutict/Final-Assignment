package com.tutict.finalassignmentbackend.ai.chat;

import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;

import java.util.UUID;

@Service
public class AiChatService {

    private final ChatStreamService chatStreamService;

    public AiChatService(ChatStreamService chatStreamService) {
        this.chatStreamService = chatStreamService;
    }

    public Flux<ChatStreamEvent> stream(AiChatStreamRequest request) {
        if (request == null || !request.hasMessage()) {
            return Flux.just(ChatStreamEvent.error(
                    null,
                    UUID.randomUUID().toString(),
                    "message is required"
            ));
        }

        AiChatStreamRequest normalizedRequest = new AiChatStreamRequest(
                request.normalizedMessage(),
                request.sessionKey(),
                request.metadata()
        );
        return chatStreamService.stream(normalizedRequest);
    }
}
