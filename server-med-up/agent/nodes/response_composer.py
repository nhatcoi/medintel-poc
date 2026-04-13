"""Node 7: Compose final response -- format reply, add safety disclaimer if needed."""

from __future__ import annotations

from agent.prompts.safety_templates import DISCLAIMER
from agent.state import PatientState


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

    return {
        "reply": reply,
        "source_type": source_type,
        "citations": citations,
    }
