"""LLM fallback intent classifier -- called when rule-based returns None."""

from __future__ import annotations

from langchain_core.messages import HumanMessage, SystemMessage
from langchain_openai import ChatOpenAI

from agent.intents.definitions import Intent
from core.config import settings

_INTENT_LIST = ", ".join(i.value for i in Intent)

_SYSTEM = f"""You are an intent classifier for a medication adherence chatbot.
Given a patient message, return ONLY the intent name from this list:
{_INTENT_LIST}

Rules:
- Return exactly one intent name, nothing else.
- If unsure, return "unknown".
- Output ONLY the intent string, no explanation."""


async def classify_by_llm(text: str) -> tuple[Intent, float]:
    llm = ChatOpenAI(
        base_url=settings.llm_base_url,
        api_key=settings.llm_api_key,
        model=settings.llm_model,
        temperature=0,
        max_tokens=32,
    )
    resp = await llm.ainvoke([
        SystemMessage(content=_SYSTEM),
        HumanMessage(content=text),
    ])
    raw = (resp.content or "").strip().lower().replace('"', "").replace("'", "")
    try:
        return Intent(raw), 0.70
    except ValueError:
        return Intent.UNKNOWN, 0.30
