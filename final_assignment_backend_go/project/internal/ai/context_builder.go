package ai

import (
	"fmt"
	"strings"

	"final_assignment_backend_go/project/internal/service"
)

// ContextBuilder formats RAG retrieval results into a readable context string for prompts
type ContextBuilder struct {
	MaxTokens int // Maximum token budget for context (default: 1200)
}

// NewContextBuilder creates a new ContextBuilder with default settings
func NewContextBuilder(maxTokens int) *ContextBuilder {
	if maxTokens <= 0 {
		maxTokens = 1200
	}
	return &ContextBuilder{
		MaxTokens: maxTokens,
	}
}

// Build formats retrieval results into a context string
func (cb *ContextBuilder) Build(results []service.RagRetrievalResult) string {
	if len(results) == 0 {
		return ""
	}

	var builder strings.Builder
	builder.WriteString("Retrieved Context:\n\n")

	currentTokens := 0
	includedCount := 0

	for i, result := range results {
		// Estimate tokens (rough: 1 token ≈ 1.5 characters for Chinese)
		titleTokens := len([]rune(result.Title)) / 2
		contentTokens := len([]rune(result.Content)) / 2
		estimatedTokens := titleTokens + contentTokens + 20 // +20 for formatting

		// Check if adding this result would exceed budget
		if currentTokens+estimatedTokens > cb.MaxTokens && includedCount > 0 {
			builder.WriteString(fmt.Sprintf("\n[Context truncated: %d more results omitted due to token limit]\n", len(results)-i))
			break
		}

		// Format result
		builder.WriteString(fmt.Sprintf("[%d] %s\n", i+1, result.Title))
		builder.WriteString(fmt.Sprintf("Source: %s", result.SourceType))
		if result.Route != "" {
			builder.WriteString(fmt.Sprintf(" | Route: %s", result.Route))
		}
		builder.WriteString(fmt.Sprintf(" | Score: %.2f\n", result.FinalScore))
		builder.WriteString(fmt.Sprintf("%s\n\n", result.Content))

		currentTokens += estimatedTokens
		includedCount++
	}

	if includedCount == 0 {
		return ""
	}

	return builder.String()
}
