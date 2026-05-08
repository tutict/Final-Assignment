package com.tutict.finalassignmentbackend.ai.chat;

import com.tutict.finalassignmentbackend.ai.prompt.ContextBuilder;
import com.tutict.finalassignmentbackend.ai.prompt.PromptAssembler;
import com.tutict.finalassignmentbackend.ai.prompt.PromptTemplateService;
import com.tutict.finalassignmentbackend.ai.rag.config.RagRetrievalProperties;
import com.tutict.finalassignmentbackend.ai.rag.dto.RetrievalResult;
import com.tutict.finalassignmentbackend.ai.rag.query.RagQueryRequest;
import com.tutict.finalassignmentbackend.ai.rag.query.RagQueryService;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;

@Service
public class ChatPipeline {

    private final ChatStreamService chatStreamService;
    private final PromptAssembler promptAssembler;
    private final RagQueryService ragQueryService;
    private final RagRetrievalProperties ragRetrievalProperties;

    public ChatPipeline(
            ChatStreamService chatStreamService,
            PromptAssembler promptAssembler,
            ObjectProvider<RagQueryService> ragQueryService,
            ObjectProvider<RagRetrievalProperties> ragRetrievalProperties
    ) {
        this(
                chatStreamService,
                promptAssembler,
                ragQueryService.getIfAvailable(),
                ragRetrievalProperties.getIfAvailable()
        );
    }

    ChatPipeline(ChatStreamService chatStreamService) {
        this(
                chatStreamService,
                new PromptAssembler(new PromptTemplateService(), new ContextBuilder(1200)),
                null,
                disabledRagProperties()
        );
    }

    ChatPipeline(
            ChatStreamService chatStreamService,
            PromptAssembler promptAssembler,
            RagQueryService ragQueryService,
            RagRetrievalProperties ragRetrievalProperties
    ) {
        this.chatStreamService = chatStreamService;
        this.promptAssembler = promptAssembler;
        this.ragQueryService = ragQueryService;
        this.ragRetrievalProperties = ragRetrievalProperties;
    }

    public Flux<ChatStreamEvent> stream(AiChatStreamRequest request) {
        String userMessage = request.normalizedMessage();
        Map<String, Object> metadata = request.metadata();
        List<RetrievalResult> retrievalResults = retrieve(userMessage, metadata);
        String prompt = promptAssembler.assemble(
                userMessage,
                conversationWindow(metadata),
                retrievalResults
        );
        return chatStreamService.stream(new AiChatStreamRequest(
                prompt,
                request.sessionKey(),
                metadata
        ));
    }

    private List<RetrievalResult> retrieve(String userMessage, Map<String, Object> metadata) {
        if (!ragEnabled(metadata) || ragQueryService == null) {
            return List.of();
        }
        return ragQueryService.query(new RagQueryRequest(
                userMessage,
                intValue(metadata, "ragTopK", "topK"),
                stringValue(metadata, "userId"),
                stringList(metadata, "roles"),
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
                if (turn != null && !turn.toString().isBlank()) {
                    turns.add(turn.toString());
                }
            }
            return List.copyOf(turns);
        }
        if (!value.toString().isBlank()) {
            return List.of(value.toString());
        }
        return List.of();
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

    private static List<String> stringList(Map<String, Object> metadata, String... keys) {
        Object value = value(metadata, keys);
        if (value instanceof Collection<?> collection) {
            List<String> values = new ArrayList<>();
            for (Object item : collection) {
                if (item != null && !item.toString().isBlank()) {
                    values.add(item.toString());
                }
            }
            return List.copyOf(values);
        }
        if (value != null && !value.toString().isBlank()) {
            return List.of(value.toString());
        }
        return List.of();
    }

    private static String stringValue(Map<String, Object> metadata, String... keys) {
        Object value = value(metadata, keys);
        return value == null ? null : value.toString();
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
}
