"""Short-term memory: lịch sử hội thoại gần nhất trong phiên."""

from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.chat import ChatMessage

# Số lượt (user+assistant) tối đa nạp vào context — tránh phình prompt.
DEFAULT_HISTORY_LIMIT = 10


def load_recent_turns(
    db: Session,
    session_id: uuid.UUID,
    limit: int = DEFAULT_HISTORY_LIMIT,
) -> list[dict[str, str]]:
    """Trả về danh sách message {role, content} theo thứ tự cũ → mới (sẵn sàng cho LLM)."""
    stmt = (
        select(ChatMessage)
        .where(ChatMessage.session_id == session_id)
        .order_by(ChatMessage.created_at.desc())
        .limit(limit)
    )
    rows = db.execute(stmt).scalars().all()
    ordered = list(reversed(rows))
    out: list[dict[str, str]] = []
    for m in ordered:
        if m.role not in ("user", "assistant"):
            continue
        content = (m.content or "").strip()
        if not content:
            continue
        out.append({"role": m.role, "content": content})
    return out
