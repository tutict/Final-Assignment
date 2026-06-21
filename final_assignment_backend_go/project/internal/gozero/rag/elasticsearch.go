package rag

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"sync"

	"final_assignment_backend_go/project/internal/domain"

	elasticsearch "github.com/elastic/go-elasticsearch/v8"
	"github.com/elastic/go-elasticsearch/v8/esapi"
)

type ElasticsearchIndexConfig struct {
	IndexName        string
	AliasName        string
	Dimensions       int
	NumberOfShards   int
	NumberOfReplicas int
	RefreshInterval  string
	TextAnalyzer     string
}

type ElasticsearchIndexManager struct {
	client *elasticsearch.Client
	config ElasticsearchIndexConfig
	ready  bool
	mutex  sync.Mutex
}

func NewElasticsearchIndexManager(client *elasticsearch.Client, config ElasticsearchIndexConfig) *ElasticsearchIndexManager {
	if config.IndexName == "" {
		config.IndexName = defaultIndexName
	}
	if config.AliasName == "" {
		config.AliasName = defaultAliasName
	}
	if config.Dimensions <= 0 {
		config.Dimensions = defaultEmbeddingDims
	}
	if config.NumberOfShards <= 0 {
		config.NumberOfShards = 1
	}
	if config.RefreshInterval == "" {
		config.RefreshInterval = "30s"
	}
	if config.TextAnalyzer == "" {
		config.TextAnalyzer = "standard"
	}
	return &ElasticsearchIndexManager{client: client, config: config}
}

func (m *ElasticsearchIndexManager) CreateIndex(ctx context.Context, indexName string) (bool, error) {
	if m == nil || m.client == nil {
		return false, fmt.Errorf("Elasticsearch client is not configured")
	}
	indexName = defaultIfBlank(indexName, m.config.IndexName)
	existsReq := esapi.IndicesExistsRequest{Index: []string{indexName}}
	existsResp, err := existsReq.Do(ctx, m.client)
	if err != nil {
		return false, fmt.Errorf("check Elasticsearch index %s: %w", indexName, err)
	}
	defer existsResp.Body.Close()
	switch existsResp.StatusCode {
	case http.StatusOK:
		return false, nil
	case http.StatusNotFound:
	default:
		return false, esError("check Elasticsearch index "+indexName, existsResp)
	}

	body, err := json.Marshal(m.indexDefinition())
	if err != nil {
		return false, fmt.Errorf("marshal Elasticsearch RAG index mapping: %w", err)
	}
	createReq := esapi.IndicesCreateRequest{
		Index: indexName,
		Body:  bytes.NewReader(body),
	}
	createResp, err := createReq.Do(ctx, m.client)
	if err != nil {
		return false, fmt.Errorf("create Elasticsearch index %s: %w", indexName, err)
	}
	defer createResp.Body.Close()
	if createResp.IsError() {
		return false, esError("create Elasticsearch index "+indexName, createResp)
	}
	return true, nil
}

func (m *ElasticsearchIndexManager) SwitchWriteAlias(ctx context.Context, indexName string) (bool, error) {
	if m == nil || m.client == nil {
		return false, fmt.Errorf("Elasticsearch client is not configured")
	}
	indexName = defaultIfBlank(indexName, m.config.IndexName)
	existing, err := m.aliasIndices(ctx)
	if err != nil {
		return false, err
	}
	actions := make([]map[string]any, 0, len(existing)+1)
	for _, existingIndex := range existing {
		if existingIndex == indexName {
			continue
		}
		actions = append(actions, map[string]any{
			"remove": map[string]any{
				"index": existingIndex,
				"alias": m.config.AliasName,
			},
		})
	}
	actions = append(actions, map[string]any{
		"add": map[string]any{
			"index":          indexName,
			"alias":          m.config.AliasName,
			"is_write_index": true,
		},
	})
	body, err := json.Marshal(map[string]any{"actions": actions})
	if err != nil {
		return false, fmt.Errorf("marshal Elasticsearch alias switch: %w", err)
	}
	req := esapi.IndicesUpdateAliasesRequest{Body: bytes.NewReader(body)}
	resp, err := req.Do(ctx, m.client)
	if err != nil {
		return false, fmt.Errorf("switch Elasticsearch alias %s: %w", m.config.AliasName, err)
	}
	defer resp.Body.Close()
	if resp.IsError() {
		return false, esError("switch Elasticsearch alias "+m.config.AliasName, resp)
	}
	m.ready = false
	return true, nil
}

