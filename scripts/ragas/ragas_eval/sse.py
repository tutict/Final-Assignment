from __future__ import annotations

import json
import re
from dataclasses import dataclass, field

# Mirrors AnswerGroundingPolicy in the Spring backend. Keep in sync when the Java text changes.
NO_SOURCE_ANSWER = (
    "抱歉，当前知识库中没有可支撑该问题的资料，我无法给出有依据的回答。请补充更多信息或联系人工客服。"
)
UNCITED_ANSWER = "抱歉，我无法为该问题提供有可靠来源支撑的回答。"
ABSTENTION_MARKERS = (
    "知识库资料不足",
    "知识库中没有",
    "资料不足",
    "没有可支撑",
    "没有相关",
    "未涵盖",
    "无法给出有依据",
)

CITATION_PATTERN = re.compile(r"[\[【](\d{1,2}(?:\s*[,，]\s*\d{1,2})*)[\]】]")

NON_ANSWER_EVENT_TYPES = {"queue", "tool", "draft", "action", "result"}


@dataclass(frozen=True)
class SseEvent:
    event: str
    data: dict
    raw: str


@dataclass
class ChatParseResult:
    answer: str = ""
    event_types: list[str] = field(default_factory=list)
    error: str | None = None
    fallback: bool = False
    non_rag_events: list[str] = field(default_factory=list)
    done: bool = False

    @property
    def guardrail_refusal(self) -> str | None:
        normalized = self.answer.strip()
        if normalized == NO_SOURCE_ANSWER:
            return "no_source"
        if normalized == UNCITED_ANSWER:
            return "uncited"
        return None


def parse_sse(raw: str) -> list[SseEvent]:
    events: list[SseEvent] = []
    event_name: str | None = None
    data_lines: list[str] = []

    def flush() -> None:
        nonlocal event_name, data_lines
        if data_lines:
            payload = "\n".join(data_lines)
            try:
                data = json.loads(payload)
            except json.JSONDecodeError:
                data = {"raw": payload}
            if not isinstance(data, dict):
                data = {"value": data}
            events.append(SseEvent(event_name or str(data.get("type", "")), data, payload))
        event_name = None
        data_lines = []

    for line in raw.splitlines():
        if not line.strip():
            flush()
            continue
        if line.startswith(":"):
            continue
        if line.startswith("event:"):
            event_name = line[len("event:") :].strip()
        elif line.startswith("data:"):
            data_lines.append(line[len("data:") :].lstrip())
    flush()
    return events


def parse_chat_events(events: list[SseEvent]) -> ChatParseResult:
    result = ChatParseResult()
    for event in events:
        event_type = str(event.data.get("type") or event.event)
        if event_type:
            result.event_types.append(event_type)
        payload = event.data.get("payload")
        if isinstance(payload, dict) and payload.get("isFallback") is True:
            result.fallback = True
        if event_type == "token":
            token = event.data.get("token")
            if isinstance(token, str):
                result.answer += token
        elif event_type == "done":
            result.done = True
            break
        elif event_type == "error":
            message = ""
            if isinstance(payload, dict):
                message = str(payload.get("message") or "")
            result.error = message or "AI stream failed"
            break
        elif event_type in NON_ANSWER_EVENT_TYPES:
            result.non_rag_events.append(event_type)
    return result


def parse_citations(answer: str) -> list[int]:
    indices: set[int] = set()
    for match in CITATION_PATTERN.finditer(answer or ""):
        for part in re.split(r"[,，]", match.group(1)):
            digits = part.strip()
            if digits:
                indices.add(int(digits))
    return sorted(indices)


def citation_compliant(answer: str, source_count: int) -> bool:
    return any(1 <= index <= source_count for index in parse_citations(answer))


def is_abstention(answer: str) -> bool:
    normalized = (answer or "").strip()
    if not normalized:
        return False
    if normalized in (NO_SOURCE_ANSWER, UNCITED_ANSWER):
        return True
    return any(marker in normalized for marker in ABSTENTION_MARKERS)
