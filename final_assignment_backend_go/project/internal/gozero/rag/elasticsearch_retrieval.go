package rag

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"

	"final_assignment_backend_go/project/internal/service"

	"github.com/elastic/go-elasticsearch/v8/esapi"
)

func (m *ElasticsearchIndexManager) BM25Search(
	ctx context.Context,
	normalizedQuery string,
	aclFilter service.RagAccessFilter,
	limit int,
) ([]service.RagRetrievalResult, error) {
	if m == nil || m.client == nil {
		return nil, fmt.Errorf("Elasticsearch client is not configured")
	}
	query := map[string]any{
		"size":    normalizeSearchLimit(limit),
		"_source": ragSearchSourceFilter(),
		"query": map[string]any{
			"bool": map[string]any{
				"should": []any{
					map[string]any{"multi_match": map[string]any{
						"query": normalizedQuery,
						"fields": []string{
							"title^4",
							"content^3",
							"source_field.text^1.5",
							"source_type",
							"source_table",
						},
					}},
					map[string]any{"match_phrase": map[string]any{
						"title": map[string]any{"query": normalizedQuery, "boost": 2},
					}},
					map[string]any{"match_phrase": map[string]any{
						"content": map[string]any{"query": normalizedQuery, "boost": 1.5},
					}},
				},
				"minimum_should_match": 1,
				"filter":               []any{ragACLFilterQuery(aclFilter)},
			},
		},
	}
	return m.executeRagSearch(ctx, query, "bm25")
}

func (m *ElasticsearchIndexManager) VectorSearch(
	ctx context.Context,
	queryVector []float32,
	aclFilter service.RagAccessFilter,
	limit int,
) ([]service.RagRetrievalResult, error) {
	if m == nil || m.client == nil {
		return nil, fmt.Errorf("Elasticsearch client is not configured")
	}
	limit = normalizeSearchLimit(limit)
	query := map[string]any{
		"size":    limit,
		"_source": ragSearchSourceFilter(),
		"knn": map[string]any{
			"field":          "embedding",
			"query_vector":   float32ToFloat64List(queryVector),
			"k":              limit,
			"num_candidates": intMax(50, limit*4),
			"filter":         ragACLFilterQuery(aclFilter),
		},
	}
	results, err := m.executeRagSearch(ctx, query, "vector")
	if err == nil {
		return results, nil
	}
	return m.executeRagSearch(ctx, ragScriptScoreQuery(queryVector, aclFilter, limit), "vector")
}

func (m *ElasticsearchIndexManager) executeRagSearch(
	ctx context.Context,
	query map[string]any,
	mode string,
) ([]service.RagRetrievalResult, error) {
	if err := m.ensureReady(ctx); err != nil {
		return nil, err
	}
	hits, err := m.searchRagOnce(ctx, m.config.AliasName, query)
	if err != nil && strings.TrimSpace(m.config.IndexName) != "" && m.config.IndexName != m.config.AliasName {
		hits, err = m.searchRagOnce(ctx, m.config.IndexName, query)
	}
	if err != nil {
		return nil, err
	}
	results := make([]service.RagRetrievalResult, 0, len(hits))
	for _, hit := range hits {
		result, ok := ragHitToResult(hit.Source, hit.Score, mode)
		if ok {
			results = append(results, result)
		}
	}
	return results, nil
}

func (m *ElasticsearchIndexManager) searchRagOnce(
	ctx context.Context,
	indexName string,
	query map[string]any,
) ([]ragSearchHit, error) {
	body, err := json.Marshal(query)
	if err != nil {
		return nil, fmt.Errorf("marshal Elasticsearch RAG search query: %w", err)
	}
	req := esapi.SearchRequest{
		Index: []string{indexName},
		Body:  bytes.NewReader(body),
	}
	resp, err := req.Do(ctx, m.client)
	if err != nil {
		return nil, fmt.Errorf("search Elasticsearch RAG index %s: %w", indexName, err)
	}
	defer resp.Body.Close()
	if resp.StatusCode == http.StatusNotFound {
		return nil, esError("search Elasticsearch RAG index "+indexName, resp)
	}
	if resp.IsError() {
		return nil, esError("search Elasticsearch RAG index "+indexName, resp)
	}
	var payload ragSearchResponse
	if err := json.NewDecoder(resp.Body).Decode(&payload); err != nil {
		return nil, fmt.Errorf("decode Elasticsearch RAG search response: %w", err)
	}
	return payload.Hits.Hits, nil
}

func ragScriptScoreQuery(queryVector []float32, aclFilter service.RagAccessFilter, limit int) map[string]any {
	return map[string]any{
		"size":    normalizeSearchLimit(limit),
		"_source": ragSearchSourceFilter(),
		"query": map[string]any{
			"script_score": map[string]any{
				"query": map[string]any{
					"bool": map[string]any{"filter": []any{ragACLFilterQuery(aclFilter)}},
				},
				"script": map[string]any{
					"source": "cosineSimilarity(params.query_vector, 'embedding') + 1.0",
					"params": map[string]any{"query_vector": float32ToFloat64List(queryVector)},
				},
			},
		},
	}
}

