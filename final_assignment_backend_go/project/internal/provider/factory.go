package provider

import (
	"fmt"

	"final_assignment_backend_go/project/internal/config"
	"final_assignment_backend_go/project/internal/service"
)

// Factory creates AI providers based on configuration
type Factory struct {
	config *config.AiChatConfig
}

// NewFactory creates a new provider factory
func NewFactory(cfg *config.AiChatConfig) *Factory {
	return &Factory{
		config: cfg,
	}
}

// CreateProvider creates an AI provider based on the configured type
func (f *Factory) CreateProvider() (service.AiProvider, error) {
	switch f.config.ProviderType {
	case "openai":
		return NewOpenAIProvider(
			f.config.ProviderAPIKey,
			f.config.ProviderURL,
			f.config.ProviderModel,
		), nil

	case "claude":
		// Claude provider would be similar to OpenAI
		// Using OpenAI provider for now with custom URL
		if f.config.ProviderURL == "" {
			return nil, fmt.Errorf("claude provider requires ProviderURL to be set")
		}
		return NewOpenAIProvider(
			f.config.ProviderAPIKey,
			f.config.ProviderURL,
			f.config.ProviderModel,
		), nil

	case "local":
		// Local provider (e.g., ollama, llamacpp)
		if f.config.ProviderURL == "" {
			return nil, fmt.Errorf("local provider requires ProviderURL to be set")
		}
		return NewOpenAIProvider(
			"", // Local providers typically don't need API key
			f.config.ProviderURL,
			f.config.ProviderModel,
		), nil

	default:
		return nil, fmt.Errorf("unsupported provider type: %s", f.config.ProviderType)
	}
}
