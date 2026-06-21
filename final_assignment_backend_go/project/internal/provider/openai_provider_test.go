package provider

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"final_assignment_backend_go/project/internal/service"
)

func TestNewOpenAIProvider(t *testing.T) {
	tests := []struct {
		name        string
		apiKey      string
		baseURL     string
		model       string
		wantBaseURL string
		wantModel   string
	}{
		{
			name:        "with all parameters",
			apiKey:      "sk-test",
			baseURL:     "https://api.example.com/v1",
			model:       "gpt-4-turbo",
			wantBaseURL: "https://api.example.com/v1",
			wantModel:   "gpt-4-turbo",
		},
		{
			name:        "default base URL",
			apiKey:      "sk-test",
			baseURL:     "",
			model:       "gpt-4",
			wantBaseURL: "https://api.openai.com/v1",
			wantModel:   "gpt-4",
		},
		{
			name:        "default model",
			apiKey:      "sk-test",
			baseURL:     "https://api.example.com/v1",
			model:       "",
			wantBaseURL: "https://api.example.com/v1",
			wantModel:   "gpt-4",
		},
		{
			name:        "trailing slash in base URL",
			apiKey:      "sk-test",
			baseURL:     "https://api.example.com/v1/",
			model:       "gpt-4",
			wantBaseURL: "https://api.example.com/v1",
			wantModel:   "gpt-4",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			provider := NewOpenAIProvider(tt.apiKey, tt.baseURL, tt.model)

			if provider.apiKey != tt.apiKey {
				t.Errorf("apiKey = %s, want %s", provider.apiKey, tt.apiKey)
			}
			if provider.baseURL != tt.wantBaseURL {
				t.Errorf("baseURL = %s, want %s", provider.baseURL, tt.wantBaseURL)
			}
			if provider.model != tt.wantModel {
				t.Errorf("model = %s, want %s", provider.model, tt.wantModel)
			}
		})
	}
}

func TestOpenAIProvider_ProviderName(t *testing.T) {
	provider := NewOpenAIProvider("sk-test", "", "")
	if name := provider.ProviderName(); name != "openai" {
		t.Errorf("ProviderName() = %s, want openai", name)
	}
}

func TestOpenAIProvider_Stream(t *testing.T) {
	// Create mock server
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Verify request
		if r.Method != "POST" {
			t.Errorf("Expected POST request, got %s", r.Method)
		}
		if r.Header.Get("Authorization") != "Bearer sk-test" {
			t.Errorf("Invalid Authorization header: %s", r.Header.Get("Authorization"))
		}

		// Send SSE response
		w.Header().Set("Content-Type", "text/event-stream")
		w.WriteHeader(http.StatusOK)

		flusher, ok := w.(http.Flusher)
		if !ok {
			t.Fatal("ResponseWriter doesn't support flushing")
		}

		// Send multiple chunks
		chunks := []string{
			`data: {"choices":[{"delta":{"content":"你好"}}]}`,
			`data: {"choices":[{"delta":{"content":"，"}}]}`,
			`data: {"choices":[{"delta":{"content":"世界"}}]}`,
			`data: {"choices":[{"delta":{},"finish_reason":"stop"}]}`,
			`data: [DONE]`,
		}

		for _, chunk := range chunks {
			w.Write([]byte(chunk + "\n\n"))
			flusher.Flush()
			time.Sleep(10 * time.Millisecond)
		}
	}))
	defer server.Close()

	provider := NewOpenAIProvider("sk-test", server.URL, "gpt-4")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	config := service.DefaultAiChatConfig()
	tokenChan, errChan := provider.Stream(ctx, "你好", map[string]any{}, config)

	// Collect tokens
	var tokens []string
	var finished bool

	for {
		select {
		case token, ok := <-tokenChan:
			if !ok {
				goto done
			}
			tokens = append(tokens, token.Text)
			if token.Finished {
				finished = true
			}
		case err := <-errChan:
			if err != nil {
				t.Fatalf("Stream error: %v", err)
			}
		case <-ctx.Done():
			t.Fatal("Test timeout")
		}
	}

