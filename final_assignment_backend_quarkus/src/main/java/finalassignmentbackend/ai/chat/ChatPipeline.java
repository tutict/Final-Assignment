package finalassignmentbackend.ai.chat;

import dev.langchain4j.data.message.UserMessage;
import dev.langchain4j.model.chat.StreamingChatModel;
import dev.langchain4j.model.chat.request.ChatRequest;
import dev.langchain4j.model.chat.response.ChatResponse;
import dev.langchain4j.model.chat.response.StreamingChatResponseHandler;
import finalassignmentbackend.ai.agent.AgentModels;
import finalassignmentbackend.ai.agent.AgentRuntime;
import finalassignmentbackend.ai.guardrail.GuardrailStage;
import finalassignmentbackend.ai.guardrail.PromptInjectionGuard;
import finalassignmentbackend.rag.service.RagQueryService;
import finalassignmentbackend.reliability.ModelCallBulkhead;
import finalassignmentbackend.reliability.ReliabilityMetrics;
import finalassignmentbackend.service.ai.AIChatSearchService;
import io.smallrye.mutiny.Multi;
import io.smallrye.mutiny.infrastructure.Infrastructure;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.json.bind.Jsonb;
import jakarta.json.bind.JsonbBuilder;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.Supplier;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Pure-RAG chat pipeline: retrieve → number the sources → prompt → stream → guardrail → SSE
 * frames. Tool-routed turns keep the previous behaviour: the agent answers on its own and the
 * model is not called.
 *
 * <p>Everything blocking (JDBC retrieval, GraalPy web search, agent lookups, guardrail
 * judgement) runs on the worker pool, so the Vert.x event loop only sees the reactive plumbing.
 */
@ApplicationScoped
public class ChatPipeline {

    private static final Logger LOG = Logger.getLogger(ChatPipeline.class.getName());

    private static final Set<String> TERMINAL_AGENT_EVENTS = Set.of("draft", "result", "error", "action");
    private static final int MAX_HISTORY_TURNS = 10;
    private static final int MAX_WEB_RESULTS = 5;

    @Inject StreamingChatModel chatModel;
    @Inject AgentRuntime agentRuntime;
    @Inject RagQueryService ragQueryService;
    @Inject PromptAssembler promptAssembler;
    @Inject GuardrailStage guardrailStage;
    @Inject AIChatSearchService aiChatSearchService;
    @Inject ModelCallBulkhead modelCalls;
    @Inject ReliabilityMetrics metrics;

    @ConfigProperty(name = "ai.agent.enabled", defaultValue = "true")
    boolean agentEnabled;

    @ConfigProperty(name = "ai.rag.enabled", defaultValue = "true")
    boolean ragEnabledByDefault;

    @ConfigProperty(name = "ai.rag.top-k", defaultValue = "5")
    int defaultTopK;

    private final Jsonb jsonb = JsonbBuilder.create();
    private final PromptInjectionGuard injectionGuard = new PromptInjectionGuard();
    private final AtomicLong messageSequence = new AtomicLong();

    public record Request(
            String message,
            String sessionKey,
            String username,
            String userKey,
            String role,
            DriverIdSupplier driverId,
            Map<String, Object> metadata
    ) {
    }

    @FunctionalInterface
    public interface DriverIdSupplier {
        Long get();
    }

    public String newMessageId() {
        return "msg-" + System.currentTimeMillis() + "-" + messageSequence.incrementAndGet();
    }

    public Multi<String> stream(Request request) {
        String messageId = newMessageId();
        String sessionKey = normalizeSessionKey(request.sessionKey());
        AtomicBoolean permitHeld = new AtomicBoolean(false);
        Multi<String> frames = Multi.createFrom().deferred(() -> {
            Multi<ChatStreamEvent> answer = answerEvents(request, sessionKey, messageId, permitHeld)
                    .onFailure().recoverWithItem(error -> {
                        LOG.log(Level.SEVERE, "AI chat stream failed", error);
                        return ChatStreamEvent.error(sessionKey, messageId, "模型生成失败");
                    });
            return Multi.createBy().concatenating()
                    .streams(answer, Multi.createFrom().item(ChatStreamEvent.done(sessionKey, messageId)))
                    .map(this::toJson);
        }).runSubscriptionOn(Infrastructure.getDefaultWorkerPool());
        return frames.onCancellation().invoke(() -> release(permitHeld));
    }

