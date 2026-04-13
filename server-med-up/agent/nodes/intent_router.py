"""Node 1: Intent classification -- rule-based first, LLM fallback."""

from __future__ import annotations

import logging

from langchain_core.messages import HumanMessage

from agent.intents.definitions import Intent
from agent.intents.rules import classify_by_rules
from agent.intents.llm_classifier import classify_by_llm
from agent.state import PatientState
from core.config import settings

_log = logging.getLogger("medintel.agent")


async def intent_router(state: PatientState) -> dict:
    last_msg = ""
    for msg in reversed(state.get("messages", [])):
        if isinstance(msg, HumanMessage):
            last_msg = msg.content
            break

    result = classify_by_rules(last_msg)
    if result:
        intent, conf = result
        if settings.agent_trace_log:
            _log.info(
                "AGENT_INTENT source=rule intent=%s confidence=%.2f text=%s",
                intent.value,
                conf,
                last_msg[: settings.agent_trace_max_chars],
            )
    else:
        intent, conf = await classify_by_llm(last_msg)
        if settings.agent_trace_log:
            _log.info(
                "AGENT_INTENT source=llm intent=%s confidence=%.2f text=%s",
                intent.value,
                conf,
                last_msg[: settings.agent_trace_max_chars],
            )

    return {
        "current_intent": intent.value,
        "intent_confidence": conf,
    }
