package guardrail

import (
	"regexp"
	"strings"
)

// Mirrors AnswerTextSanitizer in the Spring backend: small models sometimes copy prompt-internal
// labels into the answer, while user-facing citation markers such as [1] must survive.
const internalLabel = `(?:<\s*/?\s*retrieved_context\s*>` +
	`|retrieved[_\- ]context` +
	`|manual_rag_document(?:\s*\[[^\]]*\])?` +
	`|rag_chunk(?:_[a-z0-9_]+)?(?:\s*\[[^\]]*\])?)`

var (
	leadingConnective      = regexp.MustCompile(`(?i)(根据|依据|按照|从|如)\s*` + internalLabel + `\s*(?:[，,、:：]\s*)?`)
	internalLabelPattern   = regexp.MustCompile(`(?i)` + internalLabel + `\s*(?:[，,、:：]\s*)?`)
	placeholderCitation    = regexp.MustCompile(`(?i)\[\s*n\s*\]`)
	spaceBeforePunctuation = regexp.MustCompile(`[ \t]+([,，.。;；:：!?！？、])`)
	repeatedSpaces         = regexp.MustCompile(`[ \t]{2,}`)
)

// Sanitize removes prompt-internal labels from the user-visible answer.
func Sanitize(answer string) string {
	if answer == "" {
		return answer
	}
	sanitized := leadingConnective.ReplaceAllString(answer, "$1 ")
	sanitized = internalLabelPattern.ReplaceAllString(sanitized, "")
	sanitized = placeholderCitation.ReplaceAllString(sanitized, "")
	sanitized = spaceBeforePunctuation.ReplaceAllString(sanitized, "$1")
	sanitized = repeatedSpaces.ReplaceAllString(sanitized, " ")
	return strings.TrimSpace(sanitized)
}
