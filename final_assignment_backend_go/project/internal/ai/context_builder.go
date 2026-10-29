package ai

import (
	"fmt"
	"strings"

	"final_assignment_backend_go/project/internal/ai/guardrail"
	service "final_assignment_backend_go/project/internal/service/rag"
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
	context, _ := cb.BuildWithSources(results)
	return context
}

// BuildWithSources returns the context text plus the sources that actually made it into it.
// The guardrail must judge the same subset the model saw, not the full top-K.
func (cb *ContextBuilder) BuildWithSources(results []service.RagRetrievalResult) (string, []service.RagRetrievalResult) {
	if len(results) == 0 {
		return "", nil
	}

	// Titles, sources, and scores stay out of the prompt so the model cannot echo internal
	// identifiers into the answer; only the citation index and content are needed. Retrieved
	// passages are untrusted, so instruction-like spans are neutralized before they reach the
	// model and a poisoned document cannot hijack the prompt.
	var builder strings.Builder
	included := make([]service.RagRetrievalResult, 0, len(results))
	currentTokens := 0

	for _, result := range results {
		content := guardrail.SanitizeInjection(strings.Join(strings.Fields(result.Content), " "))
		if content == "" {
			continue
		}
		entryTokens := len([]rune(content))/2 + 12 // rough Chinese token estimate + formatting
		if currentTokens+entryTokens > cb.MaxTokens && len(included) > 0 {
			break
		}
		if len(included) > 0 {
			builder.WriteString("\n\n")
		}
		builder.WriteString(fmt.Sprintf("[%d]\ncontent: %s", len(included)+1, content))
		included = append(included, result)
		currentTokens += entryTokens
	}

	return builder.String(), included
}
