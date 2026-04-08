"""Gọi LLM OpenAI-compatible và parse JSON MedIntel (reply + tool_calls + suggested_actions)."""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from typing import Any

import httpx

from ai.chatbot.prompts import build_system_prompt
from app.core.config import settings
from app.services.agent.tool_validation import normalize_suggested_actions, normalize_tool_calls


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

    payload = {
        "model": settings.llm_model,
        "stream": False,
        "messages": messages,
    }

    async with httpx.AsyncClient(timeout=60) as client:
        resp = await client.post(
            settings.llm_base_url,
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {settings.llm_api_key}",
            },
            json=payload,
        )
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

    parsed = _parse_llm_json(text)
    if parsed is not None:
        reply_body = str(parsed.get("reply", "")).strip()
        source_type = _normalize_source_type(parsed.get("source_type"))
        confidence = _normalize_confidence(parsed.get("confidence"), default=0.4)
        citations = _normalize_citations(parsed.get("citations"))
        actions = normalize_suggested_actions(parsed.get("suggested_actions"))
        tools = normalize_tool_calls(parsed.get("tool_calls"))
        if reply_body:
            return ChatTurnResult(
                reply=reply_body,
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
