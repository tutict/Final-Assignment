package guardrail

import (
	"context"
	"strings"
	"time"

	aisvc "final_assignment_backend_go/project/internal/service/ai"
	ragsvc "final_assignment_backend_go/project/internal/service/rag"
)

// RepairFunc starts one citation-repair attempt with a citation-focused prompt.
type RepairFunc func(ctx context.Context) (<-chan aisvc.AiChatStreamEvent, error)

// Stage buffers a pure-RAG answer, applies the citation guardrail and the topic verifier, and
// replays the stream. Non-token events pass through untouched: a refusal must never swallow a
// tool card, an action, or an infrastructure error.
type Stage struct {
	Policy   CitationPolicy
	Verifier *Verifier
}

func (s *Stage) Wrap(
	ctx context.Context,
	in <-chan aisvc.AiChatStreamEvent,
	question string,
	sources []ragsvc.RagRetrievalResult,
	messageID string,
	repair RepairFunc,
) <-chan aisvc.AiChatStreamEvent {
	out := make(chan aisvc.AiChatStreamEvent, 16)

	go func() {
		defer close(out)

		// segment 是「还没有被判定过的一段纯文本」。控制事件之前的文本立即放行，
		// 之后的文本重新开始累积：agent 回合即使先吐工具卡片，最后仍会有一段答案，
		// 那一段必须过引用与主题检查。
		var segment []aisvc.AiChatStreamEvent
		sessionKey := ""
		terminal := ""

		for event := range in {
			if sessionKey == "" && event.SessionKey != "" {
				sessionKey = event.SessionKey
			}
			switch event.Type {
			case aisvc.ChatStreamEventTypeToken:
				segment = append(segment, event)
			case aisvc.ChatStreamEventTypeDone:
				terminal = aisvc.ChatStreamEventTypeDone
			case aisvc.ChatStreamEventTypeError:
				terminal = aisvc.ChatStreamEventTypeError
				out <- stampEvent(event, messageID)
			default:
				// Structured control events pass through untouched, and the text that came
				// before them is flushed immediately so the stream never stalls behind a
				// pending grounding decision.
				for _, pending := range segment {
					out <- stampEvent(pending, messageID)
				}
				segment = nil
				out <- stampEvent(event, messageID)
			}
			if terminal != "" {
				break
			}
		}

		if terminal == aisvc.ChatStreamEventTypeError {
			return
		}

		answer := joinTokens(segment)
		sanitized := Sanitize(answer)
		decision := s.Policy.Evaluate(sanitized, sources)
		if answer != "" && sanitized == "" {
			decision = Refused(UncitedAnswer, "missing_citation")
		}

		if !decision.Grounded && repair != nil {
			if retryAnswer, retryEvents, err := runRepair(ctx, repair); err == nil && retryAnswer != "" {
				retrySanitized := Sanitize(retryAnswer)
				retryDecision := s.Policy.Evaluate(retrySanitized, sources)
				answer = retryAnswer
				sanitized = retrySanitized
				if retryDecision.Grounded {
					segment = retryEvents
					decision = retryDecision
				} else {
					decision = retryDecision
				}
			}
		}

		if decision.Grounded && s.Verifier != nil {
			// The citation guardrail proves the answer points at *some* source, not that the
			// source is about the asked subject. Verify asynchronously and fail open.
			decision = s.Verifier.Verify(ctx, question, sanitized, sources)
		}

		if !decision.Grounded {
			out <- tokenEvent(sessionKey, messageID, decision.Answer)
			out <- doneEvent(sessionKey, messageID)
			return
		}

		if sanitized == answer && len(segment) > 0 {
			for _, event := range segment {
				out <- stampEvent(event, messageID)
			}
		} else if sanitized != "" {
			out <- tokenEvent(sessionKey, messageID, sanitized)
		}
		out <- doneEvent(sessionKey, messageID)
	}()

	return out
}

func runRepair(ctx context.Context, repair RepairFunc) (string, []aisvc.AiChatStreamEvent, error) {
	retryEvents, err := repair(ctx)
	if err != nil {
		return "", nil, err
	}
	var builder strings.Builder
	var tokens []aisvc.AiChatStreamEvent
	for event := range retryEvents {
		switch event.Type {
		case aisvc.ChatStreamEventTypeToken:
			if event.Token != nil && *event.Token != "" {
				builder.WriteString(*event.Token)
				tokens = append(tokens, event)
			}
		case aisvc.ChatStreamEventTypeDone:
			return builder.String(), tokens, nil
		case aisvc.ChatStreamEventTypeError:
			return builder.String(), tokens, nil
		}
	}
	return builder.String(), tokens, nil
}

func joinTokens(events []aisvc.AiChatStreamEvent) string {
	var builder strings.Builder
	for _, event := range events {
		if event.Token != nil {
			builder.WriteString(*event.Token)
		}
	}
	return builder.String()
}

func stampEvent(event aisvc.AiChatStreamEvent, messageID string) aisvc.AiChatStreamEvent {
	if event.MessageID == "" {
		event.MessageID = messageID
	}
	return event
}

func tokenEvent(sessionKey, messageID, text string) aisvc.AiChatStreamEvent {
	token := text
	return aisvc.AiChatStreamEvent{
		Type:       aisvc.ChatStreamEventTypeToken,
		SessionKey: sessionKey,
		MessageID:  messageID,
		Token:      &token,
		Timestamp:  time.Now(),
	}
}

func doneEvent(sessionKey, messageID string) aisvc.AiChatStreamEvent {
	return aisvc.AiChatStreamEvent{
		Type:       aisvc.ChatStreamEventTypeDone,
		SessionKey: sessionKey,
		MessageID:  messageID,
		Timestamp:  time.Now(),
	}
}
