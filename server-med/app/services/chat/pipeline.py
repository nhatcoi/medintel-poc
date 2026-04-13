"""Orchestration: ReAct + LLM, CAG cache, persist phiên chat."""

from __future__ import annotations

import uuid

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.core.config import settings
from app.schemas.chat import ChatRequest, ChatResponse, ToolCall
from app.services.agent.react_loop import run_react_turn
from app.services.cag import (
    classify_intent,
    get_cached,
    is_cacheable_request,
    is_cacheable_response,
    make_cache_key,
    normalize_query,
    set_cached,
)
from app.services.chat.context import resolve_combined_chat_context, resolve_profile_id
from app.services.chat.persistence import persist_agentic_turn, resolve_session
from app.services.chat.response import (
    cached_to_response,
    log_retrieval_trace,
    result_to_response,
)
from app.services.chat.server_tools import execute_server_tools


async def preview_chat_message(db: Session, body: ChatRequest) -> ChatResponse:
    """Chạy ReAct + LLM, KHÔNG lưu DB (dry-run)."""
    text = body.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Text must not be empty")

    profile_id = resolve_profile_id(body)
    base_context = resolve_combined_chat_context(db, body, profile_id)

    existing_session = (
        resolve_session(db, profile_id, body.session_id) if profile_id else None
    )
    session_uuid = existing_session.id if existing_session else None

    try:
        turn, trace = await run_react_turn(
            db,
            profile_id=profile_id,
            session_id=session_uuid,
            user_text=text,
            base_context=base_context,
        )
    except HTTPException:
        raise
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=502, detail=f"LLM error: {exc}") from exc

    response = result_to_response(turn, session_id=None, trace=trace)
    log_retrieval_trace(trace, response.source_type)
    return response


async def process_chat_message(db: Session, body: ChatRequest) -> ChatResponse:
    text = body.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Text must not be empty")

    profile_id = resolve_profile_id(body)
    base_context = resolve_combined_chat_context(db, body, profile_id)

    existing_session = (
        resolve_session(db, profile_id, body.session_id) if profile_id else None
    )
    session_uuid = existing_session.id if existing_session else None

    cache_eligible = is_cacheable_request(
        user_text=text,
        profile_id=profile_id,
        session_id=session_uuid,
        include_medication_context=body.include_medication_context,
    )
    cache_key: str | None = None
    intent: str | None = None
    if cache_eligible:
        normalized = normalize_query(text)
        intent = classify_intent(normalized)
        cache_key = make_cache_key(normalized, intent, settings.kb_version)
        try:
            cached = get_cached(db, cache_key)
        except Exception:  # noqa: BLE001
            cached = None
        if cached is not None:
            return cached_to_response(cached, session_id=None)

    try:
        turn, trace = await run_react_turn(
            db,
            profile_id=profile_id,
            session_id=session_uuid,
            user_text=text,
            base_context=base_context,
        )
    except HTTPException:
        raise
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=502, detail=f"LLM error: {exc}") from exc

    response = result_to_response(turn, session_id=None, trace=trace)
    log_retrieval_trace(trace, response.source_type)

    if profile_id is not None and response.tool_calls:
        raw_tools = [{"tool": t.tool, "args": dict(t.args)} for t in response.tool_calls]
        client_tools_raw, _executed = execute_server_tools(db, profile_id, raw_tools)
        response.tool_calls = [
            ToolCall(tool=t["tool"], args=t.get("args") or {})
            for t in client_tools_raw
        ]

    if cache_eligible and cache_key is not None and is_cacheable_response(
        tool_calls=[{"tool": t.tool, "args": dict(t.args)} for t in response.tool_calls],
        reply=response.reply,
    ):
        try:
            set_cached(
                db,
                cache_key=cache_key,
                query_text=text,
                intent=intent or "generic_qa",
                reply=response.reply,
                tool_calls=[
                    {"tool": t.tool, "args": dict(t.args)} for t in response.tool_calls
                ],
                suggested_actions=[
                    {"label": a.label, "prompt": a.prompt, "category": a.category}
                    for a in response.suggested_actions
                ],
            )
        except Exception:  # noqa: BLE001
            db.rollback()

    saved_session: uuid.UUID | None = None
    if profile_id is not None:
        try:
            saved_session = persist_agentic_turn(
                db,
                profile_id=profile_id,
                existing_session=existing_session,
                user_text=text,
                reply_text=response.reply,
                actions=response.suggested_actions,
                tools=response.tool_calls,
            )
        except Exception:
            db.rollback()
            raise

    if saved_session:
        response.session_id = str(saved_session)
    return response
