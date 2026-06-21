package ai

import (
	"testing"

	"final_assignment_backend_go/project/internal/service"
)

func TestContextBuilder_Build(t *testing.T) {
	cb := NewContextBuilder(1200)

	tests := []struct {
		name    string
		results []service.RagRetrievalResult
		wantLen int // Expected non-zero length
	}{
		{
			name:    "empty results",
			results: []service.RagRetrievalResult{},
			wantLen: 0,
		},
		{
			name: "single result",
			results: []service.RagRetrievalResult{
				{
					Title:      "交通违章处理流程",
					Content:    "交通违章处理流程包括：1. 查询违章记录；2. 确认违章详情；3. 缴纳罚款。",
					SourceType: "BUSINESS",
					Route:      "/offense-types/1001",
					FinalScore: 0.92,
				},
			},
			wantLen: 100,
		},
		{
			name: "multiple results",
			results: []service.RagRetrievalResult{
				{
					Title:      "违章查询",
					Content:    "可通过身份证号查询违章记录",
					SourceType: "BUSINESS",
					FinalScore: 0.95,
				},
				{
					Title:      "罚款缴纳",
					Content:    "罚款可通过线上或线下渠道缴纳",
					SourceType: "BUSINESS",
					FinalScore: 0.88,
				},
			},
			wantLen: 100,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := cb.Build(tt.results)
			if tt.wantLen == 0 && got != "" {
				t.Errorf("ContextBuilder.Build() = %v, want empty string", got)
			}
			if tt.wantLen > 0 && len(got) < tt.wantLen {
				t.Errorf("ContextBuilder.Build() length = %v, want at least %v", len(got), tt.wantLen)
			}
		})
	}
}

func TestPromptAssembler_Assemble(t *testing.T) {
	pa, err := NewPromptAssembler()
	if err != nil {
		t.Fatalf("NewPromptAssembler() error = %v", err)
	}

	tests := []struct {
		name               string
		userMessage        string
		conversationWindow []string
		ragResults         []service.RagRetrievalResult
		agentConstraints   string
		wantContains       []string
	}{
		{
			name:             "basic prompt without context",
			userMessage:      "交通违章如何处理？",
			agentConstraints: "You are a helpful assistant.",
			wantContains:     []string{"交通违章如何处理", "helpful assistant", "User:"},
		},
		{
			name:        "prompt with conversation window",
			userMessage: "继续说",
			conversationWindow: []string{
				"user: 你好",
				"assistant: 你好，有什么可以帮你？",
			},
			agentConstraints: "You are a helpful assistant.",
			wantContains:     []string{"你好", "继续说", "conversation_window"},
		},
		{
			name:        "prompt with RAG context",
			userMessage: "违章查询",
			ragResults: []service.RagRetrievalResult{
				{
					Title:      "违章查询指南",
					Content:    "可通过身份证号查询",
					SourceType: "BUSINESS",
					FinalScore: 0.95,
				},
			},
			agentConstraints: "You are a helpful assistant.",
			wantContains:     []string{"违章查询", "身份证号", "retrieved_context"},
		},
		{
			name:        "full prompt with all components",
			userMessage: "如何缴纳罚款？",
			conversationWindow: []string{
				"user: 我有违章记录",
				"assistant: 我可以帮你查询违章详情",
			},
			ragResults: []service.RagRetrievalResult{
				{
					Title:      "罚款缴纳流程",
					Content:    "罚款可通过线上或线下渠道缴纳",
					SourceType: "BUSINESS",
					FinalScore: 0.92,
				},
			},
			agentConstraints: "# Driver\nOnly access own records.",
			wantContains: []string{
				"如何缴纳罚款",
				"我有违章记录",
				"罚款缴纳流程",
				"Driver",
				"agent_constraints",
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := pa.Assemble(tt.userMessage, tt.conversationWindow, tt.ragResults, tt.agentConstraints)
			if err != nil {
				t.Errorf("PromptAssembler.Assemble() error = %v", err)
				return
			}

			for _, want := range tt.wantContains {
				if !contains(got, want) {
					t.Errorf("PromptAssembler.Assemble() result does not contain %q\nGot:\n%s", want, got)
				}
			}
		})
	}
}

func contains(s, substr string) bool {
	return len(s) > 0 && len(substr) > 0 && (s == substr || len(s) >= len(substr) && (s[:len(substr)] == substr || s[len(s)-len(substr):] == substr || containsSubstring(s, substr)))
}

func containsSubstring(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}
