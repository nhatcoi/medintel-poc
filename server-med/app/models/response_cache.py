"""CAG: cache kết quả LLM theo normalized query + kb_version."""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import DateTime, Integer, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from database.session import Base, GUID

from app.models.mixins import utc_now


class ResponseCache(Base):
    """Cache cho câu trả lời LLM (generic, không cá nhân hóa)."""

    __tablename__ = "response_cache"

    id: Mapped[uuid.UUID] = mapped_column(
        "cache_id", GUID, primary_key=True, default=uuid.uuid4
    )
    cache_key: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    query_text: Mapped[str] = mapped_column(Text)
    intent: Mapped[str | None] = mapped_column(String(64), nullable=True)
    kb_version: Mapped[int] = mapped_column(Integer, default=1)

    reply: Mapped[str] = mapped_column(Text)
    tool_calls: Mapped[list[dict[str, Any]] | None] = mapped_column(JSON, nullable=True)
    suggested_actions: Mapped[list[dict[str, Any]] | None] = mapped_column(
        JSON, nullable=True
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now
    )
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    hit_count: Mapped[int] = mapped_column(Integer, default=0)
