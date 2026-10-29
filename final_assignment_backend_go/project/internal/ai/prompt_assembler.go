package ai

import (
	"bytes"
	"strings"
	"text/template"

	service "final_assignment_backend_go/project/internal/service/rag"
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
	CitationRepair     bool
}

// Assemble combines all prompt components into the final prompt string
func (pa *PromptAssembler) Assemble(
	userMessage string,
	conversationWindow []string,
	ragResults []service.RagRetrievalResult,
	agentConstraints string,
) (string, error) {
	return pa.render(
		userMessage,
		conversationWindow,
		pa.contextBuilder.Build(ragResults),
		agentConstraints,
		false,
	)
}

// AssembleWithSources also returns the sources that actually fit in the prompt, so the
// guardrail judges the subset the model saw.
func (pa *PromptAssembler) AssembleWithSources(
	userMessage string,
	conversationWindow []string,
	ragResults []service.RagRetrievalResult,
	agentConstraints string,
) (string, []service.RagRetrievalResult, error) {
	retrievedContext, included := pa.contextBuilder.BuildWithSources(ragResults)
	prompt, err := pa.render(userMessage, conversationWindow, retrievedContext, agentConstraints, false)
	return prompt, included, err
}

// AssembleCitationRepair asks the model to rewrite an uncited draft with [n] markers.
func (pa *PromptAssembler) AssembleCitationRepair(
	userMessage string,
	conversationWindow []string,
	ragResults []service.RagRetrievalResult,
	agentConstraints string,
) (string, error) {
	return pa.render(
		userMessage,
		conversationWindow,
		pa.contextBuilder.Build(ragResults),
		agentConstraints,
		true,
	)
}

func (pa *PromptAssembler) render(
	userMessage string,
	conversationWindow []string,
	retrievedContext string,
	agentConstraints string,
	citationRepair bool,
) (string, error) {
	data := PromptData{
		AgentConstraints:   strings.TrimSpace(agentConstraints),
		ConversationWindow: conversationWindow,
		RetrievedContext:   strings.TrimSpace(retrievedContext),
		UserMessage:        strings.TrimSpace(userMessage),
		CitationRepair:     citationRepair,
	}

	var buf bytes.Buffer
	if err := pa.template.Execute(&buf, data); err != nil {
		return "", err
	}

	return buf.String(), nil
}
