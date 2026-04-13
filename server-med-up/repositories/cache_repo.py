from __future__ import annotations

import hashlib
from datetime import datetime, timedelta, timezone
from typing import Any

from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from core.config import settings
from models.cache import ResponseCache


def make_key(normalized_query: str, intent: str, kb_version: int) -> str:
    raw = f"{kb_version}|{intent}|{normalized_query}"
    return hashlib.sha256(raw.encode()).hexdigest()[:48]


def get_cached(db: Session, cache_key: str) -> ResponseCache | None:
    now = datetime.now(timezone.utc)
    stmt = select(ResponseCache).where(
        ResponseCache.cache_key == cache_key,
        ResponseCache.kb_version == settings.kb_version,
        ResponseCache.expires_at > now,
    )
    row = db.scalars(stmt).first()
    if row:
        row.hit_count += 1
        db.flush()
    return row


def set_cached(
    db: Session,
    *,
    cache_key: str,
    query_text: str,
    intent: str,
    reply: str,
    tool_calls: list[dict[str, Any]] | None = None,
    suggested_actions: list[dict[str, Any]] | None = None,
    ttl_hours: int | None = None,
) -> ResponseCache:
    ttl = ttl_hours or settings.cag_default_ttl_hours
    expires = datetime.now(timezone.utc) + timedelta(hours=ttl)
    row = ResponseCache(
        cache_key=cache_key,
        query_text=query_text,
        intent=intent,
        kb_version=settings.kb_version,
        reply=reply,
        tool_calls=tool_calls,
        suggested_actions=suggested_actions,
        expires_at=expires,
    )
    db.merge(row)
    db.flush()
    return row


def invalidate_all(db: Session) -> int:
    result = db.execute(delete(ResponseCache))
    db.flush()
    return result.rowcount  # type: ignore[return-value]
