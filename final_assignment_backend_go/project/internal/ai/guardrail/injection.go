package guardrail

import (
	"regexp"
	"strings"
)

// NeutralizedMarker replaces the instruction-like spans found inside untrusted text.
const NeutralizedMarker = "[已过滤的指令性内容]"

type injectionRule struct {
	name    string
	pattern *regexp.Regexp
}

// The rules mirror the Spring PromptInjectionGuard: deterministic pattern matching instead of
// relying on the model to defend itself. Only the most common override patterns are covered.
var injectionRules = []injectionRule{
	{"override_instructions", regexp.MustCompile(`(?i)(ignore|disregard|forget)\s+(all\s+)?(the\s+)?(previous|prior|above|earlier|preceding)\s+(instructions?|prompts?|rules?|context)`)},
	{"override_instructions", regexp.MustCompile(`(忽略|无视|忘记|不要理会)(以上|上述|之前|前面|先前|所有|全部)(的)?(指令|要求|提示|内容|规则|上下文)`)},
	{"reveal_system_prompt", regexp.MustCompile(`(?i)(reveal|show|print|repeat|output|leak)\s+(me\s+)?(your\s+)?(system\s+)?(prompt|instructions?|rules?)`)},
	{"reveal_system_prompt", regexp.MustCompile(`(输出|打印|泄露|告诉我|重复|展示)(一下)?(你的)?(系统)?(提示词|提示|指令|规则|system\s*prompt)`)},
	{"role_hijack", regexp.MustCompile(`(?i)you\s+are\s+now\s+`)},
	{"role_hijack", regexp.MustCompile(`(现在你是|从现在开始你是|假装你是)`)},
	{"jailbreak", regexp.MustCompile(`(?i)(jailbreak|developer\s+mode|dan\s+mode)`)},
	{"jailbreak", regexp.MustCompile(`(越狱|开发者模式|上帝模式)`)},
}

// InjectionScan reports the instruction-like spans found in untrusted text.
type InjectionScan struct {
	Triggered bool
	Signals   []string
	Sanitized string
}

// ScanInjection neutralizes instruction-like spans in untrusted text so the model reads the
// passage as data instead of an order.
func ScanInjection(text string) InjectionScan {
	if strings.TrimSpace(text) == "" {
		return InjectionScan{Sanitized: text}
	}
	signals := []string{}
	sanitized := text
	for _, rule := range injectionRules {
		if !rule.pattern.MatchString(sanitized) {
			continue
		}
		signals = append(signals, rule.name)
		sanitized = rule.pattern.ReplaceAllLiteralString(sanitized, NeutralizedMarker)
	}
	return InjectionScan{Triggered: len(signals) > 0, Signals: signals, Sanitized: sanitized}
}

// SanitizeInjection returns the neutralized form of untrusted text.
func SanitizeInjection(text string) string {
	return ScanInjection(text).Sanitized
}
