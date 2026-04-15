"""Node 5: Execute tool calls and feed results back into state."""

from __future__ import annotations

import json
import logging

from langchain_core.messages import HumanMessage
from langchain_core.messages import ToolMessage

from agent.planning.registry import capability_registry
from agent.state import PatientState
from agent.tools import TOOL_MAP
from core.config import settings

_log = logging.getLogger("medintel.agent")


def _write_tools() -> set[str]:
    registry = capability_registry()
    tools = registry.get("tools") or []
    return {str(t.get("name")) for t in tools if str(t.get("side_effect")) == "write"}


def _last_user_text(state: PatientState) -> str:
    for msg in reversed(state.get("messages") or []):
        if isinstance(msg, HumanMessage):
            return (msg.content or "").strip().lower()
    return ""


def _is_confirmed(state: PatientState) -> bool:
    txt = _last_user_text(state)
    if not txt:
        return False
    yes_words = ("xac nhan", "xác nhận", "dong y", "đồng ý", "ok", "oke", "duoc", "được", "thuc hien", "thực hiện")
    no_words = ("khong", "không", "huy", "hủy", "dung", "dừng", "thoi", "thôi")
    if any(w in txt for w in no_words):
        return False
    return any(w in txt for w in yes_words)


def _parse_tool_payload(raw_output: str) -> dict:
    try:
        data = json.loads(raw_output)
        if isinstance(data, dict):
            return data
    except Exception:
        pass
    return {"status": "ok", "summary": raw_output}


async def tool_executor(state: PatientState) -> dict:
    tool_calls = state.get("tool_calls", [])
    if not tool_calls:
        return {"tool_results": []}

    write_tools = _write_tools()
    pending = state.get("pending_write_action") or {}
    confirmed = bool(state.get("user_confirms_pending")) or _is_confirmed(state)
    results = []
    messages = []
    next_pending = pending if pending else None
    confirmation_status = ""
    for tc in tool_calls:
        tool_name = tc.get("tool", "")
        args = tc.get("args", {})
        if not isinstance(args, dict):
            args = {}
        # Normalize/inject profile_id for profile-scoped tools.
        profile_id = (state.get("profile_id") or "").strip()
        if tool_name in {"get_today_medications", "upsert_medication"}:
            if args.get("profile_id") in {"current_user", "me", "self", "", None} and profile_id:
                args["profile_id"] = profile_id
        if tool_name in {"log_dose", "med_list_cabinet", "profile_get_overview", "care_list_links", "habit_list_by_profile"}:
            if args.get("profile_id") in {"current_user", "me", "self", "", None} and profile_id:
                args["profile_id"] = profile_id
        tool_id = tc.get("id", tool_name)

        tool_fn = TOOL_MAP.get(tool_name)
        if tool_fn is None:
            results.append({"tool": tool_name, "error": "unknown tool"})
            continue

        is_write = tool_name in write_tools
        if is_write:
            if pending and pending.get("tool") == tool_name and confirmed:
                merged_args = dict(pending.get("args") or {})
                merged_args.update(args)
                args = merged_args
                next_pending = None
                pending = {}
                confirmation_status = "confirmed_and_executed"
            elif not confirmed:
                payload = {
                    "status": "confirm_required",
                    "code": "WRITE_CONFIRM_REQUIRED",
                    "summary": f"Hành động '{tool_name}' cần xác nhận trước khi ghi dữ liệu.",
                    "action": tool_name,
                    "proposed_args": args,
                }
                results.append({"tool": tool_name, "result": json.dumps(payload, ensure_ascii=False)})
                messages.append(ToolMessage(content=json.dumps(payload, ensure_ascii=False), tool_call_id=tool_id))
                next_pending = {"tool": tool_name, "args": args}
                confirmation_status = "pending_confirmation"
                continue
            elif pending and pending.get("tool") != tool_name:
                payload = {
                    "status": "confirm_required",
                    "code": "WRITE_CONFIRM_REQUIRED",
                    "summary": f"Bạn đang có hành động chờ xác nhận: {pending.get('tool')}. Hãy xác nhận hoặc hủy trước.",
                    "action": pending.get("tool"),
                    "proposed_args": pending.get("args") or {},
                }
                results.append({"tool": tool_name, "result": json.dumps(payload, ensure_ascii=False)})
                messages.append(ToolMessage(content=json.dumps(payload, ensure_ascii=False), tool_call_id=tool_id))
                confirmation_status = "pending_other_action"
                continue

        try:
            output = await tool_fn.ainvoke(args)
            payload = _parse_tool_payload(str(output))
            results.append({"tool": tool_name, "result": str(output), "parsed": payload})
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
        "pending_write_action": next_pending,
        "last_confirmation_status": confirmation_status,
    }
