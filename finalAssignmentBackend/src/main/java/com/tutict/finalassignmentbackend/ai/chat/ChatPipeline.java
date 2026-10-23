package com.tutict.finalassignmentbackend.ai.chat;

import com.tutict.finalassignmentbackend.ai.agent.AgentRuntime;
import com.tutict.finalassignmentbackend.ai.guardrail.AnswerGroundingPolicy;
import com.tutict.finalassignmentbackend.ai.guardrail.GroundingDecision;
import com.tutict.finalassignmentbackend.ai.guardrail.PromptInjectionGuard;
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
import java.util.stream.Collectors;

@Service
public class ChatPipeline {

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
            PromptInjectionGuard promptInjectionGuard
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
                promptInjectionGuard
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
        String prompt = promptAssembler.assemble(
                sanitizeUserMessage(userMessage),
                conversationWindow(metadata),
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
        return applyGrounding(events, retrievalResults, groundingRequired);
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
            boolean groundingRequired
    ) {
        if (!groundingRequired || answerGroundingPolicy == null
                || !answerGroundingPolicy.isEnforcementEnabled()) {
            return events;
        }
        return Flux.defer(() -> {
            List<ChatStreamEvent> buffered = new ArrayList<>();
            return events.concatMap(event -> {
                // Keep-alives are forwarded immediately so the client connection stays alive
                // while the answer is buffered for citation checking.
                if (ChatStreamEventType.KEEPALIVE.wireName().equals(event.type())) {
                    return Flux.just(event);
                }
                buffered.add(event);
                return Flux.empty();
            }).concatWith(Flux.defer(() -> resolveGrounding(buffered, sources)));
        });
    }

    private Flux<ChatStreamEvent> resolveGrounding(List<ChatStreamEvent> buffered, List<RetrievalResult> sources) {
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
        GroundingDecision decision = answerGroundingPolicy.evaluate(answer, sources);
        if (decision.grounded()) {
            return Flux.fromIterable(buffered);
        }
        String sessionKey = firstNonBlank(buffered.getFirst().sessionKey());
        String messageId = firstNonBlank(buffered.getFirst().messageId());
        return Flux.just(
                ChatStreamEvent.token(sessionKey, messageId, decision.answer()),
                ChatStreamEvent.done(sessionKey, messageId)
        );
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
