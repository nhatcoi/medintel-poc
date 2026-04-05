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


async def reply(user_message: str, *, extra_context: str | None = None) -> ChatTurnResult:
    system = build_system_prompt(extra_context=extra_context)
    payload = {
        "model": settings.llm_model,
        "stream": False,
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": user_message},
        ],
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
        actions = normalize_suggested_actions(parsed.get("suggested_actions"))
        tools = normalize_tool_calls(parsed.get("tool_calls"))
        if reply_body:
            return ChatTurnResult(
                reply=reply_body,
                suggested_actions=actions,
                tool_calls=tools,
            )

    return ChatTurnResult(reply=text, suggested_actions=[], tool_calls=[])