func ragACLFilterQuery(aclFilter service.RagAccessFilter) map[string]any {
	should := []any{
		map[string]any{"term": map[string]any{"acl_scope": "PUBLIC"}},
	}
	for _, role := range aclFilter.Roles {
		if strings.TrimSpace(role) != "" {
			should = append(should, map[string]any{"term": map[string]any{"acl_roles": strings.TrimSpace(role)}})
		}
	}
	if strings.TrimSpace(aclFilter.UserID) != "" {
		should = append(should, map[string]any{"term": map[string]any{"acl_user_ids": strings.TrimSpace(aclFilter.UserID)}})
	}
	if strings.TrimSpace(aclFilter.Department) != "" {
		should = append(should, map[string]any{"term": map[string]any{"acl_departments": strings.TrimSpace(aclFilter.Department)}})
	}
	return map[string]any{
		"bool": map[string]any{
			"should":               should,
			"minimum_should_match": 1,
		},
	}
}

func ragSearchSourceFilter() map[string]any {
	return map[string]any{"excludes": []string{"embedding"}}
}

func ragHitToResult(source map[string]any, score float64, mode string) (service.RagRetrievalResult, bool) {
	chunkID := sourceString(source, "chunk_id", "chunkId")
	if strings.TrimSpace(chunkID) == "" {
		return service.RagRetrievalResult{}, false
	}
	metadata := ragMetadataMap(source)
	aclScope := sourceString(source, "acl_scope", "aclScope")
	aclRoles := sourceStringList(source, "acl_roles", "aclRoles")
	aclUserIDs := sourceStringList(source, "acl_user_ids", "aclUserIds")
	aclDepartments := sourceStringList(source, "acl_departments", "aclDepartments")
	putMetadataIfPresent(metadata, "acl_scope", aclScope)
	putMetadataListIfPresent(metadata, "acl_roles", aclRoles)
	putMetadataListIfPresent(metadata, "acl_user_ids", aclUserIDs)
	putMetadataListIfPresent(metadata, "acl_departments", aclDepartments)

	result := service.RagRetrievalResult{
		ChunkID:        chunkID,
		DocumentID:     sourceString(source, "document_id", "documentId"),
		Content:        sourceString(source, "content"),
		Title:          sourceString(source, "title"),
		SourceType:     sourceString(source, "source_type", "sourceType"),
		SourceTable:    sourceString(source, "source_table", "sourceTable"),
		SourceID:       sourceString(source, "source_id", "sourceId"),
		SourceField:    sourceString(source, "source_field", "sourceField"),
		Route:          sourceString(source, "route"),
		Metadata:       metadata,
		ACLScope:       aclScope,
		ACLRoles:       aclRoles,
		ACLUserIDs:     aclUserIDs,
		ACLDepartments: aclDepartments,
	}
	if mode == "bm25" {
		result.BM25Score = score
	} else if mode == "vector" {
		result.VectorScore = score
	}
	return result, true
}

func ragMetadataMap(source map[string]any) map[string]any {
	value, ok := source["metadata"]
	if !ok || value == nil {
		return map[string]any{}
	}
	if metadata, ok := value.(map[string]any); ok {
		clone := make(map[string]any, len(metadata))
		for key, item := range metadata {
			clone[key] = item
		}
		return clone
	}
	return map[string]any{}
}

func sourceString(source map[string]any, keys ...string) string {
	for _, key := range keys {
		value, ok := source[key]
		if ok && value != nil && strings.TrimSpace(fmt.Sprint(value)) != "" {
			return strings.TrimSpace(fmt.Sprint(value))
		}
	}
	return ""
}

func sourceStringList(source map[string]any, keys ...string) []string {
	for _, key := range keys {
		value, ok := source[key]
		if !ok || value == nil {
			continue
		}
		switch typed := value.(type) {
		case []string:
			return cleanStringList(typed)
		case []any:
			values := make([]string, 0, len(typed))
			for _, item := range typed {
				values = append(values, fmt.Sprint(item))
			}
			return cleanStringList(values)
		default:
			text := strings.TrimSpace(fmt.Sprint(value))
			if text != "" {
				return []string{text}
			}
		}
	}
	return nil
}

func putMetadataIfPresent(metadata map[string]any, key string, value string) {
	if strings.TrimSpace(value) == "" {
		return
	}
	if _, exists := metadata[key]; !exists {
		metadata[key] = strings.TrimSpace(value)
	}
}

func putMetadataListIfPresent(metadata map[string]any, key string, values []string) {
	values = cleanStringList(values)
	if len(values) == 0 {
		return
	}
	if _, exists := metadata[key]; !exists {
		metadata[key] = values
	}
}

func cleanStringList(values []string) []string {
	cleaned := make([]string, 0, len(values))
	for _, value := range values {
		value = strings.TrimSpace(value)
		if value != "" {
			cleaned = append(cleaned, value)
		}
	}
	return cleaned
}

func float32ToFloat64List(vector []float32) []float64 {
	values := make([]float64, 0, len(vector))
	for _, value := range vector {
		values = append(values, float64(value))
	}
	return values
}

func normalizeSearchLimit(limit int) int {
	if limit < 1 {
		return 1
	}
	return limit
}

func intMax(left, right int) int {
	if left > right {
		return left
	}
	return right
}

type ragSearchResponse struct {
	Hits struct {
		Hits []ragSearchHit `json:"hits"`
	} `json:"hits"`
}

type ragSearchHit struct {
	Score  float64        `json:"_score"`
	Source map[string]any `json:"_source"`
}
