package com.tutict.finalassignmentbackend.ai.chat;

import com.tutict.finalassignmentbackend.ai.agent.AgentRuntime;
import com.tutict.finalassignmentbackend.ai.guardrail.AnswerGroundingPolicy;
import com.tutict.finalassignmentbackend.ai.guardrail.AnswerTextSanitizer;
import com.tutict.finalassignmentbackend.ai.guardrail.GroundingDecision;
import com.tutict.finalassignmentbackend.ai.guardrail.PromptInjectionGuard;
import com.tutict.finalassignmentbackend.ai.guardrail.TopicGroundingVerifier;
import com.tutict.finalassignmentbackend.ai.prompt.ContextBuilder;
import com.tutict.finalassignmentbackend.ai.prompt.AgentConstraintService;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentbackend.ai.prompt.AiAgentRoleResolver;
import com.tutict.finalassignmentbackend.ai.prompt.PromptAssembler;
import com.tutict.finalassignmentbackend.ai.prompt.PromptTemplateService;
import com.tutict.finalassignmentbackend.ai.rag.config.RagRetrievalProperties;
import com.tutict.finalassignmentbackend.ai.rag.dto.RetrievalResult;
import com.tutict.finalassignmentbackend.ai.rag.query.ServerSideRagQueryRequest;
import com.tutict.finalassignmentbackend.ai.rag.query.RagQueryService;
import com.tutict.finalassignmentbackend.service.ai.AIChatSearchService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.core.io.DefaultResourceLoader;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import java.util.function.Supplier;
import java.util.stream.Collectors;

@Service
public class ChatPipeline {

    private static final Logger logger = LoggerFactory.getLogger(ChatPipeline.class);

    private final ChatStreamService chatStreamService;
    private final PromptAssembler promptAssembler;
    private final RagQueryService ragQueryService;
    private final RagRetrievalProperties ragRetrievalProperties;
    private final AIChatSearchService aiChatSearchService;
    private final AiAgentRoleResolver aiAgentRoleResolver;
    private final AgentConstraintService agentConstraintService;
    private final AgentRuntime agentRuntime;
    private final ObjectProvider<AgentRuntime> agentRuntimeProvider;
    private final AnswerGroundingPolicy answerGroundingPolicy;
    private final PromptInjectionGuard promptInjectionGuard;
    private final TopicGroundingVerifier topicGroundingVerifier;

    @Autowired
    public ChatPipeline(
            ChatStreamService chatStreamService,
            PromptAssembler promptAssembler,
            ObjectProvider<RagQueryService> ragQueryService,
            ObjectProvider<RagRetrievalProperties> ragRetrievalProperties,
            ObjectProvider<AIChatSearchService> aiChatSearchService,
            AiAgentRoleResolver aiAgentRoleResolver,
            AgentConstraintService agentConstraintService,
            ObjectProvider<AgentRuntime> agentRuntime,
            AnswerGroundingPolicy answerGroundingPolicy,
            PromptInjectionGuard promptInjectionGuard,
            ObjectProvider<TopicGroundingVerifier> topicGroundingVerifier
    ) {
        this(
                chatStreamService,
                promptAssembler,
                ragQueryServiceIfEnabled(ragQueryService, ragRetrievalProperties),
                ragRetrievalProperties.getIfAvailable(),
                aiChatSearchService.getIfAvailable(),
                aiAgentRoleResolver,
                agentConstraintService,
                null,
                agentRuntime,
                answerGroundingPolicy,
                promptInjectionGuard,
                topicGroundingVerifier.getIfAvailable()
        );
    }

    ChatPipeline(ChatStreamService chatStreamService) {
        this(
                chatStreamService,
                new PromptAssembler(new PromptTemplateService(), new ContextBuilder(1200)),
                null,
                disabledRagProperties(),
                null,
                new AiAgentRoleResolver(),
                new AgentConstraintService(new DefaultResourceLoader(), AgentConstraintService.DEFAULT_BASE_PATH)
        );
    }

    ChatPipeline(
            ChatStreamService chatStreamService,
            PromptAssembler promptAssembler,
            RagQueryService ragQueryService,
            RagRetrievalProperties ragRetrievalProperties
    ) {
        this(
                chatStreamService,
                promptAssembler,
                ragQueryService,
                ragRetrievalProperties,
                null,
                new AiAgentRoleResolver(),
                new AgentConstraintService(new DefaultResourceLoader(), AgentConstraintService.DEFAULT_BASE_PATH)
        );
    }

