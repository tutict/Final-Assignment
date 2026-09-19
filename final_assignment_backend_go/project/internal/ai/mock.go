package ai

import (
	"context"
	ragsvc "final_assignment_backend_go/project/internal/service/rag"

	aisvc "final_assignment_backend_go/project/internal/service/ai"
)

// MockRagQueryService is a mock implementation of AiChatRagQuerier for testing
type MockRagQueryService struct {
	QueryFunc func(ctx context.Context, req ragsvc.RagQueryRequest) (ragsvc.RagQueryResponse, error)
}

func (m *MockRagQueryService) Query(ctx context.Context, req ragsvc.RagQueryRequest) (ragsvc.RagQueryResponse, error) {
	if m.QueryFunc != nil {
		return m.QueryFunc(ctx, req)
	}
	return ragsvc.RagQueryResponse{
		Results: []ragsvc.RagRetrievalResult{
			{
				ChunkID:    "test-chunk-1",
				DocumentID: "test-doc-1",
				Title:      "Test Result",
				Content:    "This is a test RAG result",
				SourceType: "BUSINESS",
				FinalScore: 0.95,
			},
		},
	}, nil
}

// MockAiProvider is a mock implementation of AiProvider for testing
type MockAiProvider struct {
	StreamFunc func(ctx context.Context, prompt string, metadata map[string]any, config aisvc.AiChatConfig) (<-chan aisvc.AiToken, <-chan error)
}

func (m *MockAiProvider) ProviderName() string {
	return "mock"
}

func (m *MockAiProvider) Stream(ctx context.Context, prompt string, metadata map[string]any, config aisvc.AiChatConfig) (<-chan aisvc.AiToken, <-chan error) {
	if m.StreamFunc != nil {
		return m.StreamFunc(ctx, prompt, metadata, config)
	}

	// Default: return simple token stream
	tokenChan := make(chan aisvc.AiToken, 5)
	errChan := make(chan error, 1)

	go func() {
		defer close(tokenChan)
		defer close(errChan)

		tokens := []string{"你好", "，", "这是", "测试", "。"}
		for i, text := range tokens {
			tokenChan <- aisvc.AiToken{
				Text:     text,
				Finished: i == len(tokens)-1,
			}
		}
	}()

	return tokenChan, errChan
}
