"""Node 7: Compose final response -- format reply, add safety disclaimer if needed."""

from __future__ import annotations

from agent.prompts.safety_templates import DISCLAIMER
from agent.state import PatientState


def _fallback_actions(state: PatientState) -> list[dict]:
    intent = (state.get("current_intent") or "").lower()
    meds = state.get("medications") or []
    tool_calls = state.get("tool_calls") or []

    if tool_calls:
        return [
            {"label": "Xem lại kết quả vừa lưu", "prompt": "Tóm tắt lại các thay đổi vừa thực hiện", "category": "follow_up"},
            {"label": "Nhắc tôi liều kế tiếp", "prompt": "Liều kế tiếp của tôi là khi nào?", "category": "adherence"},
        ]

    if "symptom" in intent or "side_effect" in intent:
        return [
            {"label": "Đánh giá mức độ triệu chứng", "prompt": "Hãy giúp tôi đánh giá mức độ nghiêm trọng của triệu chứng này", "category": "triage"},
            {"label": "Khi nào cần đi khám", "prompt": "Trường hợp nào tôi cần đi khám ngay?", "category": "safety"},
        ]

    if "medication" in intent or meds:
        return [
            {"label": "Liều kế tiếp", "prompt": "Liều kế tiếp hôm nay của tôi là gì?", "category": "adherence"},
            {"label": "Báo đã uống thuốc", "prompt": "Tôi vừa uống thuốc, hãy ghi nhận giúp tôi", "category": "log_dose"},
            {"label": "Xem tuân thủ 7 ngày", "prompt": "Tình hình tuân thủ thuốc 7 ngày gần đây của tôi thế nào?", "category": "adherence"},
        ]

    return [
        {"label": "Tóm tắt ngắn", "prompt": "Tóm tắt ngắn gọn câu trả lời trên thành 3 ý", "category": "summary"},
        {"label": "Kế hoạch hôm nay", "prompt": "Gợi ý kế hoạch theo dõi thuốc cho hôm nay", "category": "planning"},
    ]


async def response_composer(state: PatientState) -> dict:
    reply = state.get("reply", "")
    risk = state.get("risk_level", "low")

    if risk == "high" and "bac si" not in reply.lower():
        reply += f"\n\n⚠️ {DISCLAIMER}\nHay lien he bac si hoac co so y te gan nhat ngay."

    source_type = "model"
    rag_results = state.get("rag_results", [])
    if rag_results:
        source_type = "internal"

    citations = []
    for r in rag_results[:3]:
        citations.append({
            "title": f"{r.get('drug', '')} - {r.get('section', '')}",
            "url": None,
            "source_type": "internal",
        })

    suggested_actions = state.get("suggested_actions") or []
    if not suggested_actions:
        suggested_actions = _fallback_actions(state)

    return {
        "reply": reply,
        "source_type": source_type,
        "citations": citations,
        "suggested_actions": suggested_actions,
    }
