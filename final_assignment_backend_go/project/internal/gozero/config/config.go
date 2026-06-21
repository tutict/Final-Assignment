package config

import "github.com/zeromicro/go-zero/rest"

type Config struct {
	rest.RestConf
	Rag RagConf `json:",optional"`
	Ai  AiConf  `json:",optional"`
}

type AiConf struct {
	StreamingEnabled                     bool     `json:",optional"`
	ProviderPrimary                      string   `json:",optional"`
	ProviderFallback                     string   `json:",optional"`
	ProviderTimeoutMillis                int      `json:",optional"`
	ProviderStreamingTimeoutMillis       int      `json:",optional"`
	ProviderRetryAttempts                int      `json:",optional"`
	CircuitBreakerFailureThreshold       int      `json:",optional"`
	KeepaliveMillis                      int      `json:",optional"`
	PromptContextTokenBudget             int      `json:",optional"`
	MockTokens                           []string `json:",optional"`
	MockDelayMillis                      int      `json:",optional"`
	OllamaEnabled                        bool     `json:",optional"`
	OllamaBaseURL                        string   `json:",optional"`
	OllamaChatModel                      string   `json:",optional"`
	OpenAICompatibleEnabled              bool     `json:",optional"`
	OpenAICompatibleBaseURL              string   `json:",optional"`
	OpenAICompatibleAPIKey               string   `json:",optional"`
	OpenAICompatibleChatModel            string   `json:",optional"`
	OpenAICompatiblePath                 string   `json:",optional"`
	OpenAICompatibleModelsPath           string   `json:",optional"`
	ProviderUnavailableFallbackMessage   string   `json:",optional"`
	PromptInjectionWarning               string   `json:",optional"`
	DriverAgentConstraints               string   `json:",optional"`
	AdminAgentConstraints                string   `json:",optional"`
	SuperAdminAgentConstraints           string   `json:",optional"`
}

type RagConf struct {
	Enabled                bool     `json:",optional"`
	IndexingEnabled        bool     `json:",optional"`
	EmbeddingEnabled       bool     `json:",optional"`
	RetrievalEnabled       bool     `json:",optional"`
	MySQLDSN               string   `json:",optional"`
	ElasticsearchAddresses []string `json:",optional"`
	ElasticsearchUsername  string   `json:",optional"`
	ElasticsearchPassword  string   `json:",optional"`
	ElasticsearchIndex     string   `json:",optional"`
	ElasticsearchAlias     string   `json:",optional"`
	EmbeddingProvider      string   `json:",optional"`
	EmbeddingModel         string   `json:",optional"`
	EmbeddingDimensions    int      `json:",optional"`
	OllamaBaseURL          string   `json:",optional"`
	OllamaTimeoutMillis    int      `json:",optional"`
	MaxBatchSize           int      `json:",optional"`
	MaxRequeueLimit        int      `json:",optional"`
	MaxUploadBytes         int64    `json:",optional"`
	RetrievalTopK          int      `json:",optional"`
	VectorWeight           float64  `json:",optional"`
	BM25Weight             float64  `json:",optional"`
	MinScore               float64  `json:",optional"`
	CandidateMultiplier    int      `json:",optional"`
	RRFRankConstant        int      `json:",optional"`
	RerankEnabled          bool     `json:",optional"`
	RerankLexicalWeight    float64  `json:",optional"`
	AutoMigrate            bool     `json:",optional"`
}
