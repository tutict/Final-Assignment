package service

import (
	"context"
	"fmt"
	"math"
	"regexp"
	"sort"
	"strings"
	"unicode"

	"golang.org/x/text/unicode/norm"
)

var ragTokenPattern = regexp.MustCompile(`[\p{Han}]{2,}|[\p{L}\p{N}_]{2,}`)

type RagQueryService struct {
	searchBackend     RagSearchBackend
	embeddingProvider RagEmbeddingProvider
	config            RagConfig
}

func NewRagQueryService(
	searchBackend RagSearchBackend,
	embeddingProvider RagEmbeddingProvider,
	config RagConfig,
) *RagQueryService {
	return &RagQueryService{
		searchBackend:     searchBackend,
		embeddingProvider: embeddingProvider,
		config:            normalizeRagConfig(config),
	}
}

func (s *RagQueryService) Query(ctx context.Context, request RagQueryRequest) (RagQueryResponse, error) {
	if s == nil || !s.config.Enabled || !s.config.RetrievalEnabled || s.searchBackend == nil {
		return RagQueryResponse{Results: []RagRetrievalResult{}}, nil
	}
	normalizedQuery := NormalizeRagQuery(request.Query)
	if normalizedQuery == "" {
		return RagQueryResponse{Results: []RagRetrievalResult{}}, nil
	}
	topK := s.config.RetrievalTopK
	if request.TopK != nil {
		topK = *request.TopK
	}
	query := RagRetrievalQuery{
		NormalizedQuery: normalizedQuery,
		AccessContext:   newRagAccessContext(request.UserID, request.Roles, request.Department),
		TopK:            normalizeLimit(topK, 0),
	}
	return RagQueryResponse{Results: s.retrieve(ctx, query)}, nil
}

func NormalizeRagQuery(query string) string {
	if strings.TrimSpace(query) == "" {
		return ""
	}
	normalized := norm.NFKC.String(query)
	return strings.Join(strings.FieldsFunc(normalized, unicode.IsSpace), " ")
}

func (s *RagQueryService) retrieve(ctx context.Context, query RagRetrievalQuery) []RagRetrievalResult {
	aclFilter := buildRagAccessFilter(query.AccessContext)
	candidateLimit := query.TopK * intMax(1, s.config.CandidateMultiplier)
	candidateLimit = intMax(query.TopK, candidateLimit)

	bm25Results, err := s.searchBackend.BM25Search(ctx, query.NormalizedQuery, aclFilter, candidateLimit)
	if err != nil {
		bm25Results = nil
	}
	vectorResults := s.vectorResults(ctx, query.NormalizedQuery, aclFilter, candidateLimit)
	return s.rerank(query.NormalizedQuery, s.fuseResults(bm25Results, vectorResults, query.AccessContext, query.TopK))
}

func (s *RagQueryService) vectorResults(
	ctx context.Context,
	normalizedQuery string,
	aclFilter RagAccessFilter,
	candidateLimit int,
) []RagRetrievalResult {
	if s.embeddingProvider == nil {
		return nil
	}
	queryVector, err := s.embeddingProvider.Embed(ctx, normalizedQuery)
	if err != nil || len(queryVector) == 0 {
		return nil
	}
	results, err := s.searchBackend.VectorSearch(ctx, queryVector, aclFilter, candidateLimit)
	if err != nil {
		return nil
	}
	return results
}

func (s *RagQueryService) fuseResults(
	bm25Results []RagRetrievalResult,
	vectorResults []RagRetrievalResult,
	accessContext RagAccessContext,
	topK int,
) []RagRetrievalResult {
	byChunkID := make(map[string]*ragScoreAccumulator)
	order := make([]string, 0, len(bm25Results)+len(vectorResults))
	s.accumulateRankScores(byChunkID, &order, bm25Results, true)
	s.accumulateRankScores(byChunkID, &order, vectorResults, false)

	results := make([]RagRetrievalResult, 0, len(byChunkID))
	for _, chunkID := range order {
		accumulator := byChunkID[chunkID]
		if accumulator == nil {
			continue
		}
		result := accumulator.result.WithScores(accumulator.bm25Score, accumulator.vectorScore, accumulator.rrfScore)
		if result.FinalScore < s.config.MinScore {
			continue
		}
		if !allowsRagResult(result, accessContext) {
			continue
		}
		results = append(results, result)
	}
	sort.SliceStable(results, func(left, right int) bool {
		return results[left].FinalScore > results[right].FinalScore
	})
	if topK = normalizeLimit(topK, 0); len(results) > topK {
		results = results[:topK]
	}
	return results
}

