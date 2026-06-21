package ai

import (
	"context"
	"fmt"
	"net/url"
	"strings"
	"time"

	"github.com/gocolly/colly/v2"
)

// WebSearchResult represents a single web search result
type WebSearchResult struct {
	Title    string
	URL      string
	Abstract string
	Snippet  string
}

// BaiduScraper scrapes search results from Baidu
type BaiduScraper struct {
	userAgents []string
	timeout    time.Duration
	minDelay   time.Duration
	maxDelay   time.Duration
}

// NewBaiduScraper creates a new Baidu search scraper
func NewBaiduScraper() *BaiduScraper {
	return &BaiduScraper{
		userAgents: []string{
			"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
			"Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0",
			"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
			"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
		},
		timeout:  30 * time.Second,
		minDelay: 500 * time.Millisecond,
		maxDelay: 1000 * time.Millisecond,
	}
}

// Search performs a Baidu search and returns results
func (bs *BaiduScraper) Search(ctx context.Context, query string, maxResults int) ([]WebSearchResult, error) {
	if query == "" {
		return []WebSearchResult{}, nil
	}

	if maxResults <= 0 {
		maxResults = 5
	}

	results := make([]WebSearchResult, 0, maxResults)
	resultChan := make(chan WebSearchResult, maxResults)
	errChan := make(chan error, 1)

	// Create collector with anti-scraping measures
	c := colly.NewCollector(
		colly.UserAgent(bs.randomUserAgent()),
		colly.Async(true),
	)

	// Set timeout
	c.SetRequestTimeout(bs.timeout)

	// Add random delays between requests
	c.Limit(&colly.LimitRule{
		DomainGlob:  "*baidu.com*",
		Delay:       bs.minDelay,
		RandomDelay: bs.maxDelay - bs.minDelay,
	})

	// Parse search results
	// Baidu search result structure: div.result or div.result-op
	c.OnHTML("div.result, div.result-op", func(e *colly.HTMLElement) {
		if len(results) >= maxResults {
			return
		}

		// Extract title
		title := strings.TrimSpace(e.ChildText("h3.t a, h3 a"))
		if title == "" {
			title = strings.TrimSpace(e.ChildText("h3"))
		}

		// Extract URL
		resultURL := e.ChildAttr("h3.t a, h3 a", "href")

		// Extract abstract/snippet
		abstract := strings.TrimSpace(e.ChildText("div.c-abstract, div.c-span9, span.content-right_8Zs40"))
		if abstract == "" {
			// Try alternative selectors
			abstract = strings.TrimSpace(e.ChildText("div[class*=abstract]"))
		}

		// Only add if we have meaningful content
		if title != "" && (abstract != "" || resultURL != "") {
			result := WebSearchResult{
				Title:    title,
				URL:      resultURL,
				Abstract: abstract,
				Snippet:  abstract,
			}

			select {
			case resultChan <- result:
			default:
			}
		}
	})

	// Handle errors
	c.OnError(func(r *colly.Response, err error) {
		select {
		case errChan <- fmt.Errorf("scraping error: %w", err):
		default:
		}
	})

	// Start scraping
	searchURL := fmt.Sprintf("https://www.baidu.com/s?wd=%s", url.QueryEscape(query))

	go func() {
		if err := c.Visit(searchURL); err != nil {
			errChan <- err
		}
		c.Wait()
		close(resultChan)
		close(errChan)
	}()

	// Collect results with timeout
	timeout := time.After(bs.timeout)
	for {
		select {
		case <-ctx.Done():
			return results, ctx.Err()
		case <-timeout:
			return results, fmt.Errorf("search timeout after %v", bs.timeout)
		case err := <-errChan:
			if err != nil {
				// Log error but continue with partial results
				fmt.Printf("[BaiduScraper] Error: %v\n", err)
			}
		case result, ok := <-resultChan:
			if !ok {
				// Channel closed, return what we have
				return results, nil
			}
			results = append(results, result)
			if len(results) >= maxResults {
				return results, nil
			}
		}
	}
}

// randomUserAgent returns a random user agent string
func (bs *BaiduScraper) randomUserAgent() string {
	if len(bs.userAgents) == 0 {
		return "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
	}
	// Simple random selection based on current time
	idx := int(time.Now().UnixNano()) % len(bs.userAgents)
	return bs.userAgents[idx]
}
