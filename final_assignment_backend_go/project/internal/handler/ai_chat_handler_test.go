package handler

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/gin-gonic/gin"

	"final_assignment_backend_go/project/internal/ai"
	"final_assignment_backend_go/project/internal/service"
)

func TestAiChatHandler_StreamChat(t *testing.T) {
	// Setup
	gin.SetMode(gin.TestMode)

	// Create mock services
	mockRag := &ai.MockRagQueryService{
		QueryFunc: func(ctx context.Context, req service.RagQueryRequest) (service.RagQueryResponse, error) {
			return service.RagQueryResponse{
				Results: []service.RagRetrievalResult{
					{
						ChunkID: "test-1",
						Title:   "Test Result",
						Content: "Test content",
					},
				},
			}, nil
		},
	}

	mockProvider := &ai.MockAiProvider{
		StreamFunc: func(ctx context.Context, prompt string, metadata map[string]any, config service.AiChatConfig) (<-chan service.AiToken, <-chan error) {
			tokenChan := make(chan service.AiToken, 3)
			errChan := make(chan error, 1)

			go func() {
				defer close(tokenChan)
				defer close(errChan)

				tokens := []string{"你好", "，", "世界"}
				for i, text := range tokens {
					tokenChan <- service.AiToken{
						Text:     text,
						Finished: i == len(tokens)-1,
					}
					time.Sleep(10 * time.Millisecond) // Simulate streaming delay
				}
			}()

			return tokenChan, errChan
		},
	}

	config := service.DefaultAiChatConfig()
	pipeline, err := ai.NewChatPipeline(mockRag, mockProvider, config)
	if err != nil {
		t.Fatalf("NewChatPipeline() error = %v", err)
	}

	handler := NewAiChatHandler(pipeline)

	tests := []struct {
		name           string
		request        service.AiChatStreamRequest
		wantStatusCode int
		wantSSE        bool
		wantEvents     int // Minimum number of events
	}{
		{
			name: "valid stream request",
			request: service.AiChatStreamRequest{
				Message:    "Hello",
				SessionKey: "test-session",
				Metadata: map[string]any{
					"ragEnabled": false,
				},
			},
			wantStatusCode: http.StatusOK,
			wantSSE:        true,
			wantEvents:     3, // session + tokens + done
		},
		{
			name: "stream with RAG",
			request: service.AiChatStreamRequest{
				Message:    "交通违章如何处理？",
				SessionKey: "test-session-2",
				Metadata: map[string]any{
					"ragEnabled": true,
					"topK":       5,
				},
			},
			wantStatusCode: http.StatusOK,
			wantSSE:        true,
			wantEvents:     3,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create request
			body, _ := json.Marshal(tt.request)
			req := httptest.NewRequest(http.MethodPost, "/api/ai/chat/stream", bytes.NewReader(body))
			req.Header.Set("Content-Type", "application/json")

			// Create response recorder
			w := httptest.NewRecorder()

			// Create gin context
			router := gin.New()
			router.POST("/api/ai/chat/stream", handler.StreamChat)

			// Perform request
			router.ServeHTTP(w, req)

			// Check status code
			if w.Code != tt.wantStatusCode {
				t.Errorf("StreamChat() status code = %d, want %d", w.Code, tt.wantStatusCode)
			}

			// Check SSE headers
			if tt.wantSSE {
				contentType := w.Header().Get("Content-Type")
				if contentType != "text/event-stream" {
					t.Errorf("StreamChat() Content-Type = %s, want text/event-stream", contentType)
				}

				cacheControl := w.Header().Get("Cache-Control")
				if cacheControl != "no-cache" {
					t.Errorf("StreamChat() Cache-Control = %s, want no-cache", cacheControl)
				}
			}

			// Parse SSE events
			if tt.wantSSE {
				body := w.Body.String()
				events := parseSSEEvents(body)

				if len(events) < tt.wantEvents {
					t.Errorf("StreamChat() event count = %d, want at least %d", len(events), tt.wantEvents)
				}

				// Verify first event is session
				if len(events) > 0 {
					var firstEvent map[string]any
					if err := json.Unmarshal([]byte(events[0]), &firstEvent); err == nil {
						if firstEvent["sessionKey"] == nil {
							t.Error("StreamChat() first event should contain sessionKey")
						}
					}
				}

				// Verify last event is done
				if len(events) > 1 {
					var lastDataEvent map[string]any
					// Find the last data event (skip session event)
					for i := len(events) - 1; i >= 1; i-- {
						if err := json.Unmarshal([]byte(events[i]), &lastDataEvent); err == nil {
							if eventType, ok := lastDataEvent["type"].(string); ok && eventType == "done" {
								break
							}
						}
					}
				}
			}
		})
	}
}

func TestAiChatHandler_StreamChat_InvalidRequest(t *testing.T) {
	gin.SetMode(gin.TestMode)

	// Create minimal handler
	mockRag := &ai.MockRagQueryService{}
	mockProvider := &ai.MockAiProvider{}
	config := service.DefaultAiChatConfig()
	pipeline, _ := ai.NewChatPipeline(mockRag, mockProvider, config)
	handler := NewAiChatHandler(pipeline)

	tests := []struct {
		name           string
		requestBody    string
		wantStatusCode int
		wantError      string
	}{
		{
			name:           "empty message",
			requestBody:    `{"message":"","sessionKey":"test"}`,
			wantStatusCode: http.StatusBadRequest,
			wantError:      "Message is required",
		},
		{
			name:           "invalid JSON",
			requestBody:    `{invalid json}`,
			wantStatusCode: http.StatusBadRequest,
			wantError:      "Invalid request format",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodPost, "/api/ai/chat/stream", strings.NewReader(tt.requestBody))
			req.Header.Set("Content-Type", "application/json")
			w := httptest.NewRecorder()

			router := gin.New()
			router.POST("/api/ai/chat/stream", handler.StreamChat)
			router.ServeHTTP(w, req)

			if w.Code != tt.wantStatusCode {
				t.Errorf("StreamChat() status code = %d, want %d", w.Code, tt.wantStatusCode)
			}

			if tt.wantError != "" {
				body := w.Body.String()
				if !strings.Contains(body, tt.wantError) {
					t.Errorf("StreamChat() error should contain %q, got %s", tt.wantError, body)
				}
			}
		})
	}
}

// parseSSEEvents parses SSE format response body into individual event data
func parseSSEEvents(body string) []string {
	var events []string
	lines := strings.Split(body, "\n")

	for _, line := range lines {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "data: ") {
			data := strings.TrimPrefix(line, "data: ")
			if data != "" {
				events = append(events, data)
			}
		}
	}

	return events
}
