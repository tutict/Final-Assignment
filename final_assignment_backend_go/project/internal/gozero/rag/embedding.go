package rag

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"io"
	"math"
	"net/http"
	"net/url"
	"strings"
	"time"

	"final_assignment_backend_go/project/internal/gozero/config"
	"final_assignment_backend_go/project/internal/service"
)

type DeterministicEmbeddingProvider struct {
	dimensions int
	model      string
}

func NewEmbeddingProvider(conf config.RagConf) (service.RagEmbeddingProvider, error) {
	switch strings.ToLower(strings.TrimSpace(conf.EmbeddingProvider)) {
	case "", "deterministic", "local-hash", "hash":
		return NewDeterministicEmbeddingProvider(conf.EmbeddingDimensions, conf.EmbeddingModel), nil
	case "ollama":
		return NewOllamaEmbeddingProvider(conf)
	default:
		return nil, fmt.Errorf("unsupported RAG embedding provider %q", conf.EmbeddingProvider)
	}
}

func NewDeterministicEmbeddingProvider(dimensions int, model string) *DeterministicEmbeddingProvider {
	if dimensions <= 0 {
		dimensions = defaultEmbeddingDims
	}
	if strings.TrimSpace(model) == "" {
		model = fmt.Sprintf("deterministic-%d", dimensions)
	}
	return &DeterministicEmbeddingProvider{
		dimensions: dimensions,
		model:      strings.TrimSpace(model),
	}
}

func (p *DeterministicEmbeddingProvider) ProviderName() string {
	return "deterministic"
}

func (p *DeterministicEmbeddingProvider) ModelName() string {
	return p.model
}

func (p *DeterministicEmbeddingProvider) Embed(_ context.Context, text string) ([]float32, error) {
	vector := make([]float32, p.dimensions)
	seed := sha256.Sum256([]byte(text))
	for i := range vector {
		value := float32(seed[i%len(seed)])
		vector[i] = (value - 127.5) / 127.5
	}
	normalizeVector(vector)
	return vector, nil
}

type OllamaEmbeddingProvider struct {
	baseURL    string
	model      string
	dimensions int
	client     *http.Client
}

func NewOllamaEmbeddingProvider(conf config.RagConf) (*OllamaEmbeddingProvider, error) {
	baseURL := strings.TrimRight(strings.TrimSpace(conf.OllamaBaseURL), "/")
	if baseURL == "" {
		baseURL = defaultOllamaBaseURL
	}
	if _, err := url.ParseRequestURI(baseURL); err != nil {
		return nil, fmt.Errorf("invalid Rag.OllamaBaseURL %q: %w", conf.OllamaBaseURL, err)
	}
	model := strings.TrimSpace(conf.EmbeddingModel)
	if model == "" {
		return nil, fmt.Errorf("Rag.EmbeddingModel is required when Rag.EmbeddingProvider is ollama")
	}
	timeout := time.Duration(conf.OllamaTimeoutMillis) * time.Millisecond
	if timeout <= 0 {
		timeout = defaultOllamaTimeout
	}
	return &OllamaEmbeddingProvider{
		baseURL:    baseURL,
		model:      model,
		dimensions: conf.EmbeddingDimensions,
		client:     &http.Client{Timeout: timeout},
	}, nil
}

func (p *OllamaEmbeddingProvider) ProviderName() string {
	return "ollama"
}

func (p *OllamaEmbeddingProvider) ModelName() string {
	return p.model
}

func (p *OllamaEmbeddingProvider) Embed(ctx context.Context, text string) ([]float32, error) {
	vector, status, err := p.request(ctx, "/api/embeddings", map[string]any{
		"model":  p.model,
		"prompt": text,
	})
	if err != nil && (status == http.StatusBadRequest || status == http.StatusNotFound || status == http.StatusMethodNotAllowed) {
		vector, _, err = p.request(ctx, "/api/embed", map[string]any{
			"model": p.model,
			"input": text,
		})
	}
	if err != nil {
		return nil, err
	}
	if p.dimensions > 0 && len(vector) != p.dimensions {
		return nil, fmt.Errorf("embedding dimension mismatch for model %s: expected %d, got %d", p.model, p.dimensions, len(vector))
	}
	normalizeVector(vector)
	return vector, nil
}

func (p *OllamaEmbeddingProvider) request(ctx context.Context, path string, payload map[string]any) ([]float32, int, error) {
	body, err := json.Marshal(payload)
	if err != nil {
		return nil, 0, fmt.Errorf("marshal Ollama embedding request: %w", err)
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, p.baseURL+path, bytes.NewReader(body))
	if err != nil {
		return nil, 0, fmt.Errorf("build Ollama embedding request: %w", err)
	}
	req.Header.Set("Accept", "application/json")
	req.Header.Set("Content-Type", "application/json; charset=utf-8")

	resp, err := p.client.Do(req)
	if err != nil {
		return nil, 0, fmt.Errorf("Ollama embedding request failed: %w", err)
	}
	defer resp.Body.Close()

	raw, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, resp.StatusCode, fmt.Errorf("read Ollama embedding response: %w", err)
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, resp.StatusCode, fmt.Errorf("Ollama embedding request failed with HTTP %d: %s", resp.StatusCode, clipForError(raw))
	}
	vector, err := parseOllamaVector(raw)
	if err != nil {
		return nil, resp.StatusCode, err
	}
	return vector, resp.StatusCode, nil
}

func parseOllamaVector(raw []byte) ([]float32, error) {
	var payload struct {
		Embedding  []float32   `json:"embedding"`
		Embeddings [][]float32 `json:"embeddings"`
	}
	if err := json.Unmarshal(raw, &payload); err != nil {
		return nil, fmt.Errorf("parse Ollama embedding response: %w", err)
	}
	if len(payload.Embedding) > 0 {
		return payload.Embedding, nil
	}
	if len(payload.Embeddings) > 0 && len(payload.Embeddings[0]) > 0 {
		return payload.Embeddings[0], nil
	}
	return nil, fmt.Errorf("Ollama embedding response did not contain an embedding array")
}

func normalizeVector(vector []float32) {
	var sum float64
	for _, value := range vector {
		sum += float64(value * value)
	}
	norm := math.Sqrt(sum)
	if norm == 0 {
		return
	}
	for i := range vector {
		vector[i] = float32(float64(vector[i]) / norm)
	}
}

func clipForError(raw []byte) string {
	value := strings.TrimSpace(string(raw))
	if len(value) <= 500 {
		return value
	}
	return value[:500]
}
