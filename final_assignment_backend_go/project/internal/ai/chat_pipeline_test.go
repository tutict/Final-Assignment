package ai

import (
	"context"
	"testing"
	"time"

	"final_assignment_backend_go/project/internal/service"
)

func TestNewChatPipeline(t *testing.T) {
	mockRag := &MockRagQueryService{}
	mockProvider := &MockAiProvider{}
	config := service.DefaultAiChatConfig()

	pipeline, err := NewChatPipeline(mockRag, mockProvider, config)
	if err != nil {
		t.Fatalf("NewChatPipeline() error = %v", err)
	}

	if pipeline == nil {
		t.Fatal("NewChatPipeline() returned nil")
	}

	if pipeline.promptAssembler == nil {
		t.Error("ChatPipeline.promptAssembler is nil")
	}
}

func TestChatPipeline_Stream(t *testing.T) {
	tests := []struct {
		name            string
		request         service.AiChatStreamRequest
		mockRagResponse *service.RagQueryResponse
		mockTokens      []string
		wantMinEvents   int
		wantEventTypes  []string
	}{
		{
			name: "basic stream without RAG",
			request: service.AiChatStreamRequest{
				Message:    "Hello",
				SessionKey: "test-session",
				Metadata: map[string]any{
					"ragEnabled": false,
				},
			},
			mockTokens:     []string{"Hi", " there"},
			wantMinEvents:  3, // 2 tokens + 1 done
			wantEventTypes: []string{"token", "token", "done"},
		},
		{
			name: "stream with RAG context",
			request: service.AiChatStreamRequest{
				Message:    "交通违章如何处理？",
				SessionKey: "test-session",
				Metadata: map[string]any{
					"ragEnabled": true,
					"topK":       5,
					"userId":     "user123",
					"roles":      []string{"DRIVER"},
				},
			},
			mockRagResponse: &service.RagQueryResponse{
				Results: []service.RagRetrievalResult{
					{
						Title:      "违章处理流程",
						Content:    "违章处理包括查询、确认、缴纳",
						FinalScore: 0.95,
					},
				},
			},
			mockTokens:     []string{"根据", "检索", "结果"},
			wantMinEvents:  4,
			wantEventTypes: []string{"token", "token", "token", "done"},
		},
		{
			name: "stream with conversation window",
			request: service.AiChatStreamRequest{
				Message:    "继续说",
				SessionKey: "test-session",
				Metadata: map[string]any{
					"ragEnabled": false,
					"conversationWindow": []map[string]any{
						{"role": "user", "content": "你好"},
						{"role": "assistant", "content": "你好，有什么可以帮你？"},
					},
				},
			},
			mockTokens:     []string{"好的"},
			wantMinEvents:  2,
			wantEventTypes: []string{"token", "done"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Setup mock RAG service
			mockRag := &MockRagQueryService{}
			if tt.mockRagResponse != nil {
				mockRag.QueryFunc = func(ctx context.Context, req service.RagQueryRequest) (service.RagQueryResponse, error) {
					return *tt.mockRagResponse, nil
				}
			}

			// Setup mock AI provider
			mockProvider := &MockAiProvider{
				StreamFunc: func(ctx context.Context, prompt string, metadata map[string]any, config service.AiChatConfig) (<-chan service.AiToken, <-chan error) {
					tokenChan := make(chan service.AiToken, len(tt.mockTokens))
					errChan := make(chan error, 1)

					go func() {
						defer close(tokenChan)
						defer close(errChan)

						for i, text := range tt.mockTokens {
							tokenChan <- service.AiToken{
								Text:     text,
								Finished: i == len(tt.mockTokens)-1,
							}
						}
					}()

					return tokenChan, errChan
				},
			}

			config := service.DefaultAiChatConfig()
			pipeline, err := NewChatPipeline(mockRag, mockProvider, config)
			if err != nil {
				t.Fatalf("NewChatPipeline() error = %v", err)
			}

			// Stream events
			ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer cancel()

			eventChan, err := pipeline.Stream(ctx, tt.request)
			if err != nil {
				t.Fatalf("ChatPipeline.Stream() error = %v", err)
			}

			// Collect events
			var events []service.AiChatStreamEvent
			for event := range eventChan {
				events = append(events, event)
			}

			// Verify minimum event count
			if len(events) < tt.wantMinEvents {
				t.Errorf("ChatPipeline.Stream() event count = %d, want at least %d", len(events), tt.wantMinEvents)
			}

			// Verify event types
			if len(tt.wantEventTypes) > 0 {
				for i, wantType := range tt.wantEventTypes {
					if i >= len(events) {
						t.Errorf("ChatPipeline.Stream() missing event at index %d, want type %s", i, wantType)
						break
					}
					if events[i].Type != wantType {
						t.Errorf("ChatPipeline.Stream() event[%d].Type = %s, want %s", i, events[i].Type, wantType)
					}
				}
			}

			// Verify last event is "done"
			if len(events) > 0 {
				lastEvent := events[len(events)-1]
				if lastEvent.Type != service.ChatStreamEventTypeDone {
					t.Errorf("ChatPipeline.Stream() last event type = %s, want %s", lastEvent.Type, service.ChatStreamEventTypeDone)
				}
			}
		})
	}
}

func TestChatPipeline_ExtractRoles(t *testing.T) {
	tests := []struct {
		name     string
		metadata map[string]any
		want     []string
	}{
		{
			name:     "no roles in metadata",
			metadata: map[string]any{},
			want:     []string{"DRIVER"},
		},
		{
			name: "roles as string slice",
			metadata: map[string]any{
				"roles": []string{"ADMIN", "DRIVER"},
			},
			want: []string{"ADMIN", "DRIVER"},
		},
		{
			name: "roles as any slice",
			metadata: map[string]any{
				"roles": []any{"SUPER_ADMIN"},
			},
			want: []string{"SUPER_ADMIN"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := extractRoles(tt.metadata)
			if len(got) != len(tt.want) {
				t.Errorf("extractRoles() = %v, want %v", got, tt.want)
				return
			}
			for i := range got {
				if got[i] != tt.want[i] {
					t.Errorf("extractRoles()[%d] = %s, want %s", i, got[i], tt.want[i])
				}
			}
		})
	}
}

func TestChatPipeline_ExtractConversationWindow(t *testing.T) {
	tests := []struct {
		name         string
		metadata     map[string]any
		wantLen      int
		wantContains string
	}{
		{
			name:     "no conversation window",
			metadata: map[string]any{},
			wantLen:  0,
		},
		{
			name: "structured conversation window",
			metadata: map[string]any{
				"conversationWindow": []any{
					map[string]any{"role": "user", "content": "你好"},
					map[string]any{"role": "assistant", "content": "你好，有什么可以帮你？"},
				},
			},
			wantLen:      2,
			wantContains: "user: 你好",
		},
		{
			name: "string array conversation window",
			metadata: map[string]any{
				"conversationWindow": []string{
					"user: Hello",
					"assistant: Hi there",
				},
			},
			wantLen:      2,
			wantContains: "user: Hello",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := extractConversationWindow(tt.metadata)
			if len(got) != tt.wantLen {
				t.Errorf("extractConversationWindow() length = %d, want %d", len(got), tt.wantLen)
			}
			if tt.wantContains != "" {
				found := false
				for _, msg := range got {
					if msg == tt.wantContains {
						found = true
						break
					}
				}
				if !found {
					t.Errorf("extractConversationWindow() does not contain %q, got %v", tt.wantContains, got)
				}
			}
		})
	}
}
