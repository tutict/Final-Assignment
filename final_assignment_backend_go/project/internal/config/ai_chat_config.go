package config

import (
	"fmt"
	"os"
	"strconv"
	"time"
)

// AiChatConfig holds all configuration for the AI chat system
type AiChatConfig struct {
	// AI Provider settings
	ProviderType   string // "openai", "claude", "local"
	ProviderAPIKey string
	ProviderModel  string
	ProviderURL    string // For custom/local providers

	// RAG settings
	RAGEnabled     bool
	RAGTopK        int
	RAGMinScore    float64
	RAGTokenBudget int

	// Web Search settings
	WebSearchEnabled    bool
	WebSearchMaxResults int
	WebSearchCacheTTL   time.Duration

	// Agent Constraints
	ConstraintsPath            string
	DriverAgentConstraints     string
	AdminAgentConstraints      string
	SuperAdminAgentConstraints string

	// Server settings
	ServerPort         int
	ServerReadTimeout  time.Duration
	ServerWriteTimeout time.Duration

	// Streaming settings
	StreamKeepaliveInterval time.Duration
	StreamBufferSize        int

	// Cache settings
	CacheEnabled bool
	CacheTTL     time.Duration
}

// LoadFromEnv loads configuration from environment variables
func LoadFromEnv() *AiChatConfig {
	cfg := &AiChatConfig{
		// AI Provider defaults
		ProviderType:   getEnv("AI_PROVIDER_TYPE", "openai"),
		ProviderAPIKey: getEnv("AI_PROVIDER_API_KEY", ""),
		ProviderModel:  getEnv("AI_PROVIDER_MODEL", "gpt-4"),
		ProviderURL:    getEnv("AI_PROVIDER_URL", ""),

		// RAG defaults
		RAGEnabled:     getEnvBool("RAG_ENABLED", true),
		RAGTopK:        getEnvInt("RAG_TOP_K", 10),
		RAGMinScore:    getEnvFloat("RAG_MIN_SCORE", 0.5),
		RAGTokenBudget: getEnvInt("RAG_TOKEN_BUDGET", 1200),

		// Web Search defaults
		WebSearchEnabled:    getEnvBool("WEB_SEARCH_ENABLED", true),
		WebSearchMaxResults: getEnvInt("WEB_SEARCH_MAX_RESULTS", 5),
		WebSearchCacheTTL:   getEnvDuration("WEB_SEARCH_CACHE_TTL", 10*time.Minute),

		// Agent Constraints defaults
		ConstraintsPath:            getEnv("AGENT_CONSTRAINTS_PATH", "./constraints"),
		DriverAgentConstraints:     getEnv("DRIVER_CONSTRAINTS", "# Driver\n- Can only view own records"),
		AdminAgentConstraints:      getEnv("ADMIN_CONSTRAINTS", "# Admin\n- Can manage department records"),
		SuperAdminAgentConstraints: getEnv("SUPER_ADMIN_CONSTRAINTS", "# Super Admin\n- Full system access"),

		// Server defaults
		ServerPort:         getEnvInt("SERVER_PORT", 8081),
		ServerReadTimeout:  getEnvDuration("SERVER_READ_TIMEOUT", 30*time.Second),
		ServerWriteTimeout: getEnvDuration("SERVER_WRITE_TIMEOUT", 30*time.Second),

		// Streaming defaults
		StreamKeepaliveInterval: getEnvDuration("STREAM_KEEPALIVE_INTERVAL", 15*time.Second),
		StreamBufferSize:        getEnvInt("STREAM_BUFFER_SIZE", 10),

		// Cache defaults
		CacheEnabled: getEnvBool("CACHE_ENABLED", true),
		CacheTTL:     getEnvDuration("CACHE_TTL", 10*time.Minute),
	}

	return cfg
}

// Validate checks if the configuration is valid
func (c *AiChatConfig) Validate() error {
	if c.ProviderType == "" {
		return fmt.Errorf("AI_PROVIDER_TYPE is required")
	}

	if c.ProviderAPIKey == "" && c.ProviderType != "local" {
		return fmt.Errorf("AI_PROVIDER_API_KEY is required for provider type %s", c.ProviderType)
	}

	if c.RAGTopK <= 0 {
		return fmt.Errorf("RAG_TOP_K must be positive, got %d", c.RAGTopK)
	}

	if c.ServerPort <= 0 || c.ServerPort > 65535 {
		return fmt.Errorf("SERVER_PORT must be between 1 and 65535, got %d", c.ServerPort)
	}

	return nil
}

// getEnv gets an environment variable or returns a default value
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// getEnvBool gets a boolean environment variable
func getEnvBool(key string, defaultValue bool) bool {
	if value := os.Getenv(key); value != "" {
		if b, err := strconv.ParseBool(value); err == nil {
			return b
		}
	}
	return defaultValue
}

// getEnvInt gets an integer environment variable
func getEnvInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if i, err := strconv.Atoi(value); err == nil {
			return i
		}
	}
	return defaultValue
}

// getEnvFloat gets a float environment variable
func getEnvFloat(key string, defaultValue float64) float64 {
	if value := os.Getenv(key); value != "" {
		if f, err := strconv.ParseFloat(value, 64); err == nil {
			return f
		}
	}
	return defaultValue
}

// getEnvDuration gets a duration environment variable
func getEnvDuration(key string, defaultValue time.Duration) time.Duration {
	if value := os.Getenv(key); value != "" {
		if d, err := time.ParseDuration(value); err == nil {
			return d
		}
	}
	return defaultValue
}
