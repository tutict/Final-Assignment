package rag

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
					"acl_roles": []any{"ADMIN"},
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
					"acl_roles": []any{"ADMIN"},
				},
			},
		},
	}
	config := DefaultRagConfig()
	config.RetrievalEnabled = true
	service := NewRagQueryService(backend, &memoryRagEmbeddingProvider{}, config)

	result, err := service.Query(context.Background(), RagQueryRequest{
		Query: " illegal   parking appeal ",
		TopK:  &topK,
	}, NewRagAccessContext("u1", []string{"admin"}))
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

// 默认检索档是「词法为主」：BM25 0.8 + 向量 0.2。这里锁住的是本包自己的默认值，
// 不读 Spring 的配置文件；四个后端的数值一致性由 scripts/check-rag-config-parity.py 负责，
// 那条守卫会同时读 yaml 与四份配置，改名成 "MatchesSpring..." 只会让人误以为这里跨后端校验过。
func TestDefaultRagConfigUsesLexicalHeavyWeights(t *testing.T) {
	config := DefaultRagConfig()

	if config.VectorWeight != 0.2 {
		t.Fatalf("vector weight = %v, want 0.2", config.VectorWeight)
	}
	if config.BM25Weight != 0.8 {
		t.Fatalf("bm25 weight = %v, want 0.8", config.BM25Weight)
	}
	if config.MinScore != 0.2 {
		t.Fatalf("min score = %v, want 0.2", config.MinScore)
	}
	if config.CandidateMultiplier != 3 {
		t.Fatalf("candidate multiplier = %d, want 3", config.CandidateMultiplier)
	}
	if config.RRFRankConstant != 60 {
		t.Fatalf("rrf rank constant = %d, want 60", config.RRFRankConstant)
	}
	if !config.RerankEnabled || config.RerankLexicalWeight != 0.15 {
		t.Fatalf("rerank = %v/%v, want enabled with 0.15", config.RerankEnabled, config.RerankLexicalWeight)
	}
	if config.RetrievalTopK != 10 {
		t.Fatalf("retrieval topK = %d, want 10", config.RetrievalTopK)
	}
}

func TestRagQueryServiceReturnsEmptyWhenDisabledOrBlank(t *testing.T) {
	service := NewRagQueryService(&memoryRagSearchBackend{}, &memoryRagEmbeddingProvider{}, DefaultRagConfig())
	result, err := service.Query(context.Background(), RagQueryRequest{Query: "traffic appeal"}, NewRagAccessContext("u1", nil))
	if err != nil {
		t.Fatalf("Query() error = %v", err)
	}
	if len(result.Results) != 0 {
		t.Fatalf("disabled result count = %d, want 0", len(result.Results))
	}

	config := DefaultRagConfig()
	config.RetrievalEnabled = true
	service = NewRagQueryService(&memoryRagSearchBackend{}, &memoryRagEmbeddingProvider{}, config)
	result, err = service.Query(context.Background(), RagQueryRequest{Query: " \t\r\n "}, NewRagAccessContext("u1", nil))
	if err != nil {
		t.Fatalf("blank Query() error = %v", err)
	}
	if len(result.Results) != 0 {
		t.Fatalf("blank result count = %d, want 0", len(result.Results))
	}
}

func TestRagAclAllowsPublicRoleUserAndDepartmentScopes(t *testing.T) {
	context := RagAccessContext{UserID: "u1", Roles: []string{"ADMIN"}, Department: "traffic"}
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
			result:  RagRetrievalResult{Metadata: map[string]any{"acl_scope": "ROLE", "acl_roles": []any{"ADMIN"}}},
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
