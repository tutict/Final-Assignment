package guardrail

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	aisvc "final_assignment_backend_go/project/internal/service/ai"
	ragsvc "final_assignment_backend_go/project/internal/service/rag"
)

type fakeCompleter struct {
	response    string
	err         error
	calls       int
	lastPrompt  string
	lastOptions aisvc.GenerationOptions
}

func (f *fakeCompleter) Complete(_ context.Context, prompt string, options aisvc.GenerationOptions) (string, error) {
	f.calls++
	f.lastPrompt = prompt
	f.lastOptions = options
	return f.response, f.err
}

func knowledgeSource(content string) []ragsvc.RagRetrievalResult {
	return []ragsvc.RagRetrievalResult{{
		Title:      "交通违法处理资料",
		Content:    content,
		SourceType: "MANUAL",
	}}
}

func TestVerifierRefusesExplicitTopicMismatch(t *testing.T) {
	fake := &fakeCompleter{response: `{"topic_in_sources":false,"reason":"资料讲的是过户"}`}
	verifier := NewVerifier(fake, true, "qwen2.5:7b", 12*time.Second)

	decision := verifier.Verify(context.Background(), "车辆报废怎么办", "带 [1] 的回答", knowledgeSource("车辆过户流程"))

	if decision.Grounded {
		t.Fatalf("expected refusal, got %+v", decision)
	}
	if decision.Answer != NoSourceAnswer || decision.Reason != "topic_mismatch" {
		t.Fatalf("decision = %+v", decision)
	}
}

func TestVerifierAllowsMatchingTopic(t *testing.T) {
	fake := &fakeCompleter{response: `{"topic_in_sources":true,"reason":"主题一致"}`}
	verifier := NewVerifier(fake, true, "qwen2.5:7b", 12*time.Second)

	decision := verifier.Verify(context.Background(), "罚款怎么缴", "带 [1] 的回答", knowledgeSource("罚款缴纳期限"))

	if !decision.Grounded || decision.Answer != "带 [1] 的回答" {
		t.Fatalf("decision = %+v", decision)
	}
}

func TestVerifierParsesLenientVerdicts(t *testing.T) {
	tests := []struct {
		name     string
		response string
		refused  bool
	}{
		{name: "fenced json", response: "```json\n{\"topic_in_sources\":false}\n```", refused: true},
		{name: "textual false", response: `{"topic_in_sources":"false"}`, refused: true},
		{name: "textual true", response: `{"topic_in_sources":"TRUE"}`},
		{name: "garbage", response: "无法判断"},
		{name: "missing field", response: `{"reason":"unknown"}`},
		{
			name: "prose around the verdict",
			response: " false\n\n资料中没有提到相关内容。 {\"topic_in_sources\":false,\"reason\":\"未提及\"}" +
				" 资料中没有相关内容。 {\"topic_in_sources\":false,\"reason\":\"无相关内容\"}",
			refused: true,
		},
		{
			name: "revised verdict wins",
			response: "{\"topic_in_sources\":false,\"reason\":\"草稿\"}\n\n重新判断如下：\n\n" +
				"{\"topic_in_sources\":true,\"reason\":\"主题一致\"}",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			fake := &fakeCompleter{response: tt.response}
			verifier := NewVerifier(fake, true, "qwen2.5:7b", time.Second)
			decision := verifier.Verify(context.Background(), "问题", "回答 [1]", knowledgeSource("资料"))
			if decision.Grounded == tt.refused {
				t.Fatalf("grounded = %v, want refused = %v", decision.Grounded, tt.refused)
			}
		})
	}
}

func TestVerifierFailsOpenOnError(t *testing.T) {
	fake := &fakeCompleter{err: errors.New("judge timeout")}
	verifier := NewVerifier(fake, true, "qwen2.5:7b", time.Second)

	decision := verifier.Verify(context.Background(), "问题", "回答 [1]", knowledgeSource("资料"))

	if !decision.Grounded || decision.Answer != "回答 [1]" {
		t.Fatalf("expected fail-open, got %+v", decision)
	}
}

