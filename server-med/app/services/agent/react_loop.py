"""ReAct loop đơn giản: Thought → Act (internal tool) → Observation → Final reply.

Thiết kế:
- Các *internal tool* (read-only) được thực thi TRÊN SERVER trước khi LLM sinh reply.
- Các *write tool* (log_dose, upsert_medication, …) vẫn do client (app) thực thi và
  được LLM phát ra trong `tool_calls` ở output JSON cuối.
- Giữ vòng lặp nhỏ (max 2 bước) để latency chấp nhận được.

Internal tools:
- search_drug_kb(query): RAG search pgvector
- recall_patient_memory(key): đọc long-term memory theo khóa chuẩn
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass, field
from typing import Any

from sqlalchemy.orm import Session

from ai.agent2.tavily_client import build_external_context, search as tavily_search
from ai.chatbot import reply as llm_reply
from ai.chatbot.llm_client import ChatTurnResult
from ai.rag.retrieval import RagResult, build_rag_context, hybrid_search
from app.core.config import settings
from app.services.memory.long_term import (
    CANONICAL_KEYS,
    build_memory_context_block,
    get_all_memory,
)
from app.services.memory.short_term import load_recent_turns

MAX_REACT_STEPS = 3


@dataclass
class ReactTrace:
    """Dấu vết các bước ReAct — dùng cho debug/monitoring."""

    observations: list[dict[str, Any]] = field(default_factory=list)
    steps: int = 0
    rag_hit_count: int = 0
    tavily_hit_count: int = 0
    tavily_urls: list[str] = field(default_factory=list)

    def add(self, tool: str, args: dict[str, Any], result: str) -> None:
        self.observations.append({"tool": tool, "args": args, "result": result})
        self.steps += 1


# ---------- Internal tools ----------

async def _tool_search_drug_kb(
    db: Session, query: str
) -> tuple[str, list[RagResult]]:
    """RAG search — trả về (context markdown, raw results)."""
    query = (query or "").strip()
    if not query:
        return "(query rỗng)", []
    try:
        results = await hybrid_search(db, query)
    except Exception as exc:  # noqa: BLE001
        return f"(lỗi RAG: {exc})", []
    if not results:
        return "(không tìm thấy tri thức nội bộ liên quan)", []
    return build_rag_context(results), results


async def _tool_external_search(query: str) -> tuple[str, int, list[str]]:
    """Agent 2: Tavily search — chỉ gọi khi RAG nội bộ không đủ.

    Returns:
        (context_block, hit_count, urls)
    """
    query = (query or "").strip()
    if not query:
        return "(query rỗng)", 0, []
    result = await tavily_search(query)
    block = build_external_context(result)
    if not block:
        return "(external search rỗng hoặc chưa cấu hình Tavily)", 0, []
    urls = [h.url for h in result.hits if (h.url or "").startswith(("http://", "https://"))]
    return block, len(result.hits), urls


def _rag_is_confident(results: list[RagResult]) -> bool:
    """RAG đủ tin cậy khi có >= 3 chunk VÀ top similarity > ngưỡng."""
    if not results:
        return False
    if len(results) < 3:
        return False
    top_sim = max((r.similarity or 0.0) for r in results)
    return top_sim >= settings.rag_min_similarity


def _tool_recall_patient_memory(
    db: Session, profile_id: uuid.UUID | None, key: str | None = None
) -> str:
    if profile_id is None:
        return "(không có profile_id)"
    memory = get_all_memory(db, profile_id)
    if key:
        if key not in memory:
            return f"(không có khóa `{key}`)"
        return f"{key}: {memory[key]}"
    block = build_memory_context_block(memory)
    return block or "(bộ nhớ dài hạn trống)"


# ---------- Context gatherer (Act phase được "pre-plan") ----------

async def gather_observations(
    db: Session,
    *,
    profile_id: uuid.UUID | None,
    user_text: str,
) -> tuple[list[str], ReactTrace]:
    """Chạy các internal tool read-only trước khi gọi LLM.

    Đây là biến thể pre-planned của ReAct: thay vì để LLM quyết định từng bước,
    server chủ động gom các observation có ích nhất (RAG + memory) trong 1 lượt.
    Đổi sang iterative ReAct đầy đủ sau mà không phải viết lại chat_service.
    """
    trace = ReactTrace()
    blocks: list[str] = []

    # 1. Long-term memory
    if profile_id is not None:
        mem_result = _tool_recall_patient_memory(db, profile_id)
        trace.add("recall_patient_memory", {"profile_id": str(profile_id)}, mem_result)
        if mem_result and not mem_result.startswith("("):
            blocks.append(mem_result)

    # 2. RAG search (Agent 1 — internal KB)
    rag_block, rag_results = await _tool_search_drug_kb(db, user_text)
    trace.add("search_drug_kb", {"query": user_text}, rag_block)
    trace.rag_hit_count = len(rag_results)
    if rag_block and not rag_block.startswith("("):
        blocks.append(rag_block)

    # 3. Agent 2 fallback: chỉ gọi khi RAG nội bộ không đủ tin cậy
    if settings.tavily_enabled and settings.tavily_api_key and not _rag_is_confident(rag_results):
        ext_block, tavily_hits, tavily_urls = await _tool_external_search(user_text)
        trace.add("external_search", {"query": user_text}, ext_block)
        trace.tavily_hit_count = tavily_hits
        trace.tavily_urls = tavily_urls
        if ext_block and not ext_block.startswith("("):
            blocks.append(ext_block)

    return blocks, trace


# ---------- Entry point ----------

async def run_react_turn(
    db: Session,
    *,
    profile_id: uuid.UUID | None,
    session_id: uuid.UUID | None,
    user_text: str,
    base_context: str | None = None,
    history_limit: int = 10,
) -> tuple[ChatTurnResult, ReactTrace]:
    """Chạy một lượt ReAct: gather observations → gọi LLM với history → trả kết quả."""
    # Gather observations (long-term memory + RAG)
    obs_blocks, trace = await gather_observations(
        db, profile_id=profile_id, user_text=user_text
    )

    # Ghép context: base (medication) + observations
    context_parts: list[str] = []
    if base_context and base_context.strip():
        context_parts.append(base_context.strip())
    context_parts.extend(obs_blocks)
    if CANONICAL_KEYS:
        context_parts.append(
            "### Hướng dẫn dùng bộ nhớ\n"
            f"Khi cần cập nhật bộ nhớ dài hạn, chỉ dùng các khóa: {', '.join(CANONICAL_KEYS)}."
        )
    merged_context = "\n\n".join(p for p in context_parts if p) or None

    # Short-term memory: lấy history từ session nếu có
    history: list[dict[str, str]] = []
    if session_id is not None:
        try:
            history = load_recent_turns(db, session_id, limit=history_limit)
        except Exception:  # noqa: BLE001
            history = []

    # Gọi LLM với history + merged_context
    turn = await llm_reply(
        user_text,
        extra_context=merged_context,
        history=history,
    )
    return turn, trace
