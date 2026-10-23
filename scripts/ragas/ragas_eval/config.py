from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv

SCRIPT_DIR = Path(__file__).resolve().parent.parent
REPO_ROOT = SCRIPT_DIR.parent.parent
DATASET_PATH = SCRIPT_DIR / "dataset" / "ragas-dataset.json"
TARGETS_PATH = SCRIPT_DIR / "targets.json"
GOLDEN_SET_PATH = (
    REPO_ROOT
    / "finalAssignmentBackend"
    / "src"
    / "test"
    / "resources"
    / "rag-eval"
    / "golden-set.json"
)
ARTIFACTS_ROOT = REPO_ROOT / "artifacts" / "ragas"

SUITE = "ragas"
SOURCE_VERSION = "ragas-v1"
USER_CONTROL_SOURCE_ID = "ragas-user-control"
USER_CONTROL_TITLE = "评测用户控制文档"
USER_CONTROL_CONTENT = "本文档仅用于验证 USER ACL 正向可见性，不包含任何业务知识，不应出现在业务问题的检索上下文中。"
CONTEXT_TOKEN_BUDGET = 1200
DEFAULT_TOP_K = 5

METRIC_KEYS = (
    "faithfulness",
    "response_relevancy",
    "context_precision",
    "context_recall",
    "answer_correctness",
)


@dataclass(frozen=True)
class Settings:
    base_url: str
    driver_username: str
    driver_password: str
    admin_username: str
    admin_password: str
    judge_model: str
    judge_embedding_model: str
    answer_model: str
    product_embedding_model: str
    ollama_url: str
    es_url: str
    index_alias: str
    top_k: int


def load_settings(**overrides: object) -> Settings:
    load_dotenv(SCRIPT_DIR / ".env")
    values: dict[str, object] = {
        "base_url": os.getenv("RAGAS_BASE_URL", "http://localhost:9080").rstrip("/"),
        "driver_username": os.getenv("RAGAS_DRIVER_USERNAME", "ce@ce.com"),
        "driver_password": os.getenv("RAGAS_DRIVER_PASSWORD", "123456"),
        "admin_username": os.getenv("RAGAS_ADMIN_USERNAME", "superadmin"),
        "admin_password": os.getenv("RAGAS_ADMIN_PASSWORD", "SuperAdmin@123456"),
        "judge_model": os.getenv("RAGAS_JUDGE_MODEL", "qwen2.5:7b"),
        "judge_embedding_model": os.getenv("RAGAS_JUDGE_EMBEDDING_MODEL", "bge-m3"),
        "answer_model": os.getenv("RAGAS_ANSWER_MODEL", "llama3.2"),
        "product_embedding_model": os.getenv("RAGAS_PRODUCT_EMBEDDING_MODEL", "nomic-embed-text"),
        "ollama_url": os.getenv("RAGAS_OLLAMA_URL", "http://localhost:11434").rstrip("/"),
        "es_url": os.getenv("RAGAS_ES_URL", "http://localhost:9200").rstrip("/"),
        "index_alias": os.getenv("RAGAS_INDEX_ALIAS", "rag_chunk_current"),
        "top_k": _positive_int(os.getenv("RAGAS_TOP_K"), DEFAULT_TOP_K),
    }
    values.update({key: value for key, value in overrides.items() if value is not None})
    return Settings(**values)  # type: ignore[arg-type]


def _positive_int(raw: str | None, fallback: int) -> int:
    if raw is None or not raw.strip():
        return fallback
    try:
        return max(1, int(raw))
    except ValueError:
        return fallback
