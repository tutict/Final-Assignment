package ai

import (
	"bytes"
	"strings"
	"text/template"

	"final_assignment_backend_go/project/internal/service"
)

// PromptAssembler assembles the final prompt from user message, conversation history,
// RAG context, and agent constraints
type PromptAssembler struct {
	template       *template.Template
	contextBuilder *ContextBuilder
}

// NewPromptAssembler creates a new PromptAssembler with default settings
func NewPromptAssembler() (*PromptAssembler, error) {
	tmpl, err := template.New("prompt").Parse(DefaultPromptTemplate)
	if err != nil {
		return nil, err
	}

	return &PromptAssembler{
		template:       tmpl,
		contextBuilder: NewContextBuilder(1200),
	}, nil
}

// PromptData holds all data needed to render the prompt template
type PromptData struct {
	AgentConstraints   string
	ConversationWindow []string
	RetrievedContext   string
	UserMessage        string
}

// Assemble combines all prompt components into the final prompt string
func (pa *PromptAssembler) Assemble(
	userMessage string,
	conversationWindow []string,
	ragResults []service.RagRetrievalResult,
	agentConstraints string,
) (string, error) {
	// Build retrieved context from RAG results
	retrievedContext := pa.contextBuilder.Build(ragResults)

	// Prepare template data
	data := PromptData{
		AgentConstraints:   strings.TrimSpace(agentConstraints),
		ConversationWindow: conversationWindow,
		RetrievedContext:   strings.TrimSpace(retrievedContext),
		UserMessage:        strings.TrimSpace(userMessage),
	}

	// Execute template
	var buf bytes.Buffer
	if err := pa.template.Execute(&buf, data); err != nil {
		return "", err
	}

	return buf.String(), nil
}
