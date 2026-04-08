"""Luồng chat agentic: ReAct loop (memory + RAG) + persist phiên."""

from __future__ import annotations

import uuid
import logging

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.chat import ChatMessage, ChatSession
from app.repositories.profile_repository import get_by_id
from app.schemas.chat import (
    ChatRequest,
    ChatResponse,
    Citation,
    SuggestedAction,
    ToolCall,
)
from app.services.agent.medication_context import build_medication_context_block
from app.services.agent.react_loop import run_react_turn
from app.services.agent.registry import SERVER_SIDE_TOOLS
from app.services.memory.long_term import upsert_memory
from app.services.cag import (
    CachedResponse,
    classify_intent,
    get_cached,
    is_cacheable_request,
    is_cacheable_response,
    make_cache_key,
    normalize_query,
    set_cached,
)

_log = logging.getLogger("medintel.chat")


def _resolve_session(
    db: Session, profile_id: uuid.UUID, session_id_str: str | None
) -> ChatSession | None:
    """Tìm session hiện có nếu ID hợp lệ & thuộc profile; nếu không trả về None."""
    if not (session_id_str and session_id_str.strip()):
        return None
    try:
        s_uuid = uuid.UUID(session_id_str.strip())
    except ValueError:
        return None
    cand = db.get(ChatSession, s_uuid)
    if cand is not None and cand.profile_id == profile_id:
        return cand
    return None


def _persist_agentic_turn(
    db: Session,
    *,
    profile_id: uuid.UUID,
    existing_session: ChatSession | None,
    user_text: str,
    reply_text: str,
    actions: list[SuggestedAction],
    tools: list[ToolCall],
) -> uuid.UUID | None:
    profile = get_by_id(db, profile_id)
    if profile is None:
        return None

    chat_session = existing_session
    if chat_session is None:
        chat_session = ChatSession(profile_id=profile_id, title=None)
        db.add(chat_session)
        db.flush()

    db.add(
        ChatMessage(
            session_id=chat_session.id,
            profile_id=profile_id,
            role="user",
            content=user_text,
        )
    )
    tools_json = [{"tool": t.tool, "args": dict(t.args)} for t in tools]
    actions_json = [{"label": a.label, "prompt": a.prompt} for a in actions]
    db.add(
        ChatMessage(
            session_id=chat_session.id,
            profile_id=profile_id,
            role="assistant",
            content=reply_text,
            tool_calls=tools_json or None,
            suggested_actions=actions_json or None,
            model_name=settings.llm_model,
        )
    )
    db.commit()
    return chat_session.id


def _resolve_profile_id(body: ChatRequest) -> uuid.UUID | None:
    if not (body.profile_id and body.profile_id.strip()):
        return None
    try:
        return uuid.UUID(body.profile_id.strip())
    except ValueError:
        return None


def _resolve_medication_context(
    db: Session, body: ChatRequest, profile_id: uuid.UUID | None
) -> str | None:
    if not body.include_medication_context or profile_id is None:
        return None
    if get_by_id(db, profile_id) is None:
        return None
    return build_medication_context_block(db, profile_id)


def _execute_server_tools(
    db: Session,
    profile_id: uuid.UUID | None,
    tool_calls: list[dict],
) -> tuple[list[dict], list[dict]]:
    """Thực thi các server-side tool_calls ngay trên server.

    Trả về (client_tools, executed_tools):
    - client_tools: những tool còn lại để trả về app
    - executed_tools: những tool đã chạy server-side (để log)
    """
    client_tools: list[dict] = []
    executed: list[dict] = []

    for tc in tool_calls:
        tool_name = tc.get("tool", "")
        if tool_name not in SERVER_SIDE_TOOLS:
            client_tools.append(tc)
            continue

        args = tc.get("args") or {}
        try:
            if tool_name == "update_patient_memory" and profile_id is not None:
                key = str(args.get("key") or "").strip()
                value = args.get("value")
                confidence = float(args.get("confidence") or 0.9)
                if key and value is not None:
                    upsert_memory(
                        db,
                        profile_id,
                        key,
                        value,
                        source="llm_inferred",
                        confidence=min(max(confidence, 0.0), 1.0),
                    )
                    db.commit()
                    executed.append(tc)
        except Exception:  # noqa: BLE001
            db.rollback()

    return client_tools, executed


def _build_fallback_citations_from_trace(trace) -> tuple[str, float, list[Citation]]:
    """Suy ra nguồn/citation từ ReAct trace khi LLM không trả đủ metadata."""
    if trace is None:
        return (
            "model",
            0.3,
            [Citation(title="Model prior knowledge", url=None, source_type="model")],
        )

    has_external = bool(getattr(trace, "tavily_hit_count", 0) > 0 and getattr(trace, "tavily_urls", []))
    has_internal = bool(getattr(trace, "rag_hit_count", 0) > 0)

    citations: list[Citation] = []
    if has_internal:
        citations.append(
            Citation(
                title="MedIntel internal drug knowledge base",
                url=None,
                source_type="internal",
            )
        )
    if has_external:
        urls = list(getattr(trace, "tavily_urls", []))
        if urls:
            citations.append(
                Citation(
                    title="Trusted external medical web sources",
                    url=urls[0],
                    source_type="external",
                )
            )
    if citations:
        if has_internal and has_external:
            return ("mixed", 0.7, citations)
        if has_external:
            return ("external", 0.6, citations)
        return ("internal", 0.75, citations)

    return (
        "model",
        0.3,
        [Citation(title="Model prior knowledge", url=None, source_type="model")],
    )


