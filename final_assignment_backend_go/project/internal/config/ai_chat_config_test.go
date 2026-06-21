package config

import (
	"os"
	"testing"
	"time"
)

func TestLoadFromEnv(t *testing.T) {
	// Set test environment variables
	os.Setenv("AI_PROVIDER_TYPE", "claude")
	os.Setenv("AI_PROVIDER_API_KEY", "test-key")
	os.Setenv("AI_PROVIDER_MODEL", "claude-3-opus")
	os.Setenv("RAG_ENABLED", "true")
	os.Setenv("RAG_TOP_K", "5")
	os.Setenv("SERVER_PORT", "9090")
	os.Setenv("WEB_SEARCH_ENABLED", "false")

	defer func() {
		os.Unsetenv("AI_PROVIDER_TYPE")
		os.Unsetenv("AI_PROVIDER_API_KEY")
		os.Unsetenv("AI_PROVIDER_MODEL")
		os.Unsetenv("RAG_ENABLED")
		os.Unsetenv("RAG_TOP_K")
		os.Unsetenv("SERVER_PORT")
		os.Unsetenv("WEB_SEARCH_ENABLED")
	}()

	cfg := LoadFromEnv()

	if cfg.ProviderType != "claude" {
		t.Errorf("ProviderType = %s, want claude", cfg.ProviderType)
	}
	if cfg.ProviderAPIKey != "test-key" {
		t.Errorf("ProviderAPIKey = %s, want test-key", cfg.ProviderAPIKey)
	}
	if cfg.ProviderModel != "claude-3-opus" {
		t.Errorf("ProviderModel = %s, want claude-3-opus", cfg.ProviderModel)
	}
	if !cfg.RAGEnabled {
		t.Error("RAGEnabled should be true")
	}
	if cfg.RAGTopK != 5 {
		t.Errorf("RAGTopK = %d, want 5", cfg.RAGTopK)
	}
	if cfg.ServerPort != 9090 {
		t.Errorf("ServerPort = %d, want 9090", cfg.ServerPort)
	}
	if cfg.WebSearchEnabled {
		t.Error("WebSearchEnabled should be false")
	}
}

func TestLoadFromEnv_Defaults(t *testing.T) {
	// Clear all env vars to test defaults
	envVars := []string{
		"AI_PROVIDER_TYPE", "AI_PROVIDER_API_KEY", "AI_PROVIDER_MODEL",
		"RAG_ENABLED", "RAG_TOP_K", "SERVER_PORT",
	}
	for _, key := range envVars {
		os.Unsetenv(key)
	}

	cfg := LoadFromEnv()

	if cfg.ProviderType != "openai" {
		t.Errorf("Default ProviderType = %s, want openai", cfg.ProviderType)
	}
	if cfg.ProviderModel != "gpt-4" {
		t.Errorf("Default ProviderModel = %s, want gpt-4", cfg.ProviderModel)
	}
	if !cfg.RAGEnabled {
		t.Error("Default RAGEnabled should be true")
	}
	if cfg.RAGTopK != 10 {
		t.Errorf("Default RAGTopK = %d, want 10", cfg.RAGTopK)
	}
	if cfg.ServerPort != 8081 {
		t.Errorf("Default ServerPort = %d, want 8081", cfg.ServerPort)
	}
	if !cfg.WebSearchEnabled {
		t.Error("Default WebSearchEnabled should be true")
	}
}

func TestAiChatConfig_Validate(t *testing.T) {
	tests := []struct {
		name    string
		config  *AiChatConfig
		wantErr bool
	}{
		{
			name: "valid config",
			config: &AiChatConfig{
				ProviderType:   "openai",
				ProviderAPIKey: "sk-test",
				RAGTopK:        10,
				ServerPort:     8080,
			},
			wantErr: false,
		},
		{
			name: "missing provider type",
			config: &AiChatConfig{
				ProviderType:   "",
				ProviderAPIKey: "sk-test",
				RAGTopK:        10,
				ServerPort:     8080,
			},
			wantErr: true,
		},
		{
			name: "missing API key for non-local provider",
			config: &AiChatConfig{
				ProviderType:   "openai",
				ProviderAPIKey: "",
				RAGTopK:        10,
				ServerPort:     8080,
			},
			wantErr: true,
		},
		{
			name: "local provider without API key is valid",
			config: &AiChatConfig{
				ProviderType:   "local",
				ProviderAPIKey: "",
				RAGTopK:        10,
				ServerPort:     8080,
			},
			wantErr: false,
		},
		{
			name: "invalid RAG TopK",
			config: &AiChatConfig{
				ProviderType:   "openai",
				ProviderAPIKey: "sk-test",
				RAGTopK:        0,
				ServerPort:     8080,
			},
			wantErr: true,
		},
		{
			name: "invalid server port - too low",
			config: &AiChatConfig{
				ProviderType:   "openai",
				ProviderAPIKey: "sk-test",
				RAGTopK:        10,
				ServerPort:     0,
			},
			wantErr: true,
		},
		{
			name: "invalid server port - too high",
			config: &AiChatConfig{
				ProviderType:   "openai",
				ProviderAPIKey: "sk-test",
				RAGTopK:        10,
				ServerPort:     70000,
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.config.Validate()
			if (err != nil) != tt.wantErr {
				t.Errorf("Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestGetEnvDuration(t *testing.T) {
	os.Setenv("TEST_DURATION", "5m")
	defer os.Unsetenv("TEST_DURATION")

	duration := getEnvDuration("TEST_DURATION", 1*time.Minute)
	if duration != 5*time.Minute {
		t.Errorf("getEnvDuration() = %v, want 5m", duration)
	}

	// Test invalid duration falls back to default
	os.Setenv("TEST_DURATION", "invalid")
	duration = getEnvDuration("TEST_DURATION", 1*time.Minute)
	if duration != 1*time.Minute {
		t.Errorf("getEnvDuration() with invalid value = %v, want 1m (default)", duration)
	}
}

func TestGetEnvFloat(t *testing.T) {
	os.Setenv("TEST_FLOAT", "0.75")
	defer os.Unsetenv("TEST_FLOAT")

	value := getEnvFloat("TEST_FLOAT", 0.5)
	if value != 0.75 {
		t.Errorf("getEnvFloat() = %f, want 0.75", value)
	}

	// Test invalid float falls back to default
	os.Setenv("TEST_FLOAT", "invalid")
	value = getEnvFloat("TEST_FLOAT", 0.5)
	if value != 0.5 {
		t.Errorf("getEnvFloat() with invalid value = %f, want 0.5 (default)", value)
	}
}
