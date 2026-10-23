from __future__ import annotations

import json

from ragas_eval.sse import (
    NO_SOURCE_ANSWER,
    UNCITED_ANSWER,
    citation_compliant,
    is_abstention,
    parse_chat_events,
    parse_citations,
    parse_sse,
)


def sse(event: str, payload: dict) -> str:
    return f"event:{event}\ndata:{json.dumps(payload, ensure_ascii=False)}\n\n"


def test_tokens_are_concatenated_until_done() -> None:
    raw = (
        sse("session", {"type": "session", "sessionKey": "s1"})
        + sse("token", {"type": "token", "token": "罚款"})
        + ": keepalive\n\n"
        + sse("token", {"type": "token", "token": "十五日内缴纳[1]。"})
        + sse("done", {"type": "done"})
        + sse("token", {"type": "token", "token": "ignored"})
    )
    parsed = parse_chat_events(parse_sse(raw))
    assert parsed.answer == "罚款十五日内缴纳[1]。"
    assert parsed.done is True
    assert parsed.error is None
    assert parsed.event_types[:2] == ["session", "token"]


def test_error_event_stops_and_is_reported() -> None:
    raw = (
        sse("token", {"type": "token", "token": "部分"})
        + sse("error", {"type": "error", "payload": {"message": "model offline"}})
        + sse("token", {"type": "token", "token": "never"})
    )
    parsed = parse_chat_events(parse_sse(raw))
    assert parsed.answer == "部分"
    assert parsed.error == "model offline"
    assert parsed.done is False


def test_fallback_and_non_rag_events_are_detected() -> None:
    raw = (
        sse("token", {"type": "token", "token": "AI 暂时不可用", "payload": {"isFallback": True}})
        + sse("queue", {"type": "queue", "payload": {"position": 1}})
        + sse("tool", {"type": "tool", "payload": {"name": "find_offense"}})
        + sse("done", {"type": "done"})
    )
    parsed = parse_chat_events(parse_sse(raw))
    assert parsed.fallback is True
    assert parsed.non_rag_events == ["queue", "tool"]


def test_citations_accept_half_width_full_width_and_grouped_forms() -> None:
    answer = "甲[1]，乙【2】，丙[1,3]，丁[2，4]，戊[1, 5]。"
    assert parse_citations(answer) == [1, 2, 3, 4, 5]
    assert citation_compliant(answer, 5)
    assert not citation_compliant("没有任何引用", 5)
    assert not citation_compliant("[6]", 5)
    assert not citation_compliant("[6,7]", 5)


def test_guardrail_refusals_are_recognized() -> None:
    assert parse_chat_events(parse_sse(sse("token", {"type": "token", "token": NO_SOURCE_ANSWER}))).guardrail_refusal == "no_source"
    assert parse_chat_events(parse_sse(sse("token", {"type": "token", "token": UNCITED_ANSWER}))).guardrail_refusal == "uncited"
    assert parse_chat_events(parse_sse(sse("token", {"type": "token", "token": "正常回答[1]"}))).guardrail_refusal is None


def test_abstention_markers() -> None:
    assert is_abstention(NO_SOURCE_ANSWER)
    assert is_abstention("知识库资料不足，无法回答该问题。")
    assert is_abstention("现有资料未涵盖这一情形。")
    assert not is_abstention("罚款需在十五日内缴纳[1]。")


def test_multiline_data_is_joined() -> None:
    raw = 'event:token\ndata:{"type":"token",\ndata: "token":"你好"}\n\n'
    parsed = parse_chat_events(parse_sse(raw))
    assert parsed.answer == "你好"
