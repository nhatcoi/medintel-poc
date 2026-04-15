from __future__ import annotations

import uuid
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from models.chat import ChatMessage, ChatSession


def get_or_create_session(db: Session, profile_id: uuid.UUID, session_id: uuid.UUID | None = None) -> ChatSession:
    if session_id:
        existing = db.get(ChatSession, session_id)
        if existing:
            return existing
    sess = ChatSession(profile_id=profile_id)
    db.add(sess)
    db.flush()
    return sess


def add_message(
    db: Session,
    *,
    session_id: uuid.UUID | None,
    profile_id: uuid.UUID,
    role: str,
    content: str,
    tool_calls: list[dict[str, Any]] | None = None,
    suggested_actions: list[dict[str, Any]] | None = None,
) -> ChatMessage:
    msg = ChatMessage(
        session_id=session_id,
        profile_id=profile_id,
        role=role,
        content=content,
        tool_calls=tool_calls,
        suggested_actions=suggested_actions,
    )
    db.add(msg)
    db.flush()
    return msg


def get_pending_agent(db: Session, session_id: uuid.UUID) -> dict[str, Any] | None:
    row = db.get(ChatSession, session_id)
    if row is None or not row.pending_agent_json:
        return None
    data = row.pending_agent_json
    return data if isinstance(data, dict) and data.get("tool") else None


def set_pending_agent(db: Session, session_id: uuid.UUID, pending: dict[str, Any] | None) -> None:
    row = db.get(ChatSession, session_id)
    if row is None:
        return
    if pending is None or not pending.get("tool"):
        row.pending_agent_json = None
    else:
        row.pending_agent_json = pending
    db.flush()


def load_recent_turns(db: Session, session_id: uuid.UUID, limit: int = 10) -> list[dict[str, str]]:
    stmt = (
        select(ChatMessage)
        .where(ChatMessage.session_id == session_id)
        .order_by(ChatMessage.created_at.desc())
        .limit(limit)
    )
    rows = list(db.scalars(stmt).all())
    rows.reverse()
    return [
        {"role": m.role, "content": m.content}
        for m in rows
        if m.role in ("user", "assistant") and (m.content or "").strip()
    ]