    ChatPipeline(
            ChatStreamService chatStreamService,
            PromptAssembler promptAssembler,
            RagQueryService ragQueryService,
            RagRetrievalProperties ragRetrievalProperties,
            AIChatSearchService aiChatSearchService,
            AiAgentRoleResolver aiAgentRoleResolver,
            AgentConstraintService agentConstraintService
    ) {
        this(chatStreamService, promptAssembler, ragQueryService, ragRetrievalProperties,
                aiChatSearchService, aiAgentRoleResolver, agentConstraintService, null, null);
    }

    ChatPipeline(
            ChatStreamService chatStreamService,
            PromptAssembler promptAssembler,
            RagQueryService ragQueryService,
            RagRetrievalProperties ragRetrievalProperties,
            AIChatSearchService aiChatSearchService,
            AiAgentRoleResolver aiAgentRoleResolver,
            AgentConstraintService agentConstraintService,
            AgentRuntime agentRuntime
    ) {
        this(chatStreamService, promptAssembler, ragQueryService, ragRetrievalProperties,
                aiChatSearchService, aiAgentRoleResolver, agentConstraintService, agentRuntime, null);
    }

    ChatPipeline(
            ChatStreamService chatStreamService,
            PromptAssembler promptAssembler,
            RagQueryService ragQueryService,
            RagRetrievalProperties ragRetrievalProperties,
            AIChatSearchService aiChatSearchService,
            AiAgentRoleResolver aiAgentRoleResolver,
            AgentConstraintService agentConstraintService,
            AgentRuntime agentRuntime,
            ObjectProvider<AgentRuntime> agentRuntimeProvider
    ) {
        this(chatStreamService, promptAssembler, ragQueryService, ragRetrievalProperties,
                aiChatSearchService, aiAgentRoleResolver, agentConstraintService, agentRuntime,
                agentRuntimeProvider, new AnswerGroundingPolicy(true), new PromptInjectionGuard());
    }

    ChatPipeline(
            ChatStreamService chatStreamService,
            PromptAssembler promptAssembler,
            RagQueryService ragQueryService,
            RagRetrievalProperties ragRetrievalProperties,
            AIChatSearchService aiChatSearchService,
            AiAgentRoleResolver aiAgentRoleResolver,
            AgentConstraintService agentConstraintService,
            AgentRuntime agentRuntime,
            ObjectProvider<AgentRuntime> agentRuntimeProvider,
            AnswerGroundingPolicy answerGroundingPolicy,
            PromptInjectionGuard promptInjectionGuard
    ) {
        this(chatStreamService, promptAssembler, ragQueryService, ragRetrievalProperties,
                aiChatSearchService, aiAgentRoleResolver, agentConstraintService, agentRuntime,
                agentRuntimeProvider, answerGroundingPolicy, promptInjectionGuard, null);
    }

    ChatPipeline(
            ChatStreamService chatStreamService,
            PromptAssembler promptAssembler,
            RagQueryService ragQueryService,
            RagRetrievalProperties ragRetrievalProperties,
            AIChatSearchService aiChatSearchService,
            AiAgentRoleResolver aiAgentRoleResolver,
            AgentConstraintService agentConstraintService,
            AgentRuntime agentRuntime,
            ObjectProvider<AgentRuntime> agentRuntimeProvider,
            AnswerGroundingPolicy answerGroundingPolicy,
            PromptInjectionGuard promptInjectionGuard,
            TopicGroundingVerifier topicGroundingVerifier
    ) {
        this.chatStreamService = chatStreamService;
        this.promptAssembler = promptAssembler;
        this.ragQueryService = ragQueryService;
        this.ragRetrievalProperties = ragRetrievalProperties;
        this.aiChatSearchService = aiChatSearchService;
        this.aiAgentRoleResolver = aiAgentRoleResolver;
        this.agentConstraintService = agentConstraintService;
        this.agentRuntime = agentRuntime;
        this.agentRuntimeProvider = agentRuntimeProvider;
        this.answerGroundingPolicy = answerGroundingPolicy == null
                ? new AnswerGroundingPolicy(true)
                : answerGroundingPolicy;
        this.promptInjectionGuard = promptInjectionGuard == null
                ? new PromptInjectionGuard()
                : promptInjectionGuard;
        this.topicGroundingVerifier = topicGroundingVerifier;
    }

