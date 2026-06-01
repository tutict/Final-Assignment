package com.tutict.finalassignmentcloud.rag.ai.retrieval;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tutict.finalassignmentcloud.rag.ai.config.RagChunkIndexMapping;
import com.tutict.finalassignmentcloud.rag.ai.dto.RetrievalResult;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.elasticsearch.core.ElasticsearchOperations;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
@ConditionalOnProperty(prefix = "rag.retrieval", name = "enabled", havingValue = "true")
public class EmbeddingSearchService {

    private final EmbeddingProvider embeddingProvider;
    private final RagSearchBackend searchBackend;

    @Autowired
    public EmbeddingSearchService(
            EmbeddingProvider embeddingProvider,
            ObjectProvider<ElasticsearchOperations> elasticsearchOperations,
            RagChunkIndexMapping mapping,
            ObjectMapper objectMapper,
            @Value("${spring.elasticsearch.uris:http://localhost:9200}") String elasticsearchUris
    ) {
        this(
                embeddingProvider,
                new ElasticsearchRagSearchBackend(
                        elasticsearchOperations.getIfAvailable(),
                        mapping.aliasName(),
                        mapping.indexName(),
                        objectMapper,
                        elasticsearchUris
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
        try {
            return searchBackend.bm25Search(normalizedQuery, aclFilter, Math.max(1, limit));
        } catch (RuntimeException error) {
            return List.of();
        }
    }

    public List<RetrievalResult> vectorSearch(
            float[] queryVector,
            AclFilterService.AclFilter aclFilter,
            int limit
    ) {
        try {
            return searchBackend.vectorSearch(queryVector, aclFilter, Math.max(1, limit));
        } catch (RuntimeException error) {
            return List.of();
        }
    }
}

interface RagSearchBackend {

    List<RetrievalResult> bm25Search(String normalizedQuery, AclFilterService.AclFilter aclFilter, int limit);

    List<RetrievalResult> vectorSearch(float[] queryVector, AclFilterService.AclFilter aclFilter, int limit);
}

class ElasticsearchRagSearchBackend implements RagSearchBackend {

    private final ElasticsearchOperations operations;
    private final String indexAlias;
    private final String fallbackIndex;
    private final ObjectMapper objectMapper;
    private final URI elasticsearchBaseUri;
    private final HttpClient httpClient = HttpClient.newHttpClient();

    ElasticsearchRagSearchBackend(
            ElasticsearchOperations operations,
            String indexAlias,
            String fallbackIndex,
            ObjectMapper objectMapper,
            String elasticsearchUris
    ) {
        this.operations = operations;
        this.indexAlias = indexAlias;
        this.fallbackIndex = fallbackIndex;
        this.objectMapper = objectMapper;
        this.elasticsearchBaseUri = URI.create(firstUri(elasticsearchUris));
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
        Map<String, Object> query = new LinkedHashMap<>();
        query.put("size", limit);
        query.put("_source", sourceFilter());
        query.put("query", Map.of(
                "bool", Map.of(
                        "should", List.of(
                                Map.of("multi_match", Map.of(
                                        "query", normalizedQuery,
                                        "fields", List.of(
                                                "title^4",
                                                "content^3",
                                                "source_field.text^1.5",
                                                "source_type",
                                                "source_table"
                                        )
                                )),
                                Map.of("match_phrase", Map.of(
                                        "title", Map.of("query", normalizedQuery, "boost", 2)
                                )),
                                Map.of("match_phrase", Map.of(
                                        "content", Map.of("query", normalizedQuery, "boost", 1.5)
                                ))
                        ),
                        "minimum_should_match", 1,
                        "filter", aclClauses(aclFilter)
                )
        ));
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
        Map<String, Object> query = new LinkedHashMap<>();
        query.put("size", limit);
        query.put("_source", sourceFilter());
        query.put("knn", Map.of(
                "field", "embedding",
                "query_vector", toDoubleList(queryVector),
                "k", limit,
                "num_candidates", Math.max(50, limit * 4),
                "filter", aclFilterQuery(aclFilter)
        ));
        try {
            return execute(query, "vector");
        } catch (RuntimeException error) {
            return execute(scriptScoreQuery(queryVector, aclFilter, limit), "vector");
        }
    }

    private static Map<String, Object> scriptScoreQuery(
            float[] queryVector,
            AclFilterService.AclFilter aclFilter,
            int limit
    ) {
        Map<String, Object> query = new LinkedHashMap<>();
        query.put("size", limit);
        query.put("_source", sourceFilter());
        query.put("query", Map.of(
                "script_score", Map.of(
                        "query", Map.of("bool", Map.of("filter", aclClauses(aclFilter))),
                        "script", Map.of(
                                "source", "cosineSimilarity(params.query_vector, 'embedding') + 1.0",
                                "params", Map.of("query_vector", toDoubleList(queryVector))
                        )
                )
        ));
        return query;
    }

    private List<RetrievalResult> execute(Map<String, Object> query, String mode) {
        List<JsonNode> hits = search(indexAlias, query);
        List<RetrievalResult> results = new ArrayList<>();
        for (JsonNode hit : hits) {
            Map<String, Object> source = objectMapper.convertValue(hit.path("_source"), Map.class);
            RetrievalResult result = toResult(source, (float) hit.path("_score").asDouble(), mode);
            if (result != null) {
                results.add(result);
            }
        }
        return results;
    }

    private List<JsonNode> search(String indexName, Map<String, Object> query) {
        try {
            return searchOnce(indexName, query);
        } catch (RuntimeException error) {
            if (fallbackIndex == null || fallbackIndex.isBlank()
                    || fallbackIndex.equals(indexName)) {
                throw error;
            }
            return searchOnce(fallbackIndex, query);
        }
    }

    private List<JsonNode> searchOnce(String indexName, Map<String, Object> query) {
        try {
            HttpRequest request = HttpRequest.newBuilder(searchUri(indexName))
                    .header("Content-Type", "application/json; charset=utf-8")
                    .header("Accept", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(writeJson(query), StandardCharsets.UTF_8))
                    .build();
            HttpResponse<String> response = httpClient.send(
                    request,
                    HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8)
            );
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                throw new IllegalStateException("Elasticsearch RAG search failed with HTTP "
                        + response.statusCode() + " from " + request.uri() + ": " + response.body());
            }
            JsonNode hits = objectMapper.readTree(response.body()).path("hits").path("hits");
            List<JsonNode> results = new ArrayList<>();
            if (hits.isArray()) {
                hits.forEach(results::add);
            }
            return results;
        } catch (IOException error) {
            throw new IllegalStateException("Elasticsearch RAG search request failed", error);
        } catch (InterruptedException error) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Elasticsearch RAG search request was interrupted", error);
        }
    }

    private URI searchUri(String indexName) {
        String base = elasticsearchBaseUri.toString();
        if (base.endsWith("/")) {
            base = base.substring(0, base.length() - 1);
        }
        return URI.create(base + "/" + indexName + "/_search");
    }

    private static String firstUri(String uris) {
        if (uris == null || uris.isBlank()) {
            return "http://localhost:9200";
        }
        return uris.split(",")[0].trim();
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
        return List.of(aclFilterQuery(aclFilter));
    }

    private static Map<String, Object> aclFilterQuery(AclFilterService.AclFilter aclFilter) {
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
        return Map.of("bool", Map.of("should", should, "minimum_should_match", 1));
    }

    private static Map<String, Object> sourceFilter() {
        return Map.of("excludes", List.of("embedding"));
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

