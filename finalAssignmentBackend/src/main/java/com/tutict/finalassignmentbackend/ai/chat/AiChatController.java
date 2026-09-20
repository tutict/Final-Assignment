package com.tutict.finalassignmentbackend.ai.chat;

import com.tutict.finalassignmentbackend.ai.agent.AgentDraftStore;
import com.tutict.finalassignmentbackend.dto.response.ApiResponse;
import com.tutict.finalassignmentbackend.model.ai.ChatActionResponse;
import com.tutict.finalassignmentbackend.service.ai.ChatAgent;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
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

import java.util.UUID;

@RestController
@RequestMapping("/api/ai/chat")
public class AiChatController {

    private final AiChatService aiChatService;
    private final StreamEventWriter streamEventWriter;
    private final ChatAgent chatAgent;
    private final boolean streamingEnabled;
    private final AiCallerIdentityFactory identityFactory;
    private final AiUserStreamLimiter userStreamLimiter;
    private final AgentDraftStore draftStore;

    public AiChatController(
            AiChatService aiChatService,
            StreamEventWriter streamEventWriter,
            ChatAgent chatAgent,
            @Value("${ai.chat.streaming.enabled:true}") boolean streamingEnabled
    ) {
        this(aiChatService, streamEventWriter, chatAgent, streamingEnabled, null, null, null);
    }

    @Autowired
    public AiChatController(
            AiChatService aiChatService,
            StreamEventWriter streamEventWriter,
            ChatAgent chatAgent,
            @Value("${ai.chat.streaming.enabled:true}") boolean streamingEnabled,
            @Autowired(required = false) AiCallerIdentityFactory identityFactory,
            @Autowired(required = false) AiUserStreamLimiter userStreamLimiter,
            @Autowired(required = false) AgentDraftStore draftStore
    ) {
        this.aiChatService = aiChatService;
        this.streamEventWriter = streamEventWriter;
        this.chatAgent = chatAgent;
        this.streamingEnabled = streamingEnabled;
        this.identityFactory = identityFactory;
        this.userStreamLimiter = userStreamLimiter;
        this.draftStore = draftStore;
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
        AiCallerIdentity identity = identityFactory == null
                ? AiCallerIdentity.anonymous()
                : identityFactory.capture();
        String sessionKey = request == null || request.sessionKey() == null || request.sessionKey().isBlank()
                ? UUID.randomUUID().toString()
                : request.sessionKey();
        if (draftStore != null && !draftStore.bindSession(identity.userKey(), sessionKey)) {
            String messageId = UUID.randomUUID().toString();
            Flux<ServerSentEvent<String>> rejected = streamEventWriter.write(Flux.just(
                    ChatStreamEvent.error(sessionKey, messageId, "不能使用其他用户的会话")
            ));
            return ResponseEntity.ok()
                    .contentType(MediaType.TEXT_EVENT_STREAM)
                    .body(rejected);
        }
        AiUserStreamLimiter.Lease lease = userStreamLimiter == null
                ? null
                : userStreamLimiter.tryAdmit(identity.userKey());
        if (userStreamLimiter != null && lease == null) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(ApiResponse.error("TOO_MANY_REQUESTS", AiUserStreamLimiter.REJECT_MESSAGE));
        }
        AiChatStreamRequest normalized = new AiChatStreamRequest(
                request == null ? null : request.message(),
                sessionKey,
                request == null ? null : request.metadata()
        );
        String messageId = UUID.randomUUID().toString();
        Flux<ChatStreamEvent> work = Flux.defer(() -> aiChatService.stream(normalized, identity));
        Flux<ChatStreamEvent> events = work;
        if (lease != null && lease.decision() == AiUserStreamLimiter.Decision.QUEUE) {
            reactor.core.publisher.Mono<Void> turn = lease.awaitTurn().cache();
            events = Flux.just(ChatStreamEvent.queue(sessionKey, messageId, 1))
                    .concatWith(Flux.interval(java.time.Duration.ofSeconds(15))
                            .map(tick -> ChatStreamEvent.keepalive(sessionKey, messageId))
                            .takeUntilOther(turn.onErrorResume(error -> reactor.core.publisher.Mono.empty())))
                    .concatWith(turn.thenMany(work))
                    .onErrorResume(error -> Flux.just(ChatStreamEvent.error(
                            sessionKey,
                            messageId,
                            error.getMessage() == null ? "AI stream failed" : error.getMessage()
                    )));
        }
        if (lease != null) {
            events = events.doFinally(signal -> lease.release());
        }
        return ResponseEntity.ok()
                .contentType(MediaType.TEXT_EVENT_STREAM)
                .body(streamEventWriter.write(events));
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
