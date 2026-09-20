package com.tutict.finalassignmentcloud.ai.chat;

import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;

import java.util.UUID;

@Service
public class AiChatService {

    private final ChatPipeline chatPipeline;

    public AiChatService(ChatPipeline chatPipeline) {
        this.chatPipeline = chatPipeline;
    }

    public Flux<ChatStreamEvent> stream(AiChatStreamRequest request) {
        return stream(request, AiCallerIdentity.anonymous());
    }

    public Flux<ChatStreamEvent> stream(AiChatStreamRequest request, AiCallerIdentity identity) {
        if (request == null || !request.hasMessage()) {
            return Flux.just(ChatStreamEvent.error(
                    request == null ? null : request.sessionKey(),
                    UUID.randomUUID().toString(),
                    "message is required"
            ));
        }
        return chatPipeline.stream(request, identity);
    }
}
