"""Luồng chat agentic: LLM + ngữ cảnh thuốc + lưu phiên."""

from __future__ import annotations

import uuid

from fastapi import HTTPException
from sqlalchemy.orm import Session

from ai.chatbot import reply as llm_reply
from app.core.config import settings
from app.models.chat import ChatMessage, ChatSession
from app.repositories.profile_repository import get_by_id
from app.schemas.chat import ChatRequest, ChatResponse, SuggestedAction, ToolCall
from app.services.agent.medication_context import build_medication_context_block


def _persist_agentic_turn(
    db: Session,
    *,
    profile_id: uuid.UUID,
    session_id: str | None,
    user_text: str,
    reply_text: str,
    actions: list[SuggestedAction],
    tools: list[ToolCall],
) -> uuid.UUID | None:
    profile = get_by_id(db, profile_id)
    if profile is None:
        return None

    chat_session: ChatSession | None = None
    if session_id and session_id.strip():
        try:
            s_uuid = uuid.UUID(session_id.strip())
            cand = db.get(ChatSession, s_uuid)
            if cand is not None and cand.profile_id == profile_id:
                chat_session = cand
        except ValueError:
            pass

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


def _resolve_medication_context(db: Session, body: ChatRequest) -> str | None:
    if not (body.include_medication_context and body.profile_id and body.profile_id.strip()):
        return None
    try:
        pid = uuid.UUID(body.profile_id.strip())
    except ValueError:
        return None
    if get_by_id(db, pid) is None:
        return None
    return build_medication_context_block(db, pid)


async def preview_chat_message(db: Session, body: ChatRequest) -> ChatResponse:
    """LLM + tool_calls, không lưu DB."""
    text = body.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Text must not be empty")

    extra_context = _resolve_medication_context(db, body)

    try:
        turn = await llm_reply(text, extra_context=extra_context)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"LLM error: {exc}") from exc

    actions = [
        SuggestedAction(
            label=a["label"],
            prompt=a["prompt"] if a.get("prompt") else a["label"],
        )
        for a in turn.suggested_actions
    ]
    tools = [ToolCall(tool=t["tool"], args=t.get("args") or {}) for t in turn.tool_calls]
    return ChatResponse(
        reply=turn.reply,
        session_id=None,
        suggested_actions=actions,
        tool_calls=tools,
    )


async def process_chat_message(db: Session, body: ChatRequest) -> ChatResponse:
    text = body.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Text must not be empty")

    extra_context = _resolve_medication_context(db, body)

    try:
        turn = await llm_reply(text, extra_context=extra_context)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"LLM error: {exc}") from exc

    actions = [
        SuggestedAction(
            label=a["label"],
            prompt=a["prompt"] if a.get("prompt") else a["label"],
        )
        for a in turn.suggested_actions
    ]
    tools = [ToolCall(tool=t["tool"], args=t.get("args") or {}) for t in turn.tool_calls]

    saved_session: uuid.UUID | None = None
    if body.profile_id and body.profile_id.strip():
        try:
            pid = uuid.UUID(body.profile_id.strip())
            saved_session = _persist_agentic_turn(
                db,
                profile_id=pid,
                session_id=body.session_id,
                user_text=text,
                reply_text=turn.reply,
                actions=actions,
                tools=tools,
            )
        except ValueError:
            pass
        except Exception:
            db.rollback()
            raise

    return ChatResponse(
        reply=turn.reply,
        session_id=str(saved_session) if saved_session else None,
        suggested_actions=actions,
        tool_calls=tools,
    )