func (s *RagQueryService) accumulateRankScores(
	byChunkID map[string]*ragScoreAccumulator,
	order *[]string,
	results []RagRetrievalResult,
	bm25 bool,
) {
	for index, result := range results {
		chunkID := strings.TrimSpace(result.ChunkID)
		if chunkID == "" {
			continue
		}
		accumulator, exists := byChunkID[chunkID]
		if !exists {
			accumulator = &ragScoreAccumulator{result: result}
			byChunkID[chunkID] = accumulator
			*order = append(*order, chunkID)
		}
		if bm25 {
			accumulator.bm25Score = math.Max(accumulator.bm25Score, result.BM25Score)
			accumulator.rrfScore += s.reciprocalRankScore(index+1, s.config.BM25Weight)
		} else {
			accumulator.vectorScore = math.Max(accumulator.vectorScore, result.VectorScore)
			accumulator.rrfScore += s.reciprocalRankScore(index+1, s.config.VectorWeight)
		}
	}
}

func (s *RagQueryService) reciprocalRankScore(rank int, weight float64) float64 {
	if weight < 0 {
		weight = 0
	}
	rankConstant := intMax(1, s.config.RRFRankConstant)
	return 100.0 * weight / float64(rankConstant+intMax(1, rank))
}

func (s *RagQueryService) rerank(query string, results []RagRetrievalResult) []RagRetrievalResult {
	if !s.config.RerankEnabled || len(results) < 2 {
		return results
	}
	queryTokens := ragTokens(query)
	if len(queryTokens) == 0 {
		return results
	}
	weight := clamp01(s.config.RerankLexicalWeight)
	if weight <= 0 {
		return results
	}
	reranked := make([]RagRetrievalResult, 0, len(results))
	for _, result := range results {
		result.FinalScore += lexicalRagScore(queryTokens, result) * weight
		reranked = append(reranked, result)
	}
	sort.SliceStable(reranked, func(left, right int) bool {
		return reranked[left].FinalScore > reranked[right].FinalScore
	})
	return reranked
}

func newRagAccessContext(userID string, roles []string, department string) RagAccessContext {
	return RagAccessContext{
		UserID:     blankToEmpty(userID),
		Roles:      normalizeRagList(roles),
		Department: blankToEmpty(department),
	}
}

func buildRagAccessFilter(context RagAccessContext) RagAccessFilter {
	return RagAccessFilter{
		UserID:     context.UserID,
		Roles:      normalizeRagList(context.Roles),
		Department: context.Department,
	}
}

func allowsRagResult(result RagRetrievalResult, context RagAccessContext) bool {
	scope := strings.ToUpper(metadataString(result.Metadata, result.ACLScope, "aclScope", "acl_scope"))
	if scope == "" || scope == "PUBLIC" {
		return true
	}
	switch scope {
	case "ROLE":
		return intersectsRagValues(context.Roles, metadataValues(result.Metadata, result.ACLRoles, "roles", "aclRoles", "acl_roles"))
	case "USER":
		return context.UserID != "" &&
			containsRagValue(metadataValues(result.Metadata, result.ACLUserIDs, "userIds", "userId", "aclUserIds", "acl_user_ids"), context.UserID)
	case "DEPARTMENT":
		return context.Department != "" &&
			containsRagValue(metadataValues(result.Metadata, result.ACLDepartments, "departments", "department", "aclDepartments", "acl_departments"), context.Department)
	default:
		return false
	}
}

func lexicalRagScore(queryTokens map[string]struct{}, result RagRetrievalResult) float64 {
	titleScore := ragTokenOverlap(queryTokens, result.Title)
	contentScore := ragTokenOverlap(queryTokens, result.Content)
	sourceScore := ragTokenOverlap(queryTokens, result.SourceField)
	return titleScore*0.45 + contentScore*0.45 + sourceScore*0.10
}

