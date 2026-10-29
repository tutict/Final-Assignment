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

func eventStream(events ...aisvc.AiChatStreamEvent) <-chan aisvc.AiChatStreamEvent {
	ch := make(chan aisvc.AiChatStreamEvent, len(events))
	for _, event := range events {
		ch <- event
	}
	close(ch)
	return ch
}

func collectEvents(ch <-chan aisvc.AiChatStreamEvent) []aisvc.AiChatStreamEvent {
	var events []aisvc.AiChatStreamEvent
	for event := range ch {
		events = append(events, event)
	}
	return events
}

func providerToken(text string) aisvc.AiChatStreamEvent {
	token := text
	return aisvc.AiChatStreamEvent{Type: aisvc.ChatStreamEventTypeToken, SessionKey: "s1", Token: &token}
}

func providerDone() aisvc.AiChatStreamEvent {
	return aisvc.AiChatStreamEvent{Type: aisvc.ChatStreamEventTypeDone, SessionKey: "s1"}
}

func answerOf(events []aisvc.AiChatStreamEvent) string {
	var builder strings.Builder
	for _, event := range events {
		if event.Type == aisvc.ChatStreamEventTypeToken && event.Token != nil {
			builder.WriteString(*event.Token)
		}
	}
	return builder.String()
}

func tokenCount(events []aisvc.AiChatStreamEvent) int {
	count := 0
	for _, event := range events {
		if event.Type == aisvc.ChatStreamEventTypeToken {
			count++
		}
	}
	return count
}

func TestStageRefusesUncitedAnswer(t *testing.T) {
	stage := &Stage{Policy: CitationPolicy{EnforcementEnabled: true}}
	out := stage.Wrap(
		context.Background(),
		eventStream(providerToken("这个问题我直接回答。"), providerDone()),
		"车辆报废怎么办",
		knowledgeSource("车辆过户流程"),
		"msg-1",
		nil,
	)

	events := collectEvents(out)
	if got := answerOf(events); got != UncitedAnswer {
		t.Fatalf("answer = %q, want uncited refusal", got)
	}
	if tokenCount(events) != 1 {
		t.Fatalf("token events = %d, want 1", tokenCount(events))
	}
	if events[len(events)-1].Type != aisvc.ChatStreamEventTypeDone {
		t.Fatalf("last event = %s, want done", events[len(events)-1].Type)
	}
	for _, event := range events {
		if event.MessageID != "msg-1" {
			t.Fatalf("messageId = %q, want msg-1", event.MessageID)
		}
	}
}

func TestStageReplaysCitedAnswer(t *testing.T) {
	stage := &Stage{Policy: CitationPolicy{EnforcementEnabled: true}}
	out := stage.Wrap(
		context.Background(),
		eventStream(providerToken("罚款需在十五日内缴纳 [1]。"), providerDone()),
		"罚款怎么缴",
		knowledgeSource("罚款应在十五日内缴纳"),
		"msg-2",
		nil,
	)

	events := collectEvents(out)
	if got := answerOf(events); got != "罚款需在十五日内缴纳 [1]。" {
		t.Fatalf("answer = %q", got)
	}
}

func TestStageRepairsOnceThenAllows(t *testing.T) {
	repairs := 0
	repair := func(context.Context) (<-chan aisvc.AiChatStreamEvent, error) {
		repairs++
		return eventStream(providerToken("罚款需在十五日内缴纳 [1]。"), providerDone()), nil
	}
	stage := &Stage{Policy: CitationPolicy{EnforcementEnabled: true}}
	out := stage.Wrap(
		context.Background(),
		eventStream(providerToken("没有引用的草稿。"), providerDone()),
		"罚款怎么缴",
		knowledgeSource("罚款应在十五日内缴纳"),
		"msg-3",
		repair,
	)

	events := collectEvents(out)
	if repairs != 1 {
		t.Fatalf("repairs = %d, want 1", repairs)
	}
	if got := answerOf(events); got != "罚款需在十五日内缴纳 [1]。" {
		t.Fatalf("answer = %q", got)
	}
}

func TestStageRepairsOnceThenRefuses(t *testing.T) {
	repairs := 0
	repair := func(context.Context) (<-chan aisvc.AiChatStreamEvent, error) {
		repairs++
		return eventStream(providerToken("仍然没有引用。"), providerDone()), nil
	}
	stage := &Stage{Policy: CitationPolicy{EnforcementEnabled: true}}
	out := stage.Wrap(
		context.Background(),
		eventStream(providerToken("没有引用的草稿。"), providerDone()),
		"罚款怎么缴",
		knowledgeSource("罚款应在十五日内缴纳"),
		"msg-4",
		repair,
	)

	events := collectEvents(out)
	if repairs != 1 {
		t.Fatalf("repairs = %d, want 1", repairs)
	}
	if got := answerOf(events); got != UncitedAnswer {
		t.Fatalf("answer = %q, want uncited refusal", got)
	}
}

func TestStagePassesErrorsThrough(t *testing.T) {
	stage := &Stage{Policy: CitationPolicy{EnforcementEnabled: true}}
	out := stage.Wrap(
		context.Background(),
		eventStream(
			providerToken("部分回答"),
			aisvc.AiChatStreamEvent{Type: aisvc.ChatStreamEventTypeError, SessionKey: "s1", Payload: "upstream failed"},
		),
		"罚款怎么缴",
		knowledgeSource("罚款应在十五日内缴纳"),
		"msg-5",
		nil,
	)

	events := collectEvents(out)
	if len(events) != 1 || events[0].Type != aisvc.ChatStreamEventTypeError {
		t.Fatalf("events = %+v, want a single error event", events)
	}
}

