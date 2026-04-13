"""Node 4: Core LLM reasoning -- builds prompt from state, calls LLM with tool binding."""

from __future__ import annotations

import logging

from langchain_core.messages import AIMessage, SystemMessage
from langchain_openai import ChatOpenAI

from agent.prompts.system import build_system_prompt
from agent.prompts.intent_templates import get_intent_snippet
from agent.state import PatientState
from agent.tools import ALL_TOOLS
from core.config import settings

_log = logging.getLogger("medintel.agent")


def _build_context_block(state: PatientState) -> str:
    parts: list[str] = []

    meds = state.get("medications", [])
    if meds:
        lines = ["### Tu thuoc hien tai"]
        for m in meds:
            lines.append(f"- {m['name']}: {m.get('dosage', '')} / {m.get('frequency', '')}")
        parts.append("\n".join(lines))

    memory = state.get("memory", {})
    if memory:
        lines = ["### Bo nho dai han"]
        for k, v in memory.items():
            lines.append(f"- {k}: {v}")
        parts.append("\n".join(lines))

    rag = state.get("retrieved_context", "")
    if rag:
        parts.append(f"### Tri thuc thuoc (RAG)\n{rag}")

    intent = state.get("current_intent", "")
    snippet = get_intent_snippet(intent)
    if snippet:
        parts.append(f"### Huong dan xu ly intent: {intent}\n{snippet}")

    return "\n\n".join(parts)


async def reasoning(state: PatientState) -> dict:
    system = build_system_prompt()
    context = _build_context_block(state)
    if context:
        system = f"{system}\n\n{context}"

    llm = ChatOpenAI(
        base_url=settings.llm_base_url,
        api_key=settings.llm_api_key,
        model=settings.llm_model,
        temperature=settings.llm_temperature,
        max_tokens=min(settings.llm_max_tokens, settings.agent_reply_max_tokens),
        timeout=settings.llm_timeout_seconds,
        max_retries=settings.llm_max_retries,
    )
    llm_with_tools = llm.bind_tools(ALL_TOOLS)

    messages = [SystemMessage(content=system)] + list(state.get("messages", []))
    response: AIMessage = await llm_with_tools.ainvoke(messages)

    tool_calls_raw = []
    if response.tool_calls:
        for tc in response.tool_calls:
            tool_calls_raw.append({
                "tool": tc["name"],
                "args": tc.get("args", {}),
                "id": tc.get("id", ""),
            })
    if settings.agent_trace_log:
        _log.info(
            "AGENT_REASONING intent=%s tool_calls=%s reply=%s",
            state.get("current_intent", ""),
            [tc.get("tool") for tc in tool_calls_raw],
            (response.content or "")[: settings.agent_trace_max_chars],
        )

    return {
        "messages": [response],
        "reply": response.content or "",
        "tool_calls": tool_calls_raw,
        "confidence": 0.7 if tool_calls_raw else 0.5,
    }