func ragTokenOverlap(queryTokens map[string]struct{}, text string) float64 {
	textTokens := ragTokens(text)
	if len(textTokens) == 0 {
		return 0
	}
	hits := 0
	for token := range queryTokens {
		if _, ok := textTokens[token]; ok {
			hits++
		}
	}
	return float64(hits) / float64(len(queryTokens))
}

func ragTokens(text string) map[string]struct{} {
	if strings.TrimSpace(text) == "" {
		return nil
	}
	normalized := strings.ToLower(norm.NFKC.String(text))
	matches := ragTokenPattern.FindAllString(normalized, -1)
	if len(matches) == 0 {
		return nil
	}
	tokens := make(map[string]struct{}, len(matches))
	for _, token := range matches {
		tokens[token] = struct{}{}
		runes := []rune(token)
		if hasHanRune(runes) && len(runes) > 2 {
			for index := 0; index <= len(runes)-2; index++ {
				tokens[string(runes[index:index+2])] = struct{}{}
			}
		}
	}
	return tokens
}

func hasHanRune(runes []rune) bool {
	for _, value := range runes {
		if unicode.Is(unicode.Han, value) {
			return true
		}
	}
	return false
}

func metadataString(metadata map[string]any, fallback string, keys ...string) string {
	if text := strings.TrimSpace(fallback); text != "" {
		return text
	}
	for _, key := range keys {
		value, ok := metadata[key]
		if ok && value != nil && strings.TrimSpace(valueToString(value)) != "" {
			return strings.TrimSpace(valueToString(value))
		}
	}
	return "PUBLIC"
}

func metadataValues(metadata map[string]any, fallback []string, keys ...string) []string {
	if values := normalizeRagList(fallback); len(values) > 0 {
		return values
	}
	for _, key := range keys {
		value, ok := metadata[key]
		if !ok || value == nil {
			continue
		}
		values := anyToStringList(value)
		if len(values) > 0 {
			return values
		}
	}
	return nil
}

func anyToStringList(value any) []string {
	switch typed := value.(type) {
	case []string:
		return normalizeRagList(typed)
	case []any:
		values := make([]string, 0, len(typed))
		for _, item := range typed {
			values = append(values, valueToString(item))
		}
		return normalizeRagList(values)
	default:
		text := strings.TrimSpace(valueToString(typed))
		if text == "" {
			return nil
		}
		return []string{text}
	}
}

func normalizeRagList(values []string) []string {
	if len(values) == 0 {
		return nil
	}
	seen := make(map[string]struct{}, len(values))
	normalized := make([]string, 0, len(values))
	for _, value := range values {
		text := strings.TrimSpace(value)
		if text == "" {
			continue
		}
		if _, ok := seen[text]; ok {
			continue
		}
		seen[text] = struct{}{}
		normalized = append(normalized, text)
	}
	return normalized
}

func intersectsRagValues(left []string, right []string) bool {
	if len(left) == 0 || len(right) == 0 {
		return false
	}
	values := make(map[string]struct{}, len(right))
	for _, value := range right {
		values[value] = struct{}{}
	}
	for _, value := range left {
		if _, ok := values[value]; ok {
			return true
		}
	}
	return false
}

func containsRagValue(values []string, target string) bool {
	for _, value := range values {
		if value == target {
			return true
		}
	}
	return false
}

func blankToEmpty(value string) string {
	return strings.TrimSpace(value)
}

func valueToString(value any) string {
	if value == nil {
		return ""
	}
	return strings.TrimSpace(fmt.Sprint(value))
}

func clamp01(value float64) float64 {
	if math.IsNaN(value) || value <= 0 {
		return 0
	}
	if value > 1 {
		return 1
	}
	return value
}

func intMax(left, right int) int {
	if left > right {
		return left
	}
	return right
}

type ragScoreAccumulator struct {
	result      RagRetrievalResult
	bm25Score   float64
	vectorScore float64
	rrfScore    float64
}
