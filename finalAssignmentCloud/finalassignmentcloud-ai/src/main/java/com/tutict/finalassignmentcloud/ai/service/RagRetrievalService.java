package com.tutict.finalassignmentcloud.ai.service;

import com.tutict.finalassignmentcloud.ai.client.rag.RagClient;
import com.tutict.finalassignmentcloud.ai.client.rag.RagQueryRequest;
import com.tutict.finalassignmentcloud.ai.client.rag.RagRetrievalResult;
import com.tutict.finalassignmentcloud.ai.config.AiRagProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class RagRetrievalService {

    private static final Logger logger = LoggerFactory.getLogger(RagRetrievalService.class);

    private final RagClient ragClient;
    private final AiRagProperties properties;

    public RagRetrievalService(RagClient ragClient, AiRagProperties properties) {
        this.ragClient = ragClient;
        this.properties = properties;
    }

    public List<RagRetrievalResult> retrieve(String message, Map<String, Object> metadata) {
        String query = queryText(message, metadata);
        if (!isEnabled(metadata) || query.isBlank()) {
            return List.of();
        }
        try {
            RagClient.RagQueryApiResponse response = ragClient.query(
                    new RagQueryRequest(query, topK(metadata), null, List.of(), department(metadata))
            );
            if (response == null || !response.success() || response.data() == null) {
                return List.of();
            }
            return response.data().getOrDefault("results", List.of());
        } catch (RuntimeException error) {
            logger.warn("RAG retrieval failed: {}", error.getMessage());
            return List.of();
        }
    }

    private boolean isEnabled(Map<String, Object> metadata) {
        Object override = firstValue(metadata, "ragEnabled", "rag_enabled", "useRag", "use_rag");
        if (override == null) {
            return properties.isEnabled();
        }
        if (override instanceof Boolean enabled) {
            return enabled;
        }
        return Boolean.parseBoolean(override.toString());
    }

    private int topK(Map<String, Object> metadata) {
        Object value = firstValue(metadata, "ragTopK", "rag_top_k", "topK", "top_k");
        int fallback = Math.max(1, properties.getTopK());
        if (value instanceof Number number) {
            return Math.max(1, number.intValue());
        }
        if (value != null) {
            try {
                return Math.max(1, Integer.parseInt(value.toString()));
            } catch (NumberFormatException ignored) {
                return fallback;
            }
        }
        return fallback;
    }

    private static String queryText(String message, Map<String, Object> metadata) {
        Object explicit = firstValue(metadata, "ragQuery", "rag_query");
        if (explicit != null && !explicit.toString().isBlank()) {
            return explicit.toString().trim();
        }
        return message == null ? "" : message.trim();
    }

    private static String department(Map<String, Object> metadata) {
        Object value = firstValue(metadata, "department", "dept");
        return value == null || value.toString().isBlank() ? null : value.toString().trim();
    }

    private static Object firstValue(Map<String, Object> metadata, String... keys) {
        if (metadata == null || metadata.isEmpty()) {
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
}
