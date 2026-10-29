"""评测口径的默认值必须与线上一致，否则测出来的不是线上配置下的质量。"""

from __future__ import annotations

from ragas_eval.config import DEFAULT_TOP_K


def test_default_top_k_matches_the_backend_chat_default() -> None:
    # 四个后端交互式聊天的 chat_top_k 也是 10（见 scripts/check-rag-config-parity.py）。
    # 这里写死 10 是有意的：改默认值必须同时改这条断言，逼人确认历史基线怎么处理。
    assert DEFAULT_TOP_K == 10