func (m *ElasticsearchIndexManager) DefaultIndexName() string {
	if m == nil {
		return defaultIndexName
	}
	return m.config.IndexName
}

func (m *ElasticsearchIndexManager) AliasName() string {
	if m == nil {
		return ""
	}
	return m.config.AliasName
}

func (m *ElasticsearchIndexManager) IndexChunk(
	ctx context.Context,
	document domain.RagDocument,
	chunk domain.RagChunk,
	vector []float32,
	provider string,
	model string,
) error {
	if m == nil || m.client == nil {
		return fmt.Errorf("Elasticsearch client is not configured")
	}
	if err := m.ensureReady(ctx); err != nil {
		return err
	}
	source, err := json.Marshal(m.chunkSource(document, chunk, vector, provider, model))
	if err != nil {
		return fmt.Errorf("marshal RAG chunk vector document: %w", err)
	}
	req := esapi.IndexRequest{
		Index:      m.config.AliasName,
		DocumentID: chunk.ID,
		Body:       bytes.NewReader(source),
		Refresh:    "false",
	}
	resp, err := req.Do(ctx, m.client)
	if err != nil {
		return fmt.Errorf("index RAG chunk %s into Elasticsearch: %w", chunk.ID, err)
	}
	defer resp.Body.Close()
	if resp.IsError() {
		return esError("index RAG chunk "+chunk.ID, resp)
	}
	return nil
}

func (m *ElasticsearchIndexManager) ensureReady(ctx context.Context) error {
	m.mutex.Lock()
	defer m.mutex.Unlock()
	if m.ready {
		return nil
	}
	if _, err := m.CreateIndex(ctx, m.config.IndexName); err != nil {
		return err
	}
	existsReq := esapi.IndicesExistsAliasRequest{Name: []string{m.config.AliasName}}
	existsResp, err := existsReq.Do(ctx, m.client)
	if err != nil {
		return fmt.Errorf("check Elasticsearch alias %s: %w", m.config.AliasName, err)
	}
	defer existsResp.Body.Close()
	if existsResp.StatusCode == http.StatusNotFound {
		if _, err := m.SwitchWriteAlias(ctx, m.config.IndexName); err != nil {
			return err
		}
	} else if existsResp.StatusCode != http.StatusOK {
		return esError("check Elasticsearch alias "+m.config.AliasName, existsResp)
	}
	m.ready = true
	return nil
}

