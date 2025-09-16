package caffeine

import (
	"github.com/Yiling-J/theine-go"
)

func NewCacheManager() (*theine.Cache[string, string], error) {
	// Create a builder with maximum size of 100 entries
	builder := theine.NewBuilder[string, string](100)

	// Optional: Define cost function if values have varying "weights" (e.g., based on size)
	builder.Cost(func(v string) int64 {
		return 1 // Each entry costs 1 unit; adjust if needed for variable sizes
	})

	// Build the cache
	cache, err := builder.Build()
	if err != nil {
		return nil, err
	}

	return cache, nil
}
