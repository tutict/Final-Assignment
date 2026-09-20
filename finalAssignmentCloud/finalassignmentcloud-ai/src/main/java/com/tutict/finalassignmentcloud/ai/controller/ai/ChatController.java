package com.tutict.finalassignmentcloud.ai.controller.ai;

import com.tutict.finalassignmentcloud.ai.agent.AgentDraftStore;
import com.tutict.finalassignmentcloud.ai.chat.AiCallerIdentity;
import com.tutict.finalassignmentcloud.ai.chat.AiCallerIdentityFactory;
import com.tutict.finalassignmentcloud.ai.chat.AiChatService;
import com.tutict.finalassignmentcloud.ai.chat.AiChatStreamRequest;
import com.tutict.finalassignmentcloud.ai.chat.ChatStreamEvent;
import com.tutict.finalassignmentcloud.ai.chat.StreamEventWriter;
import com.tutict.finalassignmentcloud.ai.service.ChatAgent;
import com.tutict.finalassignmentcloud.model.ai.ChatActionResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;

import java.util.UUID;

@RestController
@RequestMapping("/api/ai")
@Tag(name = "AI Chat", description = "Cloud AI chat endpoints")
public class ChatController {

    private final ChatAgent chatAgent;
    private final AiChatService aiChatService;
    private final StreamEventWriter streamEventWriter;
    private final AiCallerIdentityFactory identityFactory;
    private final AgentDraftStore draftStore;

    public ChatController(
            ChatAgent chatAgent,
            AiChatService aiChatService,
            StreamEventWriter streamEventWriter,
            @Autowired(required = false) AiCallerIdentityFactory identityFactory,
            @Autowired(required = false) AgentDraftStore draftStore
    ) {
        this.chatAgent = chatAgent;
        this.aiChatService = aiChatService;
        this.streamEventWriter = streamEventWriter;
        this.identityFactory = identityFactory;
        this.draftStore = draftStore;
    }

    @GetMapping(value = "/chat", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    @Operation(summary = "Legacy streaming AI chat")
    public Flux<ChatResponse> chat(
            @RequestParam(value = "message", required = false) String message,
            @RequestParam(value = "massage", required = false) @Parameter(deprecated = true) String massage,
            @RequestParam(value = "webSearch", defaultValue = "false") boolean webSearch
    ) {
        return chatAgent.streamChat(message, massage, webSearch);
    }

    @PostMapping(
            value = "/chat/stream",
            consumes = MediaType.APPLICATION_JSON_VALUE,
            produces = MediaType.TEXT_EVENT_STREAM_VALUE
    )
    @Operation(summary = "Compatible streaming AI chat")
    public Flux<ServerSentEvent<String>> streamChat(@RequestBody AiChatStreamRequest request) {
        AiCallerIdentity identity = identityFactory == null
                ? AiCallerIdentity.anonymous()
                : identityFactory.capture();
        String sessionKey = request == null || request.sessionKey() == null || request.sessionKey().isBlank()
                ? UUID.randomUUID().toString()
                : request.sessionKey().trim();
        if (draftStore != null && !draftStore.bindSession(identity.userKey(), sessionKey)) {
            String messageId = UUID.randomUUID().toString();
            return streamEventWriter.write(Flux.just(
                    ChatStreamEvent.error(sessionKey, messageId, "不能使用其他用户的会话")
            ));
        }
        AiChatStreamRequest normalized = new AiChatStreamRequest(
                request == null ? null : request.message(),
                sessionKey,
                request == null ? null : request.metadata()
        );
        return streamEventWriter.write(aiChatService.stream(normalized, identity));
    }

    @GetMapping(value = "/chat/actions", produces = MediaType.APPLICATION_JSON_VALUE)
    @Operation(summary = "Get structured AI actions")
    public ChatActionResponse chatActions(
            @RequestParam(value = "message", required = false) String message,
            @RequestParam(value = "massage", required = false) @Parameter(deprecated = true) String massage,
            @RequestParam(value = "webSearch", defaultValue = "false") boolean webSearch
    ) {
        return chatAgent.chatWithActions(message, massage, webSearch);
    }
}
