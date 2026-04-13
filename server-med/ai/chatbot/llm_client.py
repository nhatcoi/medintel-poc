"""Gọi LLM OpenAI-compatible và parse JSON MedIntel (reply + tool_calls + suggested_actions)."""

from __future__ import annotations

import asyncio
import json
import logging
import re
from dataclasses import dataclass, field
from typing import Any

import httpx

from ai.chatbot.prompts import build_system_prompt
from app.core.config import settings
from app.core.llm_openai_compat import apply_max_output_tokens
from app.services.agent.tool_validation import normalize_suggested_actions, normalize_tool_calls

_log = logging.getLogger("medintel.llm_client")

_llm_http_client: httpx.AsyncClient | None = None


def _llm_http() -> httpx.AsyncClient:
    """Một client giữ kết nối — tránh TLS + TCP handshake mỗi lượt chat."""
    global _llm_http_client
    if _llm_http_client is None:
        _llm_http_client = httpx.AsyncClient(
            timeout=httpx.Timeout(60.0, connect=15.0),
            limits=httpx.Limits(max_keepalive_connections=8, max_connections=16),
        )
    return _llm_http_client


async def close_llm_http_client() -> None:
    global _llm_http_client
    if _llm_http_client is not None:
        await _llm_http_client.aclose()
        _llm_http_client = None


@dataclass
class ChatTurnResult:
    reply: str
    source_type: str = "model"
    confidence: float = 0.4
    citations: list[dict[str, str | None]] = field(default_factory=list)
    suggested_actions: list[dict[str, str]] = field(default_factory=list)
    tool_calls: list[dict[str, Any]] = field(default_factory=list)


def _strip_code_fence(text: str) -> str:
    t = text.strip()
    m = re.match(r"^```(?:json)?\s*\n?(.*?)\n?```\s*$", t, re.DOTALL | re.IGNORECASE)
    if m:
        return m.group(1).strip()
    return t


def _parse_llm_json(content: str) -> dict | None:
    raw = _strip_code_fence(content)
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        return None
    return data if isinstance(data, dict) else None


def _extract_embedded_json_object(text: str) -> dict | None:
    """Khi model chèn lời thoại trước JSON (vi phạm 'chỉ JSON'), trích object `{...}` đầu tiên đủ lớn."""
    raw = text.strip()
    start = raw.find("{")
    end = raw.rfind("}")
    if start < 0 or end <= start:
        return None
    chunk = raw[start : end + 1]
    try:
        data = json.loads(chunk)
    except json.JSONDecodeError:
        return None
    return data if isinstance(data, dict) else None


def _parse_medintel_payload(text: str) -> dict | None:
    """Parse toàn chuỗi hoặc JSON nhúng sau văn bản."""
    return _parse_llm_json(text) or _extract_embedded_json_object(text)


def _normalize_source_type(raw: object) -> str:
    val = str(raw or "").strip().lower()
    if val in {"internal", "external", "mixed", "model"}:
        return val
    return "model"


def _normalize_confidence(raw: object, *, default: float = 0.4) -> float:
    try:
        c = float(raw)
    except (TypeError, ValueError):
        c = default
    if c < 0:
        return 0.0
    if c > 1:
        return 1.0
    return c


def _normalize_citations(raw: object, *, max_items: int = 6) -> list[dict[str, str | None]]:
    if not isinstance(raw, list):
        return []
    out: list[dict[str, str | None]] = []
    for item in raw[:max_items]:
        if not isinstance(item, dict):
            continue
        title = str(item.get("title") or item.get("name") or "").strip()
        if not title:
            continue
        url_raw = item.get("url")
        url = str(url_raw).strip() if url_raw is not None else None
        if url == "":
            url = None
        s_type = _normalize_source_type(item.get("source_type"))
        out.append({"title": title[:200], "url": url, "source_type": s_type})
    return out


async def reply(
    user_message: str,
    *,
    extra_context: str | None = None,
    history: list[dict[str, str]] | None = None,
) -> ChatTurnResult:
    """Gọi LLM với system prompt + history (short-term memory) + user message mới."""
    system = build_system_prompt(extra_context=extra_context)
    messages: list[dict[str, str]] = [{"role": "system", "content": system}]
    if history:
        for turn in history:
            role = turn.get("role")
            content = (turn.get("content") or "").strip()
            if role in ("user", "assistant") and content:
                messages.append({"role": role, "content": content})
    messages.append({"role": "user", "content": user_message})

    payload: dict[str, object] = {
        "model": settings.llm_model,
        "stream": False,
        "messages": messages,
    }
    apply_max_output_tokens(
        payload,
        base_url=settings.llm_base_url,
        limit=settings.llm_max_tokens,
    )

    client = _llm_http()
    max_retries = 3
    resp = None
    for attempt in range(max_retries):
        resp = await client.post(
            settings.llm_base_url,
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {settings.llm_api_key}",
            },
            json=payload,
        )
        if resp.status_code != 429:
            break
        retry_after = float(resp.headers.get("retry-after", 2 ** (attempt + 1)))
        retry_after = min(retry_after, 30.0)
        _log.warning("LLM 429 rate-limited, retry %d/%d in %.1fs", attempt + 1, max_retries, retry_after)
        await asyncio.sleep(retry_after)
    assert resp is not None
    resp.raise_for_status()
    data = resp.json()

    choices = data.get("choices", [])
    if not choices:
        return ChatTurnResult(
            reply="Xin lỗi, tôi không thể xử lý yêu cầu này. Vui lòng thử lại.",
        )

    content = choices[0].get("message", {}) or {}
    text = (content.get("content") or "").strip()
    if not text:
        return ChatTurnResult(reply="Không có phản hồi từ AI.")

    parsed = _parse_medintel_payload(text)
    if parsed is not None:
        reply_body = str(parsed.get("reply", "")).strip()
        if not reply_body and "{" in text:
            prefix = text[: text.find("{")].strip()
            if prefix:
                reply_body = prefix
        source_type = _normalize_source_type(parsed.get("source_type"))
        confidence = _normalize_confidence(parsed.get("confidence"), default=0.4)
        citations = _normalize_citations(parsed.get("citations"))
        actions = normalize_suggested_actions(parsed.get("suggested_actions"))
        tools = normalize_tool_calls(parsed.get("tool_calls"))
        if reply_body or actions or tools:
            return ChatTurnResult(
                reply=reply_body or "Đã xử lý.",
                source_type=source_type,
                confidence=confidence,
                citations=citations,
                suggested_actions=actions,
                tool_calls=tools,
            )

    return ChatTurnResult(
        reply=text,
        source_type="model",
        confidence=0.3,
        citations=[{"title": "Model prior knowledge", "url": None, "source_type": "model"}],
        suggested_actions=[],
        tool_calls=[],
    )