func TestStageGroundsTheAnswerAfterAControlEvent(t *testing.T) {
	token := "这是工具卡片前的说明。"
	stage := &Stage{Policy: CitationPolicy{EnforcementEnabled: true}}
	out := stage.Wrap(
		context.Background(),
		eventStream(
			aisvc.AiChatStreamEvent{Type: "draft", SessionKey: "s1", Payload: map[string]any{"id": "d1"}},
			aisvc.AiChatStreamEvent{Type: aisvc.ChatStreamEventTypeToken, SessionKey: "s1", Token: &token},
			providerDone(),
		),
		"罚款怎么缴",
		knowledgeSource("罚款应在十五日内缴纳"),
		"msg-6",
		nil,
	)

	events := collectEvents(out)
	if events[0].Type != "draft" {
		t.Fatalf("first event = %s, want draft passthrough", events[0].Type)
	}
	// The text after the control event is the answer segment; it must not skip the guardrail.
	if got := answerOf(events); got != UncitedAnswer {
		t.Fatalf("answer = %q, want the uncited refusal", got)
	}
}

func TestStageFlushesTheSegmentBeforeAControlEvent(t *testing.T) {
	stage := &Stage{Policy: CitationPolicy{EnforcementEnabled: true}}
	in := make(chan aisvc.AiChatStreamEvent)
	out := stage.Wrap(
		context.Background(),
		in,
		"罚款怎么缴",
		knowledgeSource("罚款应在十五日内缴纳"),
		"msg-11",
		nil,
	)

	token := "工具卡片之前的说明。"
	in <- aisvc.AiChatStreamEvent{Type: aisvc.ChatStreamEventTypeToken, SessionKey: "s1", Token: &token}
	in <- aisvc.AiChatStreamEvent{Type: "draft", SessionKey: "s1"}

	first := <-out
	if first.Type != aisvc.ChatStreamEventTypeToken || first.Token == nil || *first.Token != token {
		t.Fatalf("first event = %+v, want the buffered text", first)
	}
	second := <-out
	if second.Type != "draft" {
		t.Fatalf("second event = %s, want the control event", second.Type)
	}
	close(in)

	events := collectEvents(out)
	if last := events[len(events)-1]; last.Type != aisvc.ChatStreamEventTypeDone {
		t.Fatalf("last event = %s, want done", last.Type)
	}
}

func TestStageVerifierCanRefuse(t *testing.T) {
	fake := &fakeCompleter{response: `{"topic_in_sources":false,"reason":"资料讲的是过户"}`}
	stage := &Stage{
		Policy:   CitationPolicy{EnforcementEnabled: true},
		Verifier: NewVerifier(fake, true, "qwen2.5:7b", time.Second),
	}
	out := stage.Wrap(
		context.Background(),
		eventStream(providerToken("车辆报废流程如下 [1]。"), providerDone()),
		"车辆报废怎么办",
		knowledgeSource("车辆过户流程"),
		"msg-7",
		nil,
	)

	events := collectEvents(out)
	if got := answerOf(events); got != NoSourceAnswer {
		t.Fatalf("answer = %q, want no-source refusal", got)
	}
}

func TestStageVerifierFailsOpen(t *testing.T) {
	fake := &fakeCompleter{err: errors.New("judge unavailable")}
	stage := &Stage{
		Policy:   CitationPolicy{EnforcementEnabled: true},
		Verifier: NewVerifier(fake, true, "qwen2.5:7b", time.Second),
	}
	out := stage.Wrap(
		context.Background(),
		eventStream(providerToken("罚款需在十五日内缴纳 [1]。"), providerDone()),
		"罚款怎么缴",
		knowledgeSource("罚款应在十五日内缴纳"),
		"msg-8",
		nil,
	)

	events := collectEvents(out)
	if got := answerOf(events); got != "罚款需在十五日内缴纳 [1]。" {
		t.Fatalf("answer = %q", got)
	}
}

func TestStageReplacesSanitizedAnswer(t *testing.T) {
	stage := &Stage{Policy: CitationPolicy{EnforcementEnabled: false}}
	out := stage.Wrap(
		context.Background(),
		eventStream(providerToken("根据 retrieved_context，罚款需在十五日内缴纳 [1]。"), providerDone()),
		"罚款怎么缴",
		knowledgeSource("罚款应在十五日内缴纳"),
		"msg-9",
		nil,
	)

	events := collectEvents(out)
	if got := answerOf(events); got != "根据 罚款需在十五日内缴纳 [1]。" {
		t.Fatalf("answer = %q", got)
	}
	if tokenCount(events) != 1 {
		t.Fatalf("token events = %d, want 1 replacement", tokenCount(events))
	}
}

func TestStageRefusesWhenRetrievalHasNoSources(t *testing.T) {
	stage := &Stage{Policy: CitationPolicy{EnforcementEnabled: true}}
	out := stage.Wrap(
		context.Background(),
		eventStream(providerToken("直接回答。"), providerDone()),
		"罚款怎么缴",
		nil,
		"msg-10",
		nil,
	)

	events := collectEvents(out)
	if got := answerOf(events); got != NoSourceAnswer {
		t.Fatalf("answer = %q, want no-source refusal", got)
	}
}

var _ = ragsvc.RagRetrievalResult{}
