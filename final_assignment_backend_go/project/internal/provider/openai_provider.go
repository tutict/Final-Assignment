package provider

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"strings"
	"time"

	service "final_assignment_backend_go/project/internal/service/ai"
)

// OpenAIProvider implements AiProvider for OpenAI-compatible APIs
type OpenAIProvider struct {
	apiKey           string
	baseURL          string
	model            string
	client           *http.Client
	completionClient *http.Client
}

// defaultProviderTimeout bounds a single provider call: connection setup and the wait for the
// response headers. It matches the Spring budget (AI_PROVIDER_TIMEOUT, 60s); a tighter deadline
// aborts a cold model load before Ollama can answer.
const defaultProviderTimeout = 60 * time.Second

// NewOpenAIProvider creates a new OpenAI provider
func NewOpenAIProvider(apiKey, baseURL, model string, timeout time.Duration) *OpenAIProvider {
	if baseURL == "" {
		baseURL = "https://api.openai.com/v1"
	}
	if model == "" {
		model = "gpt-4"
	}
	if timeout <= 0 {
		timeout = defaultProviderTimeout
	}

	return &OpenAIProvider{
		apiKey:  apiKey,
		baseURL: strings.TrimSuffix(baseURL, "/"),
		model:   model,
		client: &http.Client{
			// The exchange budget covers the whole streamed answer; the header budget only
			// covers the wait for the first response byte.
			Timeout: 2 * timeout,
			Transport: &http.Transport{
				DialContext:           (&net.Dialer{Timeout: timeout}).DialContext,
				ResponseHeaderTimeout: timeout,
			},
		},
		// Chat and judge have different latency envelopes: the chat header budget is unusable
		// for a 7B judge, so auxiliary calls get their own client bounded by context.
		completionClient: &http.Client{
			Transport: &http.Transport{
				DialContext: (&net.Dialer{Timeout: 5 * time.Second}).DialContext,
			},
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

		if err := p.streamRequest(ctx, prompt, metadata, config.Temperature, tokenChan); err != nil {
			errChan <- err
		}
	}()

	return tokenChan, errChan
}

// Complete runs a single non-streaming completion. Auxiliary callers (grounding judge) use it;
// unlike Stream it honours a per-call model and JSON response format.
func (p *OpenAIProvider) Complete(
	ctx context.Context,
	prompt string,
	options service.GenerationOptions,
) (string, error) {
	timeout := options.Timeout
	if timeout <= 0 {
		timeout = 60 * time.Second
	}
	callCtx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()

	model := p.model
	if options.Model != "" {
		model = options.Model
	}
	requestBody := map[string]any{
		"model":  model,
		"stream": false,
		"messages": []map[string]string{
			{"role": "user", "content": prompt},
		},
	}
	if options.Temperature != nil {
		requestBody["temperature"] = *options.Temperature
	}
	if options.MaxTokens > 0 {
		requestBody["max_tokens"] = options.MaxTokens
	}
	if len(options.ResponseFormat) > 0 {
		requestBody["response_format"] = options.ResponseFormat
	}

	bodyBytes, err := json.Marshal(requestBody)
	if err != nil {
		return "", fmt.Errorf("failed to marshal request: %w", err)
	}

	attempts := options.RetryAttempts + 1
	if attempts < 1 {
		attempts = 1
	}
	var lastErr error
	for attempt := 0; attempt < attempts; attempt++ {
		content, err := p.completeOnce(callCtx, bodyBytes)
		if err == nil {
			return content, nil
		}
		lastErr = err
	}
	return "", lastErr
}

func (p *OpenAIProvider) completeOnce(ctx context.Context, bodyBytes []byte) (string, error) {
	req, err := http.NewRequestWithContext(
		ctx,
		http.MethodPost,
		p.baseURL+"/chat/completions",
		bytes.NewReader(bodyBytes),
	)
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+p.apiKey)

	resp, err := p.completionClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
		return "", fmt.Errorf("completion API error (status %d): %s", resp.StatusCode, string(body))
	}

	var payload struct {
		Choices []struct {
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
		} `json:"choices"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&payload); err != nil {
		return "", fmt.Errorf("failed to decode completion: %w", err)
	}
	if len(payload.Choices) == 0 {
		return "", fmt.Errorf("completion returned no choices")
	}
	return payload.Choices[0].Message.Content, nil
}

// streamRequest performs the actual streaming request
func (p *OpenAIProvider) streamRequest(
	ctx context.Context,
	prompt string,
	metadata map[string]any,
	temperature float64,
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

	// The configured temperature is the baseline; a per-request value wins.
	if temperature > 0 {
		requestBody["temperature"] = temperature
	}
	if override, ok := metadata["temperature"].(float64); ok {
		requestBody["temperature"] = override
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

		// Check for stream end. The terminal token is a sentinel only: the answer text was
		// already streamed chunk by chunk, so repeating it here would duplicate the reply.
		if data == "[DONE]" {
			tokenChan <- service.AiToken{Finished: true}
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
			tokenChan <- service.AiToken{Finished: true}
			return nil
		}
	}

	if err := scanner.Err(); err != nil {
		return fmt.Errorf("stream reading error: %w", err)
	}

	return nil
}
