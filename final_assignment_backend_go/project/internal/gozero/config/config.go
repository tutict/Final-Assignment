package config

import "github.com/zeromicro/go-zero/rest"

type Config struct {
	rest.RestConf
	Rag RagConf `json:",optional"`
}

type RagConf struct {
	Enabled                bool     `json:",optional"`
	IndexingEnabled        bool     `json:",optional"`
	EmbeddingEnabled       bool     `json:",optional"`
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
	AutoMigrate            bool     `json:",optional"`
}
