"""Node 7: Compose final response -- format reply, disclaimer, citations.

`suggested_actions` đã được `action_planner` sinh trước đó; node này chỉ forward
và ghép thêm disclaimer/citations.
"""

from __future__ import annotations

from agent.prompts.safety_templates import DISCLAIMER
from agent.state import PatientState


async def response_composer(state: PatientState) -> dict:
    reply = state.get("reply", "")
    risk = state.get("risk_level", "low")

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
        "suggested_actions": state.get("suggested_actions") or [],
    }
