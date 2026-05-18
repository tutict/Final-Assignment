package com.tutict.finalassignmentbackend.ai.rag.retrieval;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentbackend.ai.rag.config.RagChunkIndexMapping;
import com.tutict.finalassignmentbackend.ai.rag.dto.RetrievalResult;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.elasticsearch.core.ElasticsearchOperations;
import org.springframework.data.elasticsearch.core.SearchHit;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.core.mapping.IndexCoordinates;
import org.springframework.data.elasticsearch.core.query.StringQuery;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
@ConditionalOnProperty(prefix = "rag.retrieval", name = "enabled", havingValue = "true")
public class EmbeddingSearchService {

    private final EmbeddingProvider embeddingProvider;
    private final RagSearchBackend searchBackend;

    public EmbeddingSearchService(
            EmbeddingProvider embeddingProvider,
            ObjectProvider<ElasticsearchOperations> elasticsearchOperations,
            RagChunkIndexMapping mapping,
            ObjectMapper objectMapper
    ) {
        this(
                embeddingProvider,
                new ElasticsearchRagSearchBackend(
                        elasticsearchOperations.getIfAvailable(),
                        mapping.aliasName(),
                        objectMapper
                )
        );
    }

    EmbeddingSearchService(EmbeddingProvider embeddingProvider, RagSearchBackend searchBackend) {
        this.embeddingProvider = embeddingProvider;
        this.searchBackend = searchBackend;
    }

    public float[] embedQuery(String normalizedQuery) {
        return embeddingProvider.embed(normalizedQuery);
    }

    public List<RetrievalResult> bm25Search(
            String normalizedQuery,
            AclFilterService.AclFilter aclFilter,
            int limit
    ) {
        return searchBackend.bm25Search(normalizedQuery, aclFilter, Math.max(1, limit));
    }

    public List<RetrievalResult> vectorSearch(
            float[] queryVector,
            AclFilterService.AclFilter aclFilter,
            int limit
    ) {
        return searchBackend.vectorSearch(queryVector, aclFilter, Math.max(1, limit));
    }
}

interface RagSearchBackend {

    List<RetrievalResult> bm25Search(String normalizedQuery, AclFilterService.AclFilter aclFilter, int limit);

    List<RetrievalResult> vectorSearch(float[] queryVector, AclFilterService.AclFilter aclFilter, int limit);
}

class ElasticsearchRagSearchBackend implements RagSearchBackend {

    private final ElasticsearchOperations operations;
    private final String indexAlias;
    private final ObjectMapper objectMapper;

    ElasticsearchRagSearchBackend(
            ElasticsearchOperations operations,
            String indexAlias,
            ObjectMapper objectMapper
    ) {
        this.operations = operations;
        this.indexAlias = indexAlias;
        this.objectMapper = objectMapper;
    }

    @Override
    public List<RetrievalResult> bm25Search(
            String normalizedQuery,
            AclFilterService.AclFilter aclFilter,
            int limit
    ) {
        if (operations == null) {
            return List.of();
        }
        Map<String, Object> query = Map.of(
                "size", limit,
                "query", Map.of(
                        "bool", Map.of(
                                "must", List.of(Map.of(
                                        "multi_match", Map.of(
                                                "query", normalizedQuery,
                                                "fields", List.of("content^2", "title", "source_field")
                                        )
                                )),
                                "filter", aclClauses(aclFilter)
                        )
                )
        );
        return execute(query, "bm25");
    }

    @Override
    public List<RetrievalResult> vectorSearch(
            float[] queryVector,
            AclFilterService.AclFilter aclFilter,
            int limit
    ) {
        if (operations == null) {
            return List.of();
        }
        Map<String, Object> query = Map.of(
                "size", limit,
                "query", Map.of(
                        "script_score", Map.of(
                                "query", Map.of("bool", Map.of("filter", aclClauses(aclFilter))),
                                "script", Map.of(
                                        "source", "cosineSimilarity(params.query_vector, 'embedding') + 1.0",
                                        "params", Map.of("query_vector", toDoubleList(queryVector))
                                )
                        )
                )
        );
        return execute(query, "vector");
    }

