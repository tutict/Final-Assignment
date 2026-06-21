package rag

import (
	"testing"

	"final_assignment_backend_go/project/internal/service"
)

func TestRagHitToResultMapsScoresAndAclMetadata(t *testing.T) {
	result, ok := ragHitToResult(map[string]any{
		"chunk_id":        "chunk-1",
		"document_id":     "doc-1",
		"content":         "content",
		"title":           "title",
		"source_type":     "BUSINESS",
		"source_table":    "appeal_record",
		"source_id":       "42",
		"source_field":    "appealReason",
		"route":           "/appeals/42",
		"acl_scope":       "ROLE",
		"acl_roles":       []any{"admin"},
		"acl_user_ids":    []any{"u1"},
		"acl_departments": []any{"traffic"},
		"metadata": map[string]any{
			"source": "appeal_record:42",
		},
	}, 2.5, "bm25")
	if !ok {
		t.Fatalf("ragHitToResult() ok = false")
	}
	if result.ChunkID != "chunk-1" || result.BM25Score != 2.5 || result.VectorScore != 0 {
		t.Fatalf("unexpected result: %+v", result)
	}
	if result.Metadata["acl_scope"] != "ROLE" {
		t.Fatalf("metadata acl_scope = %v", result.Metadata["acl_scope"])
	}
	if len(result.ACLRoles) != 1 || result.ACLRoles[0] != "admin" {
		t.Fatalf("ACLRoles = %+v", result.ACLRoles)
	}
}

func TestRagACLFilterQueryIncludesPublicAndContextClauses(t *testing.T) {
	query := ragACLFilterQuery(service.RagAccessFilter{
		UserID:     "u1",
		Roles:      []string{"admin"},
		Department: "traffic",
	})
	boolQuery := query["bool"].(map[string]any)
	should := boolQuery["should"].([]any)
	if len(should) != 4 {
		t.Fatalf("ACL should clause count = %d, want 4", len(should))
	}
	if boolQuery["minimum_should_match"] != 1 {
		t.Fatalf("minimum_should_match = %v", boolQuery["minimum_should_match"])
	}
}
