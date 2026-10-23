from __future__ import annotations

import pytest

from ragas_eval import seed


class FakeClient:
    def __init__(self, pages: list[dict[str, int]]) -> None:
        self._pages = iter(pages)
        self.calls: list[tuple[str, list[str]]] = []

    def es_source_counts(self, index: str, source_ids: list[str]) -> dict[str, int]:
        self.calls.append((index, list(source_ids)))
        return next(self._pages)


def test_wait_for_index_visibility_returns_once_every_source_id_is_searchable() -> None:
    client = FakeClient([{"a": 1, "b": 0}, {"a": 1, "b": 1}])

    seed.wait_for_index_visibility(
        client,
        "rag_chunk_current",
        ["a", "b"],
        timeout_seconds=1,
        poll_seconds=0,
    )

    assert client.calls == [
        ("rag_chunk_current", ["a", "b"]),
        ("rag_chunk_current", ["a", "b"]),
    ]


def test_wait_for_index_visibility_fails_with_missing_source_ids(monkeypatch: pytest.MonkeyPatch) -> None:
    client = FakeClient([{"a": 1, "b": 0}])
    clock = iter([0.0, 0.0, 2.0])
    monkeypatch.setattr(seed.time, "monotonic", lambda: next(clock))
    monkeypatch.setattr(seed.time, "sleep", lambda _: None)

    with pytest.raises(RuntimeError, match=r"\['b'\]"):
        seed.wait_for_index_visibility(
            client,
            "rag_chunk_current",
            ["a", "b"],
            timeout_seconds=1,
            poll_seconds=0,
        )