done:
	if !finished {
		t.Error("Stream did not finish properly")
	}

	if len(tokens) < 3 {
		t.Errorf("Expected at least 3 tokens, got %d", len(tokens))
	}

	// Verify we got the expected content
	expectedTokens := []string{"你好", "，", "世界"}
	for i, expected := range expectedTokens {
		if i >= len(tokens) {
			t.Errorf("Missing token %d: %s", i, expected)
			continue
		}
		if tokens[i] != expected {
			t.Errorf("Token %d = %s, want %s", i, tokens[i], expected)
		}
	}
}

func TestOpenAIProvider_Stream_Error(t *testing.T) {
	// Create mock server that returns an error
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusUnauthorized)
		w.Write([]byte(`{"error":{"message":"Invalid API key"}}`))
	}))
	defer server.Close()

	provider := NewOpenAIProvider("invalid-key", server.URL, "gpt-4")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	config := service.DefaultAiChatConfig()
	tokenChan, errChan := provider.Stream(ctx, "test", map[string]any{}, config)

	// Should receive error
	select {
	case <-tokenChan:
		t.Error("Should not receive tokens on error")
	case err := <-errChan:
		if err == nil {
			t.Error("Expected error, got nil")
		}
	case <-time.After(2 * time.Second):
		t.Fatal("Timeout waiting for error")
	}
}

func TestOpenAIProvider_Stream_ContextCancellation(t *testing.T) {
	// Create mock server with slow response
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/event-stream")
		w.WriteHeader(http.StatusOK)
		time.Sleep(5 * time.Second) // Simulate slow response
	}))
	defer server.Close()

	provider := NewOpenAIProvider("sk-test", server.URL, "gpt-4")

	ctx, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
	defer cancel()

	config := service.DefaultAiChatConfig()
	tokenChan, errChan := provider.Stream(ctx, "test", map[string]any{}, config)

	// Wait for context cancellation
	select {
	case <-tokenChan:
		// May receive some tokens before cancellation
	case err := <-errChan:
		// Should get context cancellation error
		if err == nil {
			t.Error("Expected context cancellation error")
		}
	case <-time.After(200 * time.Millisecond):
		// Context should have cancelled by now
	}
}

func TestOpenAIProvider_Stream_WithMetadata(t *testing.T) {
	receivedRequest := false

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Verify metadata was passed
		var body map[string]any
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			t.Errorf("Failed to decode request body: %v", err)
		}

		if temp, ok := body["temperature"].(float64); !ok || temp != 0.7 {
			t.Errorf("temperature = %v, want 0.7", body["temperature"])
		}

		if maxTokens, ok := body["max_tokens"].(float64); !ok || int(maxTokens) != 100 {
			t.Errorf("max_tokens = %v, want 100", body["max_tokens"])
		}

		receivedRequest = true

		w.Header().Set("Content-Type", "text/event-stream")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`data: {"choices":[{"delta":{"content":"test"},"finish_reason":"stop"}]}` + "\n\n"))
		w.Write([]byte(`data: [DONE]` + "\n\n"))
	}))
	defer server.Close()

	provider := NewOpenAIProvider("sk-test", server.URL, "gpt-4")

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	metadata := map[string]any{
		"temperature": 0.7,
		"maxTokens":   100,
	}

	config := service.DefaultAiChatConfig()
	tokenChan, errChan := provider.Stream(ctx, "test", metadata, config)

	// Consume stream
	for {
		select {
		case _, ok := <-tokenChan:
			if !ok {
				goto done
			}
		case err := <-errChan:
			if err != nil {
				t.Fatalf("Stream error: %v", err)
			}
		case <-ctx.Done():
			t.Fatal("Test timeout")
		}
	}

done:
	if !receivedRequest {
		t.Error("Server did not receive request")
	}
}