    public Flux<ChatStreamEvent> stream(AiChatStreamRequest request) {
        return stream(request, AiCallerIdentity.anonymous());
    }

    public Flux<ChatStreamEvent> stream(AiChatStreamRequest request, AiCallerIdentity identity) {
        AiCallerIdentity snapshot = identity == null ? AiCallerIdentity.anonymous() : identity;
        if (!request.isWebSearchEnabled()) {
            return streamWithContext(request, List.of(), snapshot);
        }
        String messageId = UUID.randomUUID().toString();
        return Flux.just(ChatStreamEvent.keepalive(request.sessionKey(), messageId))
                .concatWith(Flux.defer(() -> {
                    List<RetrievalResult> webResults = webSearch(request.normalizedMessage(), request);
                    return Flux.just(ChatStreamEvent.keepalive(request.sessionKey(), messageId))
                            .concatWith(streamWithContext(request, webResults, snapshot));
                }));
    }

    private Flux<ChatStreamEvent> streamWithContext(
            AiChatStreamRequest request,
            List<RetrievalResult> webResults,
            AiCallerIdentity identity
    ) {
        String userMessage = request.normalizedMessage();
        Map<String, Object> metadata = request.metadata();
        boolean ragEngaged = ragEnabled(metadata) && ragQueryService != null;
        List<RetrievalResult> retrievalResults = new ArrayList<>();
        retrievalResults.addAll(retrieve(userMessage, metadata, identity));
        retrievalResults.addAll(webResults);
        AiAgentRole agentRole = identity.isAuthenticated()
                ? aiAgentRoleResolver.resolve(identity.roles())
                : aiAgentRoleResolver.resolve(metadata);
        // Tool-routing constraints only make sense when the agent loop is active. In pure RAG
        // mode (ai.agent.enabled=false) injecting navigation/draft rules would steer the model
        // away from answering from the retrieved context.
        AgentRuntime runtime = resolveAgentRuntime();
        String agentConstraints = runtime != null && agentConstraintService != null
                ? agentConstraintService.constraintsFor(agentRole)
                : "";
        String sanitizedMessage = sanitizeUserMessage(userMessage);
        List<String> conversationWindow = conversationWindow(metadata);
        String prompt = promptAssembler.assemble(
                sanitizedMessage,
                conversationWindow,
                retrievalResults,
                agentConstraints
        );
        Flux<ChatStreamEvent> events = runtime != null
                ? runtime.run(userMessage, request.sessionKey(), prompt, metadata, identity)
                : chatStreamService.stream(new AiChatStreamRequest(
                        prompt,
                        request.sessionKey(),
                        metadata
                ));
        boolean groundingRequired = ragEngaged || !retrievalResults.isEmpty();
        // One repair attempt with a citation-focused prompt, then the guardrail still refuses.
        // The agent path is excluded because replaying it would re-run tools and side effects.
        Supplier<Flux<ChatStreamEvent>> citationRetry =
                runtime == null && !retrievalResults.isEmpty()
                        ? () -> chatStreamService.stream(new AiChatStreamRequest(
                                promptAssembler.assembleCitationRepair(
                                        sanitizedMessage,
                                        conversationWindow,
                                        retrievalResults,
                                        agentConstraints
                                ),
                                request.sessionKey(),
                                metadata
                        ))
                        : null;
        return applyGrounding(events, retrievalResults, groundingRequired, citationRetry, sanitizedMessage);
    }

    /**
     * 输出护栏：当本轮问答确实依赖知识库/检索时，要求回答带有可核验的引用来源；否则用安全
     * 兜底文本替换模型输出，避免“无依据回答”。
     *
     * <p>为了能真正阻止无引用回答到达用户，这里对“需要引用”的回合做缓冲：先收集完整回答，
     * 判定通过才按原样回放事件，否则只发出兜底回答。非检索回合不缓冲，保持原有流式体验。
     *
     * <p>只对<b>纯文本回答</b>做引用强制：基础设施消息（熔断/降级兜底、错误）与结构化
     * 控制事件（TOOL / DRAFT / RESULT / ACTION / QUEUE 等）原样透传。否则一次拒答会连草稿卡片、导航动作
     * 一并吞掉，或把“AI 暂时不可用”误改成引用拒答。
     */
    private Flux<ChatStreamEvent> applyGrounding(
            Flux<ChatStreamEvent> events,
            List<RetrievalResult> sources,
            boolean groundingRequired,
            Supplier<Flux<ChatStreamEvent>> citationRetry,
            String question
    ) {
        if (!groundingRequired) {
            return events;
        }
        return bufferAndResolve(events, sources, citationRetry, question);
    }