    private Multi<ChatStreamEvent> answerEvents(
            Request request,
            String sessionKey,
            String messageId,
            AtomicBoolean permitHeld
    ) {
        String message = request.message() == null ? "" : request.message().trim();
        if (message.isBlank()) {
            return Multi.createFrom().item(ChatStreamEvent.error(sessionKey, messageId, "message must not be blank"));
        }
        if (!agentRuntime.bindSession(request.userKey(), sessionKey)) {
            return Multi.createFrom().item(ChatStreamEvent.error(sessionKey, messageId, "不能使用其他用户的会话"));
        }

        List<Map<String, Object>> agentEvents = runAgent(request, message, sessionKey);
        List<ChatStreamEvent> prefix = agentEvents.stream()
                .map(event -> ChatStreamEvent.fromAgentEvent(event, sessionKey, messageId))
                .toList();
        boolean agentAnswered = agentEvents.stream()
                .anyMatch(event -> TERMINAL_AGENT_EVENTS.contains(String.valueOf(event.get("type"))));
        if (agentAnswered) {
            return Multi.createFrom().iterable(prefix);
        }

        boolean ragEngaged = booleanValue(request.metadata(), "ragEnabled", ragEnabledByDefault);
        List<RagQueryService.RetrievedChunk> sources = collectSources(request, message, ragEngaged);
        String sanitizedMessage = injectionGuard.sanitize(message);
        List<String> conversationWindow = conversationWindow(request.metadata());
        PromptAssembler.Assembled assembled = promptAssembler.assemble(
                sanitizedMessage,
                conversationWindow,
                sources
        );
        Multi<ChatStreamEvent> tokens = tokenEvents(assembled.prompt(), sessionKey, messageId, permitHeld);
        // Spring parity: any turn that engaged retrieval is judged on the sources the model
        // actually saw, even when the search returned nothing (then the guardrail refuses).
        if (ragEngaged || !assembled.sources().isEmpty()) {
            List<RagQueryService.RetrievedChunk> judgedSources = assembled.sources();
            // One repair attempt with a citation-focused prompt, then the guardrail still refuses.
            Supplier<Multi<ChatStreamEvent>> citationRepair = judgedSources.isEmpty()
                    ? null
                    : () -> tokenEvents(
                            promptAssembler.assembleCitationRepair(
                                    sanitizedMessage, conversationWindow, judgedSources).prompt(),
                            sessionKey,
                            messageId,
                            permitHeld);
            tokens = guardrailStage.apply(tokens, sanitizedMessage, judgedSources, citationRepair);
        }
        if (prefix.isEmpty()) {
            return tokens;
        }
        return Multi.createBy().concatenating()
                .streams(Multi.createFrom().iterable(prefix), tokens);
    }

    private List<Map<String, Object>> runAgent(Request request, String message, String sessionKey) {
        if (!agentEnabled) {
            return List.of();
        }
        Long driverId = request.driverId() == null ? null : request.driverId().get();
        AgentModels.Context context = new AgentModels.Context(
                request.role(), sessionKey, request.username(), request.userKey(), driverId, false);
        return agentRuntime.execute(message, context);
    }

    private List<RagQueryService.RetrievedChunk> collectSources(
            Request request,
            String message,
            boolean ragEngaged
    ) {
        List<RagQueryService.RetrievedChunk> sources = new ArrayList<>();
        if (ragEngaged) {
            try {
                sources.addAll(ragQueryService.retrieve(message, request.role(), topK(request.metadata())));
            } catch (RuntimeException ex) {
                // Spring semantics: a retrieval failure behaves like an empty result set. The
                // guardrail then refuses instead of letting the model answer without evidence.
                LOG.log(Level.WARNING, "RAG retrieval failed; continuing without knowledge-base sources", ex);
            }
        }
        if (webSearchEnabled(request.metadata())) {
            sources.addAll(webSearchSources(message));
        }
        return sources;
    }

    private List<RagQueryService.RetrievedChunk> webSearchSources(String message) {
        List<RagQueryService.RetrievedChunk> results = new ArrayList<>();
        try {
            List<Map<String, String>> searched = aiChatSearchService.search(message);
            int index = 1;
            for (Map<String, String> item : searched) {
                String content = firstNonBlank(item.get("abstract"), item.get("content"), item.get("snippet"));
                if (content == null || content.isBlank() || index > MAX_WEB_RESULTS) {
                    continue;
                }
                String title = firstNonBlank(item.get("title"), "Web search result " + index);
                results.add(new RagQueryService.RetrievedChunk(
                        "web-search-" + index, "web-search", item.get("url"), content, title,
                        "WEB_SEARCH", "web_search", Math.max(0.1, 1.0 - index * 0.01)));
                index++;
            }
        } catch (RuntimeException ex) {
            // Keep a WEB_SEARCH source in the list: the topic verifier must not judge a web
            // answer against knowledge-base passages (mirrors the Spring fallback entry).
            LOG.log(Level.WARNING, "Web search failed", ex);
            results.add(new RagQueryService.RetrievedChunk(
                    "web-search-error", "web-search", null, "Web search failed: " + ex.getMessage(),
                    "Web search unavailable", "WEB_SEARCH", "web_search", 0.0));
        }
        return results;
    }

