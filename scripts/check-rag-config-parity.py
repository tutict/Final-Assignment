#!/usr/bin/env python3
"""四个后端的 RAG 检索配置一致性检查。

只读静态配置，不启动任何服务。任何一项偏离期望值、或两个后端共用同一个索引名，
都以非零退出码结束；这样 CI 能直接挡住配置漂移。

允许的差异只有两类，都在 ALLOWED_SKIPS 里显式写明：
  * 部署开关（enabled）随环境变化；
  * gozero-rag-live 是 deterministic-384 的压测档，只豁免 provider/model/dimensions。
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

GO = "final_assignment_backend_go/project/etc/gozero-api.yaml"
GO_LIVE = "final_assignment_backend_go/project/etc/gozero-rag-live.yaml"
QUARKUS = "final_assignment_backend_quarkus/src/main/resources/application.yaml"
SPRING = "finalAssignmentBackend/src/main/resources/application.yml"
CLOUD_AI = "finalAssignmentCloud/finalassignmentcloud-ai/src/main/resources/application.yml"
CLOUD_RAG = "finalAssignmentCloud/finalassignmentcloud-rag/src/main/resources/application.yml"
GO_CHAT_PIPELINE = "final_assignment_backend_go/project/internal/ai/chat_pipeline.go"

EXPECTED = {
    "provider": "ollama",
    "model": "nomic-embed-text",
    "dimensions": 768,
    "vector_weight": 0.2,
    "bm25_weight": 0.8,
    "min_score": 0.2,
    "candidate_multiplier": 3,
    "rrf_rank_constant": 60,
    "rerank_lexical_weight": 0.15,
    "rerank_enabled": True,
    # 交互式聊天的默认上下文条数（请求带 metadata.ragTopK 时以请求为准）。三个后端的
    # 配置项各不相同（Spring 复用 rag.retrieval.top-k，Cloud/Quarkus 用 ai.rag.top-k，
    # Go 是代码里的 defaultTopK），取值不同会让同一个问题在不同后端看到不同深度的资料。
    # RAGAS 评测每轮显式传 ragTopK，不走这里，所以别拿评测分数当这个值的证据。
    "chat_top_k": 10,
}

# (backend, field) -> 跳过校验。live 档故意使用 deterministic 嵌入做压测。
ALLOWED_SKIPS = {
    ("go_live", "provider"),
    ("go_live", "model"),
    ("go_live", "dimensions"),
}

_ENV_DEFAULT = re.compile(r"^\$\{[^:}]+:([^}]*)\}$")


def scalar(raw: str):
    value = raw.strip()
    if value.startswith("${") and value.endswith("}"):
        match = _ENV_DEFAULT.match(value)
        if match:
            value = match.group(1).strip()
    value = value.strip().strip("'\"")
    if value.lower() in ("true", "false"):
        return value.lower() == "true"
    for cast in (int, float):
        try:
            return cast(value)
        except ValueError:
            continue
    return value


def parse_yaml(path: Path) -> dict:
    """解析这几个配置文件用到的 YAML 子集：嵌套映射、标量、注释、列表。"""
    root: dict = {}
    stack: list[tuple[int, dict]] = [(-1, root)]
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.rstrip()
        stripped = line.lstrip()
        if not stripped or stripped.startswith("#") or stripped.startswith("- "):
            continue
        if ":" not in stripped:
            continue
        indent = len(line) - len(stripped)
        key, _, value = stripped.partition(":")
        key = key.strip()
        value = value.split(" #", 1)[0].strip()
        while stack and indent <= stack[-1][0]:
            stack.pop()
        parent = stack[-1][1]
        if not value:
            node: dict = {}
            parent[key] = node
            stack.append((indent, node))
        else:
            parent[key] = scalar(value)
    return root


def pick(config: dict, path: str):
    node = config
    for key in path.split("."):
        if not isinstance(node, dict) or key not in node:
            return None
        node = node[key]
    return node


# backend -> (file, field -> config path)
BACKENDS: dict[str, tuple[str, dict[str, str]]] = {
    "go": (GO, {
        "provider": "Rag.EmbeddingProvider",
        "model": "Rag.EmbeddingModel",
        "dimensions": "Rag.EmbeddingDimensions",
        "vector_weight": "Rag.VectorWeight",
        "bm25_weight": "Rag.BM25Weight",
        "min_score": "Rag.MinScore",
        "candidate_multiplier": "Rag.CandidateMultiplier",
        "rrf_rank_constant": "Rag.RRFRankConstant",
        "rerank_lexical_weight": "Rag.RerankLexicalWeight",
        "rerank_enabled": "Rag.RerankEnabled",
        "index": "Rag.ElasticsearchIndex",
        "alias": "Rag.ElasticsearchAlias",
    }),
    "go_live": (GO_LIVE, {
        "provider": "Rag.EmbeddingProvider",
        "model": "Rag.EmbeddingModel",
        "dimensions": "Rag.EmbeddingDimensions",
        "vector_weight": "Rag.VectorWeight",
        "bm25_weight": "Rag.BM25Weight",
        "min_score": "Rag.MinScore",
        "candidate_multiplier": "Rag.CandidateMultiplier",
        "rrf_rank_constant": "Rag.RRFRankConstant",
        "rerank_lexical_weight": "Rag.RerankLexicalWeight",
        "rerank_enabled": "Rag.RerankEnabled",
        "index": "Rag.ElasticsearchIndex",
        "alias": "Rag.ElasticsearchAlias",
    }),
    "quarkus": (QUARKUS, {
        "provider": "rag.embedding.provider",
        "model": "rag.embedding.model",
        "dimensions": "rag.embedding.dimensions",
        "vector_weight": "rag.retrieval.vector-weight",
        "bm25_weight": "rag.retrieval.bm25-weight",
        "min_score": "rag.retrieval.min-score",
        "candidate_multiplier": "rag.retrieval.candidate-multiplier",
        "rrf_rank_constant": "rag.retrieval.rrf-rank-constant",
        "rerank_lexical_weight": "rag.retrieval.rerank-lexical-weight",
        "rerank_enabled": "rag.retrieval.rerank-enabled",
        "index": "rag.index.name",
        "alias": "rag.index.alias",
        "chat_top_k": "ai.rag.top-k",
    }),
    "spring": (SPRING, {
        "provider": "rag.embedding.provider",
        "model": "rag.embedding.model",
        "dimensions": "rag.embedding.dimensions",
        "vector_weight": "rag.retrieval.vector-weight",
        "bm25_weight": "rag.retrieval.bm25-weight",
        "min_score": "rag.retrieval.min-score",
        "candidate_multiplier": "rag.retrieval.candidate-multiplier",
        "rrf_rank_constant": "rag.retrieval.rrf-rank-constant",
        "rerank_lexical_weight": "rag.retrieval.rerank-lexical-weight",
        "rerank_enabled": "rag.retrieval.rerank-enabled",
        "index": "rag.index.name",
        "alias": "rag.index.alias",
        # 聊天回合不带 topK 时，Spring 的 RagQueryService 回落到检索档的 top-k。
        "chat_top_k": "rag.retrieval.top-k",
    }),
    "cloud_rag": (CLOUD_RAG, {
        "provider": "rag.embedding.provider",
        "model": "rag.embedding.model",
        "dimensions": "rag.embedding.dimensions",
        "vector_weight": "rag.retrieval.vector-weight",
        "bm25_weight": "rag.retrieval.bm25-weight",
        "min_score": "rag.retrieval.min-score",
        "candidate_multiplier": "rag.retrieval.candidate-multiplier",
        "rrf_rank_constant": "rag.retrieval.rrf-rank-constant",
        "rerank_lexical_weight": "rag.retrieval.rerank-lexical-weight",
        "rerank_enabled": "rag.retrieval.rerank-enabled",
        "index": "rag.index.name",
        "alias": "rag.index.alias",
    }),
    "cloud_ai": (CLOUD_AI, {
        "chat_top_k": "ai.rag.top-k",
    }),
}


def go_chat_top_k() -> int | None:
    """Go 的聊天 topK 是代码里的常量，不在 yaml 里，只能读源码。"""
    path = ROOT / GO_CHAT_PIPELINE
    if not path.is_file():
        return None
    match = re.search(r"\bdefaultTopK\s*(?::=|=)\s*(\d+)", path.read_text(encoding="utf-8"))
    return int(match.group(1)) if match else None


def main() -> int:
    errors: list[str] = []
    rows: list[tuple[str, str, object]] = []
    index_owners: dict[object, list[str]] = {}
    alias_owners: dict[object, list[str]] = {}

    for backend, (relative, fields) in BACKENDS.items():
        path = ROOT / relative
        if not path.exists():
            errors.append(f"{backend}: 配置文件不存在 {relative}")
            continue
        config = parse_yaml(path)
        for field, config_path in fields.items():
            value = pick(config, config_path)
            if value is None:
                errors.append(f"{backend}: 缺少配置项 {config_path} ({relative})")
                continue
            rows.append((backend, field, value))
            if field == "index":
                index_owners.setdefault(value, []).append(backend)
            if field == "alias":
                alias_owners.setdefault(value, []).append(backend)
            if (backend, field) in ALLOWED_SKIPS:
                continue
            expected = EXPECTED.get(field)
            if expected is not None and value != expected:
                errors.append(
                    f"{backend}.{field} = {value!r}，期望 {expected!r}（{config_path}）"
                )

    for label, owners_by_name in (("index", index_owners), ("alias", alias_owners)):
        for name, owners in owners_by_name.items():
            if len(owners) > 1:
                errors.append(f"{label} 未隔离：{', '.join(owners)} 共用 {name!r}")

    go_top_k = go_chat_top_k()
    if go_top_k is None:
        errors.append(f"go: 读不到 {GO_CHAT_PIPELINE} 里的 defaultTopK")
    else:
        rows.append(("go", "chat_top_k", go_top_k))
        if go_top_k != EXPECTED["chat_top_k"]:
            errors.append(
                f"go.chat_top_k = {go_top_k!r}，期望 {EXPECTED['chat_top_k']}（{GO_CHAT_PIPELINE} 的 defaultTopK）"
            )

    chat_top_k = {backend: value for backend, field, value in rows if field == "chat_top_k"}

    width = max((len(backend) for backend, _, _ in rows), default=8)
    for backend, field, value in rows:
        print(f"{backend:<{width}}  {field:<24} {value!r}")
    if chat_top_k:
        print("\n聊天链路 topK（四端必须同档）：", chat_top_k)

    if errors:
        print("\n发现配置漂移：", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1
    print("\n四个后端的检索配置一致。")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
