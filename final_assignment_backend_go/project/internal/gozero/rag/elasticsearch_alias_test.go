package rag

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	elasticsearch "github.com/elastic/go-elasticsearch/v8"
)

// aliasServer 是一个只实现别名相关 API 的假 Elasticsearch。
type aliasServer struct {
	aliasTargets map[string][]string
	aliasUpdates [][]byte
	createdIndex []string
	// writeIndex 非空时，该索引在别名元数据里带上 is_write_index=true。
	writeIndex string
}

func newAliasServer(aliasTargets map[string][]string) *aliasServer {
	return &aliasServer{aliasTargets: aliasTargets}
}

// newAliasIndexManager 建立一个写入索引固定为 rag_chunk_go_768_v1 的索引管理器。
func newAliasIndexManager(t *testing.T, handler http.HandlerFunc) *ElasticsearchIndexManager {
	t.Helper()
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// The client refuses to talk to a server that does not identify as Elasticsearch.
		w.Header().Set("X-Elastic-Product", "Elasticsearch")
		handler(w, r)
	}))
	t.Cleanup(server.Close)
	client, err := elasticsearch.NewClient(elasticsearch.Config{Addresses: []string{server.URL}})
	if err != nil {
		t.Fatalf("create Elasticsearch client: %v", err)
	}
	return NewElasticsearchIndexManager(client, ElasticsearchIndexConfig{
		IndexName:  "rag_chunk_go_768_v1",
		AliasName:  "rag_chunk_go_current",
		Dimensions: 768,
	})
}

func (s *aliasServer) handler(t *testing.T) http.HandlerFunc {
	t.Helper()
	return func(w http.ResponseWriter, r *http.Request) {
		switch {
		case r.Method == http.MethodPut:
			s.createdIndex = append(s.createdIndex, strings.TrimPrefix(r.URL.Path, "/"))
			w.WriteHeader(http.StatusOK)
			_, _ = w.Write([]byte(`{"acknowledged":true}`))
		case r.Method == http.MethodGet && strings.HasPrefix(r.URL.Path, "/_alias/"):
			alias := strings.TrimPrefix(r.URL.Path, "/_alias/")
			targets := s.aliasTargets[alias]
			if len(targets) == 0 {
				w.WriteHeader(http.StatusNotFound)
				_, _ = w.Write([]byte(`{"error":{"type":"alias_not_found_exception"}}`))
				return
			}
			payload := map[string]any{}
			for _, target := range targets {
				metadata := map[string]any{}
				if s.writeIndex != "" && target == s.writeIndex {
					metadata["is_write_index"] = true
				}
				payload[target] = map[string]any{"aliases": map[string]any{alias: metadata}}
			}
			w.Header().Set("Content-Type", "application/json")
			_ = json.NewEncoder(w).Encode(payload)
		case r.Method == http.MethodPost && r.URL.Path == "/_aliases":
			body, _ := io.ReadAll(r.Body)
			s.aliasUpdates = append(s.aliasUpdates, body)
			w.WriteHeader(http.StatusOK)
			_, _ = w.Write([]byte(`{"acknowledged":true}`))
		case r.Method == http.MethodHead:
			// 索引存在性探测：这个假服务里的索引只在 PUT 之后才存在。
			w.WriteHeader(http.StatusNotFound)
		default:
			w.WriteHeader(http.StatusOK)
			_, _ = w.Write([]byte(`{}`))
		}
	}
}

func TestEnsureReadyFollowsExistingAliasInsteadOfRevertingIt(t *testing.T) {
	server := newAliasServer(map[string][]string{
		"rag_chunk_go_current": {"rag_chunk_go_v1"},
	})
	manager := newAliasIndexManager(t, server.handler(t))

	if err := manager.ensureReady(context.Background()); err != nil {
		t.Fatalf("ensureReady() error = %v", err)
	}
	if len(server.aliasUpdates) != 0 {
		t.Fatalf("alias updates = %d, want 0: an existing alias is authoritative", len(server.aliasUpdates))
	}
	if manager.activeIndex != "rag_chunk_go_v1" {
		t.Fatalf("activeIndex = %q, want the alias target", manager.activeIndex)
	}
}

func TestEnsureReadyCreatesConfiguredIndexWhenAliasIsMissing(t *testing.T) {
	server := newAliasServer(nil)
	manager := newAliasIndexManager(t, server.handler(t))

	if err := manager.ensureReady(context.Background()); err != nil {
		t.Fatalf("ensureReady() error = %v", err)
	}
	if len(server.createdIndex) != 1 || server.createdIndex[0] != "rag_chunk_go_768_v1" {
		t.Fatalf("created indexes = %v, want the configured index", server.createdIndex)
	}
	if len(server.aliasUpdates) != 1 {
		t.Fatalf("alias updates = %d, want 1", len(server.aliasUpdates))
	}
	if body := string(server.aliasUpdates[0]); !strings.Contains(body, "rag_chunk_go_768_v1") {
		t.Fatalf("alias update = %s, want the configured index", body)
	}
}

func TestAliasIndicesPrefersTheWriteIndex(t *testing.T) {
	server := newAliasServer(map[string][]string{
		"rag_chunk_go_current": {"rag_chunk_go_768_v1", "rag_chunk_go_768_v2"},
	})
	server.writeIndex = "rag_chunk_go_768_v2"
	manager := newAliasIndexManager(t, server.handler(t))

	indices, err := manager.aliasIndices(context.Background())
	if err != nil {
		t.Fatalf("aliasIndices() error = %v", err)
	}
	if len(indices) != 2 {
		t.Fatalf("indices = %v, want two entries", indices)
	}
	if indices[0] != "rag_chunk_go_768_v2" {
		t.Fatalf("indices = %v, want the write index first", indices)
	}
}

func TestEnsureReadyKeepsAliasWhenItAlreadyPointsAtConfiguredIndex(t *testing.T) {
	server := newAliasServer(map[string][]string{
		"rag_chunk_go_current": {"rag_chunk_go_768_v1"},
	})
	manager := newAliasIndexManager(t, server.handler(t))

	if err := manager.ensureReady(context.Background()); err != nil {
		t.Fatalf("ensureReady() error = %v", err)
	}
	if len(server.aliasUpdates) != 0 {
		t.Fatalf("alias updates = %d, want 0", len(server.aliasUpdates))
	}
}

func TestEnsureReadyKeepsManualMigrationTarget(t *testing.T) {
	// 模拟重启：上一个进程用迁移端点把别名指向 v2，配置里的索引仍是 v1。
	server := newAliasServer(map[string][]string{
		"rag_chunk_go_current": {"rag_chunk_go_768_v2"},
	})
	manager := newAliasIndexManager(t, server.handler(t))

	if err := manager.ensureReady(context.Background()); err != nil {
		t.Fatalf("ensureReady() error = %v", err)
	}
	if len(server.aliasUpdates) != 0 {
		t.Fatalf("alias updates = %d, want 0: the migration target must not be reverted", len(server.aliasUpdates))
	}
	if manager.activeIndex != "rag_chunk_go_768_v2" {
		t.Fatalf("activeIndex = %q, want the migration target", manager.activeIndex)
	}
}
