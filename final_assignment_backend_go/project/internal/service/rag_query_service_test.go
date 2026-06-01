package service

import (
	"context"
	"testing"
)

func TestRagQueryServiceHybridRetrievalAclAndRerank(t *testing.T) {
	topK := 3
	backend := &memoryRagSearchBackend{
		bm25Results: []RagRetrievalResult{
			{
				ChunkID:     "private-appeal",
				Content:     "Illegal parking appeal record has matched evidence.",
				Title:       "Appeal record",
				SourceField: "appealReason",
				BM25Score:   9,
				Metadata: map[string]any{
					"acl_scope": "ROLE",
					"acl_roles": []any{"admin"},
				},
			},
			{
				ChunkID:   "denied-user",
				Content:   "Illegal parking hidden user note.",
				Title:     "Hidden note",
				BM25Score: 8,
				Metadata: map[string]any{
					"acl_scope":    "USER",
					"acl_user_ids": []any{"u2"},
				},
			},
		},
		vectorResults: []RagRetrievalResult{
			{
				ChunkID:     "public-rule",
				Content:     "Illegal parking rule and fine guidance.",
				Title:       "Parking rule",
				SourceField: "description",
				VectorScore: 0.91,
				Metadata: map[string]any{
					"acl_scope": "PUBLIC",
				},
			},
			{
				ChunkID:     "private-appeal",
				Content:     "Illegal parking appeal record has matched evidence.",
				Title:       "Appeal record",
				SourceField: "appealReason",
				VectorScore: 0.83,
				Metadata: map[string]any{
					"acl_scope": "ROLE",
					"acl_roles": []any{"admin"},
				},
			},
		},
	}
	config := DefaultRagConfig()
	config.RetrievalEnabled = true
	service := NewRagQueryService(backend, &memoryRagEmbeddingProvider{}, config)

	result, err := service.Query(context.Background(), RagQueryRequest{
		Query:  " illegal   parking appeal ",
		TopK:   &topK,
		UserID: "u1",
		Roles:  []string{"admin"},
	})
	if err != nil {
		t.Fatalf("Query() error = %v", err)
	}
	if backend.bm25Limit != 9 || backend.vectorLimit != 9 {
		t.Fatalf("candidate limits = bm25:%d vector:%d", backend.bm25Limit, backend.vectorLimit)
	}
	if len(result.Results) != 2 {
		t.Fatalf("result count = %d, want 2: %+v", len(result.Results), result.Results)
	}
	if result.Results[0].ChunkID != "private-appeal" {
		t.Fatalf("first chunk = %q, want private-appeal", result.Results[0].ChunkID)
	}
	if result.Results[0].BM25Score != 9 || result.Results[0].VectorScore != 0.83 {
		t.Fatalf("merged scores = bm25:%f vector:%f", result.Results[0].BM25Score, result.Results[0].VectorScore)
	}
	for _, item := range result.Results {
		if item.ChunkID == "denied-user" {
			t.Fatalf("ACL-denied result leaked into response: %+v", item)
		}
	}
}

func TestRagQueryServiceReturnsEmptyWhenDisabledOrBlank(t *testing.T) {
	service := NewRagQueryService(&memoryRagSearchBackend{}, &memoryRagEmbeddingProvider{}, DefaultRagConfig())
	result, err := service.Query(context.Background(), RagQueryRequest{Query: "traffic appeal"})
	if err != nil {
		t.Fatalf("Query() error = %v", err)
	}
	if len(result.Results) != 0 {
		t.Fatalf("disabled result count = %d, want 0", len(result.Results))
	}

	config := DefaultRagConfig()
	config.RetrievalEnabled = true
	service = NewRagQueryService(&memoryRagSearchBackend{}, &memoryRagEmbeddingProvider{}, config)
	result, err = service.Query(context.Background(), RagQueryRequest{Query: " \t\r\n "})
	if err != nil {
		t.Fatalf("blank Query() error = %v", err)
	}
	if len(result.Results) != 0 {
		t.Fatalf("blank result count = %d, want 0", len(result.Results))
	}
}

func TestRagAclAllowsPublicRoleUserAndDepartmentScopes(t *testing.T) {
	context := newRagAccessContext("u1", []string{"admin"}, "traffic")
	cases := []struct {
		name    string
		result  RagRetrievalResult
		allowed bool
	}{
		{
			name:    "public default",
			result:  RagRetrievalResult{Metadata: map[string]any{}},
			allowed: true,
		},
		{
			name:    "role match",
			result:  RagRetrievalResult{Metadata: map[string]any{"acl_scope": "ROLE", "acl_roles": []any{"admin"}}},
			allowed: true,
		},
		{
			name:    "user match",
			result:  RagRetrievalResult{Metadata: map[string]any{"acl_scope": "USER", "acl_user_ids": []any{"u1"}}},
			allowed: true,
		},
		{
			name:    "department match",
			result:  RagRetrievalResult{Metadata: map[string]any{"acl_scope": "DEPARTMENT", "acl_departments": []any{"traffic"}}},
			allowed: true,
		},
		{
			name:    "unknown denied",
			result:  RagRetrievalResult{Metadata: map[string]any{"acl_scope": "TENANT"}},
			allowed: false,
		},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			if got := allowsRagResult(testCase.result, context); got != testCase.allowed {
				t.Fatalf("allowsRagResult() = %v, want %v", got, testCase.allowed)
			}
		})
	}
}

func TestRagQueryRerankPromotesLexicalOverlap(t *testing.T) {
	config := DefaultRagConfig()
	config.RetrievalEnabled = true
	service := NewRagQueryService(nil, nil, config)
	results := service.rerank("road law", []RagRetrievalResult{
		{ChunkID: "generic", Content: "unrelated text", FinalScore: 1},
		{ChunkID: "match", Title: "Road law", Content: "road law reference", FinalScore: 1},
	})
	if len(results) != 2 || results[0].ChunkID != "match" {
		t.Fatalf("reranked results = %+v", results)
	}
}

func TestNormalizeRagQuery(t *testing.T) {
	got := NormalizeRagQuery("\uFF21\uFF22\uFF23\t  illegal\r\nparking")
	if got != "ABC illegal parking" {
		t.Fatalf("NormalizeRagQuery() = %q", got)
	}
}

type memoryRagSearchBackend struct {
	bm25Results   []RagRetrievalResult
	vectorResults []RagRetrievalResult
	bm25Limit     int
	vectorLimit   int
}

func (b *memoryRagSearchBackend) BM25Search(
	_ context.Context,
	_ string,
	_ RagAccessFilter,
	limit int,
) ([]RagRetrievalResult, error) {
	b.bm25Limit = limit
	return b.bm25Results, nil
}

func (b *memoryRagSearchBackend) VectorSearch(
	_ context.Context,
	_ []float32,
	_ RagAccessFilter,
	limit int,
) ([]RagRetrievalResult, error) {
	b.vectorLimit = limit
	return b.vectorResults, nil
}
