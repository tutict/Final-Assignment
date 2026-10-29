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
				payload[target] = map[string]any{"aliases": map[string]any{alias: map[string]any{}}}
			}
			w.Header().Set("Content-Type", "application/json")
			_ = json.NewEncoder(w).Encode(payload)
		case r.Method == http.MethodPost && r.URL.Path == "/_aliases":
			body, _ := io.ReadAll(r.Body)
			s.aliasUpdates = append(s.aliasUpdates, body)
			w.WriteHeader(http.StatusOK)
			_, _ = w.Write([]byte(`{"acknowledged":true}`))
		default:
			w.WriteHeader(http.StatusOK)
			_, _ = w.Write([]byte(`{}`))
		}
	}
}

func TestEnsureReadySwitchesAliasToConfiguredIndex(t *testing.T) {
	server := newAliasServer(map[string][]string{
		"rag_chunk_go_current": {"rag_chunk_go_v1"},
	})
	manager := newAliasIndexManager(t, server.handler(t))

	if err := manager.ensureReady(context.Background()); err != nil {
		t.Fatalf("ensureReady() error = %v", err)
	}
	if len(server.aliasUpdates) != 1 {
		t.Fatalf("alias updates = %d, want 1", len(server.aliasUpdates))
	}
	body := string(server.aliasUpdates[0])
	if !strings.Contains(body, "rag_chunk_go_768_v1") {
		t.Fatalf("alias update = %s, want the configured index", body)
	}
	if !strings.Contains(body, "rag_chunk_go_v1") {
		t.Fatalf("alias update = %s, want the stale index removed", body)
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
	server := newAliasServer(map[string][]string{
		"rag_chunk_go_current": {"rag_chunk_go_768_v1"},
	})
	manager := newAliasIndexManager(t, server.handler(t))

	if _, err := manager.SwitchWriteAlias(context.Background(), "rag_chunk_go_768_v2"); err != nil {
		t.Fatalf("SwitchWriteAlias() error = %v", err)
	}
	server.aliasTargets["rag_chunk_go_current"] = []string{"rag_chunk_go_768_v2"}
	server.aliasUpdates = nil

	if err := manager.ensureReady(context.Background()); err != nil {
		t.Fatalf("ensureReady() error = %v", err)
	}
	if len(server.aliasUpdates) != 0 {
		t.Fatalf("alias updates = %d, want 0: the migration target must not be reverted", len(server.aliasUpdates))
	}
}
