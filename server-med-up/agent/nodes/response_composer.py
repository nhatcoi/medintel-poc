"""Node 7: Compose final response -- format reply, disclaimer, citations.

`suggested_actions` đã được `action_planner` sinh trước đó; node này chỉ forward
và ghép thêm disclaimer/citations.
"""

from __future__ import annotations

import json

from agent.prompts.safety_templates import DISCLAIMER
from agent.state import PatientState


def _friendly_rewrite(reply: str, state: PatientState) -> str:
    text = (reply or "").strip()
    if not text:
        text = "Mình sẵn sàng hỗ trợ bạn quản lý thuốc và lịch uống."

    lower = text.lower()
    hard_negative = (
        "không thể tìm thấy" in lower
        or "khong the tim thay" in lower
        or "không tìm thấy" in lower
        or "xin lỗi bạn, mình không thể" in lower
    )
    if not hard_negative:
        return text

    intent = (state.get("current_intent") or "").strip().lower()
    meds = state.get("medications") or []
    has_meds = bool(meds)

    if intent == "check_med_schedule" and not has_meds:
        return (
            "Hiện tại bạn chưa có lịch uống hoặc dữ liệu tuân thủ nào trong hồ sơ. "
            "Mình có thể giúp bạn thêm thuốc và thiết lập giờ uống ngay bây giờ. "
            "Bạn muốn bắt đầu từ tủ thuốc hay quét đơn thuốc?"
        )

    return (
        "Hiện tại mình chưa có đủ dữ liệu để trả lời thật chính xác. "
        "Bạn có thể cung cấp thêm thông tin (thuốc đang dùng, giờ uống, hoặc triệu chứng) "
        "để mình hỗ trợ chi tiết hơn được không?"
    )


def _enforce_tool_truth(reply: str, state: PatientState) -> str:
    text = (reply or "").strip()
    low = text.lower()
    claims_added = (
        "đã thêm" in low
        or "da them" in low
        or "đã lưu" in low
        or "da luu" in low
    )
    if not claims_added:
        return text

    tool_results = state.get("tool_results") or []
    has_upsert_ok = False
    for tr in tool_results:
        if tr.get("tool") != "upsert_medication":
            continue
        result = tr.get("result")
        if not isinstance(result, str):
            continue
        try:
            parsed = json.loads(result)
            if isinstance(parsed, dict) and parsed.get("status") == "ok":
                has_upsert_ok = True
                break
        except Exception:
            if "thanh cong" in result.lower():
                has_upsert_ok = True
                break
    if has_upsert_ok:
        return text

    return (
        "Mình chưa ghi thuốc vào dữ liệu của bạn ở lượt này. "
        "Nếu bạn muốn, mình sẽ thêm thuốc vào tủ ngay bây giờ khi bạn xác nhận tên thuốc và liều."
    )


async def response_composer(state: PatientState) -> dict:
    reply = state.get("reply", "")
    risk = state.get("risk_level", "low")
    pending = state.get("pending_write_action") or {}
    if pending and pending.get("tool"):
        action = pending.get("tool", "hành động")
        reply = (
            f"Để an toàn dữ liệu, mình cần bạn xác nhận trước khi thực hiện `{action}`. "
            "Bạn trả lời 'xác nhận' để mình thực hiện, hoặc 'hủy' để bỏ qua nhé."
        )
    reply = _friendly_rewrite(reply, state)
    reply = _enforce_tool_truth(reply, state)

    if risk == "high" and "bac si" not in reply.lower():
        reply += f"\n\n⚠️ {DISCLAIMER}\nHay lien he bac si hoac co so y te gan nhat ngay."

    rag_results = state.get("rag_results", [])
    source_type = "internal" if rag_results else "model"

    citations = [
        {
            "title": f"{r.get('drug', '')} - {r.get('section', '')}",
            "url": None,
            "source_type": "internal",
        }
        for r in rag_results[:3]
    ]

    return {
        "reply": reply,
        "source_type": source_type,
        "citations": citations,
        "tool_calls": state.get("tool_calls") or [
            {"tool": tr.get("tool", ""), "args": {}}
            for tr in (state.get("tool_results") or [])
            if tr.get("tool")
        ],
        "suggested_actions": state.get("suggested_actions") or [],
    }