func TestVerifierSkipsWhenDisabledOrUnusable(t *testing.T) {
	tests := []struct {
		name     string
		verifier func(*fakeCompleter) *Verifier
		question string
		answer   string
		sources  []ragsvc.RagRetrievalResult
	}{
		{
			name: "blank judge model disables verification",
			verifier: func(f *fakeCompleter) *Verifier {
				return NewVerifier(f, true, "  ", time.Second)
			},
			question: "问题",
			answer:   "回答 [1]",
			sources:  knowledgeSource("资料"),
		},
		{
			name: "web search sources are out of calibration",
			verifier: func(f *fakeCompleter) *Verifier {
				return NewVerifier(f, true, "qwen2.5:7b", time.Second)
			},
			question: "问题",
			answer:   "回答 [1]",
			sources:  []ragsvc.RagRetrievalResult{{SourceType: "WEB_SEARCH", Content: "网页摘要"}},
		},
		{
			name: "sources without content",
			verifier: func(f *fakeCompleter) *Verifier {
				return NewVerifier(f, true, "qwen2.5:7b", time.Second)
			},
			question: "问题",
			answer:   "回答 [1]",
			sources:  []ragsvc.RagRetrievalResult{{SourceType: "MANUAL", Content: "   "}},
		},
		{
			name: "canonical refusal is not re-judged",
			verifier: func(f *fakeCompleter) *Verifier {
				return NewVerifier(f, true, "qwen2.5:7b", time.Second)
			},
			question: "问题",
			answer:   NoSourceAnswer,
			sources:  knowledgeSource("资料"),
		},
		{
			name: "blank question",
			verifier: func(f *fakeCompleter) *Verifier {
				return NewVerifier(f, true, "qwen2.5:7b", time.Second)
			},
			question: "  ",
			answer:   "回答 [1]",
			sources:  knowledgeSource("资料"),
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			fake := &fakeCompleter{response: `{"topic_in_sources":false}`}
			verifier := tt.verifier(fake)
			decision := verifier.Verify(context.Background(), tt.question, tt.answer, tt.sources)
			if !decision.Grounded {
				t.Fatalf("expected skip/allow, got %+v", decision)
			}
			if fake.calls != 0 {
				t.Fatalf("judge was called %d times, want 0", fake.calls)
			}
		})
	}
}

func TestVerifierUsesJudgeProfileAndNumberedSources(t *testing.T) {
	fake := &fakeCompleter{response: `{"topic_in_sources":true}`}
	verifier := NewVerifier(fake, true, "qwen2.5:7b", 9*time.Second)

	sources := []ragsvc.RagRetrievalResult{
		{Content: "罚款应在十五日内缴纳"},
		{Content: "   "},
		{Content: "逾期加处罚款"},
	}
	verifier.Verify(context.Background(), "罚款怎么缴", "回答 [1]", sources)

	if fake.lastOptions.Model != "qwen2.5:7b" {
		t.Fatalf("model = %q", fake.lastOptions.Model)
	}
	if fake.lastOptions.Temperature == nil || *fake.lastOptions.Temperature != 0 {
		t.Fatalf("temperature = %v, want 0", fake.lastOptions.Temperature)
	}
	if fake.lastOptions.MaxTokens != 96 || fake.lastOptions.Timeout != 9*time.Second {
		t.Fatalf("options = %+v", fake.lastOptions)
	}
	if fake.lastOptions.ResponseFormat == nil {
		t.Fatal("response format missing")
	}
	for _, fragment := range []string{"[1] 罚款应在十五日内缴纳", "[2] 逾期加处罚款", "问题：罚款怎么缴", "回答：回答 [1]"} {
		if !strings.Contains(fake.lastPrompt, fragment) {
			t.Errorf("prompt missing %q:\n%s", fragment, fake.lastPrompt)
		}
	}
	if strings.Contains(fake.lastPrompt, "[3]") {
		t.Errorf("blank source should not consume a citation number:\n%s", fake.lastPrompt)
	}
}
