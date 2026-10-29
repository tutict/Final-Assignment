package config

import (
	"path/filepath"
	"testing"

	"github.com/zeromicro/go-zero/core/conf"
)

func TestLoadDefaultConfig(t *testing.T) {
	var config Config
	path := filepath.Join("..", "..", "..", "etc", "gozero-api.yaml")
	if err := conf.Load(path, &config); err != nil {
		t.Fatalf("Load(%s) error = %v", path, err)
	}
	if config.Rag.EmbeddingProvider != "ollama" {
		t.Fatalf("Rag.EmbeddingProvider = %q", config.Rag.EmbeddingProvider)
	}
	if config.Rag.EmbeddingDimensions != 768 {
		t.Fatalf("Rag.EmbeddingDimensions = %d", config.Rag.EmbeddingDimensions)
	}
	if config.Rag.RetrievalTopK != 10 {
		t.Fatalf("Rag.RetrievalTopK = %d", config.Rag.RetrievalTopK)
	}
	if !config.Rag.RerankEnabled {
		t.Fatalf("Rag.RerankEnabled = false")
	}
}
