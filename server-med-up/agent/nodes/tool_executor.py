"""Node 5: Execute tool calls and feed results back into state."""

from __future__ import annotations

import logging

from langchain_core.messages import ToolMessage

from agent.state import PatientState
from agent.tools import TOOL_MAP
from core.config import settings

_log = logging.getLogger("medintel.agent")


async def tool_executor(state: PatientState) -> dict:
    tool_calls = state.get("tool_calls", [])
    if not tool_calls:
        return {"tool_results": []}

    results = []
    messages = []
    for tc in tool_calls:
        tool_name = tc.get("tool", "")
        args = tc.get("args", {})
        tool_id = tc.get("id", tool_name)

        tool_fn = TOOL_MAP.get(tool_name)
        if tool_fn is None:
            results.append({"tool": tool_name, "error": "unknown tool"})
            continue

        try:
            output = await tool_fn.ainvoke(args)
            results.append({"tool": tool_name, "result": str(output)})
            messages.append(ToolMessage(content=str(output), tool_call_id=tool_id))
            if settings.agent_trace_log:
                _log.info(
                    "AGENT_TOOL tool=%s args=%s result=%s",
                    tool_name,
                    str(args)[: settings.agent_trace_max_chars],
                    str(output)[: settings.agent_trace_max_chars],
                )
        except Exception as e:
            results.append({"tool": tool_name, "error": str(e)})
            messages.append(ToolMessage(content=f"Error: {e}", tool_call_id=tool_id))
            if settings.agent_trace_log:
                _log.warning(
                    "AGENT_TOOL_ERROR tool=%s args=%s error=%s",
                    tool_name,
                    str(args)[: settings.agent_trace_max_chars],
                    str(e)[: settings.agent_trace_max_chars],
                )

    return {
        "tool_results": results,
        "messages": messages,
    }