func (m *ElasticsearchIndexManager) aliasIndices(ctx context.Context) ([]string, error) {
	req := esapi.IndicesGetAliasRequest{Name: []string{m.config.AliasName}}
	resp, err := req.Do(ctx, m.client)
	if err != nil {
		return nil, fmt.Errorf("get Elasticsearch alias %s: %w", m.config.AliasName, err)
	}
	defer resp.Body.Close()
	if resp.StatusCode == http.StatusNotFound {
		return nil, nil
	}
	if resp.IsError() {
		return nil, esError("get Elasticsearch alias "+m.config.AliasName, resp)
	}
	var payload map[string]struct {
		Aliases map[string]any `json:"aliases"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&payload); err != nil {
		return nil, fmt.Errorf("decode Elasticsearch alias %s: %w", m.config.AliasName, err)
	}
	indices := make([]string, 0, len(payload))
	for indexName, value := range payload {
		if _, ok := value.Aliases[m.config.AliasName]; ok {
			indices = append(indices, indexName)
		}
	}
	return indices, nil
}

func (m *ElasticsearchIndexManager) indexDefinition() map[string]any {
	return map[string]any{
		"settings": map[string]any{
			"index": map[string]any{
				"number_of_shards":   m.config.NumberOfShards,
				"number_of_replicas": m.config.NumberOfReplicas,
				"refresh_interval":   m.config.RefreshInterval,
			},
		},
		"mappings": map[string]any{
			"properties": map[string]any{
				"chunk_id":           keyword(),
				"document_id":        keyword(),
				"content":            text(m.config.TextAnalyzer),
				"title":              textWithKeyword(m.config.TextAnalyzer),
				"source_type":        keyword(),
				"source_table":       keyword(),
				"source_id":          keyword(),
				"source_field":       keywordWithText(m.config.TextAnalyzer),
				"source_version":     keyword(),
				"route":              keyword(),
				"acl_scope":          keyword(),
				"acl_roles":          keyword(),
				"acl_user_ids":       keyword(),
				"acl_departments":    keyword(),
				"metadata":           map[string]any{"type": "object", "enabled": true},
				"embedding_provider": keyword(),
				"embedding_model":    keyword(),
				"embedding": map[string]any{
					"type":       "dense_vector",
					"dims":       m.config.Dimensions,
					"index":      true,
					"similarity": "cosine",
				},
			},
		},
	}
}

func (m *ElasticsearchIndexManager) chunkSource(
	document domain.RagDocument,
	chunk domain.RagChunk,
	vector []float32,
	provider string,
	model string,
) map[string]any {
	metadata := metadataMap(document.MetadataJSON)
	return map[string]any{
		"chunk_id":           chunk.ID,
		"document_id":        document.ID,
		"content":            chunk.Content,
		"title":              document.Title,
		"source_type":        document.SourceType,
		"source_table":       document.SourceTable,
		"source_id":          document.SourceID,
		"source_version":     document.SourceVersion,
		"source_field":       chunk.SourceField,
		"route":              document.Route,
		"acl_scope":          document.ACLScope,
		"acl_roles":          listMetadataValue(metadata, "acl_roles", "aclRoles", "roles"),
		"acl_user_ids":       listMetadataValue(metadata, "acl_user_ids", "aclUserIds", "userIds"),
		"acl_departments":    listMetadataValue(metadata, "acl_departments", "aclDepartments", "departments"),
		"metadata":           metadata,
		"embedding_provider": provider,
		"embedding_model":    model,
		"embedding":          vector,
	}
}

func metadataMap(value string) map[string]any {
	metadata := make(map[string]any)
	if strings.TrimSpace(value) == "" {
		return metadata
	}
	if err := json.Unmarshal([]byte(value), &metadata); err != nil {
		return map[string]any{
			"rawMetadata":        value,
			"metadataParseError": err.Error(),
		}
	}
	return metadata
}

func listMetadataValue(metadata map[string]any, keys ...string) []string {
	for _, key := range keys {
		value, ok := metadata[key]
		if !ok || value == nil {
			continue
		}
		switch typed := value.(type) {
		case []any:
			values := make([]string, 0, len(typed))
			for _, item := range typed {
				if item != nil && strings.TrimSpace(fmt.Sprint(item)) != "" {
					values = append(values, strings.TrimSpace(fmt.Sprint(item)))
				}
			}
			return values
		case []string:
			return typed
		default:
			text := strings.TrimSpace(fmt.Sprint(value))
			if text != "" {
				return []string{text}
			}
		}
	}
	return []string{}
}

func keyword() map[string]any {
	return map[string]any{"type": "keyword"}
}

func text(analyzer string) map[string]any {
	return map[string]any{"type": "text", "analyzer": analyzer}
}

func textWithKeyword(analyzer string) map[string]any {
	return map[string]any{
		"type":     "text",
		"analyzer": analyzer,
		"fields": map[string]any{
			"keyword": map[string]any{"type": "keyword", "ignore_above": 256},
		},
	}
}

func keywordWithText(analyzer string) map[string]any {
	return map[string]any{
		"type": "keyword",
		"fields": map[string]any{
			"text": text(analyzer),
		},
	}
}

func defaultIfBlank(value, fallback string) string {
	if strings.TrimSpace(value) == "" {
		return fallback
	}
	return strings.TrimSpace(value)
}

func esError(action string, resp *esapi.Response) error {
	raw, _ := io.ReadAll(resp.Body)
	message := strings.TrimSpace(string(raw))
	if message == "" {
		message = resp.String()
	}
	return fmt.Errorf("%s failed with HTTP %d: %s", action, resp.StatusCode, message)
}
