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

func TestApplyEnvOverridesReplacesRetrievalWeights(t *testing.T) {
	t.Setenv("RAG_RETRIEVAL_BM25_WEIGHT", "0.85")
	t.Setenv("RAG_RETRIEVAL_VECTOR_WEIGHT", "0.15")
	t.Setenv("RAG_RETRIEVAL_MIN_SCORE", "0.35")
	t.Setenv("RAG_RETRIEVAL_CANDIDATE_MULTIPLIER", "5")
	t.Setenv("RAG_RETRIEVAL_RRF_RANK_CONSTANT", "30")
	t.Setenv("RAG_RERANK_LEXICAL_WEIGHT", "0.25")

	conf := applyEnvOverrides(config.RagConf{
		BM25Weight:          0.8,
		VectorWeight:        0.2,
		MinScore:            0.2,
		CandidateMultiplier: 3,
		RRFRankConstant:     60,
		RerankLexicalWeight: 0.15,
	})

	if conf.BM25Weight != 0.85 {
		t.Fatalf("bm25 weight = %v, want 0.85", conf.BM25Weight)
	}
	if conf.VectorWeight != 0.15 {
		t.Fatalf("vector weight = %v, want 0.15", conf.VectorWeight)
	}
	if conf.MinScore != 0.35 {
		t.Fatalf("min score = %v, want 0.35", conf.MinScore)
	}
	if conf.CandidateMultiplier != 5 {
		t.Fatalf("candidate multiplier = %d, want 5", conf.CandidateMultiplier)
	}
	if conf.RRFRankConstant != 30 {
		t.Fatalf("rrf rank constant = %d, want 30", conf.RRFRankConstant)
	}
	if conf.RerankLexicalWeight != 0.25 {
		t.Fatalf("rerank lexical weight = %v, want 0.25", conf.RerankLexicalWeight)
	}
}

func TestApplyEnvOverridesIgnoresInvalidRetrievalWeights(t *testing.T) {
	t.Setenv("RAG_RETRIEVAL_BM25_WEIGHT", "not-a-number")
	t.Setenv("RAG_RETRIEVAL_VECTOR_WEIGHT", "0")
	t.Setenv("RAG_RETRIEVAL_CANDIDATE_MULTIPLIER", "-2")

	conf := applyEnvOverrides(config.RagConf{
		BM25Weight:          0.8,
		VectorWeight:        0.2,
		CandidateMultiplier: 3,
	})

	if conf.BM25Weight != 0.8 {
		t.Fatalf("bm25 weight = %v, want the configured 0.8", conf.BM25Weight)
	}
	if conf.VectorWeight != 0.2 {
		t.Fatalf("vector weight = %v, want the configured 0.2", conf.VectorWeight)
	}
	if conf.CandidateMultiplier != 3 {
		t.Fatalf("candidate multiplier = %d, want the configured 3", conf.CandidateMultiplier)
	}
}

func TestApplyEnvOverridesHonoursTheRagEnabledSwitch(t *testing.T) {
	t.Setenv("RAG_ENABLED", "false")

	conf := applyEnvOverrides(config.RagConf{Enabled: true})

	if conf.Enabled {
		t.Fatal("RAG_ENABLED=false 必须关掉检索，否则压测关不掉这条链路")
	}
}

func TestApplyEnvOverridesKeepsTheYamlSwitchWithoutAnEnvValue(t *testing.T) {
	t.Setenv("RAG_ENABLED", "")

	if conf := applyEnvOverrides(config.RagConf{Enabled: true}); !conf.Enabled {
		t.Fatal("没设置 RAG_ENABLED 时应当沿用 yaml 的 Rag.Enabled=true")
	}
	if conf := applyEnvOverrides(config.RagConf{Enabled: false}); conf.Enabled {
		t.Fatal("没设置 RAG_ENABLED 时应当沿用 yaml 的 Rag.Enabled=false")
	}
}