    private Flux<ChatStreamEvent> bufferAndResolve(
            Flux<ChatStreamEvent> events,
            List<RetrievalResult> sources,
            Supplier<Flux<ChatStreamEvent>> citationRetry,
            String question
    ) {
        return Flux.defer(() -> {
            // segment 是「尚未判定的最后一段纯文本」。控制事件之前的文本先放行，
            // 之后的文本重新累积：agent 回合即使先吐工具卡片，最后仍有一段答案要判定。
            List<ChatStreamEvent> segment = new ArrayList<>();
            return events.concatMap(event -> {
                // Keep-alives and queue positions are not answer text: forward them immediately so
                // the connection stays alive, and keep them out of the grounding decision so a
                // queue notice can never exempt an uncited answer from the guardrail.
                if (isImmediateEvent(event)) {
                    return Flux.just(event);
                }
                if (!isNonTextEvent(event)) {
                    segment.add(event);
                    return Flux.empty();
                }
                // Structured control events pass through untouched, and the text before them is
                // flushed immediately so the stream never stalls behind a pending decision.
                List<ChatStreamEvent> flushed = new ArrayList<>(segment);
                segment.clear();
                return Flux.fromIterable(flushed).concatWith(Flux.just(event));
            }).concatWith(Flux.defer(() -> resolveGrounding(segment, sources, citationRetry, question)));
        });
    }

    private Flux<ChatStreamEvent> resolveGrounding(
            List<ChatStreamEvent> buffered,
            List<RetrievalResult> sources,
            Supplier<Flux<ChatStreamEvent>> citationRetry,
            String question
    ) {
        if (buffered.isEmpty()) {
            return Flux.empty();
        }
        // Infrastructure messages and structured control events are not "answers": pass them
        // through untouched so a refusal never swallows a draft card / action / tool result or
        // rewrites a bulkhead fallback.
        if (buffered.stream().anyMatch(ChatPipeline::isNonTextEvent)) {
            return Flux.fromIterable(buffered);
        }
        String answer = buffered.stream()
                .filter(event -> ChatStreamEventType.TOKEN.wireName().equals(event.type()))
                .map(ChatStreamEvent::token)
                .filter(Objects::nonNull)
                .collect(Collectors.joining());
        String sanitized = AnswerTextSanitizer.sanitize(answer);

        // Do not let a response made only of internal labels turn into a successful empty answer.
        if (!answer.isBlank() && sanitized.isBlank()) {
            return citationRetry != null
                    ? retryWithCitations(buffered, sources, citationRetry, question)
                    : refusedAnswer(buffered, AnswerGroundingPolicy.UNCITED_ANSWER);
        }

        // Judge the user-visible text so stripped labels cannot satisfy grounding on their own.
        GroundingDecision decision = answerGroundingPolicy == null
                ? GroundingDecision.allowed(sanitized)
                : answerGroundingPolicy.evaluate(sanitized, sources);
        if (decision.grounded()) {
            List<ChatStreamEvent> replay = Objects.equals(sanitized, answer)
                    ? buffered
                    : replaceAnswer(buffered, sanitized);
            if (topicGroundingVerifier == null) {
                return Flux.fromIterable(replay);
            }
            // The citation guardrail proves the answer points at *some* source, not that the
            // source is about the asked subject. Verify asynchronously and fail open.
            return topicGroundingVerifier.verify(question, sanitized, sources)
                    .flatMapMany(verdict -> verdict.grounded()
                            ? Flux.fromIterable(replay)
                            : refusedAnswer(buffered, verdict.answer()));
        }
        return citationRetry != null
                ? retryWithCitations(buffered, sources, citationRetry, question)
                : refusedAnswer(buffered, decision.answer());
    }

    private Flux<ChatStreamEvent> retryWithCitations(
            List<ChatStreamEvent> buffered,
            List<RetrievalResult> sources,
            Supplier<Flux<ChatStreamEvent>> citationRetry,
            String question
    ) {
        ChatStreamEvent first = buffered.getFirst();
        logger.info(
                "Retrying uncited answer with citation repair. sessionKey={}, messageId={}",
                first.sessionKey(),
                first.messageId()
        );
        // Keep the first attempt's identity so one SSE stream never mixes message ids.
        return bufferAndResolve(
                citationRetry.get().map(event -> rebind(event, first.sessionKey(), first.messageId())),
                sources,
                null,
                question
        );
    }

