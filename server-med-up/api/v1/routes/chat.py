"""Chat endpoint: invokes the LangGraph agent graph."""

from __future__ import annotations

import logging
import time
import uuid

from fastapi import APIRouter, HTTPException, Query, Response
from langchain_core.messages import HumanMessage

from api.deps import DbSession
from schemas.chat import (
    ChatRequest,
    ChatResponse,
    Citation,
    SuggestedAction,
    SuggestedQuestionsResponse,
    ToolCall,
    WelcomeHintsResponse,
)
from cache.cag import is_cacheable_request, is_cacheable_response, try_cache_lookup, write_cache
from repositories import chat_repo, profile_repo
from services.welcome_service import build_suggested_questions, build_welcome_hints

router = APIRouter(prefix="/chat", tags=["chat"])
_log = logging.getLogger("medintel.chat")


def _clip(value: object, max_chars: int = 3000) -> str:
    text = str(value)
    if len(text) <= max_chars:
        return text
    return f"{text[:max_chars]} ...[truncated {len(text) - max_chars} chars]"


async def _invoke_graph(
    *,
    text: str,
    profile_id: str | None,
    session_id: str | None,
    include_medication_context: bool,
) -> ChatResponse:
    from agent.graph import graph

    initial_state = {
        "messages": [HumanMessage(content=text)],
        "profile_id": profile_id,
        "session_id": session_id,
        "include_medication_context": include_medication_context,
    }

    config = {"configurable": {"thread_id": session_id or str(uuid.uuid4())}}
    result = await graph.ainvoke(initial_state, config=config)

    return ChatResponse(
        reply=result.get("reply", ""),
        source_type=result.get("source_type", "model"),
        confidence=result.get("confidence", 0.4),
        citations=[Citation(**c) for c in result.get("citations", [])],
        tool_calls=[ToolCall(**t) for t in result.get("tool_calls", [])],
        suggested_actions=[SuggestedAction(**a) for a in result.get("suggested_actions", [])],
        session_id=session_id,
    )


@router.post("/message", response_model=ChatResponse)
async def send_message(body: ChatRequest, db: DbSession, response: Response):
    t0 = time.perf_counter()
    text = body.text.strip()
    _log.info(
        "CHAT_IN profile_id=%s session_id=%s include_medication_context=%s text=%s",
        body.profile_id,
        body.session_id,
        body.include_medication_context,
        _clip(text),
    )
    if not text:
        raise HTTPException(status_code=400, detail="Text must not be empty")

    profile_uuid: uuid.UUID | None = None
    if body.profile_id and body.profile_id.strip():
        try:
            profile_uuid = uuid.UUID(body.profile_id.strip())
        except ValueError as exc:
            raise HTTPException(status_code=400, detail="profile_id phai la UUID hop le") from exc
        if profile_repo.get_by_id(db, profile_uuid) is None:
            raise HTTPException(status_code=404, detail="Khong tim thay profile")

    request_session_uuid: uuid.UUID | None = None
    if body.session_id and body.session_id.strip():
        try:
            request_session_uuid = uuid.UUID(body.session_id.strip())
        except ValueError as exc:
            raise HTTPException(status_code=400, detail="session_id phai la UUID hop le") from exc

    effective_session_id: str | None = body.session_id
    if profile_uuid is not None:
        sess = chat_repo.get_or_create_session(db, profile_uuid, request_session_uuid)
        effective_session_id = str(sess.id)
        db.commit()

    if is_cacheable_request(text, body.profile_id, body.session_id, body.include_medication_context):
        cached = try_cache_lookup(db, text)
        if cached:
            ms = (time.perf_counter() - t0) * 1000
            response.headers["X-Process-Time-Ms"] = f"{ms:.1f}"
            _log.info("CHAT_CACHE_HIT profile_id=%s session_id=%s", body.profile_id, body.session_id)
            if profile_uuid is not None and effective_session_id is not None:
                sid = uuid.UUID(effective_session_id)
                chat_repo.add_message(
                    db,
                    session_id=sid,
                    profile_id=profile_uuid,
                    role="user",
                    content=text,
                )
                chat_repo.add_message(
                    db,
                    session_id=sid,
                    profile_id=profile_uuid,
                    role="assistant",
                    content=cached["reply"],
                )
                db.commit()
            return ChatResponse(reply=cached["reply"], session_id=effective_session_id)

    result = await _invoke_graph(
        text=text,
        profile_id=body.profile_id,
        session_id=effective_session_id,
        include_medication_context=body.include_medication_context,
    )

    if is_cacheable_request(text, body.profile_id, body.session_id, body.include_medication_context):
        raw_tools = [{"tool": t.tool, "args": t.args} for t in result.tool_calls]
        if is_cacheable_response(raw_tools, result.reply):
            try:
                write_cache(db, text, result.reply)
                db.commit()
            except Exception:
                db.rollback()

    if profile_uuid is not None and effective_session_id is not None:
        sid = uuid.UUID(effective_session_id)
        chat_repo.add_message(
            db,
            session_id=sid,
            profile_id=profile_uuid,
            role="user",
            content=text,
        )
        chat_repo.add_message(
            db,
            session_id=sid,
            profile_id=profile_uuid,
            role="assistant",
            content=result.reply,
            tool_calls=[{"tool": t.tool, "args": t.args} for t in result.tool_calls],
            suggested_actions=[
                {"label": a.label, "prompt": a.prompt, "category": a.category}
                for a in result.suggested_actions
            ],
        )
        db.commit()

    ms = (time.perf_counter() - t0) * 1000
    response.headers["X-Process-Time-Ms"] = f"{ms:.1f}"
    _log.info(
        "CHAT_OUT profile_id=%s session_id=%s tool_calls=%s reply=%s duration_ms=%.1f",
        body.profile_id,
        result.session_id or body.session_id,
        [t.tool for t in result.tool_calls],
        _clip(result.reply),
        ms,
    )
    result.session_id = effective_session_id
    return result


@router.post("/message/dry-run", response_model=ChatResponse)
async def send_message_dry_run(body: ChatRequest, response: Response):
    t0 = time.perf_counter()
    text = body.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Text must not be empty")
    result = await _invoke_graph(
        text=text,
        profile_id=body.profile_id,
        session_id=body.session_id,
        include_medication_context=body.include_medication_context,
    )
    ms = (time.perf_counter() - t0) * 1000
    response.headers["X-Process-Time-Ms"] = f"{ms:.1f}"
    return result


@router.get("/suggested-questions", response_model=SuggestedQuestionsResponse)
async def get_suggested_questions(db: DbSession, profile_id: str = Query(...)):
    try:
        pid = uuid.UUID(profile_id.strip())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="profile_id phai la UUID") from exc
    if profile_repo.get_by_id(db, pid) is None:
        raise HTTPException(status_code=404, detail="Khong tim thay profile")
    questions, source = await build_suggested_questions(db, pid)
    return SuggestedQuestionsResponse(questions=questions, source=source)


@router.get("/welcome-hints", response_model=WelcomeHintsResponse)
async def get_welcome_hints(db: DbSession, profile_id: str = Query(...)):
    try:
        pid = uuid.UUID(profile_id.strip())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="profile_id phai la UUID") from exc
    if profile_repo.get_by_id(db, pid) is None:
        raise HTTPException(status_code=404, detail="Khong tim thay profile")
    hints, source = await build_welcome_hints(db, pid)
    return WelcomeHintsResponse(hints=hints, source=source)
