package com.tutict.finalassignmentcloud.ai.chat;

import com.tutict.finalassignmentcloud.ai.prompt.ContextBuilder;
import com.tutict.finalassignmentcloud.ai.prompt.AgentConstraintService;
import com.tutict.finalassignmentcloud.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentcloud.ai.prompt.AiAgentRoleResolver;
import com.tutict.finalassignmentcloud.ai.prompt.PromptAssembler;
import com.tutict.finalassignmentcloud.ai.prompt.PromptTemplateService;
import com.tutict.finalassignmentcloud.ai.rag.config.RagRetrievalProperties;
import com.tutict.finalassignmentcloud.ai.rag.dto.RetrievalResult;
import com.tutict.finalassignmentcloud.ai.rag.query.RagQueryRequest;
import com.tutict.finalassignmentcloud.ai.rag.query.RagQueryService;
import com.tutict.finalassignmentcloud.service.ai.AIChatSearchService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.core.io.DefaultResourceLoader;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class ChatPipeline {

    private final ChatStreamService chatStreamService;
    private final PromptAssembler promptAssembler;
    private final RagQueryService ragQueryService;
    private final RagRetrievalProperties ragRetrievalProperties;
    private final AIChatSearchService aiChatSearchService;
    private final AiAgentRoleResolver aiAgentRoleResolver;
    private final AgentConstraintService agentConstraintService;

    @Autowired
    public ChatPipeline(
            ChatStreamService chatStreamService,
            PromptAssembler promptAssembler,
            ObjectProvider<RagQueryService> ragQueryService,
            ObjectProvider<RagRetrievalProperties> ragRetrievalProperties,
            ObjectProvider<AIChatSearchService> aiChatSearchService,
            AiAgentRoleResolver aiAgentRoleResolver,
            AgentConstraintService agentConstraintService
    ) {
        this(
                chatStreamService,
                promptAssembler,
                ragQueryServiceIfEnabled(ragQueryService, ragRetrievalProperties),
                ragRetrievalProperties.getIfAvailable(),
                aiChatSearchService.getIfAvailable(),
                aiAgentRoleResolver,
                agentConstraintService
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
        this.chatStreamService = chatStreamService;
        this.promptAssembler = promptAssembler;
        this.ragQueryService = ragQueryService;
        this.ragRetrievalProperties = ragRetrievalProperties;
        this.aiChatSearchService = aiChatSearchService;
        this.aiAgentRoleResolver = aiAgentRoleResolver;
        this.agentConstraintService = agentConstraintService;
    }

    public Flux<ChatStreamEvent> stream(AiChatStreamRequest request) {
        if (!request.isWebSearchEnabled()) {
            return streamWithContext(request, List.of());
        }
        String messageId = UUID.randomUUID().toString();
        return Flux.just(ChatStreamEvent.keepalive(request.sessionKey(), messageId))
                .concatWith(Flux.defer(() -> {
                    List<RetrievalResult> webResults = webSearch(request.normalizedMessage(), request);
                    return Flux.just(ChatStreamEvent.keepalive(request.sessionKey(), messageId))
                            .concatWith(streamWithContext(request, webResults));
                }));
    }

    private Flux<ChatStreamEvent> streamWithContext(
            AiChatStreamRequest request,
            List<RetrievalResult> webResults
    ) {
        String userMessage = request.normalizedMessage();
        Map<String, Object> metadata = request.metadata();
        List<RetrievalResult> retrievalResults = new ArrayList<>();
        retrievalResults.addAll(retrieve(userMessage, metadata));
        retrievalResults.addAll(webResults);
        AiAgentRole agentRole = aiAgentRoleResolver.resolve(metadata);
        String prompt = promptAssembler.assemble(
                userMessage,
                conversationWindow(metadata),
                retrievalResults,
                agentConstraintService.constraintsFor(agentRole)
        );
        return chatStreamService.stream(new AiChatStreamRequest(
                prompt,
                request.sessionKey(),
                metadata
        ));
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

    private List<RetrievalResult> retrieve(String userMessage, Map<String, Object> metadata) {
        if (!ragEnabled(metadata) || ragQueryService == null) {
            return List.of();
        }
        return ragQueryService.query(new RagQueryRequest(
                userMessage,
                intValue(metadata, "ragTopK", "topK"),
                stringValue(metadata, "userId"),
                aiAgentRoleResolver.resolveRoleCodes(metadata),
                stringValue(metadata, "department")
        ));
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