    private static ChatStreamEvent rebind(ChatStreamEvent event, String sessionKey, String messageId) {
        if (Objects.equals(event.sessionKey(), sessionKey) && Objects.equals(event.messageId(), messageId)) {
            return event;
        }
        return new ChatStreamEvent(
                event.type(),
                sessionKey,
                messageId,
                event.token(),
                event.payload(),
                event.timestamp()
        );
    }

    private static Flux<ChatStreamEvent> refusedAnswer(List<ChatStreamEvent> buffered, String answer) {
        return Flux.fromIterable(replaceAnswer(buffered, answer));
    }

    private static List<ChatStreamEvent> replaceAnswer(List<ChatStreamEvent> buffered, String answer) {
        List<ChatStreamEvent> events = new ArrayList<>();
        ChatStreamEvent firstToken = null;
        boolean answerEmitted = false;
        boolean done = false;
        for (ChatStreamEvent event : buffered) {
            if (ChatStreamEventType.TOKEN.wireName().equals(event.type())) {
                if (firstToken == null) {
                    firstToken = event;
                }
                events.add(new ChatStreamEvent(
                        event.type(),
                        event.sessionKey(),
                        event.messageId(),
                        answerEmitted ? "" : answer,
                        event.payload(),
                        event.timestamp()
                ));
                answerEmitted = true;
            } else if (ChatStreamEventType.DONE.wireName().equals(event.type())) {
                events.add(event);
                done = true;
            }
        }
        if (firstToken == null) {
            throw new IllegalArgumentException("A sanitized answer must contain a token event");
        }
        if (!done) {
            events.add(ChatStreamEvent.done(firstToken.sessionKey(), firstToken.messageId()));
        }
        return events;
    }

    /**
     * 真正受引用强制约束的只有 TOKEN / DONE；其他类型以及任何带
     * {@code isFallback} 载荷的事件都视为非文本事件。
     */
    private static boolean isNonTextEvent(ChatStreamEvent event) {
        String type = event.type();
        if (!ChatStreamEventType.TOKEN.wireName().equals(type)
                && !ChatStreamEventType.DONE.wireName().equals(type)) {
            return true;
        }
        return event.payload() instanceof Map<?, ?> payload
                && Boolean.TRUE.equals(payload.get("isFallback"));
    }

    private static boolean isImmediateEvent(ChatStreamEvent event) {
        String type = event.type();
        return ChatStreamEventType.KEEPALIVE.wireName().equals(type)
                || ChatStreamEventType.QUEUE.wireName().equals(type);
    }

    private String sanitizeUserMessage(String userMessage) {
        if (promptInjectionGuard == null || userMessage == null) {
            return userMessage;
        }
        return promptInjectionGuard.sanitize(userMessage);
    }

    private List<RetrievalResult> webSearch(String userMessage, AiChatStreamRequest request) {
        if (!request.isWebSearchEnabled() || aiChatSearchService == null) {
            return List.of();
        }
        try {
            List<Map<String, String>> results = aiChatSearchService.search(userMessage);
            List<RetrievalResult> retrievalResults = new ArrayList<>();
            int index = 1;
            for (Map<String, String> result : results) {
                String title = stringValue(result, "title");
                String content = firstNonBlank(
                        stringValue(result, "abstract"),
                        stringValue(result, "content"),
                        stringValue(result, "snippet")
                );
                if (content == null || content.isBlank()) {
                    continue;
                }
                retrievalResults.add(new RetrievalResult(
                        "web-search-" + index,
                        "web-search",
                        content,
                        firstNonBlank(title, "Web search result " + index),
                        "WEB_SEARCH",
                        "web_search",
                        String.valueOf(index),
                        "content",
                        stringValue(result, "url"),
                        0.0,
                        0.0,
                        Math.max(0.1, 1.0 - (index * 0.01)),
                        Map.of("source", firstNonBlank(stringValue(result, "url"), "web-search"))
                ));
                index++;
            }
            return List.copyOf(retrievalResults);
        } catch (RuntimeException ex) {
            return List.of(new RetrievalResult(
                    "web-search-error",
                    "web-search",
                    "Web search failed: " + ex.getMessage(),
                    "Web search unavailable",
                    "WEB_SEARCH",
                    "web_search",
                    "error",
                    "content",
                    null,
                    0.0,
                    0.0,
                    0.0,
                    Map.of("source", "web-search")
            ));
        }
    }