    private Multi<ChatStreamEvent> tokenEvents(
            String prompt,
            String sessionKey,
            String messageId,
            AtomicBoolean permitHeld
    ) {
        return Multi.createFrom().emitter(emitter -> {
            if (!modelCalls.tryAcquire()) {
                metrics.aiFallback();
                emitter.emit(ChatStreamEvent.error(sessionKey, messageId, "模型繁忙，请稍后重试"));
                emitter.complete();
                return;
            }
            permitHeld.set(true);
            ChatRequest chatRequest = ChatRequest.builder()
                    .messages(UserMessage.from(prompt))
                    .build();
            try {
                chatModel.chat(chatRequest, new StreamingChatResponseHandler() {
                    @Override
                    public void onPartialResponse(String partialResponse) {
                        if (partialResponse == null || partialResponse.isEmpty() || emitter.isCancelled()) {
                            return;
                        }
                        emitter.emit(ChatStreamEvent.token(sessionKey, messageId, partialResponse));
                    }

                    @Override
                    public void onCompleteResponse(ChatResponse completeResponse) {
                        release(permitHeld);
                        emitter.complete();
                    }

                    @Override
                    public void onError(Throwable error) {
                        release(permitHeld);
                        LOG.log(Level.SEVERE, "AI chat stream failed", error);
                        if (!emitter.isCancelled()) {
                            emitter.emit(ChatStreamEvent.error(sessionKey, messageId, "模型生成失败"));
                            emitter.complete();
                        }
                    }
                });
            } catch (RuntimeException ex) {
                release(permitHeld);
                LOG.log(Level.SEVERE, "AI chat invocation failed", ex);
                emitter.emit(ChatStreamEvent.error(sessionKey, messageId, "模型生成失败"));
                emitter.complete();
            }
        });
    }

    private void release(AtomicBoolean permitHeld) {
        if (permitHeld.getAndSet(false)) {
            modelCalls.release();
        }
    }

    private String toJson(ChatStreamEvent event) {
        return jsonb.toJson(event.toMap());
    }

    private static String normalizeSessionKey(String sessionKey) {
        return sessionKey == null || sessionKey.isBlank() ? UUID.randomUUID().toString() : sessionKey;
    }

    private static boolean webSearchEnabled(Map<String, Object> metadata) {
        return booleanValue(metadata, "webSearchRequested", false)
                || booleanValue(metadata, "webSearch", false);
    }

    private int topK(Map<String, Object> metadata) {
        int requested = defaultTopK;
        Object ragTopK = metadata == null ? null : metadata.get("ragTopK");
        if (ragTopK instanceof Number number) {
            requested = number.intValue();
        }
        Object topK = metadata == null ? null : metadata.get("topK");
        if (topK instanceof Number number) {
            requested = number.intValue();
        }
        return Math.max(1, Math.min(requested, RagQueryService.MAX_TOP_K));
    }

    private static boolean booleanValue(Map<String, Object> metadata, String key, boolean fallback) {
        Object value = metadata == null ? null : metadata.get(key);
        if (value instanceof Boolean bool) {
            return bool;
        }
        return value == null ? fallback : Boolean.parseBoolean(String.valueOf(value));
    }

    static List<String> conversationWindow(Map<String, Object> metadata) {
        Object value = metadata == null ? null : metadata.get("conversationWindow");
        if (!(value instanceof List<?> list) || list.isEmpty()) {
            return List.of();
        }
        List<String> turns = new ArrayList<>();
        for (Object item : list) {
            String turn = conversationTurn(item);
            if (!turn.isBlank()) {
                turns.add(turn);
            }
        }
        if (turns.size() <= MAX_HISTORY_TURNS) {
            return List.copyOf(turns);
        }
        return List.copyOf(turns.subList(turns.size() - MAX_HISTORY_TURNS, turns.size()));
    }

    private static String conversationTurn(Object item) {
        if (item instanceof Map<?, ?> map) {
            Object content = map.get("content");
            if (content == null) {
                return "";
            }
            Object role = map.get("role");
            String roleText = role == null ? "message" : String.valueOf(role).trim().toLowerCase(Locale.ROOT);
            return PromptAssembler.normalizeWhitespace(roleText + ": " + content);
        }
        return PromptAssembler.normalizeWhitespace(item == null ? "" : String.valueOf(item));
    }

    private static String firstNonBlank(String... values) {
        for (String value : values) {
            if (value != null && !value.isBlank()) {
                return value;
            }
        }
        return null;
    }

    public static Map<String, Object> stringMap(Map<?, ?> map) {
        Map<String, Object> copy = new LinkedHashMap<>();
        if (map != null) {
            map.forEach((key, value) -> {
                if (key != null) {
                    copy.put(String.valueOf(key), value);
                }
            });
        }
        return copy;
    }
}
