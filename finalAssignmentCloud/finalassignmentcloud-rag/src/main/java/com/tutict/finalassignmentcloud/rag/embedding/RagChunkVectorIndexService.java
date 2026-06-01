package com.tutict.finalassignmentcloud.rag.embedding;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.rag.ai.config.RagChunkIndexMapping;
import com.tutict.finalassignmentcloud.rag.entity.RagChunk;
import com.tutict.finalassignmentcloud.rag.entity.RagDocument;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.elasticsearch.core.ElasticsearchOperations;
import org.springframework.data.elasticsearch.core.IndexOperations;
import org.springframework.data.elasticsearch.core.document.Document;
import org.springframework.data.elasticsearch.core.index.AliasAction;
import org.springframework.data.elasticsearch.core.index.AliasActionParameters;
import org.springframework.data.elasticsearch.core.index.AliasActions;
import org.springframework.data.elasticsearch.core.mapping.IndexCoordinates;
import org.springframework.data.elasticsearch.core.query.IndexQuery;
import org.springframework.data.elasticsearch.core.query.IndexQueryBuilder;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
@ConditionalOnProperty(prefix = "rag.embedding", name = "enabled", havingValue = "true")
public class RagChunkVectorIndexService {

    private static final TypeReference<Map<String, Object>> MAP_TYPE = new TypeReference<>() {
    };

    private final ObjectProvider<ElasticsearchOperations> operationsProvider;
    private final RagChunkIndexMapping mapping;
    private final ObjectMapper objectMapper;
    private volatile boolean indexReady;

    public RagChunkVectorIndexService(
            ObjectProvider<ElasticsearchOperations> operationsProvider,
            RagChunkIndexMapping mapping,
            ObjectMapper objectMapper
    ) {
        this.operationsProvider = operationsProvider;
        this.mapping = mapping;
        this.objectMapper = objectMapper;
    }

    public void index(RagDocument document, RagChunk chunk, float[] embedding, String provider, String model) {
        ElasticsearchOperations operations = operationsProvider.getIfAvailable();
        if (operations == null) {
            throw new IllegalStateException("ElasticsearchOperations is not available for RAG vector indexing");
        }
        ensureIndex(operations);
        IndexQuery query = new IndexQueryBuilder()
                .withId(chunk.getId())
                .withSource(writeJson(source(document, chunk, embedding, provider, model)))
                .build();
        try {
            operations.index(query, IndexCoordinates.of(mapping.aliasName()));
        } catch (RuntimeException error) {
            operations.index(query, IndexCoordinates.of(mapping.indexName()));
        }
    }

    private void ensureIndex(ElasticsearchOperations operations) {
        if (indexReady) {
            return;
        }
        synchronized (this) {
            if (indexReady) {
                return;
            }
            IndexOperations indexOperations = operations.indexOps(IndexCoordinates.of(mapping.indexName()));
            if (!indexOperations.exists()) {
                indexOperations.create(mapping.settings(), Document.from(mapping.mapping()));
            }
            ensureAlias(indexOperations);
            indexReady = true;
        }
    }

    private void ensureAlias(IndexOperations indexOperations) {
        Map<String, ?> aliases = indexOperations.getAliases(mapping.aliasName());
        if (!aliases.isEmpty()) {
            return;
        }
        AliasActionParameters parameters = AliasActionParameters.builder()
                .withIndices(mapping.indexName())
                .withAliases(mapping.aliasName())
                .withIsWriteIndex(true)
                .build();
        indexOperations.alias(new AliasActions(new AliasAction.Add(parameters)));
    }

    private Map<String, Object> source(
            RagDocument document,
            RagChunk chunk,
            float[] embedding,
            String provider,
            String model
    ) {
        Map<String, Object> metadata = metadata(document.getMetadataJson());
        Map<String, Object> source = new LinkedHashMap<>();
        source.put("chunk_id", chunk.getId());
        source.put("document_id", document.getId());
        source.put("content", chunk.getContent());
        source.put("title", document.getTitle());
        source.put("source_type", document.getSourceType());
        source.put("source_table", document.getSourceTable());
        source.put("source_id", document.getSourceId());
        source.put("source_version", document.getSourceVersion());
        source.put("source_field", chunk.getSourceField());
        source.put("route", document.getRoute());
        source.put("acl_scope", document.getAclScope());
        source.put("acl_roles", listValue(metadata, "acl_roles", "aclRoles", "roles"));
        source.put("acl_user_ids", listValue(metadata, "acl_user_ids", "aclUserIds", "userIds"));
        source.put("acl_departments", listValue(metadata, "acl_departments", "aclDepartments", "departments"));
        source.put("metadata", metadata);
        source.put("embedding_provider", provider);
        source.put("embedding_model", model);
        source.put("embedding", toDoubleList(embedding));
        return source;
    }

    private Map<String, Object> metadata(String metadataJson) {
        if (metadataJson == null || metadataJson.isBlank()) {
            return new LinkedHashMap<>();
        }
        try {
            return new LinkedHashMap<>(objectMapper.readValue(metadataJson, MAP_TYPE));
        } catch (Exception error) {
            Map<String, Object> fallback = new LinkedHashMap<>();
            fallback.put("rawMetadata", metadataJson);
            fallback.put("metadataParseError", error.getMessage());
            return fallback;
        }
    }

    private String writeJson(Map<String, Object> source) {
        try {
            return objectMapper.writeValueAsString(source);
        } catch (Exception error) {
            throw new IllegalStateException("Failed to serialize RAG chunk vector document", error);
        }
    }

    private static List<Object> listValue(Map<String, Object> metadata, String... keys) {
        Object value = null;
        for (String key : keys) {
            if (metadata.containsKey(key)) {
                value = metadata.get(key);
                break;
            }
        }
        if (value == null) {
            return List.of();
        }
        if (value instanceof Iterable<?> iterable) {
            List<Object> values = new ArrayList<>();
            iterable.forEach(item -> {
                if (item != null && !item.toString().isBlank()) {
                    values.add(item.toString());
                }
            });
            return values;
        }
        String text = value.toString();
        if (text.isBlank()) {
            return List.of();
        }
        return List.of(text);
    }

    private static List<Double> toDoubleList(float[] vector) {
        List<Double> values = new ArrayList<>(vector.length);
        for (float value : vector) {
            values.add((double) value);
        }
        return values;
    }
}

