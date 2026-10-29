package guardrail

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"strconv"
	"strings"
	"time"

	aisvc "final_assignment_backend_go/project/internal/service/ai"
	ragsvc "final_assignment_backend_go/project/internal/service/rag"
)

// Mirrors the calibrated Spring prompt: judge the subject only, not completeness or correctness.
const topicPromptTemplate = `你在审核知识库问答系统的一次回答，只判断主题是否对得上，不评价答案是否完整或正确。

第一步：问题问的是哪个具体业务或对象？
第二步：<资料> 中是否有哪一段就是在讲这个业务或对象？如果所有段落讲的都是其他业务，即使内容相关、措辞接近，也判 false。
第三步：<回答> 是否在讲这个业务？如果回答换成了资料中另一类业务，判 false。
问题涉及多个事项时，只要资料覆盖其中至少一个事项且回答围绕该事项，就判 true。

资料：
%s
问题：%s
回答：%s

输出 JSON：{"topic_in_sources":true或false,"reason":"不超过20字"}`

var verdictSchema = map[string]any{
	"type": "object",
	"properties": map[string]any{
		"topic_in_sources": map[string]any{"type": "boolean"},
		"reason":           map[string]any{"type": "string"},
	},
	"required": []string{"topic_in_sources", "reason"},
}

// Verifier answers one question after the citation guardrail: is the retrieved material about
// the subject the user asked? It fails open — timeout, provider failure or unparseable output
// must never turn into a refusal.
type Verifier struct {
	completer aisvc.IsolatedCompleter
	enabled   bool
	model     string
	timeout   time.Duration
}

func NewVerifier(
	completer aisvc.IsolatedCompleter,
	enabled bool,
	model string,
	timeout time.Duration,
) *Verifier {
	trimmedModel := strings.TrimSpace(model)
	effective := enabled && trimmedModel != "" && completer != nil
	if enabled && trimmedModel == "" {
		log.Printf("[WARNING] Topic verification stays off: configure AI_GUARDRAIL_TOPIC_MODEL " +
			"with a judge model to enable it")
	}
	if timeout <= 0 {
		timeout = 12 * time.Second
	}
	return &Verifier{
		completer: completer,
		enabled:   effective,
		model:     trimmedModel,
		timeout:   timeout,
	}
}

func (v *Verifier) Enabled() bool {
	return v.enabled
}

func (v *Verifier) Verify(
	ctx context.Context,
	question string,
	answer string,
	sources []ragsvc.RagRetrievalResult,
) Decision {
	if !v.shouldVerify(question, answer, sources) {
		return Allowed(answer)
	}
	prompt := buildTopicPrompt(question, answer, sources)
	options := aisvc.VerificationOptions(v.timeout, v.model, verdictSchema)
	response, err := v.completer.Complete(ctx, prompt, options)
	if err != nil {
		log.Printf("[INFO] Topic verification skipped: %v", err)
		return Allowed(answer)
	}
	verdict := parseVerdict(response)
	if verdict != nil && !*verdict {
		log.Printf("[INFO] Topic verification refused an answer: sources do not cover the asked subject")
		return Refused(NoSourceAnswer, "topic_mismatch")
	}
	return Allowed(answer)
}

func (v *Verifier) shouldVerify(question, answer string, sources []ragsvc.RagRetrievalResult) bool {
	if !v.enabled || strings.TrimSpace(question) == "" || strings.TrimSpace(answer) == "" {
		return false
	}
	if len(sources) == 0 {
		return false
	}
	if answer == NoSourceAnswer || answer == UncitedAnswer {
		return false
	}
	hasUsableSource := false
	for _, source := range sources {
		// Web snippets are live search results, not curated knowledge; the calibrated prompt
		// was built for knowledge-base passages.
		if strings.EqualFold(source.SourceType, "WEB_SEARCH") {
			return false
		}
		hasUsableSource = hasUsableSource || strings.TrimSpace(source.Content) != ""
	}
	return hasUsableSource
}

func buildTopicPrompt(question, answer string, sources []ragsvc.RagRetrievalResult) string {
	var contextText strings.Builder
	index := 1
	for _, source := range sources {
		content := strings.TrimSpace(source.Content)
		if content == "" {
			continue
		}
		if contextText.Len() > 0 {
			contextText.WriteByte('\n')
		}
		contextText.WriteString("[")
		contextText.WriteString(strconv.Itoa(index))
		contextText.WriteString("] ")
		contextText.WriteString(content)
		index++
	}
	return fmt.Sprintf(topicPromptTemplate, contextText.String(), strings.TrimSpace(question), strings.TrimSpace(answer))
}

func parseVerdict(rawResponse string) *bool {
	if strings.TrimSpace(rawResponse) == "" {
		return nil
	}
	node := readVerdictObject(rawResponse)
	if node == nil {
		return nil
	}
	value, ok := node["topic_in_sources"]
	if !ok {
		return nil
	}
	switch typed := value.(type) {
	case bool:
		result := typed
		return &result
	case string:
		switch strings.ToLower(strings.TrimSpace(typed)) {
		case "true":
			allowed := true
			return &allowed
		case "false":
			refused := false
			return &refused
		}
	}
	return nil
}

// readVerdictObject returns the JSON object that carries the verdict.
//
// A judge that is not constrained to structured output answers with prose around the object, so
// slicing from the first brace to the last one loses the verdict. Every balanced object is read
// instead and the last one that carries topic_in_sources wins: a model that first drafts a
// verdict and then revises it has stated its final opinion last.
func readVerdictObject(rawResponse string) map[string]any {
	trimmed := strings.TrimSpace(rawResponse)
	if trimmed == "" {
		return nil
	}
	var direct map[string]any
	if err := json.Unmarshal([]byte(trimmed), &direct); err == nil && direct != nil {
		if _, ok := direct["topic_in_sources"]; ok {
			return direct
		}
	}
	var verdict map[string]any
	for _, candidate := range jsonObjects(rawResponse) {
		var node map[string]any
		if err := json.Unmarshal([]byte(candidate), &node); err != nil || node == nil {
			continue
		}
		if _, ok := node["topic_in_sources"]; ok {
			verdict = node
		}
	}
	return verdict
}

// jsonObjects returns every balanced {...} block in the raw text, ignoring braces inside strings.
func jsonObjects(raw string) []string {
	var objects []string
	for index := 0; index < len(raw); index++ {
		if raw[index] != '{' {
			continue
		}
		depth := 0
		inString := false
		escaped := false
		for end := index; end < len(raw); end++ {
			character := raw[end]
			switch {
			case escaped:
				escaped = false
			case character == '\\' && inString:
				escaped = true
			case character == '"':
				inString = !inString
			case inString:
			case character == '{':
				depth++
			case character == '}':
				depth--
				if depth == 0 {
					objects = append(objects, raw[index:end+1])
					index = end
					end = len(raw)
				}
			}
		}
	}
	return objects
}
