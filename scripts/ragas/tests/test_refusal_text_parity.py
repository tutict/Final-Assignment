"""拒答文案的跨后端一致性守卫。

`ragas_eval.sse` 要按文本精确判断「这次回答是护栏拒答」。那两句话在五个地方各抄了一份：
Spring 单体、Spring Cloud、Quarkus、Go 的 guardrail、以及评测脚本自己。任何一处改了措辞，
评测就会把拒答当成正常答案记进 faithfulness，分数悄悄失真而没人报错。

所以这里直接读四份源码，逐字比对。只比常量本身，不解释语义。
"""

from __future__ import annotations

import re
from pathlib import Path

import pytest

from ragas_eval.sse import NO_SOURCE_ANSWER, UNCITED_ANSWER

ROOT = Path(__file__).resolve().parents[3]

# backend -> (文件, NO_SOURCE 常量名, UNCITED 常量名)
SOURCES: dict[str, tuple[Path, str, str]] = {
    "spring": (
        ROOT / "finalAssignmentBackend/src/main/java/com/tutict/finalassignmentbackend/ai/guardrail/AnswerGroundingPolicy.java",
        "NO_SOURCE_ANSWER",
        "UNCITED_ANSWER",
    ),
    "spring-cloud": (
        ROOT / "finalAssignmentCloud/finalassignmentcloud-ai/src/main/java/com/tutict/finalassignmentcloud/ai/guardrail/AnswerGroundingPolicy.java",
        "NO_SOURCE_ANSWER",
        "UNCITED_ANSWER",
    ),
    "quarkus": (
        ROOT / "final_assignment_backend_quarkus/src/main/java/finalassignmentbackend/ai/guardrail/AnswerGroundingPolicy.java",
        "NO_SOURCE_ANSWER",
        "UNCITED_ANSWER",
    ),
    "go": (
        ROOT / "final_assignment_backend_go/project/internal/ai/guardrail/policy.go",
        "NoSourceAnswer",
        "UncitedAnswer",
    ),
}


def _extract(source: Path, name: str) -> str:
    text = source.read_text(encoding="utf-8")
    pattern = re.compile(rf'\b{name}\b\s*=\s*"([^"]*)"')
    matches = pattern.findall(text)
    assert len(matches) == 1, f"{source} 里 {name} 的字符串常量应当恰好出现一次，实际 {len(matches)} 次"
    return matches[0]


@pytest.mark.parametrize("backend", sorted(SOURCES))
def test_refusal_texts_match_the_evaluator(backend: str) -> None:
    source, no_source_name, uncited_name = SOURCES[backend]
    assert source.is_file(), f"找不到 {backend} 的源文件 {source}"

    assert _extract(source, no_source_name) == NO_SOURCE_ANSWER, (
        f"{backend} 的 {no_source_name} 与 ragas_eval.sse.NO_SOURCE_ANSWER 不一致；"
        "改文案必须同时改评测脚本，否则拒答会被当成答案计分"
    )
    assert _extract(source, uncited_name) == UNCITED_ANSWER, (
        f"{backend} 的 {uncited_name} 与 ragas_eval.sse.UNCITED_ANSWER 不一致"
    )
