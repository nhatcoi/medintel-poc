"""LLM chatbot — OpenAI-compatible API; agentic tool_calls + gợi ý tiếp (JSON)."""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from typing import Any

import httpx

from app.core.config import settings

ALLOWED_TOOLS = frozenset(
    {
        "log_dose",
        "upsert_medication",
        "append_care_note",
        "save_reminder_intent",
    }
)

SYSTEM_PROMPT = """Bạn là MedIntel Agent — chạy TRONG app theo dõi thuốc / tuân thủ. Dữ liệu thao tác được app LƯU CỤC BỘ trên máy (đồng bộ cloud làm sau).

Tư duy agent (quan trọng):
- KHÔNG chỉ “hướng dẫn” nếu người dùng đã nói rõ hành động — hãy GHI NHẬN bằng tool_calls để app lưu thật.
- Ví dụ: “tôi vừa uống metformin”, “nhớ là tôi bỏ liều sáng”, “thêm thuốc X 500mg sau ăn” → dùng tool tương ứng.
- reply: tiếng Việt, RẤT NGẮN (1–3 câu): xác nhận đã làm gì + lưu ý y tế ngắn nếu cần (không thay bác sĩ).

Công cụ (tool_calls), mỗi phần tử: {"tool":"<tên>","args":{...}}

1) log_dose — ghi nhận một liều
   args: medication_name (string, bắt buộc), status: "taken" | "missed" | "skipped", note (tùy chọn), recorded_at (ISO8601 tùy chọn; bỏ trống = app dùng giờ hiện tại)

2) upsert_medication — thêm/cập nhật một dòng thuốc trong danh sách cục bộ
   args: name (bắt buộc), dosage_label (tùy), schedule_hint (tùy, ví dụ "sau ăn sáng")

3) append_care_note — ghi chú nhanh (nhật ký)
   args: text (bắt buộc)

4) save_reminder_intent — ý định nhắc (chỉ lưu nháp cục bộ; báo thức thật app xử lý sau)
   args: title (bắt buộc), detail (tùy)

Nếu không có thao tác lưu nào phù hợp, để tool_calls: [].

Chỉ trả về MỘT object JSON (không markdown, không ```):
{"reply":"...","tool_calls":[...],"suggested_actions":[{"label":"...","prompt":"..."}]}

suggested_actions: 0–4 chip gợi ý câu tiếp theo (có thể rỗng)."""


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


def _normalize_actions(raw: object) -> list[dict[str, str]]:
    if not isinstance(raw, list):
        return []
    out: list[dict[str, str]] = []
    for item in raw[:5]:
        if not isinstance(item, dict):
            continue
        label = str(item.get("label") or item.get("title") or "").strip()
        prompt = str(item.get("prompt") or item.get("query") or item.get("message") or label).strip()
        if not label:
            continue
        out.append(
            {
                "label": label[:80],
                "prompt": (prompt or label)[:800],
            }
        )
    return out


def _normalize_tool_calls(raw: object) -> list[dict[str, Any]]:
    if not isinstance(raw, list):
        return []
    out: list[dict[str, Any]] = []
    for item in raw[:12]:
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


async def reply(user_message: str) -> ChatTurnResult:
    payload = {
        "model": settings.llm_model,
        "stream": False,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
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
        actions = _normalize_actions(parsed.get("suggested_actions"))
        tools = _normalize_tool_calls(parsed.get("tool_calls"))
        if reply_body:
            return ChatTurnResult(
                reply=reply_body,
                suggested_actions=actions,
                tool_calls=tools,
            )

    return ChatTurnResult(reply=text, suggested_actions=[], tool_calls=[])
