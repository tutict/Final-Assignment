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
	if config.Rag.EmbeddingProvider != "deterministic" {
		t.Fatalf("Rag.EmbeddingProvider = %q", config.Rag.EmbeddingProvider)
	}
}
