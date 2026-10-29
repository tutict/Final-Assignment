package rag

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	elasticsearch "github.com/elastic/go-elasticsearch/v8"
)

func newTestIndexManager(t *testing.T, handler http.HandlerFunc) (*ElasticsearchIndexManager, *httptest.Server) {
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
		IndexName:  "rag_chunk_go_v1",
		AliasName:  "rag_chunk_go_current",
		Dimensions: 768,
	}), server
}

func TestDeleteChunkRemovesDocumentFromAlias(t *testing.T) {
	var method, path string
	manager, _ := newTestIndexManager(t, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		method = r.Method
		path = r.URL.Path
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"result":"deleted"}`))
	}))

	if err := manager.DeleteChunk(context.Background(), "chunk-1"); err != nil {
		t.Fatalf("DeleteChunk() error = %v", err)
	}
	if method != http.MethodDelete {
		t.Fatalf("method = %q, want DELETE", method)
	}
	if path != "/rag_chunk_go_current/_doc/chunk-1" {
		t.Fatalf("path = %q, want /rag_chunk_go_current/_doc/chunk-1", path)
	}
}

func TestDeleteChunkTreatsMissingDocumentAsSuccess(t *testing.T) {
	manager, _ := newTestIndexManager(t, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusNotFound)
		_, _ = w.Write([]byte(`{"error":{"type":"document_missing_exception"}}`))
	}))

	if err := manager.DeleteChunk(context.Background(), "chunk-missing"); err != nil {
		t.Fatalf("DeleteChunk() error = %v, want nil for a missing document", err)
	}
}

func TestDeleteChunkReportsServerFailure(t *testing.T) {
	manager, _ := newTestIndexManager(t, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
		_, _ = w.Write([]byte(`{"error":"boom"}`))
	}))

	err := manager.DeleteChunk(context.Background(), "chunk-1")
	if err == nil {
		t.Fatal("expected DeleteChunk() to report the failure")
	}
	if !strings.Contains(err.Error(), "chunk-1") {
		t.Fatalf("error = %v, want the chunk id in the message", err)
	}
}

func TestDeleteChunkIgnoresBlankChunkID(t *testing.T) {
	manager, _ := newTestIndexManager(t, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Fatalf("unexpected request for a blank chunk id: %s", r.URL.Path)
	}))

	if err := manager.DeleteChunk(context.Background(), "  "); err != nil {
		t.Fatalf("DeleteChunk() error = %v", err)
	}
}
