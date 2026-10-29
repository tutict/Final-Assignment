package rag

import (
	"testing"

	"final_assignment_backend_go/project/internal/gozero/config"
)

func TestApplyEnvOverridesReplacesRagWiring(t *testing.T) {
	t.Setenv("RAG_ELASTICSEARCH_ADDRESSES", "http://es-a:9200, http://es-b:9200")
	t.Setenv("RAG_ELASTICSEARCH_INDEX", "rag_chunk_go_eval_v1")
	t.Setenv("RAG_ELASTICSEARCH_ALIAS", "rag_chunk_go_eval_current")
	t.Setenv("RAG_EMBEDDING_PROVIDER", "ollama")
	t.Setenv("RAG_EMBEDDING_MODEL", "nomic-embed-text")
	t.Setenv("RAG_EMBEDDING_DIMENSIONS", "768")
	t.Setenv("RAG_OLLAMA_BASE_URL", "http://ollama:11434")
	t.Setenv("RAG_OLLAMA_TIMEOUT_MILLIS", "45000")

	conf := applyEnvOverrides(config.RagConf{
		ElasticsearchAddresses: []string{"http://127.0.0.1:9200"},
		ElasticsearchIndex:     "rag_chunk_go_v1",
		ElasticsearchAlias:     "rag_chunk_go_current",
		EmbeddingProvider:      "deterministic",
		EmbeddingModel:         "deterministic-384",
		EmbeddingDimensions:    384,
		OllamaBaseURL:          "http://127.0.0.1:11434",
		OllamaTimeoutMillis:    30000,
	})

	if len(conf.ElasticsearchAddresses) != 2 {
		t.Fatalf("addresses = %v, want two entries", conf.ElasticsearchAddresses)
	}
	if conf.ElasticsearchIndex != "rag_chunk_go_eval_v1" {
		t.Fatalf("index = %q, want rag_chunk_go_eval_v1", conf.ElasticsearchIndex)
	}
	if conf.ElasticsearchAlias != "rag_chunk_go_eval_current" {
		t.Fatalf("alias = %q, want rag_chunk_go_eval_current", conf.ElasticsearchAlias)
	}
	if conf.EmbeddingProvider != "ollama" {
		t.Fatalf("provider = %q, want ollama", conf.EmbeddingProvider)
	}
	if conf.EmbeddingModel != "nomic-embed-text" {
		t.Fatalf("model = %q, want nomic-embed-text", conf.EmbeddingModel)
	}
	if conf.EmbeddingDimensions != 768 {
		t.Fatalf("dimensions = %d, want 768", conf.EmbeddingDimensions)
	}
	if conf.OllamaBaseURL != "http://ollama:11434" {
		t.Fatalf("ollama base url = %q, want http://ollama:11434", conf.OllamaBaseURL)
	}
	if conf.OllamaTimeoutMillis != 45000 {
		t.Fatalf("ollama timeout = %d, want 45000", conf.OllamaTimeoutMillis)
	}
}

func TestApplyEnvOverridesKeepsConfiguredValuesWithoutEnv(t *testing.T) {
	conf := applyEnvOverrides(config.RagConf{
		ElasticsearchAddresses: []string{"http://127.0.0.1:9200"},
		ElasticsearchIndex:     "rag_chunk_go_v1",
		EmbeddingProvider:      "deterministic",
		EmbeddingModel:         "deterministic-384",
		EmbeddingDimensions:    384,
	})

	if conf.ElasticsearchIndex != "rag_chunk_go_v1" {
		t.Fatalf("index = %q, want the configured index", conf.ElasticsearchIndex)
	}
	if conf.EmbeddingModel != "deterministic-384" {
		t.Fatalf("model = %q, want the configured model", conf.EmbeddingModel)
	}
}

func TestNormalizeConfUsesOllamaDefaults(t *testing.T) {
	conf := normalizeConf(config.RagConf{EmbeddingProvider: "ollama"})

	if conf.EmbeddingModel != "nomic-embed-text" {
		t.Fatalf("model = %q, want nomic-embed-text", conf.EmbeddingModel)
	}
	if conf.EmbeddingDimensions != 768 {
		t.Fatalf("dimensions = %d, want 768", conf.EmbeddingDimensions)
	}
}

func TestNormalizeConfKeepsDeterministicDefaults(t *testing.T) {
	conf := normalizeConf(config.RagConf{})

	if conf.EmbeddingProvider != "deterministic" {
		t.Fatalf("provider = %q, want deterministic", conf.EmbeddingProvider)
	}
	if conf.EmbeddingDimensions != 384 {
		t.Fatalf("dimensions = %d, want 384", conf.EmbeddingDimensions)
	}
	if conf.EmbeddingModel != "deterministic-384" {
		t.Fatalf("model = %q, want deterministic-384", conf.EmbeddingModel)
	}
}