def _result_to_response(turn, session_id: str | None, trace=None) -> ChatResponse:
    actions = [
        SuggestedAction(
            label=a["label"],
            prompt=a["prompt"] if a.get("prompt") else a["label"],
        )
        for a in turn.suggested_actions
    ]
    tools = [ToolCall(tool=t["tool"], args=t.get("args") or {}) for t in turn.tool_calls]
    citations = [
        Citation(
            title=str(c.get("title") or "").strip(),
            url=(str(c.get("url")).strip() if c.get("url") else None),
            source_type=str(c.get("source_type") or "internal").strip().lower(),
        )
        for c in (turn.citations or [])
        if str(c.get("title") or "").strip()
    ]
    source_type = str(turn.source_type or "").strip().lower()
    confidence = float(turn.confidence if turn.confidence is not None else 0.4)
    if not citations or source_type not in {"internal", "external", "mixed", "model"}:
        fb_source_type, fb_confidence, fb_citations = _build_fallback_citations_from_trace(trace)
        if not citations:
            citations = fb_citations
        if source_type not in {"internal", "external", "mixed", "model"}:
            source_type = fb_source_type
        if not (0.0 <= confidence <= 1.0):
            confidence = fb_confidence

    return ChatResponse(
        reply=turn.reply,
        source_type=source_type,
        confidence=max(0.0, min(1.0, confidence)),
        citations=citations,
        session_id=session_id,
        suggested_actions=actions,
        tool_calls=tools,
    )


def _log_retrieval_trace(trace, final_source_type: str) -> None:
    if trace is None:
        _log.info(
            "chat_trace rag_hit_count=%d tavily_hit_count=%d final_source_type=%s",
            0,
            0,
            final_source_type,
        )
        return
    _log.info(
        "chat_trace rag_hit_count=%d tavily_hit_count=%d final_source_type=%s",
        int(getattr(trace, "rag_hit_count", 0)),
        int(getattr(trace, "tavily_hit_count", 0)),
        final_source_type,
    )


def _cached_to_response(cached: CachedResponse, session_id: str | None) -> ChatResponse:
    actions = [
        SuggestedAction(
            label=a.get("label", ""),
            prompt=a.get("prompt") or a.get("label", ""),
        )
        for a in cached.suggested_actions
        if a.get("label")
    ]
    tools = [
        ToolCall(tool=t.get("tool", ""), args=t.get("args") or {})
        for t in cached.tool_calls
        if t.get("tool")
    ]
    return ChatResponse(
        reply=cached.reply,
        source_type="internal",
        confidence=0.85,
        citations=[Citation(title="MedIntel cached response", url=None, source_type="internal")],
        session_id=session_id,
        suggested_actions=actions,
        tool_calls=tools,
    )


async def preview_chat_message(db: Session, body: ChatRequest) -> ChatResponse:
    """Chạy ReAct + LLM, KHÔNG lưu DB (dry-run)."""
    text = body.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Text must not be empty")

    profile_id = _resolve_profile_id(body)
    base_context = _resolve_medication_context(db, body, profile_id)

    # Preview có thể vẫn dùng session_id sẵn có để load history (read-only)
    existing_session = (
        _resolve_session(db, profile_id, body.session_id) if profile_id else None
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

    response = _result_to_response(turn, session_id=None, trace=trace)
    _log_retrieval_trace(trace, response.source_type)
    return response


async def process_chat_message(db: Session, body: ChatRequest) -> ChatResponse:
    text = body.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Text must not be empty")

    profile_id = _resolve_profile_id(body)
    base_context = _resolve_medication_context(db, body, profile_id)

    existing_session = (
        _resolve_session(db, profile_id, body.session_id) if profile_id else None
    )
    session_uuid = existing_session.id if existing_session else None

    # --- CAG: kiểm tra cache (chỉ với câu hỏi generic) ---
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
            return _cached_to_response(cached, session_id=None)

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

    response = _result_to_response(turn, session_id=None, trace=trace)
    _log_retrieval_trace(trace, response.source_type)

    # --- Thực thi server-side tools (update_patient_memory, …) ---
    if profile_id is not None and response.tool_calls:
        raw_tools = [{"tool": t.tool, "args": dict(t.args)} for t in response.tool_calls]
        client_tools_raw, _executed = _execute_server_tools(db, profile_id, raw_tools)
        # Cập nhật lại response chỉ giữ client tools
        response.tool_calls = [
            ToolCall(tool=t["tool"], args=t.get("args") or {})
            for t in client_tools_raw
        ]

    # --- CAG: ghi cache nếu response an toàn ---
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
                    {"label": a.label, "prompt": a.prompt}
                    for a in response.suggested_actions
                ],
            )
        except Exception:  # noqa: BLE001
            db.rollback()

    saved_session: uuid.UUID | None = None
    if profile_id is not None:
        try:
            saved_session = _persist_agentic_turn(
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
