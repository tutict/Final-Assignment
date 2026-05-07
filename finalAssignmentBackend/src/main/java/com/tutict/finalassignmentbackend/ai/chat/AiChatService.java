package com.tutict.finalassignmentbackend.ai.chat;

import com.tutict.finalassignmentbackend.ai.rag.dto.RetrievalResult;
import com.tutict.finalassignmentbackend.ai.rag.query.RagQueryRequest;
import com.tutict.finalassignmentbackend.ai.rag.query.RagQueryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;

import java.util.List;
import java.util.UUID;

@Service
public class AiChatService {

    private final ChatStreamService chatStreamService;
    private final RagQueryService ragQueryService;

    public AiChatService(ChatStreamService chatStreamService) {
        this(chatStreamService, null);
    }

    @Autowired
    public AiChatService(ChatStreamService chatStreamService, RagQueryService ragQueryService) {
        this.chatStreamService = chatStreamService;
        this.ragQueryService = ragQueryService;
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

    public List<RetrievalResult> retrieve(RagQueryRequest request) {
        if (ragQueryService == null) {
            return List.of();
        }
        return ragQueryService.query(request);
    }
}
