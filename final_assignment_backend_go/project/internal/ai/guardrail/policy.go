package guardrail

import (
	"regexp"
	"strconv"
	"strings"
	"unicode"

	ragsvc "final_assignment_backend_go/project/internal/service/rag"
)

// Canonical refusal texts. scripts/ragas/ragas_eval/sse.py compares them byte for byte.
const (
	NoSourceAnswer = "抱歉，当前知识库中没有可支撑该问题的资料，我无法给出有依据的回答。请补充更多信息或联系人工客服。"
	UncitedAnswer  = "抱歉，我无法为该问题提供有可靠来源支撑的回答。"
)

// Accept half-width [1] and full-width 【1】 markers, including grouped forms such as [1,2].
var (
	numericCitation   = regexp.MustCompile(`[\[【](\d{1,2}(?:\s*[,，]\s*\d{1,2})*)[\]】]`)
	citationSeparator = regexp.MustCompile(`[,，]`)
)

type Decision struct {
	Grounded bool
	Answer   string
	Reason   string
}

func Allowed(answer string) Decision {
	return Decision{Grounded: true, Answer: answer}
}

func Refused(answer, reason string) Decision {
	return Decision{Grounded: false, Answer: answer, Reason: reason}
}

// CitationPolicy implements "no citation, no answer": when retrieval hit the knowledge base,
// the answer must cite one of the retrieved sources.
type CitationPolicy struct {
	EnforcementEnabled bool
}

func (p CitationPolicy) Enabled() bool {
	return p.EnforcementEnabled
}

func (p CitationPolicy) Evaluate(answer string, sources []ragsvc.RagRetrievalResult) Decision {
	if !p.EnforcementEnabled {
		return Allowed(answer)
	}
	if strings.TrimSpace(answer) == "" {
		return Allowed(answer)
	}
	if len(sources) == 0 {
		return Refused(NoSourceAnswer, "no_sources")
	}
	if hasCitation(answer, sources) {
		return Allowed(answer)
	}
	return Refused(UncitedAnswer, "missing_citation")
}

func hasCitation(answer string, sources []ragsvc.RagRetrievalResult) bool {
	for _, match := range numericCitation.FindAllStringSubmatch(answer, -1) {
		for _, part := range citationSeparator.Split(match[1], -1) {
			digits := strings.TrimSpace(part)
			if digits == "" {
				continue
			}
			index, err := strconv.Atoi(digits)
			if err != nil {
				continue
			}
			if index >= 1 && index <= len(sources) {
				return true
			}
		}
	}
	lowered := strings.ToLower(answer)
	for _, source := range sources {
		if containsIdentifier(lowered, source.SourceID) ||
			containsIdentifier(lowered, source.DocumentID) ||
			containsIdentifier(lowered, source.Title) {
			return true
		}
	}
	return false
}

func containsIdentifier(loweredAnswer, candidate string) bool {
	needle := strings.ToLower(strings.TrimSpace(candidate))
	// Only distinctive identifiers count: a bare row id such as "12" would otherwise match
	// nearly any answer and let an uncited answer pass.
	if !isDistinctive(needle) {
		return false
	}
	return strings.Contains(loweredAnswer, needle)
}

func isDistinctive(needle string) bool {
	runes := []rune(needle)
	if len(runes) < 2 {
		return false
	}
	han := false
	letter := false
	for _, r := range runes {
		if unicode.Is(unicode.Han, r) {
			han = true
		}
		if unicode.IsLetter(r) {
			letter = true
		}
	}
	if han {
		return true
	}
	return letter && len(runes) >= 4
}
