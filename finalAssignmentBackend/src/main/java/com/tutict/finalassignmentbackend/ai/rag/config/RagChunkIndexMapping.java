package com.tutict.finalassignmentbackend.ai.rag.config;

import com.tutict.finalassignmentbackend.rag.config.RagProperties;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Map;

@Component
public class RagChunkIndexMapping {

    public static final String CURRENT_ALIAS = "rag_chunk_current";
    public static final int EMBEDDING_DIMS = 1024;

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
        Map<String, Object> propertiesMap = new LinkedHashMap<>();
        propertiesMap.put("chunk_id", keyword());
        propertiesMap.put("document_id", keyword());
        propertiesMap.put("content", Map.of("type", "text", "analyzer", "ik_max_word"));
        propertiesMap.put("title", Map.of("type", "text", "analyzer", "ik_max_word"));
        propertiesMap.put("source_type", keyword());
        propertiesMap.put("source_table", keyword());
        propertiesMap.put("source_id", keyword());
        propertiesMap.put("source_field", keyword());
        propertiesMap.put("route", keyword());
        propertiesMap.put("acl_scope", keyword());
        propertiesMap.put("acl_roles", keyword());
        propertiesMap.put("acl_user_ids", keyword());
        propertiesMap.put("acl_departments", keyword());
        propertiesMap.put("metadata", Map.of("type", "object", "enabled", true));
        propertiesMap.put("embedding", Map.of(
                "type", "dense_vector",
                "dims", EMBEDDING_DIMS,
                "index", true,
                "similarity", "cosine"
        ));
        return Map.of("properties", propertiesMap);
    }

    public Map<String, Object> aliasConfig() {
        return Map.of(aliasName(), Map.of("is_write_index", false));
    }

    private static Map<String, Object> keyword() {
        return Map.of("type", "keyword");
    }
}