    private List<RetrievalResult> execute(Map<String, Object> query, String mode) {
        SearchHits<Map> hits = operations.search(
                new StringQuery(writeJson(query)),
                Map.class,
                IndexCoordinates.of(indexAlias)
        );
        List<RetrievalResult> results = new ArrayList<>();
        for (SearchHit<Map> hit : hits) {
            RetrievalResult result = toResult(hit.getContent(), hit.getScore(), mode);
            if (result != null) {
                results.add(result);
            }
        }
        return results;
    }

    private RetrievalResult toResult(Map<String, Object> source, float score, String mode) {
        String chunkId = stringValue(source, "chunk_id", "chunkId");
        if (chunkId.isBlank()) {
            return null;
        }
        Map<String, Object> metadata = metadata(source);
        putIfPresent(metadata, "acl_scope", stringValue(source, "acl_scope", "aclScope"));
        putIfPresent(metadata, "acl_roles", value(source, "acl_roles", "aclRoles"));
        putIfPresent(metadata, "acl_user_ids", value(source, "acl_user_ids", "aclUserIds"));
        putIfPresent(metadata, "acl_departments", value(source, "acl_departments", "aclDepartments"));
        double bm25Score = "bm25".equals(mode) ? score : 0;
        double vectorScore = "vector".equals(mode) ? score : 0;
        return new RetrievalResult(
                chunkId,
                stringValue(source, "document_id", "documentId"),
                stringValue(source, "content"),
                stringValue(source, "title"),
                stringValue(source, "source_type", "sourceType"),
                stringValue(source, "source_table", "sourceTable"),
                stringValue(source, "source_id", "sourceId"),
                stringValue(source, "source_field", "sourceField"),
                stringValue(source, "route"),
                bm25Score,
                vectorScore,
                0,
                metadata
        );
    }

    private static List<Map<String, Object>> aclClauses(AclFilterService.AclFilter aclFilter) {
        List<Map<String, Object>> should = new ArrayList<>();
        should.add(Map.of("term", Map.of("acl_scope", "PUBLIC")));
        for (String role : aclFilter.roles()) {
            should.add(Map.of("term", Map.of("acl_roles", role)));
        }
        if (aclFilter.userId() != null) {
            should.add(Map.of("term", Map.of("acl_user_ids", aclFilter.userId())));
        }
        if (aclFilter.department() != null) {
            should.add(Map.of("term", Map.of("acl_departments", aclFilter.department())));
        }
        return List.of(Map.of("bool", Map.of("should", should, "minimum_should_match", 1)));
    }

    private String writeJson(Map<String, Object> query) {
        try {
            return objectMapper.writeValueAsString(query);
        } catch (JsonProcessingException error) {
            throw new IllegalStateException("Failed to serialize Elasticsearch query", error);
        }
    }

    private static List<Double> toDoubleList(float[] vector) {
        List<Double> values = new ArrayList<>(vector.length);
        for (float value : vector) {
            values.add((double) value);
        }
        return values;
    }

    private static Map<String, Object> metadata(Map<String, Object> source) {
        Object value = source.get("metadata");
        if (value instanceof Map<?, ?> map) {
            Map<String, Object> metadata = new LinkedHashMap<>();
            map.forEach((key, mapValue) -> metadata.put(String.valueOf(key), mapValue));
            return metadata;
        }
        return new LinkedHashMap<>();
    }

    private static Object value(Map<String, Object> source, String... keys) {
        for (String key : keys) {
            Object value = source.get(key);
            if (value != null) {
                return value;
            }
        }
        return null;
    }

    private static String stringValue(Map<String, Object> source, String... keys) {
        Object value = value(source, keys);
        return value == null ? "" : value.toString();
    }

    private static void putIfPresent(Map<String, Object> metadata, String key, Object value) {
        if (value == null || value.toString().isBlank()) {
            return;
        }
        metadata.putIfAbsent(key, value);
    }
}
