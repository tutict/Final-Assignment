package provider

import (
	"testing"

	"final_assignment_backend_go/project/internal/config"
)

func TestFactory_CreateProvider(t *testing.T) {
	tests := []struct {
		name     string
		config   *config.AiChatConfig
		wantErr  bool
		wantType string
	}{
		{
			name: "openai provider",
			config: &config.AiChatConfig{
				ProviderType:   "openai",
				ProviderAPIKey: "sk-test",
				ProviderModel:  "gpt-4",
			},
			wantErr:  false,
			wantType: "openai",
		},
		{
			name: "claude provider with URL",
			config: &config.AiChatConfig{
				ProviderType:   "claude",
				ProviderAPIKey: "sk-test",
				ProviderURL:    "https://api.anthropic.com/v1",
				ProviderModel:  "claude-3-opus",
			},
			wantErr:  false,
			wantType: "openai", // Uses OpenAI-compatible provider
		},
		{
			name: "claude provider without URL",
			config: &config.AiChatConfig{
				ProviderType:   "claude",
				ProviderAPIKey: "sk-test",
				ProviderModel:  "claude-3-opus",
			},
			wantErr: true,
		},
		{
			name: "local provider with URL",
			config: &config.AiChatConfig{
				ProviderType:  "local",
				ProviderURL:   "http://localhost:11434",
				ProviderModel: "llama2",
			},
			wantErr:  false,
			wantType: "openai",
		},
		{
			name: "local provider without URL",
			config: &config.AiChatConfig{
				ProviderType:  "local",
				ProviderModel: "llama2",
			},
			wantErr: true,
		},
		{
			name: "unsupported provider type",
			config: &config.AiChatConfig{
				ProviderType:   "unsupported",
				ProviderAPIKey: "sk-test",
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			factory := NewFactory(tt.config)
			provider, err := factory.CreateProvider()

			if (err != nil) != tt.wantErr {
				t.Errorf("CreateProvider() error = %v, wantErr %v", err, tt.wantErr)
				return
			}

			if tt.wantErr {
				return
			}

			if provider == nil {
				t.Error("CreateProvider() returned nil provider")
				return
			}

			if tt.wantType != "" && provider.ProviderName() != tt.wantType {
				t.Errorf("Provider type = %s, want %s", provider.ProviderName(), tt.wantType)
			}
		})
	}
}

func TestNewFactory(t *testing.T) {
	cfg := &config.AiChatConfig{
		ProviderType:   "openai",
		ProviderAPIKey: "sk-test",
	}

	factory := NewFactory(cfg)
	if factory == nil {
		t.Fatal("NewFactory() returned nil")
	}

	if factory.config != cfg {
		t.Error("Factory config not set correctly")
	}
}
