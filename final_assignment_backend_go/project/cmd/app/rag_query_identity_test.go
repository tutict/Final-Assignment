package main

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	gozerorag "final_assignment_backend_go/project/internal/gozero/rag"
	ragsvc "final_assignment_backend_go/project/internal/service/rag"

	"github.com/gin-gonic/gin"
)

// recordingRagBackend 记录检索时使用的身份，并返回固定候选。
type recordingRagBackend struct {
	filter  ragsvc.RagAccessFilter
	limit   int
	results []ragsvc.RagRetrievalResult
}

func (b *recordingRagBackend) BM25Search(
	_ context.Context,
	_ string,
	filter ragsvc.RagAccessFilter,
	limit int,
) ([]ragsvc.RagRetrievalResult, error) {
	b.filter = filter
	b.limit = limit
	return b.results, nil
}

func (b *recordingRagBackend) VectorSearch(
	_ context.Context,
	_ []float32,
	_ ragsvc.RagAccessFilter,
	_ int,
) ([]ragsvc.RagRetrievalResult, error) {
	return nil, nil
}

func newRagQueryTestRouter(t *testing.T, username string, roles []string, backend *recordingRagBackend) *gin.Engine {
	t.Helper()
	gin.SetMode(gin.TestMode)

	config := ragsvc.DefaultRagConfig()
	config.RetrievalEnabled = true
	runtime := &gozerorag.Runtime{
		Enabled: true,
		Query:   ragsvc.NewRagQueryService(backend, nil, config),
	}

	router := gin.New()
	router.Use(func(c *gin.Context) {
		if username != "" {
			c.Set("username", username)
		}
		if roles != nil {
			c.Set("normalizedRoles", roles)
		}
		c.Next()
	})
	router.POST("/api/rag/query", ragQueryHandler(runtime))
	return router
}

func TestRagQueryIgnoresCallerSuppliedIdentity(t *testing.T) {
	backend := &recordingRagBackend{results: []ragsvc.RagRetrievalResult{
		{ChunkID: "public-1", Metadata: map[string]any{"acl_scope": "PUBLIC"}},
	}}
	router := newRagQueryTestRouter(t, "driver-1", []string{"USER"}, backend)

	body := `{"query":"illegal parking","topK":5,"roles":["SUPER_ADMIN"],"userId":"admin","department":"ALL"}`
	req := httptest.NewRequest(http.MethodPost, "/api/rag/query", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	res := httptest.NewRecorder()
	router.ServeHTTP(res, req)

	if res.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200: %s", res.Code, res.Body.String())
	}
	if backend.filter.UserID != "driver-1" {
		t.Fatalf("filter user = %q, want driver-1", backend.filter.UserID)
	}
	if len(backend.filter.Roles) != 1 || backend.filter.Roles[0] != "USER" {
		t.Fatalf("filter roles = %#v, want [USER]", backend.filter.Roles)
	}
	if backend.filter.Department != "" {
		t.Fatalf("filter department = %q, want empty", backend.filter.Department)
	}
}

func TestRagQueryDeniesRoleScopedChunkForPlainUser(t *testing.T) {
	backend := &recordingRagBackend{results: []ragsvc.RagRetrievalResult{
		{ChunkID: "admin-only", Metadata: map[string]any{"acl_scope": "ROLE", "acl_roles": []any{"SUPER_ADMIN"}}},
		{ChunkID: "public-1", Metadata: map[string]any{"acl_scope": "PUBLIC"}},
	}}
	router := newRagQueryTestRouter(t, "driver-1", []string{"USER"}, backend)

	req := httptest.NewRequest(http.MethodPost, "/api/rag/query", strings.NewReader(`{"query":"illegal parking"}`))
	req.Header.Set("Content-Type", "application/json")
	res := httptest.NewRecorder()
	router.ServeHTTP(res, req)

	if res.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200: %s", res.Code, res.Body.String())
	}
	if strings.Contains(res.Body.String(), "admin-only") {
		t.Fatalf("role-scoped chunk leaked for plain user: %s", res.Body.String())
	}
	if !strings.Contains(res.Body.String(), "public-1") {
		t.Fatalf("public chunk missing from response: %s", res.Body.String())
	}
}

func TestRagQueryCapsTopKAtFifty(t *testing.T) {
	backend := &recordingRagBackend{results: []ragsvc.RagRetrievalResult{
		{ChunkID: "public-1", Metadata: map[string]any{"acl_scope": "PUBLIC"}},
	}}
	router := newRagQueryTestRouter(t, "driver-1", []string{"USER"}, backend)

	req := httptest.NewRequest(http.MethodPost, "/api/rag/query", strings.NewReader(`{"query":"illegal parking","topK":5000}`))
	req.Header.Set("Content-Type", "application/json")
	res := httptest.NewRecorder()
	router.ServeHTTP(res, req)

	if res.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200: %s", res.Code, res.Body.String())
	}
	wantLimit := ragsvc.MaxRagTopK * 3
	if backend.limit != wantLimit {
		t.Fatalf("candidate limit = %d, want %d", backend.limit, wantLimit)
	}
}
