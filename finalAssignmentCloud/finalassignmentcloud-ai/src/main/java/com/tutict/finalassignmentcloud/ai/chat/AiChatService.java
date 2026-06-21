package com.tutict.finalassignmentcloud.ai.chat;

import com.tutict.finalassignmentcloud.ai.rag.dto.RetrievalResult;
import com.tutict.finalassignmentcloud.ai.rag.query.RagQueryRequest;
import com.tutict.finalassignmentcloud.ai.rag.query.RagQueryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;

import java.util.List;
import java.util.UUID;

@Service
public class AiChatService {

    private final ChatPipeline chatPipeline;
    private final RagQueryService ragQueryService;

    public AiChatService(ChatStreamService chatStreamService) {
        this(new ChatPipeline(chatStreamService), (RagQueryService) null);
    }

    @Autowired
    public AiChatService(ChatPipeline chatPipeline, ObjectProvider<RagQueryService> ragQueryService) {
        this(chatPipeline, ragQueryService == null ? null : ragQueryService.getIfAvailable());
    }

    AiChatService(ChatPipeline chatPipeline, RagQueryService ragQueryService) {
        this.chatPipeline = chatPipeline;
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
        return chatPipeline.stream(normalizedRequest);
    }

    public List<RetrievalResult> retrieve(RagQueryRequest request) {
        if (ragQueryService == null) {
            return List.of();
        }
        return ragQueryService.query(request);
    }
}