    private List<RetrievalResult> retrieve(
            String userMessage,
            Map<String, Object> metadata,
            AiCallerIdentity identity
    ) {
        if (!ragEnabled(metadata) || ragQueryService == null) {
            return List.of();
        }
        AiCallerIdentity snapshot = identity == null ? AiCallerIdentity.anonymous() : identity;
        return ragQueryService.query(new ServerSideRagQueryRequest(
                userMessage,
                intValue(metadata, "ragTopK", "topK"),
                snapshot.userId(),
                snapshot.roles(),
                snapshot.department()
        ));
    }

    private AgentRuntime resolveAgentRuntime() {
        if (agentRuntime != null) {
            return agentRuntime;
        }
        return agentRuntimeProvider == null ? null : agentRuntimeProvider.getIfAvailable();
    }

    private boolean ragEnabled(Map<String, Object> metadata) {
        if (ragRetrievalProperties == null || !ragRetrievalProperties.isEnabled()) {
            return false;
        }
        Object override = value(metadata, "ragEnabled");
        if (override == null) {
            return true;
        }
        if (override instanceof Boolean enabled) {
            return enabled;
        }
        return Boolean.parseBoolean(override.toString());
    }

    private static List<String> conversationWindow(Map<String, Object> metadata) {
        Object value = value(metadata, "conversationWindow", "conversation_window", "conversation");
        if (value == null) {
            return List.of();
        }
        if (value instanceof Collection<?> collection) {
            List<String> turns = new ArrayList<>();
            for (Object turn : collection) {
                String normalized = conversationTurn(turn);
                if (!normalized.isBlank()) {
                    turns.add(normalized);
                }
            }
            return List.copyOf(turns);
        }
        if (!value.toString().isBlank()) {
            return List.of(value.toString());
        }
        return List.of();
    }

    private static String conversationTurn(Object turn) {
        if (turn == null) {
            return "";
        }
        if (turn instanceof Map<?, ?> map) {
            Object role = map.get("role");
            Object content = map.get("content");
            if (content != null && !content.toString().isBlank()) {
                String roleText = role == null || role.toString().isBlank()
                        ? "message"
                        : role.toString().trim();
                return roleText + ": " + content.toString().trim();
            }
        }
        return turn.toString().trim();
    }

    private static Integer intValue(Map<String, Object> metadata, String... keys) {
        Object value = value(metadata, keys);
        if (value instanceof Number number) {
            return Math.max(1, number.intValue());
        }
        if (value != null && !value.toString().isBlank()) {
            try {
                return Math.max(1, Integer.parseInt(value.toString()));
            } catch (NumberFormatException ignored) {
                return null;
            }
        }
        return null;
    }

    private static String stringValue(Map<String, Object> metadata, String... keys) {
        Object value = value(metadata, keys);
        return value == null ? null : value.toString();
    }

    private static String stringValue(Map<String, String> metadata, String key) {
        if (metadata == null) {
            return null;
        }
        return metadata.get(key);
    }

    private static String firstNonBlank(String... values) {
        if (values == null) {
            return null;
        }
        for (String value : values) {
            if (value != null && !value.isBlank()) {
                return value.trim();
            }
        }
        return null;
    }

    private static Object value(Map<String, Object> metadata, String... keys) {
        if (metadata == null) {
            return null;
        }
        for (String key : keys) {
            Object value = metadata.get(key);
            if (value != null) {
                return value;
            }
        }
        return null;
    }

    private static RagRetrievalProperties disabledRagProperties() {
        RagRetrievalProperties properties = new RagRetrievalProperties();
        properties.setEnabled(false);
        return properties;
    }

    private static RagQueryService ragQueryServiceIfEnabled(
            ObjectProvider<RagQueryService> ragQueryService,
            ObjectProvider<RagRetrievalProperties> ragRetrievalProperties
    ) {
        RagRetrievalProperties properties = ragRetrievalProperties.getIfAvailable();
        return properties != null && properties.isEnabled()
                ? ragQueryService.getIfAvailable()
                : null;
    }
}
