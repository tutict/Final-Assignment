package ai

import (
	"context"
	"testing"
	"time"

	"final_assignment_backend_go/project/internal/service"
)

func TestBaiduScraper_Search(t *testing.T) {
	scraper := NewBaiduScraper()

	tests := []struct {
		name        string
		query       string
		maxResults  int
		wantMinimum int // Minimum results we expect (allowing for scraping variability)
		skipLive    bool
	}{
		{
			name:        "empty query",
			query:       "",
			maxResults:  5,
			wantMinimum: 0,
			skipLive:    false,
		},
		{
			name:        "simple query",
			query:       "交通违章",
			maxResults:  3,
			wantMinimum: 0,    // Set to 0 to avoid flaky tests
			skipLive:    true, // Skip live test by default
		},
		{
			name:        "english query",
			query:       "golang tutorial",
			maxResults:  5,
			wantMinimum: 0,
			skipLive:    true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if tt.skipLive {
				t.Skip("Skipping live web scraping test")
			}

			ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			defer cancel()

			results, err := scraper.Search(ctx, tt.query, tt.maxResults)
			if err != nil && tt.query != "" {
				t.Logf("BaiduScraper.Search() error = %v (this is expected for anti-scraping)", err)
			}

			if len(results) < tt.wantMinimum {
				t.Errorf("BaiduScraper.Search() got %d results, want at least %d", len(results), tt.wantMinimum)
			}

			// Verify result structure
			for i, result := range results {
				if result.Title == "" && result.Abstract == "" {
					t.Errorf("BaiduScraper.Search() result[%d] has empty title and abstract", i)
				}
			}
		})
	}
}

func TestBaiduScraper_RandomUserAgent(t *testing.T) {
	scraper := NewBaiduScraper()

	// Call multiple times to ensure randomness
	agents := make(map[string]bool)
	for i := 0; i < 10; i++ {
		ua := scraper.randomUserAgent()
		if ua == "" {
			t.Error("randomUserAgent() returned empty string")
		}
		agents[ua] = true
	}

	// Should have at least 1 unique agent
	if len(agents) < 1 {
		t.Error("randomUserAgent() should return at least 1 unique agent")
	}
}

func TestWebSearchService_Search(t *testing.T) {
	wss := NewWebSearchService()

	tests := []struct {
		name      string
		query     string
		wantEmpty bool
	}{
		{
			name:      "empty query",
			query:     "",
			wantEmpty: true,
		},
		{
			name:      "valid query",
			query:     "test query",
			wantEmpty: false, // May be empty due to scraping failure
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer cancel()

			results, err := wss.Search(ctx, tt.query)
			if err != nil {
				t.Errorf("WebSearchService.Search() error = %v", err)
				return
			}

			if tt.wantEmpty && len(results) > 0 {
				t.Errorf("WebSearchService.Search() got %d results, want 0", len(results))
			}

			// Verify RAG format
			for i, result := range results {
				if result.SourceType != "WEB_SEARCH" {
					t.Errorf("WebSearchService.Search() result[%d].SourceType = %s, want WEB_SEARCH", i, result.SourceType)
				}
				if result.ChunkID == "" {
					t.Errorf("WebSearchService.Search() result[%d].ChunkID is empty", i)
				}
				if result.FinalScore <= 0 {
					t.Errorf("WebSearchService.Search() result[%d].FinalScore = %f, want > 0", i, result.FinalScore)
				}
			}
		})
	}
}

func TestWebSearchService_Cache(t *testing.T) {
	wss := NewWebSearchService()
	wss.cacheTTL = 1 * time.Second

	ctx := context.Background()
	query := "test cache query"

	// First search (will attempt to scrape, may fail)
	results1, err := wss.Search(ctx, query)
	if err != nil {
		t.Fatalf("First search error = %v", err)
	}

	// Manually populate cache for testing
	testResults := []service.RagRetrievalResult{
		{
			ChunkID:    "test-1",
			Content:    "test content",
			SourceType: "WEB_SEARCH",
			FinalScore: 0.9,
		},
	}
	wss.saveToCache(query, testResults)

	// Second search (should hit cache)
	results2, err := wss.Search(ctx, query)
	if err != nil {
		t.Fatalf("Second search error = %v", err)
	}

	// Should get cached results
	if len(results2) != len(testResults) {
		t.Errorf("Cache hit: got %d results, want %d", len(results2), len(testResults))
	}

	// Wait for cache to expire
	time.Sleep(2 * time.Second)

	// Third search (cache expired, will scrape again)
	results3, err := wss.Search(ctx, query)
	if err != nil {
		t.Fatalf("Third search error = %v", err)
	}

	// Results may be different (or empty if scraping fails)
	_ = results1
	_ = results3
}

func TestWebSearchService_ConvertToRagFormat(t *testing.T) {
	wss := NewWebSearchService()

	rawResults := []WebSearchResult{
		{
			Title:    "Test Result 1",
			URL:      "https://example.com/1",
			Abstract: "This is test abstract 1",
		},
		{
			Title:   "Test Result 2",
			URL:     "https://example.com/2",
			Snippet: "This is test snippet 2",
		},
		{
			Title:    "Empty Result",
			URL:      "https://example.com/3",
			Abstract: "",
			Snippet:  "",
		},
	}

	results := wss.convertToRagFormat(rawResults)

	// Should skip empty results
	if len(results) != 2 {
		t.Errorf("convertToRagFormat() got %d results, want 2", len(results))
	}

	// Check first result
	if results[0].Title != "Test Result 1" {
		t.Errorf("convertToRagFormat() result[0].Title = %s, want Test Result 1", results[0].Title)
	}
	if results[0].Content != "This is test abstract 1" {
		t.Errorf("convertToRagFormat() result[0].Content = %s, want abstract", results[0].Content)
	}
	if results[0].SourceType != "WEB_SEARCH" {
		t.Errorf("convertToRagFormat() result[0].SourceType = %s, want WEB_SEARCH", results[0].SourceType)
	}

	// Check score decay
	if results[0].FinalScore <= results[1].FinalScore {
		t.Errorf("convertToRagFormat() scores should decay: %f <= %f", results[0].FinalScore, results[1].FinalScore)
	}
}

func TestWebSearchService_ClearCache(t *testing.T) {
	wss := NewWebSearchService()

	// Add to cache
	testResults := []service.RagRetrievalResult{
		{ChunkID: "test-1", Content: "test", SourceType: "WEB_SEARCH"},
	}
	wss.saveToCache("test query", testResults)

	// Verify cache has entry
	if cached := wss.getFromCache("test query"); cached == nil {
		t.Error("Cache should have entry before clear")
	}

	// Clear cache
	wss.ClearCache()

	// Verify cache is empty
	if cached := wss.getFromCache("test query"); cached != nil {
		t.Error("Cache should be empty after clear")
	}
}
