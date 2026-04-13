"""Chuẩn hoá tool_calls / suggested_actions từ JSON LLM — chỉ giữ tool trong whitelist."""

from __future__ import annotations

import json
from typing import Any

from app.services.agent.registry import ALLOWED_TOOLS

_ALLOWED_SUGGEST_CATEGORIES = frozenset({"app", "knowledge", "other"})


def normalize_suggested_actions(raw: object, *, max_items: int = 8) -> list[dict[str, str]]:
    """Giữ nguyên số lượng do LLM chọn (tối đa max_items); không đệm chip cứng."""
    if not isinstance(raw, list):
        return []
    out: list[dict[str, str]] = []
    for item in raw[:max_items]:
        if not isinstance(item, dict):
            continue
        label = str(item.get("label") or item.get("title") or "").strip()
        prompt = str(item.get("prompt") or item.get("query") or item.get("message") or label).strip()
        if not label:
            continue
        cat = str(item.get("category") or item.get("kind") or "other").strip().lower()
        if cat not in _ALLOWED_SUGGEST_CATEGORIES:
            cat = "other"
        out.append(
            {
                "label": label[:120],
                "prompt": (prompt or label)[:800],
                "category": cat,
            }
        )
    return out


def normalize_tool_calls(raw: object, *, max_items: int = 12) -> list[dict[str, Any]]:
    if not isinstance(raw, list):
        return []
    out: list[dict[str, Any]] = []
    for item in raw[:max_items]:
        if not isinstance(item, dict):
            continue
        tool = str(item.get("tool") or item.get("name") or "").strip()
        if tool not in ALLOWED_TOOLS:
            continue
        args = item.get("args") or item.get("arguments") or {}
        if isinstance(args, str):
            try:
                args = json.loads(args)
            except json.JSONDecodeError:
                args = {}
        if not isinstance(args, dict):
            args = {}
        out.append({"tool": tool, "args": dict(args)})
    return out


def validate_incoming_tool_calls(
    items: list[dict[str, Any]],
    *,
    max_items: int = 12,
) -> list[dict[str, Any]]:
    """API nhận tool_calls từ client — lọc tên tool và giới hạn số lượng."""
    return normalize_tool_calls(items, max_items=max_items)
