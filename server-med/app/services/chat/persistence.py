"""Lưu / tải phiên chat (ChatSession, ChatMessage)."""

from __future__ import annotations

import uuid

from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.chat import ChatMessage, ChatSession
from app.repositories.profile_repository import get_by_id
from app.schemas.chat import SuggestedAction, ToolCall


def resolve_session(
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


def persist_agentic_turn(
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
    actions_json = [
        {"label": a.label, "prompt": a.prompt, "category": a.category} for a in actions
    ]
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
