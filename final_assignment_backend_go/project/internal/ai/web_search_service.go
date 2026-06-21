package ai

import (
	"context"
	"fmt"
	"strconv"
	"sync"
	"time"

	"final_assignment_backend_go/project/internal/service"
)

// WebSearchService provides web search capabilities with caching
type WebSearchService struct {
	scraper    *BaiduScraper
	cache      map[string]*cachedSearchResult
	cacheMutex sync.RWMutex
	cacheTTL   time.Duration
	maxResults int
}

// cachedSearchResult stores search results with expiration
type cachedSearchResult struct {
	Results   []service.RagRetrievalResult
	ExpiresAt time.Time
}

// NewWebSearchService creates a new WebSearchService
func NewWebSearchService() *WebSearchService {
	return &WebSearchService{
		scraper:    NewBaiduScraper(),
		cache:      make(map[string]*cachedSearchResult),
		cacheTTL:   10 * time.Minute,
		maxResults: 5,
	}
}

// Search performs a web search and returns results in RAG format
func (wss *WebSearchService) Search(ctx context.Context, query string) ([]service.RagRetrievalResult, error) {
	if query == "" {
		return []service.RagRetrievalResult{}, nil
	}

	// Check cache first
	if cached := wss.getFromCache(query); cached != nil {
		return cached, nil
	}

	// Perform search
	rawResults, err := wss.scraper.Search(ctx, query, wss.maxResults)
	if err != nil {
		// Log error but return empty results (graceful degradation)
		fmt.Printf("[WebSearchService] Search failed (graceful degradation): %v\n", err)
		return []service.RagRetrievalResult{}, nil
	}

	// Convert to RAG format
	results := wss.convertToRagFormat(rawResults)

	// Cache results
	wss.saveToCache(query, results)

	return results, nil
}

// convertToRagFormat converts WebSearchResult to RagRetrievalResult
func (wss *WebSearchService) convertToRagFormat(rawResults []WebSearchResult) []service.RagRetrievalResult {
	results := make([]service.RagRetrievalResult, 0, len(rawResults))

	for i, r := range rawResults {
		// Use abstract if available, otherwise use snippet
		content := r.Abstract
		if content == "" {
			content = r.Snippet
		}

		// Skip results without meaningful content
		if content == "" {
			continue
		}

		// Calculate score based on rank (decay by position)
		score := 1.0 - float64(i)*0.01
		if score < 0.1 {
			score = 0.1
		}

		result := service.RagRetrievalResult{
			ChunkID:     fmt.Sprintf("web-search-%d", i+1),
			DocumentID:  "web-search",
			Content:     content,
			Title:       r.Title,
			SourceType:  "WEB_SEARCH",
			SourceTable: "web_search",
			SourceID:    strconv.Itoa(i + 1),
			SourceField: "content",
			Route:       r.URL,
			BM25Score:   0.0,
			VectorScore: 0.0,
			FinalScore:  score,
			Metadata: map[string]any{
				"source": "baidu",
				"url":    r.URL,
			},
		}

		results = append(results, result)
	}

	return results
}

// getFromCache retrieves cached search results
func (wss *WebSearchService) getFromCache(query string) []service.RagRetrievalResult {
	wss.cacheMutex.RLock()
	defer wss.cacheMutex.RUnlock()

	cached, exists := wss.cache[query]
	if !exists {
		return nil
	}

	// Check if expired
	if time.Now().After(cached.ExpiresAt) {
		return nil
	}

	return cached.Results
}

// saveToCache stores search results in cache
func (wss *WebSearchService) saveToCache(query string, results []service.RagRetrievalResult) {
	wss.cacheMutex.Lock()
	defer wss.cacheMutex.Unlock()

	wss.cache[query] = &cachedSearchResult{
		Results:   results,
		ExpiresAt: time.Now().Add(wss.cacheTTL),
	}

	// Simple cache cleanup: remove expired entries
	now := time.Now()
	for q, cached := range wss.cache {
		if now.After(cached.ExpiresAt) {
			delete(wss.cache, q)
		}
	}
}

// SetMaxResults sets the maximum number of search results
func (wss *WebSearchService) SetMaxResults(max int) {
	if max > 0 {
		wss.maxResults = max
	}
}

// ClearCache clears all cached search results
func (wss *WebSearchService) ClearCache() {
	wss.cacheMutex.Lock()
	defer wss.cacheMutex.Unlock()
	wss.cache = make(map[string]*cachedSearchResult)
}
