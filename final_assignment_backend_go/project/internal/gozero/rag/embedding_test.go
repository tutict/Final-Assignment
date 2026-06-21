package rag

import (
	"context"
	"testing"
)

func TestDeterministicEmbeddingProviderStableNormalizedVector(t *testing.T) {
	provider := NewDeterministicEmbeddingProvider(8, "")

	first, err := provider.Embed(context.Background(), "traffic offense")
	if err != nil {
		t.Fatalf("Embed() error = %v", err)
	}
	second, err := provider.Embed(context.Background(), "traffic offense")
	if err != nil {
		t.Fatalf("Embed() second error = %v", err)
	}

	if len(first) != 8 {
		t.Fatalf("len(vector) = %d, want 8", len(first))
	}
	for i := range first {
		if first[i] != second[i] {
			t.Fatalf("vector[%d] is not stable: %v != %v", i, first[i], second[i])
		}
	}
	if provider.ProviderName() != "deterministic" {
		t.Fatalf("ProviderName() = %q", provider.ProviderName())
	}
	if provider.ModelName() != "deterministic-8" {
		t.Fatalf("ModelName() = %q", provider.ModelName())
	}
}
