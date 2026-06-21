package provider

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"final_assignment_backend_go/project/internal/service"
)

// OpenAIProvider implements AiProvider for OpenAI-compatible APIs
type OpenAIProvider struct {
	apiKey  string
	baseURL string
	model   string
	client  *http.Client
}

// NewOpenAIProvider creates a new OpenAI provider
func NewOpenAIProvider(apiKey, baseURL, model string) *OpenAIProvider {
	if baseURL == "" {
		baseURL = "https://api.openai.com/v1"
	}
	if model == "" {
		model = "gpt-4"
	}

	return &OpenAIProvider{
		apiKey:  apiKey,
		baseURL: strings.TrimSuffix(baseURL, "/"),
		model:   model,
		client: &http.Client{
			Timeout: 120 * time.Second,
		},
	}
}

// ProviderName returns the provider name
func (p *OpenAIProvider) ProviderName() string {
	return "openai"
}

// Stream sends a prompt to OpenAI and returns a streaming response
func (p *OpenAIProvider) Stream(
	ctx context.Context,
	prompt string,
	metadata map[string]any,
	config service.AiChatConfig,
) (<-chan service.AiToken, <-chan error) {
	tokenChan := make(chan service.AiToken, 10)
	errChan := make(chan error, 1)

	go func() {
		defer close(tokenChan)
		defer close(errChan)

		if err := p.streamRequest(ctx, prompt, metadata, tokenChan); err != nil {
			errChan <- err
		}
	}()

	return tokenChan, errChan
}

// streamRequest performs the actual streaming request
func (p *OpenAIProvider) streamRequest(
	ctx context.Context,
	prompt string,
	metadata map[string]any,
	tokenChan chan<- service.AiToken,
) error {
	// Build request payload
	requestBody := map[string]any{
		"model":  p.model,
		"stream": true,
		"messages": []map[string]string{
			{
				"role":    "user",
				"content": prompt,
			},
		},
	}

	// Add optional parameters from metadata
	if temperature, ok := metadata["temperature"].(float64); ok {
		requestBody["temperature"] = temperature
	}
	if maxTokens, ok := metadata["maxTokens"].(int); ok {
		requestBody["max_tokens"] = maxTokens
	}

	// Marshal request
	bodyBytes, err := json.Marshal(requestBody)
	if err != nil {
		return fmt.Errorf("failed to marshal request: %w", err)
	}

	// Create HTTP request
	url := p.baseURL + "/chat/completions"
	req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewReader(bodyBytes))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	// Set headers
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+p.apiKey)
	req.Header.Set("Accept", "text/event-stream")

	// Send request
	resp, err := p.client.Do(req)
	if err != nil {
		return fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("API error (status %d): %s", resp.StatusCode, string(body))
	}

	// Parse SSE stream
	return p.parseSSEStream(resp.Body, tokenChan)
}

// parseSSEStream parses Server-Sent Events from the response
func (p *OpenAIProvider) parseSSEStream(reader io.Reader, tokenChan chan<- service.AiToken) error {
	scanner := bufio.NewScanner(reader)
	var fullText strings.Builder

	for scanner.Scan() {
		line := scanner.Text()

		// SSE format: "data: {json}"
		if !strings.HasPrefix(line, "data: ") {
			continue
		}

		data := strings.TrimPrefix(line, "data: ")
		data = strings.TrimSpace(data)

		// Check for stream end
		if data == "[DONE]" {
			tokenChan <- service.AiToken{
				Text:     fullText.String(),
				Finished: true,
			}
			return nil
		}

		// Parse JSON chunk
		var chunk struct {
			Choices []struct {
				Delta struct {
					Content string `json:"content"`
				} `json:"delta"`
				FinishReason *string `json:"finish_reason"`
			} `json:"choices"`
		}

		if err := json.Unmarshal([]byte(data), &chunk); err != nil {
			// Skip malformed chunks
			continue
		}

		if len(chunk.Choices) == 0 {
			continue
		}

		content := chunk.Choices[0].Delta.Content
		if content != "" {
			fullText.WriteString(content)
			tokenChan <- service.AiToken{
				Text:     content,
				Finished: false,
			}
		}

		// Check if finished
		if chunk.Choices[0].FinishReason != nil {
			tokenChan <- service.AiToken{
				Text:     fullText.String(),
				Finished: true,
			}
			return nil
		}
	}

	if err := scanner.Err(); err != nil {
		return fmt.Errorf("stream reading error: %w", err)
	}

	return nil
}
