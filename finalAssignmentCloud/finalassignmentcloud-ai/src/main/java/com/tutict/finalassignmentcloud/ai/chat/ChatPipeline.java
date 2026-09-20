package com.tutict.finalassignmentcloud.ai.chat;

import com.tutict.finalassignmentcloud.ai.agent.AgentRuntime;
import com.tutict.finalassignmentcloud.ai.client.rag.RagRetrievalResult;
import com.tutict.finalassignmentcloud.ai.prompt.AgentConstraintService;
import com.tutict.finalassignmentcloud.ai.prompt.AiAgentRole;
import com.tutict.finalassignmentcloud.ai.prompt.AiAgentRoleResolver;
import com.tutict.finalassignmentcloud.ai.prompt.PromptAssembler;
import com.tutict.finalassignmentcloud.ai.service.AIChatSearchService;
import com.tutict.finalassignmentcloud.ai.service.RagRetrievalService;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;

import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class ChatPipeline {

    private final ChatStreamService chatStreamService;
    private final PromptAssembler promptAssembler;
    private final RagRetrievalService ragRetrievalService;
    private final AIChatSearchService aiChatSearchService;
    private final AiAgentRoleResolver aiAgentRoleResolver;
    private final AgentConstraintService agentConstraintService;
    private final ObjectProvider<AgentRuntime> agentRuntimeProvider;

    public ChatPipeline(
            ChatStreamService chatStreamService,
            PromptAssembler promptAssembler,
            ObjectProvider<RagRetrievalService> ragRetrievalService,
            ObjectProvider<AIChatSearchService> aiChatSearchService,
            AiAgentRoleResolver aiAgentRoleResolver,
            AgentConstraintService agentConstraintService,
            ObjectProvider<AgentRuntime> agentRuntimeProvider
    ) {
        this.chatStreamService = chatStreamService;
        this.promptAssembler = promptAssembler;
        this.ragRetrievalService = ragRetrievalService.getIfAvailable();
        this.aiChatSearchService = aiChatSearchService.getIfAvailable();
        this.aiAgentRoleResolver = aiAgentRoleResolver;
        this.agentConstraintService = agentConstraintService;
        this.agentRuntimeProvider = agentRuntimeProvider;
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
                    List<RagRetrievalResult> webResults = webSearch(request.normalizedMessage());
                    return Flux.just(ChatStreamEvent.keepalive(request.sessionKey(), messageId))
                            .concatWith(streamWithContext(request, webResults, snapshot));
                }));
    }

    private Flux<ChatStreamEvent> streamWithContext(
            AiChatStreamRequest request,
            List<RagRetrievalResult> webResults,
            AiCallerIdentity identity
    ) {
        String userMessage = request.normalizedMessage();
        Map<String, Object> metadata = new LinkedHashMap<>(request.metadata());
        if (identity.userId() != null) {
            metadata.putIfAbsent("userId", identity.userId());
        }
        if (!identity.roles().isEmpty()) {
            metadata.putIfAbsent("roles", identity.roles());
        }
        if (identity.driverId() != null) {
            metadata.putIfAbsent("driverId", identity.driverId());
        }
        List<RagRetrievalResult> retrievalResults = new ArrayList<>();
        retrievalResults.addAll(retrieve(userMessage, metadata));
        retrievalResults.addAll(webResults);
        AiAgentRole agentRole = identity.isAuthenticated()
                ? aiAgentRoleResolver.resolve(Map.of("roles", identity.roles()))
                : aiAgentRoleResolver.resolve(metadata);
        String prompt = promptAssembler.assemble(
                userMessage,
                conversationWindow(metadata),
                retrievalResults,
                agentConstraintService.constraintsFor(agentRole)
        );
        AgentRuntime runtime = agentRuntimeProvider == null ? null : agentRuntimeProvider.getIfAvailable();
        if (runtime != null) {
            return runtime.run(userMessage, request.sessionKey(), prompt, metadata, identity);
        }
        return chatStreamService.stream(new AiChatStreamRequest(prompt, request.sessionKey(), metadata));
    }

    private List<RagRetrievalResult> webSearch(String userMessage) {
        if (aiChatSearchService == null) {
            return List.of();
        }
        try {
            List<Map<String, String>> results = aiChatSearchService.search(userMessage);
            List<RagRetrievalResult> retrievalResults = new ArrayList<>();
            int index = 1;
            for (Map<String, String> result : results) {
                String content = firstNonBlank(result.get("abstract"), result.get("content"), result.get("snippet"));
                if (content == null || content.isBlank()) {
                    continue;
                }
                retrievalResults.add(new RagRetrievalResult(
                        "web-search-" + index,
                        "web-search",
                        content,
                        firstNonBlank(result.get("title"), "Web search result " + index),
                        "WEB_SEARCH",
                        "web_search",
                        String.valueOf(index),
                        "content",
                        result.get("url"),
                        0.0,
                        0.0,
                        Math.max(0.1, 1.0 - (index * 0.01)),
                        Map.of("source", firstNonBlank(result.get("url"), "web-search"))
                ));
                index++;
            }
            return List.copyOf(retrievalResults);
        } catch (RuntimeException ex) {
            return List.of();
        }
    }

    private List<RagRetrievalResult> retrieve(String userMessage, Map<String, Object> metadata) {
        if (ragRetrievalService == null) {
            return List.of();
        }
        return ragRetrievalService.retrieve(userMessage, metadata);
    }

    private static List<String> conversationWindow(Map<String, Object> metadata) {
        Object value = metadata.get("conversationWindow");
        if (value == null) {
            value = metadata.get("conversation_window");
        }
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
        return value.toString().isBlank() ? List.of() : List.of(value.toString());
    }

    private static String conversationTurn(Object turn) {
        if (turn == null) {
            return "";
        }
        if (turn instanceof Map<?, ?> map) {
            Object role = map.get("role");
            Object content = map.get("content");
            if (content != null && !content.toString().isBlank()) {
                String roleText = role == null || role.toString().isBlank() ? "message" : role.toString().trim();
                return roleText + ": " + content.toString().trim();
            }
        }
        return turn.toString().trim();
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
}
