package com.tutict.finalassignmentcloud.rag.ai.config;

import com.tutict.finalassignmentcloud.rag.config.RagProperties;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Map;

@Component
public class RagChunkIndexMapping {

    public static final String CURRENT_ALIAS = "rag_chunk_current";
    private final RagProperties properties;

    public RagChunkIndexMapping(RagProperties properties) {
        this.properties = properties;
    }

    public String indexName() {
        return properties.getIndex().getName();
    }

    public String aliasName() {
        return properties.getIndex().getAlias();
    }

    public Map<String, Object> mapping() {
        String textAnalyzer = properties.getIndex().getTextAnalyzer();
        int dimensions = Math.max(1, properties.getEmbedding().getDimensions());
        Map<String, Object> propertiesMap = new LinkedHashMap<>();
        propertiesMap.put("chunk_id", keyword());
        propertiesMap.put("document_id", keyword());
        propertiesMap.put("content", text(textAnalyzer));
        propertiesMap.put("title", textWithKeyword(textAnalyzer));
        propertiesMap.put("source_type", keyword());
        propertiesMap.put("source_table", keyword());
        propertiesMap.put("source_id", keyword());
        propertiesMap.put("source_field", keywordWithText(textAnalyzer));
        propertiesMap.put("source_version", keyword());
        propertiesMap.put("route", keyword());
        propertiesMap.put("acl_scope", keyword());
        propertiesMap.put("acl_roles", keyword());
        propertiesMap.put("acl_user_ids", keyword());
        propertiesMap.put("acl_departments", keyword());
        propertiesMap.put("embedding_provider", keyword());
        propertiesMap.put("embedding_model", keyword());
        propertiesMap.put("metadata", Map.of("type", "object", "enabled", true));
        propertiesMap.put("embedding", Map.of(
                "type", "dense_vector",
                "dims", dimensions,
                "index", true,
                "similarity", "cosine"
        ));
        return Map.of("properties", propertiesMap);
    }

    public Map<String, Object> settings() {
        Map<String, Object> indexSettings = new LinkedHashMap<>();
        indexSettings.put("number_of_shards", Math.max(1, properties.getIndex().getNumberOfShards()));
        indexSettings.put("number_of_replicas", Math.max(0, properties.getIndex().getNumberOfReplicas()));
        indexSettings.put("refresh_interval", blankToDefault(properties.getIndex().getRefreshInterval(), "30s"));
        return Map.of("index", indexSettings);
    }

    public Map<String, Object> aliasConfig() {
        return Map.of(aliasName(), Map.of("is_write_index", false));
    }

    private static Map<String, Object> keyword() {
        return Map.of("type", "keyword");
    }

    private static Map<String, Object> text(String analyzer) {
        return Map.of("type", "text", "analyzer", analyzer);
    }

    private static Map<String, Object> textWithKeyword(String analyzer) {
        return Map.of(
                "type", "text",
                "analyzer", analyzer,
                "fields", Map.of("keyword", Map.of("type", "keyword", "ignore_above", 256))
        );
    }

    private static Map<String, Object> keywordWithText(String analyzer) {
        return Map.of(
                "type", "keyword",
                "fields", Map.of("text", text(analyzer))
        );
    }

    private static String blankToDefault(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }
}

