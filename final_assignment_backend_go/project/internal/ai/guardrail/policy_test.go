package guardrail

import (
	"testing"

	ragsvc "final_assignment_backend_go/project/internal/service/rag"
)

func retrievalSources(count int) []ragsvc.RagRetrievalResult {
	sources := make([]ragsvc.RagRetrievalResult, 0, count)
	for i := 1; i <= count; i++ {
		sources = append(sources, ragsvc.RagRetrievalResult{
			ChunkID:    "chunk-" + string(rune('0'+i)),
			DocumentID: "doc-2026-00" + string(rune('0'+i)),
			Title:      "交通违法处理资料",
			Content:    "示例内容",
		})
	}
	return sources
}

func TestCitationPolicyEvaluate(t *testing.T) {
	twoSources := retrievalSources(2)
	titled := []ragsvc.RagRetrievalResult{{Title: "车辆过户", SourceID: "src-1", DocumentID: "doc-1", Content: "过户流程"}}
	shortID := []ragsvc.RagRetrievalResult{{Title: "资料", SourceID: "12", DocumentID: "7", Content: "内容"}}

	tests := []struct {
		name       string
		enabled    bool
		answer     string
		sources    []ragsvc.RagRetrievalResult
		grounded   bool
		wantText   string
		wantReason string
	}{
		{
			name:     "disabled allows answer without sources",
			enabled:  false,
			answer:   "直接回答",
			grounded: true,
		},
		{
			name:     "blank answer is allowed",
			enabled:  true,
			answer:   "   ",
			sources:  twoSources,
			grounded: true,
		},
		{
			name:       "no sources refuses",
			enabled:    true,
			answer:     "直接回答",
			grounded:   false,
			wantText:   NoSourceAnswer,
			wantReason: "no_sources",
		},
		{
			name:     "half width citation in range",
			enabled:  true,
			answer:   "罚款应在15日内缴纳。[1]",
			sources:  twoSources,
			grounded: true,
		},
		{
			name:     "full width citation in range",
			enabled:  true,
			answer:   "罚款应在15日内缴纳。【2】",
			sources:  twoSources,
			grounded: true,
		},
		{
			name:     "grouped citation with one valid index",
			enabled:  true,
			answer:   "罚款应在15日内缴纳。[1，3]",
			sources:  twoSources,
			grounded: true,
		},
		{
			name:       "citation out of range refuses",
			enabled:    true,
			answer:     "罚款应在15日内缴纳。[3]",
			sources:    twoSources,
			grounded:   false,
			wantText:   UncitedAnswer,
			wantReason: "missing_citation",
		},
		{
			name:       "zero index refuses",
			enabled:    true,
			answer:     "罚款应在15日内缴纳。[0]",
			sources:    twoSources,
			grounded:   false,
			wantText:   UncitedAnswer,
			wantReason: "missing_citation",
		},
		{
			name:     "distinctive title counts as citation",
			enabled:  true,
			answer:   "车辆过户需要双方到场。",
			sources:  titled,
			grounded: true,
		},
		{
			name:     "distinctive source id counts as citation",
			enabled:  true,
			answer:   "详见 src-1 的说明。",
			sources:  titled,
			grounded: true,
		},
		{
			name:       "bare numeric id does not count",
			enabled:    true,
			answer:     "详见 12 号说明。",
			sources:    shortID,
			grounded:   false,
			wantText:   UncitedAnswer,
			wantReason: "missing_citation",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			policy := CitationPolicy{EnforcementEnabled: tt.enabled}
			decision := policy.Evaluate(tt.answer, tt.sources)
			if decision.Grounded != tt.grounded {
				t.Fatalf("grounded = %v, want %v (decision %+v)", decision.Grounded, tt.grounded, decision)
			}
			if tt.wantText != "" && decision.Answer != tt.wantText {
				t.Fatalf("answer = %q, want %q", decision.Answer, tt.wantText)
			}
			if tt.wantReason != "" && decision.Reason != tt.wantReason {
				t.Fatalf("reason = %q, want %q", decision.Reason, tt.wantReason)
			}
			if tt.grounded && decision.Answer != tt.answer {
				t.Fatalf("allowed answer mutated: %q", decision.Answer)
			}
		})
	}
}
